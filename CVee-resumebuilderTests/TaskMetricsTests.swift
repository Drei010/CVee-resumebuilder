import XCTest
@testable import CVee_resumebuilder

@MainActor
final class TaskMetricsTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private lazy var now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 9, hour: 12))!

    private func task(_ company: String, daysAgo: Int = 90) -> TaskMetricsSnapshot.TaskRecord {
        TaskMetricsSnapshot.TaskRecord(id: UUID(), company: company,
                                       createdAt: calendar.date(byAdding: .day, value: -daysAgo, to: now)!)
    }

    func testUsageCountsEachTaskOnceAcrossResumes() {
        let tasks = [task("Acme"), task("Acme"), task("Globex"), task("Initech")]
        let snapshot = TaskMetricsSnapshot(tasks: tasks,
                                           resumeTaskIDs: [[tasks[0].id, tasks[1].id], [tasks[0].id, UUID()]],
                                           resumeDates: [now, now],
                                           jobCount: 0, readyJobCount: 0, now: now, calendar: calendar)
        XCTAssertEqual(snapshot.totalTasks, 4)
        XCTAssertEqual(snapshot.usedTasks, 2)
        XCTAssertEqual(snapshot.usedFraction ?? -1, 0.5, accuracy: 0.0001)
    }

    func testEmptyLibraryHasNoUsageFraction() {
        let snapshot = TaskMetricsSnapshot(tasks: [], resumeTaskIDs: [], resumeDates: [],
                                           jobCount: 0, readyJobCount: 0, now: now, calendar: calendar)
        XCTAssertNil(snapshot.usedFraction)
        XCTAssertTrue(snapshot.companyShares.isEmpty)
    }

    func testCompanySharesKeepTopFourAndGroupTheRest() {
        let tasks = [task("A"), task("A"), task("A"), task("B"), task("B"), task("C"), task("D"), task("E"), task("F"), task("  ")]
        let snapshot = TaskMetricsSnapshot(tasks: tasks, resumeTaskIDs: [], resumeDates: [],
                                           jobCount: 0, readyJobCount: 0, now: now, calendar: calendar)
        XCTAssertEqual(snapshot.companyShares.map(\.name), ["A", "B", "C", "D", "Other"])
        XCTAssertEqual(snapshot.companyShares.map(\.count), [3, 2, 1, 1, 3])
        XCTAssertTrue(snapshot.companyShares.last?.isOther == true)
        XCTAssertEqual(snapshot.companyShares.reduce(0) { $0 + $1.count }, tasks.count)
    }

    func testBlankCompanyIsLabelledWorkHistory() {
        let snapshot = TaskMetricsSnapshot(tasks: [task("")], resumeTaskIDs: [], resumeDates: [],
                                           jobCount: 0, readyJobCount: 0, now: now, calendar: calendar)
        XCTAssertEqual(snapshot.companyShares.map(\.name), ["Work history"])
    }

    func testRecentTasksAndResumesThisMonth() {
        let tasks = [task("A", daysAgo: 2), task("A", daysAgo: 29), task("A", daysAgo: 31)]
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        let snapshot = TaskMetricsSnapshot(tasks: tasks, resumeTaskIDs: [[], []], resumeDates: [now, lastMonth],
                                           jobCount: 3, readyJobCount: 2, now: now, calendar: calendar)
        XCTAssertEqual(snapshot.recentTaskCount, 2)
        XCTAssertEqual(snapshot.resumeCount, 2)
        XCTAssertEqual(snapshot.resumesThisMonth, 1)
        XCTAssertEqual(snapshot.readyJobCount, 2)
        XCTAssertEqual(snapshot.jobCount, 3)
    }

    func testLayoutRoundTripsAndIgnoresUnknownOrRepeatedWidgets() {
        XCTAssertEqual(TaskMetricLayout.decode(TaskMetricLayout.defaultRaw), [.companyMix, .resumeUsage])
        XCTAssertEqual(TaskMetricLayout.decode("recentTasks, bogus,recentTasks,jobsReady"), [.recentTasks, .jobsReady])
        XCTAssertEqual(TaskMetricLayout.decode(""), [])
        let layout: [TaskMetricWidget] = [.jobsReady, .companyMix]
        XCTAssertEqual(TaskMetricLayout.decode(TaskMetricLayout.encode(layout)), layout)
    }
}
