import SwiftUI
import Charts

// Progress widgets on the Tasks tab. People choose which widgets appear and in what order;
// the choice is stored as a comma-separated list under `TaskMetricLayout.storageKey`.

enum TaskMetricWidget: String, CaseIterable, Identifiable {
    case companyMix, resumeUsage, resumesSaved, jobsReady, recentTasks

    static let defaultLayout: [TaskMetricWidget] = [.companyMix, .resumeUsage]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .companyMix: "Tasks by company"
        case .resumeUsage: "Used in resumes"
        case .resumesSaved: "Resumes saved"
        case .jobsReady: "Jobs ready"
        case .recentTasks: "Last 30 days"
        }
    }

    var summary: String {
        switch self {
        case .companyMix: "Pie chart of your tasks by company"
        case .resumeUsage: "Share of tasks you have used in a resume"
        case .resumesSaved: "Resumes saved, and how many this month"
        case .jobsReady: "Saved jobs that are ready for a resume"
        case .recentTasks: "Tasks recorded in the last 30 days"
        }
    }

    var systemImage: String {
        switch self {
        case .companyMix: "chart.pie"
        case .resumeUsage: "checkmark.seal"
        case .resumesSaved: "doc.text"
        case .jobsReady: "bookmark"
        case .recentTasks: "calendar"
        }
    }
}

enum TaskMetricLayout {
    static let storageKey = "tasks.metricWidgets"
    static let defaultRaw = encode(TaskMetricWidget.defaultLayout)

    /// Unknown or repeated names are dropped, so older or hand-edited values still load.
    static func decode(_ raw: String) -> [TaskMetricWidget] {
        var seen = Set<TaskMetricWidget>()
        return raw.split(separator: ",").compactMap { name in
            guard let widget = TaskMetricWidget(rawValue: name.trimmingCharacters(in: .whitespaces)),
                  seen.insert(widget).inserted else { return nil }
            return widget
        }
    }

    static func encode(_ widgets: [TaskMetricWidget]) -> String {
        widgets.map(\.rawValue).joined(separator: ",")
    }
}

/// Plain values the widgets need, computed from the work library, saved resumes and saved jobs.
struct TaskMetricsSnapshot: Equatable {
    struct CompanyShare: Identifiable, Equatable {
        let name: String
        let count: Int
        let isOther: Bool
        var id: String { isOther ? "\u{0}other" : name }
    }

    struct TaskRecord {
        let id: UUID
        let company: String
        let createdAt: Date
    }

    static let maxNamedCompanies = 4

    let totalTasks: Int
    let usedTasks: Int
    let companyShares: [CompanyShare]
    let resumeCount: Int
    let resumesThisMonth: Int
    let jobCount: Int
    let readyJobCount: Int
    let recentTaskCount: Int

    var usedFraction: Double? { totalTasks == 0 ? nil : Double(usedTasks) / Double(totalTasks) }

    init(tasks: [TaskRecord], resumeTaskIDs: [[UUID]], resumeDates: [Date], jobCount: Int, readyJobCount: Int,
         now: Date = .now, calendar: Calendar = .current) {
        totalTasks = tasks.count
        let usedIDs = Set(resumeTaskIDs.flatMap { $0 })
        usedTasks = tasks.filter { usedIDs.contains($0.id) }.count

        let byCompany: [String: [TaskRecord]] = Dictionary(grouping: tasks) {
            $0.company.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let counted: [(name: String, count: Int)] = byCompany.map { entry in
            (name: entry.key.isEmpty ? "Work history" : entry.key, count: entry.value.count)
        }
        let grouped = counted.sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
        var shares = grouped.prefix(Self.maxNamedCompanies).map { CompanyShare(name: $0.name, count: $0.count, isOther: false) }
        let otherCount = grouped.dropFirst(Self.maxNamedCompanies).reduce(0) { $0 + $1.count }
        if otherCount > 0 { shares.append(CompanyShare(name: "Other", count: otherCount, isOther: true)) }
        companyShares = shares

        resumeCount = resumeDates.count
        resumesThisMonth = resumeDates.filter { calendar.isDate($0, equalTo: now, toGranularity: .month) }.count
        self.jobCount = jobCount
        self.readyJobCount = readyJobCount
        let windowStart = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        recentTaskCount = tasks.filter { $0.createdAt >= windowStart && $0.createdAt <= now }.count
    }

    init(experiences: [WorkExperience], resumes: [Resume], jobs: [JobTarget], now: Date = .now) {
        self.init(tasks: experiences.map { TaskRecord(id: $0.id, company: $0.company, createdAt: $0.createdAt) },
                  resumeTaskIDs: resumes.map(\.linkedWorkExperienceIDs),
                  resumeDates: resumes.map(\.createdAt),
                  jobCount: jobs.count,
                  readyJobCount: jobs.filter(\.isUsableForResume).count,
                  now: now)
    }
}

/// Series colors for the company chart. They stay clear of coral (actions), green (selection)
/// and object blue (metadata); every slice also has a labeled legend row.
enum TaskMetricPalette {
    static let series: [Color] = [CVeeColors.chart1, CVeeColors.chart2, CVeeColors.chart3, CVeeColors.chart4]
    static let other = CVeeColors.secondary

