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

        if isUITesting, ProcessInfo.processInfo.arguments.contains("-resume-format-fixture") {
            let context = sharedModelContainer.mainContext
            let experience = WorkExperience(jobTitle: "Full Stack AI Developer", company: "Accenture Philippines", tasks: [
                "Reduced manual search time by 83% by developing a custom RAG-based knowledge base with Python and LangChain.",
                "Delivered annual cost savings by developing TypeScript data-processing tools to automate reporting workflows."
            ])
            let job = JobTarget(sourceType: .pastedText, rawText: "Full Stack AI Developer role requiring Python, TypeScript, React, and AI application development.", parsedTitle: "Full Stack AI Developer", parsedCompany: "Accenture Philippines")
            context.insert(experience)
            context.insert(job)
            try? context.save()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(ProcessInfo.processInfo.arguments.contains("-ui-testing") &&
                                      ProcessInfo.processInfo.arguments.contains("-ui-testing-dark") ? .dark : nil)
        }
            .modelContainer(sharedModelContainer)
    }
}
