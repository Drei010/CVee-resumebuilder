import AppIntents

struct OpenNewResumeIntent: AppIntent {
    static var title: LocalizedStringResource = "Create a New Resume"
    static var description = IntentDescription("Open CVee's tailored resume workflow.")
    static var openAppWhenRun = true
    func perform() async throws -> some IntentResult { .result() }
}

struct OpenWorkHistoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Work History"
    static var description = IntentDescription("Open your reusable work history in CVee.")
    static var openAppWhenRun = true
    func perform() async throws -> some IntentResult { .result() }
}

struct CVeeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: OpenNewResumeIntent(), phrases: ["Create a resume in \(.applicationName)", "Start a resume with \(.applicationName)"], shortTitle: "New resume", systemImageName: "doc.badge.plus")
        AppShortcut(intent: OpenWorkHistoryIntent(), phrases: ["Open work history in \(.applicationName)"], shortTitle: "Work history", systemImageName: "briefcase")
    }
}