    static func color(for share: TaskMetricsSnapshot.CompanyShare, at index: Int) -> Color {
        share.isOther ? other : series[index % series.count]
    }
}

struct TaskMetricsSection: View {
    let snapshot: TaskMetricsSnapshot
    @AppStorage(TaskMetricLayout.storageKey) private var layoutRaw = TaskMetricLayout.defaultRaw
    @State private var showingEditor = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var widgets: [TaskMetricWidget] { TaskMetricLayout.decode(layoutRaw) }

    private var columnCount: Int { dynamicTypeSize.isAccessibilitySize ? 1 : 2 }

    /// Widgets split into rows so cards in the same row share one height.
    private var rows: [[TaskMetricWidget]] {
        stride(from: 0, to: widgets.count, by: columnCount).map {
            Array(widgets[$0..<min($0 + columnCount, widgets.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your progress")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CVeeColors.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button { showingEditor = true } label: {
                    Text(widgets.isEmpty ? "Add widgets" : "Edit")
                        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CVeeColors.actionInk)
                .accessibilityLabel(widgets.isEmpty ? "Add widgets to Your progress" : "Edit progress widgets")
                .accessibilityInputLabels(widgets.isEmpty ? ["Add widgets"] : ["Edit", "Edit progress widgets"])
                .accessibilityHint("Choose, remove and reorder the widgets shown on Tasks")
                .accessibilityIdentifier("tasks.metrics.edit")
            }
            if !widgets.isEmpty {
                Grid(alignment: .topLeading, horizontalSpacing: 12, verticalSpacing: 12) {
                    ForEach(rows, id: \.self) { row in
                        GridRow {
                            ForEach(row) { widget in
                                TaskMetricCard(widget: widget, snapshot: snapshot)
                            }
                            if row.count < columnCount {
                                // Keeps a lone widget at half width, matching the two-up layout.
                                Color.clear.gridCellUnsizedAxes(.vertical)
                            }
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tasks.metrics")
        .sheet(isPresented: $showingEditor) {
            TaskMetricWidgetEditor(layoutRaw: $layoutRaw)
        }
    }
}

struct TaskMetricCard: View {
    let widget: TaskMetricWidget
    let snapshot: TaskMetricsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(widget.title, systemImage: widget.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CVeeColors.secondary)
                .lineLimit(2)
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 152, maxHeight: .infinity, alignment: .topLeading)
        .background(CVeeColors.card, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widget.title)
        .accessibilityValue(accessibilitySummary)
        .accessibilityIdentifier("tasks.metric.\(widget.rawValue)")
    }

    @ViewBuilder
    private var content: some View {
        switch widget {
        case .companyMix: companyMix
        case .resumeUsage: resumeUsage
        case .resumesSaved:
            bigNumber("\(snapshot.resumeCount)",
                      caption: snapshot.resumeCount == 1 ? "resume saved" : "resumes saved",
                      detail: "\(snapshot.resumesThisMonth) this month")
        case .jobsReady:
            bigNumber(snapshot.jobCount == 0 ? "0" : "\(snapshot.readyJobCount) of \(snapshot.jobCount)",
                      caption: snapshot.jobCount == 0 ? "No saved jobs yet" : "saved jobs ready for a resume",
                      detail: nil)
        case .recentTasks:
            bigNumber("\(snapshot.recentTaskCount)",
                      caption: snapshot.recentTaskCount == 1 ? "task recorded" : "tasks recorded",
                      detail: "in the last 30 days")
        }
    }

    private var companyMix: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if snapshot.companyShares.isEmpty {
                    Circle()
                        .stroke(CVeeColors.divider, lineWidth: 14)
                        .padding(7)
                } else {
                    Chart(Array(snapshot.companyShares.enumerated()), id: \.element.id) { index, share in
                        SectorMark(angle: .value("Tasks", share.count), innerRadius: .ratio(0.6), angularInset: 1.5)
                            .cornerRadius(2)
                            .foregroundStyle(TaskMetricPalette.color(for: share, at: index))
                    }
                    .chartLegend(.hidden)
                }
                // The card's accessibility value already speaks the total, so the label can stay
                // capped to fit the donut hole at large text sizes.
                Text("\(snapshot.totalTasks)")
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(CVeeColors.ink)
                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: 40)
            }
            .frame(width: 76, height: 76)

            if snapshot.companyShares.isEmpty {
                Text("Record a task to see your mix")
                    .font(.caption)
                    .foregroundStyle(CVeeColors.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(snapshot.companyShares.enumerated()), id: \.element.id) { index, share in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(TaskMetricPalette.color(for: share, at: index))
                                .frame(width: 8, height: 8)
                            Text(share.name)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer(minLength: 4)
                            Text("\(share.count)").monospacedDigit()
                        }
                        .font(.caption)
                        .foregroundStyle(CVeeColors.ink)
                    }
                }
            }
        }
    }

    private var resumeUsage: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(snapshot.usedFraction.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "–")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(CVeeColors.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("of tasks used in resumes")
                .font(.caption)
                .foregroundStyle(CVeeColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ProgressView(value: snapshot.usedFraction ?? 0)
                .tint(CVeeColors.chart1)
            Text(snapshot.totalTasks == 0 ? "Record a task to start" : "\(snapshot.usedTasks) of \(snapshot.totalTasks) \(snapshot.totalTasks == 1 ? "task" : "tasks")")
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(CVeeColors.secondary)
        }
    }

    private func bigNumber(_ value: String, caption: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(CVeeColors.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(caption)
                .font(.caption)
                .foregroundStyle(CVeeColors.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(CVeeColors.secondary)
            }
        }
    }

    private var accessibilitySummary: String {
        switch widget {
        case .companyMix:
            guard !snapshot.companyShares.isEmpty else { return "No tasks yet" }
            let parts = snapshot.companyShares.map { "\($0.name), \($0.count)" }
            return "\(snapshot.totalTasks) \(snapshot.totalTasks == 1 ? "task" : "tasks"). " + parts.joined(separator: "; ")
        case .resumeUsage:
            guard let fraction = snapshot.usedFraction else { return "No tasks yet" }
            return "\(fraction.formatted(.percent.precision(.fractionLength(0)))), \(snapshot.usedTasks) of \(snapshot.totalTasks) \(snapshot.totalTasks == 1 ? "task" : "tasks") used in resumes"
        case .resumesSaved:
            return "\(snapshot.resumeCount) saved, \(snapshot.resumesThisMonth) this month"
        case .jobsReady:
            return snapshot.jobCount == 0 ? "No saved jobs yet" : "\(snapshot.readyJobCount) of \(snapshot.jobCount) saved jobs ready"
        case .recentTasks:
            return "\(snapshot.recentTaskCount) \(snapshot.recentTaskCount == 1 ? "task" : "tasks") recorded in the last 30 days"
        }
    }
}

