import SwiftUI
import SwiftData

@main
struct CVee_resumebuilderApp: App {
    let sharedModelContainer: ModelContainer

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        if isUITesting, let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        }

        let schema = Schema([WorkExperience.self, JobTarget.self, Resume.self, ResumeSection.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)
        do { sharedModelContainer = try ModelContainer(for: schema, configurations: [configuration]) }
        catch {
            // ponytail: in-memory fallback keeps launch usable; add a migration plan when schema history stabilizes.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            sharedModelContainer = (try? ModelContainer(for: schema, configurations: [fallback])) ?? {
                preconditionFailure("Could not create an in-memory ModelContainer: \(error)")
            }()
        }
    }

    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(sharedModelContainer)
    }
}
