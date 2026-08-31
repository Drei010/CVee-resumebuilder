import SwiftUI
import SwiftData

@main
struct CVee_resumebuilderApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([WorkExperience.self, JobTarget.self, Resume.self, ResumeSection.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [configuration]) }
        catch {
            // ponytail: in-memory fallback keeps launch usable; add a migration plan when schema history stabilizes.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [fallback])) ?? {
                preconditionFailure("Could not create an in-memory ModelContainer: \(error)")
            }()
        }
    }()

    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(sharedModelContainer)
    }
}