/// Lets people show, hide and reorder the progress widgets.
struct TaskMetricWidgetEditor: View {
    @Binding var layoutRaw: String
    @Environment(\.dismiss) private var dismiss
    @State private var shown: [TaskMetricWidget] = []
    @State private var didLoad = false

    private var available: [TaskMetricWidget] {
        TaskMetricWidget.allCases.filter { !shown.contains($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(shown) { widget in
                        row(widget)
                            .accessibilityIdentifier("tasks.metrics.shown.\(widget.rawValue)")
                    }
                    .onMove { shown.move(fromOffsets: $0, toOffset: $1); save() }
                    .onDelete { shown.remove(atOffsets: $0); save() }
                } header: {
                    Text("Shown on Tasks")
                } footer: {
                    Text(shown.isEmpty ? "No widgets are shown. Add one below." : "Drag to reorder. Remove a widget to hide it.")
                }

                if !available.isEmpty {
                    Section("More widgets") {
                        ForEach(available) { widget in
                            Button {
                                shown.append(widget)
                                save()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(CVeeColors.green)
                                        .accessibilityHidden(true)
                                    row(widget)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Add \(widget.title)")
                            .accessibilityHint(widget.summary)
                            .accessibilityIdentifier("tasks.metrics.add.\(widget.rawValue)")
                        }
                    }
                }

                Section {
                    Button("Reset to default") {
                        shown = TaskMetricWidget.defaultLayout
                        save()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(CVeeColors.actionInk)
                    .disabled(shown == TaskMetricWidget.defaultLayout)
                    .accessibilityIdentifier("tasks.metrics.reset")
                }
            }
            .environment(\.editMode, .constant(.active))
            .modifier(WorkspaceSurface())
            .navigationTitle("Progress widgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("tasks.metrics.done")
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            guard !didLoad else { return }
            shown = TaskMetricLayout.decode(layoutRaw)
            didLoad = true
        }
    }

    private func row(_ widget: TaskMetricWidget) -> some View {
        HStack(spacing: 12) {
            Image(systemName: widget.systemImage)
                .frame(width: 24)
                .foregroundStyle(CVeeColors.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(widget.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CVeeColors.ink)
                Text(widget.summary)
                    .font(.caption)
                    .foregroundStyle(CVeeColors.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private func save() {
        layoutRaw = TaskMetricLayout.encode(shown)
    }
}
