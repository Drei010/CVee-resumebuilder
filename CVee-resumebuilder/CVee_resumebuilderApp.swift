import SwiftUI
import SwiftData

@main
struct CVee_resumebuilderApp: App {
    let sharedModelContainer: ModelContainer

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        if isUITesting,
           !ProcessInfo.processInfo.arguments.contains("-ui-testing-preserve-drafts"),
           let bundleIdentifier = Bundle.main.bundleIdentifier {
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
            var document = ResumeDocument.empty
            document.sections[0].content = .contact(ContactContent(name: "Andrei Hidalgo", email: "test@example.com"))
            let resume = Resume(name: "Fixture Resume", jobTarget: job, structuredDocumentData: try? document.data())
            context.insert(experience)
            context.insert(job)
            context.insert(resume)
        }

        if ProcessInfo.processInfo.arguments.contains("-mock-data") {
            seedMockTasks()
        }
    }

    private func seedMockTasks() {
        let context = sharedModelContainer.mainContext
        let existing = (try? context.fetch(FetchDescriptor<WorkExperience>())) ?? []
        guard !existing.contains(where: { $0.company.hasPrefix("[Mock]") }) else { return }

        let roles = [
            ("[Mock] Northstar Labs", "Product Designer"),
            ("[Mock] Harbor Health", "UX Researcher"),
            ("[Mock] Pinecone Systems", "iOS Developer"),
            ("[Mock] Brightline Finance", "Product Manager"),
            ("[Mock] Atlas Commerce", "Frontend Engineer"),
            ("[Mock] Cedar Analytics", "Data Analyst")
        ]
        let tasks = [
            "Mapped the customer journey and documented the highest-friction steps.",
            "Created a reusable component spec and aligned implementation details with engineering.",
            "Reviewed feedback, grouped recurring themes, and proposed the next iteration.",
            "Prepared a concise status update with decisions, risks, and follow-up owners.",
            "Validated the workflow on a representative mobile screen and recorded the findings."
        ]

        for index in 0..<30 {
            let role = roles[index / tasks.count]
            let startDate = Calendar.current.date(byAdding: .month, value: -(index + 1), to: .now) ?? .now
            context.insert(WorkExperience(jobTitle: role.1, company: role.0, startDate: startDate, tasks: [tasks[index % tasks.count]]))
        }
        try? context.save()
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
