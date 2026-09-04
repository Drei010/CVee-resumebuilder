import SwiftUI
import SwiftData
import UIKit
import PDFKit
import UniformTypeIdentifiers

private enum CVeeColors {
    static let blue = Color(red: 13 / 255, green: 79 / 255, blue: 184 / 255)
    static let page = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .systemBackground : UIColor(red: 242 / 255, green: 247 / 255, blue: 252 / 255, alpha: 1)
    })
    static let card = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .secondarySystemBackground : UIColor(red: 232 / 255, green: 250 / 255, blue: 255 / 255, alpha: 1)
    })
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { WorkHistoryView() }
                .tabItem { Label("Tasks", systemImage: "checklist") }
                .accessibilityIdentifier("tab.tasks")
                .tag(0)
            NavigationStack { SavedJobsView(onOpenTasks: { selectedTab = 0 }) }
                .tabItem { Label("Saved Jobs", systemImage: "bookmark") }
                .accessibilityIdentifier("tab.saved-jobs")
                .tag(1)
            NavigationStack { NewResumeView(onSaved: { selectedTab = 3 }) }
                .tabItem { Label("Resume Wizard", systemImage: "wand.and.stars") }
                .tag(2)
            NavigationStack { ResumesView() }
                .tabItem { Label("Resumes", systemImage: "doc.text") }
                .tag(3)
            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(4)
        }
        .tint(CVeeColors.blue)
    }
}

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("profile.name") private var name = "Andrei Hidalgo"
    @AppStorage("profile.email") private var email = ""
    @AppStorage("profile.phone") private var phone = ""
    @AppStorage("profile.location") private var location = ""
    @AppStorage("profile.linkedin") private var linkedin = ""
    @AppStorage("profile.github") private var github = ""
    @AppStorage("profile.education") private var education = ""
    @AppStorage("profile.skills") private var skills = ""
    @AppStorage("profile.certifications") private var certifications = ""
    @State private var showingEdit = false
    @State private var showingClearPrompt = false
    @State private var showingSavedMessage = false

    var body: some View {
        Form {
            Section("Identity") {
                LabeledContent("Full name", value: name.isEmpty ? "Not set" : name)
                LabeledContent("Email", value: email.isEmpty ? "Not set" : email)
                LabeledContent("Phone", value: phone.isEmpty ? "Not set" : phone)
                LabeledContent("Location", value: location.isEmpty ? "Not set" : location)
                LabeledContent("LinkedIn URL", value: linkedin.isEmpty ? "Not set" : linkedin)
                LabeledContent("GitHub URL", value: github.isEmpty ? "Not set" : github)
                LabeledContent("Education", value: education.isEmpty ? "Not set" : education)
                LabeledContent("Skills & abilities", value: skills.isEmpty ? "Not set" : skills)
                LabeledContent("Certifications", value: certifications.isEmpty ? "Not set" : certifications)
                Button("Update personal info") { showingEdit = true }
            }
            Section("About") {
                Text("CVee is a focused workspace for organizing your experience, saving target jobs, and building tailored resumes from the facts you provide.")
                Text("Create reusable tasks, connect them to resumes, review job descriptions, and export polished drafts when you are ready to apply.")
                Label("Resume generation stays on-device when supported.", systemImage: "lock.shield")
                    .foregroundStyle(.secondary)
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                NavigationLink("Terms and conditions") { TermsAndConditionsView() }
                Link("Contact support · andreihidalgo16@gmail.com", destination: URL(string: "mailto:andreihidalgo16@gmail.com")!)
            }
            Section("Advanced settings") {
                Button("Clear all data", role: .destructive) { showingClearPrompt = true }
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showingEdit) {
            ProfileEditView(name: $name, email: $email, phone: $phone, location: $location, linkedin: $linkedin, github: $github, education: $education, skills: $skills, certifications: $certifications) { showingSavedMessage = true }
        }
        .sheet(isPresented: $showingClearPrompt) { ClearAllDataView { clearAllData(); showingClearPrompt = false } }
        .alert("Personal info updated", isPresented: $showingSavedMessage) {
            Button("OK", role: .cancel) { }
        }
    }

    private func clearAllData() {
        (try? modelContext.fetch(FetchDescriptor<WorkExperience>()))?.forEach(modelContext.delete)
        (try? modelContext.fetch(FetchDescriptor<JobTarget>()))?.forEach(modelContext.delete)
        (try? modelContext.fetch(FetchDescriptor<ResumeSection>()))?.forEach(modelContext.delete)
        (try? modelContext.fetch(FetchDescriptor<Resume>()))?.forEach(modelContext.delete)
        try? modelContext.save()
        name = "Andrei Hidalgo"; email = ""; phone = ""; location = ""; linkedin = ""; github = ""; education = ""; skills = ""; certifications = ""
    }
}

struct TermsAndConditionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Terms and Conditions")
                    .font(.title.bold())
                Text("Last updated: September 1, 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                termsSection("1. Using CVee", "CVee is a resume-building tool for organizing your work history, saving job descriptions, and creating resume drafts. You are responsible for the information you enter and for reviewing all generated content before using it.")
                termsSection("2. Your content", "You retain ownership of the work history, job descriptions, profile information, and resume content you add to CVee. You grant CVee permission to store and process that content on your device so the app can provide its features.")
                termsSection("3. Resume generation", "Resume drafts are generated from the information you provide. CVee does not guarantee accuracy, completeness, job placement, interviews, or employment outcomes. Review every draft for accuracy before sharing or submitting it.")
                termsSection("4. Exports and sharing", "You choose when to export or share a resume. You are responsible for selecting the correct document, destination, and recipients, and for complying with any requirements of the employer or platform receiving it.")
                termsSection("5. Privacy Policy", "CVee stores saved tasks, jobs, resumes, and profile information in the app’s local data store. Resume generation is designed to run on-device when supported. CVee does not require an account for local app use. Deleting the app or using Clear all data may permanently remove this information. Keep your own backup of content you need to retain.")
                termsSection("6. Third-party services", "LinkedIn listings and sharing destinations may be provided by third parties. Their availability, content, and terms are controlled by those services, not CVee.")
                termsSection("7. Acceptable use", "Do not use CVee to submit misleading, fraudulent, unlawful, or infringing information. You are responsible for ensuring your content and use of exported resumes comply with applicable rules and agreements.")
                termsSection("8. Changes and availability", "Features may change, be suspended, or become unavailable as the app is updated. We may update these terms when the app’s features or requirements change.")
                termsSection("9. Contact", "Questions about these terms can be sent to andreihidalgo16@gmail.com.")
            }
            .padding()
        }
        .navigationTitle("Terms and conditions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func termsSection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.headline)
            Text(body).foregroundStyle(.secondary)
        }
    }
}

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    @Binding var email: String
    @Binding var phone: String
    @Binding var location: String
    @Binding var linkedin: String
    @Binding var github: String
    @Binding var education: String
    @Binding var skills: String
    @Binding var certifications: String
    let onSave: () -> Void
    @State private var draft: Draft

    private struct Draft {
        var name, email, phone, location, linkedin, github, education, skills, certifications: String
    }

    private var invalidURLFields: [String] {
        [(draft.linkedin, "LinkedIn URL", "linkedin.com"), (draft.github, "GitHub URL", "github.com")].compactMap { value, label, host in
            guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            guard let url = URL(string: value), url.scheme == "https", url.host?.contains(host) == true else { return label }
            return nil
        }
    }

    init(name: Binding<String>, email: Binding<String>, phone: Binding<String>, location: Binding<String>, linkedin: Binding<String>, github: Binding<String>, education: Binding<String>, skills: Binding<String>, certifications: Binding<String>, onSave: @escaping () -> Void) {
        _name = name; _email = email; _phone = phone; _location = location; _linkedin = linkedin; _github = github; _education = education; _skills = skills; _certifications = certifications
        self.onSave = onSave
        _draft = State(initialValue: Draft(name: name.wrappedValue, email: email.wrappedValue, phone: phone.wrappedValue, location: location.wrappedValue, linkedin: linkedin.wrappedValue, github: github.wrappedValue, education: education.wrappedValue, skills: skills.wrappedValue, certifications: certifications.wrappedValue))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal information") {
                    TextField("Full name", text: $draft.name).textContentType(.name)
                    TextField("Email", text: $draft.email).textContentType(.emailAddress).keyboardType(.emailAddress)
                    TextField("Phone", text: $draft.phone).textContentType(.telephoneNumber).keyboardType(.phonePad)
                    TextField("Location", text: $draft.location)
                    TextField("LinkedIn URL", text: $draft.linkedin).textInputAutocapitalization(.never).keyboardType(.URL)
                    TextField("GitHub URL", text: $draft.github).textInputAutocapitalization(.never).keyboardType(.URL)
                    TextField("Education", text: $draft.education)
                    TextField("Skills & abilities", text: $draft.skills, axis: .vertical).lineLimit(3...6)
                    TextField("Certifications", text: $draft.certifications, axis: .vertical).lineLimit(3...6)
                }
                Section {
                    if !invalidURLFields.isEmpty {
                        Text("Enter valid HTTPS URLs for: \(invalidURLFields.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    Button("Save changes") {
                        name = draft.name; email = draft.email; phone = draft.phone; location = draft.location; linkedin = draft.linkedin; github = draft.github; education = draft.education; skills = draft.skills; certifications = draft.certifications
                        onSave()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!invalidURLFields.isEmpty)
                }
            }
            .navigationTitle("Update personal info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

struct ClearAllDataView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phrase = ""
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("This permanently deletes all saved tasks, jobs, resumes, and profile information.")
                    TextField("Type CLEAR to confirm", text: $phrase)
                        .textInputAutocapitalization(.characters)
                }
                Section {
                    Button("Clear all data", role: .destructive) { onConfirm() }
                        .frame(maxWidth: .infinity)
                        .disabled(phrase != "CLEAR")
                }
            }
            .navigationTitle("Confirm deletion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

struct WorkHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkExperience.startDate, order: .reverse) private var experiences: [WorkExperience]
    @State private var selected: WorkExperience?
    @State private var showingAddTask = false
    @State private var searchText = ""
    @State private var selectedCompany = "All companies"

    private var companies: [String] {
        Array(Set(experiences.map(\.company).filter { !$0.isEmpty })).sorted()
    }

    private var filteredExperiences: [WorkExperience] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return experiences.filter { experience in
            let matchesCompany = selectedCompany == "All companies" || experience.company == selectedCompany
            let matchesSearch = query.isEmpty || [experience.jobTitle, experience.company, experience.tasksText]
                .joined(separator: " ")
                .localizedCaseInsensitiveContains(query)
            return matchesCompany && matchesSearch
        }
    }

    var body: some View {
        List {
            if filteredExperiences.isEmpty {
                ContentUnavailableView(searchText.isEmpty && selectedCompany == "All companies" ? "No work history" : "No matching tasks", systemImage: "magnifyingglass", description: Text(searchText.isEmpty && selectedCompany == "All companies" ? "Add roles once and reuse them for every tailored resume." : "Try a different search or filter."))
            }
            ForEach(filteredExperiences) { experience in
                Button { selected = experience } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(experience.jobTitle).font(.headline)
                        Text(experience.company).foregroundStyle(.secondary)
                        Text(experience.tasks.isEmpty ? "No task details yet" : experience.tasks.first ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Text(experience.dateRange).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(CVeeColors.card)
                .accessibilityHint("Opens this work experience for editing")
            }
            .onDelete { offsets in offsets.map { filteredExperiences[$0] }.forEach(modelContext.delete) }
        }
        .navigationTitle("Tasks")
        .searchable(text: $searchText, prompt: "Search tasks")
        .scrollContentBackground(.hidden)
        .background(CVeeColors.page)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("All companies") { selectedCompany = "All companies" }
                    ForEach(companies, id: \.self) { company in
                        Button(company) { selectedCompany = company }
                    }
                } label: {
                    Label(selectedCompany == "All companies" ? "Filter" : selectedCompany, systemImage: "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Filter tasks by company")
            }
            ToolbarItem(placement: .topBarTrailing) { Button { showingAddTask = true } label: { Image(systemName: "plus") }.accessibilityLabel("Add task") }
        }
        .sheet(item: $selected) { experience in TaskDetailView(experience: experience) }
        .sheet(isPresented: $showingAddTask) { WorkExperienceEditor(experience: WorkExperience(jobTitle: "", company: "")) }
    }
}

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var experience: WorkExperience
    @Query private var resumes: [Resume]
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var saveError: String?
    @State private var selectedResume: Resume?
    @State private var title: String
    @State private var company: String
    @State private var tasks: String

    init(experience: WorkExperience) {
        self.experience = experience
        _title = State(initialValue: experience.jobTitle)
        _company = State(initialValue: experience.company)
        _tasks = State(initialValue: experience.tasksText)
    }

    private var linkedResumes: [Resume] {
        resumes.filter { $0.linkedWorkExperienceIDs.contains(experience.id) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task details") {
                    if isEditing {
                        TextField("Task title", text: $title)
                        TextField("Company", text: $company)
                        TextEditor(text: $tasks).frame(minHeight: 180).accessibilityLabel("Task details")
                    } else {
                        LabeledContent("Task", value: experience.jobTitle)
                        LabeledContent("Company", value: experience.company)
                        Text(experience.tasksText.isEmpty ? "No task details yet" : experience.tasksText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
                Section("Linked saved resumes (\(linkedResumes.count))") {
                    if linkedResumes.isEmpty {
                        Text("No saved resumes use this task yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(linkedResumes) { resume in
                            Button { selectedResume = resume } label: {
                                Text(resume.name)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section {
                    if isEditing {
                        Button("Save changes") {
                            experience.jobTitle = title
                            experience.company = company
                            experience.tasksText = tasks
                            do { try modelContext.save(); isEditing = false }
                            catch { saveError = error.localizedDescription }
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Button("Edit") { isEditing = true }.frame(maxWidth: .infinity)
                        Button("Delete", role: .destructive) { showingDeleteAlert = true }.frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing {
                            title = experience.jobTitle
                            company = experience.company
                            tasks = experience.tasksText
                            isEditing = false
                        } else { dismiss() }
                    }
                }
            }
            .alert("Confirm delete", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(experience)
                    do { try modelContext.save(); dismiss() }
                    catch { saveError = error.localizedDescription }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This task will be permanently removed.")
            }
            .alert("Couldn’t save changes", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: { Text(saveError ?? "Try again.") }
            .sheet(item: $selectedResume) { resume in ResumePreviewView(resume: resume) }
        }
    }
}

struct SavedJobsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JobTarget.createdAt, order: .reverse) private var jobs: [JobTarget]
    @State private var searchText = ""
    @State private var showingAddJob = false
    @State private var selectedJob: JobTarget?
    @State private var saveError: String?
    let onOpenTasks: () -> Void

    init(onOpenTasks: @escaping () -> Void = {}) {
        self.onOpenTasks = onOpenTasks
    }

    private var filteredJobs: [JobTarget] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return jobs }
        return jobs.filter { job in
            [job.parsedTitle, job.parsedCompany, job.rawText]
                .compactMap { $0 }
                .joined(separator: " ")
                .localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            if filteredJobs.isEmpty {
                ContentUnavailableView("No saved jobs", systemImage: "bookmark", description: Text("Generate a resume from a job listing to keep it here."))
            }
            ForEach(filteredJobs) { job in
                Button { selectedJob = job } label: {
                    VStack(alignment: .leading, spacing: 5) {
                    Text(job.parsedTitle ?? job.rawText.split(whereSeparator: \.isNewline).first.map(String.init) ?? "Untitled job")
                        .font(.headline)
                    Text(job.parsedCompany ?? "Job target")
                        .foregroundStyle(.secondary)
                    Text(job.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                .listRowBackground(Color(uiColor: .systemBackground))
                .accessibilityElement(children: .combine)
                .accessibilityHint("Opens saved job details")
            }
            .onDelete { offsets in
                offsets.map { filteredJobs[$0] }.forEach(modelContext.delete)
                do { try modelContext.save() } catch { saveError = error.localizedDescription }
            }
        }
        .navigationTitle("Saved Jobs")
        .searchable(text: $searchText, prompt: "Search saved jobs")
        .scrollContentBackground(.hidden)
        .background(CVeeColors.page)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAddJob = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add saved job")
            }
        }
        .sheet(isPresented: $showingAddJob) { AddJobView() }
        .sheet(item: $selectedJob) { job in JobDetailView(job: job, onOpenTasks: onOpenTasks) }
        .alert("Couldn’t save changes", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: { Text(saveError ?? "Try again.") }
    }
}

struct JobDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var job: JobTarget
    @Query private var allResumes: [Resume]
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var selectedResume: Resume?
    @State private var name: String
    @State private var company: String
    @State private var description: String
    @State private var saveError: String?
    let onOpenTasks: () -> Void

    init(job: JobTarget, onOpenTasks: @escaping () -> Void = {}) {
        self.job = job
        self.onOpenTasks = onOpenTasks
        _name = State(initialValue: job.parsedTitle ?? "")
        _company = State(initialValue: job.parsedCompany ?? "")
        _description = State(initialValue: job.rawText)
    }

    private var linkedResumes: [Resume] {
        allResumes.filter { $0.jobTarget?.id == job.id }.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Job details") {
                    if isEditing {
                        TextField("Name of the job", text: $name)
                        TextField("Company of the job", text: $company)
                        TextEditor(text: $description)
                            .frame(minHeight: 220)
                            .accessibilityLabel("Job description")
                    } else {
                        LabeledContent("Job", value: job.parsedTitle ?? "Untitled job")
                        LabeledContent("Company", value: job.parsedCompany ?? "Job target")
                        Text(job.rawText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
                Section("Linked saved resumes (\(linkedResumes.count))") {
                    if linkedResumes.isEmpty {
                        Text("No saved resumes use this job yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(linkedResumes) { resume in
                            Button { selectedResume = resume } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(resume.name)
                                    Text(resume.updatedAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section {
                    Button {
                        dismiss()
                        onOpenTasks()
                    } label: {
                        Label("View tasks", systemImage: "checklist")
                    }
                    .accessibilityIdentifier("job.view-tasks")
                } footer: {
                    Text("Review your saved work history before tailoring a resume for this job.")
                }
                Section {
                    if isEditing {
                        Button("Save changes") {
                            job.parsedTitle = name
                            job.parsedCompany = company
                            job.rawText = description
                            do { try modelContext.save(); isEditing = false }
                            catch { saveError = error.localizedDescription }
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Button("Edit") { isEditing = true }
                            .frame(maxWidth: .infinity)
                        Button("Delete", role: .destructive) { showingDeleteAlert = true }
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Job" : "Job Details (\(linkedResumes.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing {
                            name = job.parsedTitle ?? ""
                            company = job.parsedCompany ?? ""
                            description = job.rawText
                            isEditing = false
                        } else { dismiss() }
                    }
                }
            }
            .alert("Confirm delete", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(job)
                    do { try modelContext.save(); dismiss() }
                    catch { saveError = error.localizedDescription }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This saved job will be permanently removed.")
            }
            .alert("Couldn’t save changes", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: { Text(saveError ?? "Try again.") }
            .sheet(item: $selectedResume) { resume in
                ResumeEditorView(resume: resume)
            }
        }
    }
}

struct AddJobView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var company = ""
    @State private var description = ""
    @State private var saveError: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Job details") {
                    TextField("Name of the job", text: $name)
                    TextField("Company of the job", text: $company)
                    TextEditor(text: $description)
                        .frame(minHeight: 160)
                        .accessibilityLabel("Job description")
                        .overlay(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Job description")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                Section {
                    Button("Add job") {
                        let job = JobTarget(sourceType: .pastedText, rawText: description, parsedTitle: name, parsedCompany: company)
                        modelContext.insert(job)
                        do { try modelContext.save(); dismiss() }
                        catch { saveError = error.localizedDescription }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!canSave)
                }
            }
            .navigationTitle("Add Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .alert("Couldn’t save job", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: { Text(saveError ?? "Try again.") }
        }
    }
}

struct WorkExperienceEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var experience: WorkExperience
    @State private var isNew = false
    @State private var jobTitle = ""
    @State private var company = ""
    @State private var task = ""
    @State private var isEnhancing = false
    @State private var saveError: String?
    @State private var enhanceError: String?

    init(experience: WorkExperience) {
        self.experience = experience
        _isNew = State(initialValue: experience.jobTitle.isEmpty && experience.company.isEmpty)
        _jobTitle = State(initialValue: experience.jobTitle)
        _company = State(initialValue: experience.company)
        _task = State(initialValue: experience.tasks.first ?? experience.tasksText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Role") {
                    TextField("Job title", text: $jobTitle)
                        .textContentType(.jobTitle)
                        .accessibilityIdentifier("task.role")
                    TextField("Company", text: $company)
                        .textContentType(.organizationName)
                        .accessibilityIdentifier("task.company")
                }
                Section("Dates") {
                    DatePicker("Start date", selection: $experience.startDate, displayedComponents: .date)
                    Toggle("Currently working here", isOn: Binding(get: { experience.endDate == nil }, set: { experience.endDate = $0 ? nil : .now }))
                    if experience.endDate != nil { DatePicker("End date", selection: Binding($experience.endDate)!, displayedComponents: .date) }
                }
                Section {
                    TextField("Describe one task or achievement", text: $task, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Task details")
                        .accessibilityIdentifier("task.details")
                    Text("Add one task or achievement to this card.").font(.caption).foregroundStyle(.secondary)
                } header: {
                    HStack {
                        Text("Task details")
                        Spacer()
                        Button {
                            Task { await enhanceTask() }
                        } label: {
                            Label(isEnhancing ? "Enhancing…" : "Enhance with AI", systemImage: "sparkles")
                                .font(.caption.weight(.semibold))
                        }
                        .disabled(isEnhancing || task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityLabel("Enhance task details with Apple Intelligence")
                        .accessibilityIdentifier("task.enhance-ai")
                    }
                }
                Section {
                    Button(isNew ? "Add task" : "Save changes") {
                        experience.jobTitle = jobTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        experience.company = company.trimmingCharacters(in: .whitespacesAndNewlines)
                        experience.tasksText = task.trimmingCharacters(in: .whitespacesAndNewlines)
                        if isNew { modelContext.insert(experience) }
                        do { try modelContext.save(); dismiss() }
                        catch { saveError = error.localizedDescription }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(jobTitle.trimmingCharacters(in: .whitespaces).isEmpty || company.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle(isNew ? "Add task" : "Edit experience")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { if isNew { modelContext.delete(experience) }; dismiss() } }
            }
            .alert("Couldn’t save task", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: { Text(saveError ?? "Try again.") }
            .alert("AI enhancement unavailable", isPresented: Binding(get: { enhanceError != nil }, set: { if !$0 { enhanceError = nil } })) {
                Button("OK", role: .cancel) { enhanceError = nil }
            } message: { Text(enhanceError ?? "Try again.") }
        }
    }

    private func enhanceTask() async {
        isEnhancing = true
        defer { isEnhancing = false }
        do { task = try await TaskEnhancementService().enhance(task) }
        catch { enhanceError = error.localizedDescription }
    }
}

private enum ResumeWizardStep: Int, CaseIterable {
    case start, workLibrary, jobDescription, summary, generated
    var title: String { ["Start", "Work Library", "Job Description", "Summary", "Generated"][rawValue] }
}

private enum ResumeStartMode: String, CaseIterable {
    case fresh = "Start Fresh"
    case existing = "Use Existing Resume"
}

struct NewResumeView: View {
    let onSaved: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Query private var experiences: [WorkExperience]
    @Query(sort: \JobTarget.createdAt, order: .reverse) private var jobs: [JobTarget]
    @Query(sort: \Resume.updatedAt, order: .reverse) private var resumes: [Resume]
    @AppStorage("profile.name") private var profileName = "Andrei Hidalgo"
    @AppStorage("profile.email") private var profileEmail = ""
    @AppStorage("profile.phone") private var profilePhone = ""
    @AppStorage("profile.location") private var profileLocation = ""
    @AppStorage("profile.linkedin") private var profileLinkedIn = ""
    @AppStorage("profile.github") private var profileGitHub = ""
    @AppStorage("profile.education") private var profileEducation = ""
    @AppStorage("profile.skills") private var profileSkills = ""
    @AppStorage("profile.certifications") private var profileCertifications = ""
    @State private var step: ResumeWizardStep = .start
    @State private var startMode: ResumeStartMode = .fresh
    @State private var draftName = ""
    @State private var draftEmail = ""
    @State private var draftPhone = ""
    @State private var draftLocation = ""
    @State private var draftLinkedIn = ""
    @State private var draftGitHub = ""
    @State private var draftEducation = ""
    @State private var draftSkills = ""
    @State private var draftCertifications = ""
    @State private var baselineText = ""
    @State private var selectedResumeID: UUID?
    @State private var selectedExperienceIDs = Set<UUID>()
    @State private var selectedJobID: UUID?
    @State private var taskSearch = ""
    @State private var jobSearch = ""
    @State private var showingFileImporter = false
    @State private var showingAddTask = false
    @State private var showingAddJob = false
    @State private var taskCountBeforeAdd = 0
    @State private var jobCountBeforeAdd = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var generatedDraft: ResumeDraft?
    @State private var generatedText = ""
    @State private var isEditingGenerated = false
    @State private var isSaved = false

    init(onSaved: @escaping () -> Void = {}) { self.onSaved = onSaved }

    private var selectedExperiences: [WorkExperience] { experiences.filter { selectedExperienceIDs.contains($0.id) } }
    private var selectedJob: JobTarget? { jobs.first { $0.id == selectedJobID } }
    private var filteredExperiences: [WorkExperience] {
        experiences.filter { taskSearch.isEmpty || [$0.jobTitle, $0.company, $0.tasksText].joined(separator: " ").localizedCaseInsensitiveContains(taskSearch) }
    }
    private var filteredJobs: [JobTarget] {
        jobs.filter { jobSearch.isEmpty || [$0.parsedTitle ?? "", $0.parsedCompany ?? "", $0.rawText].joined(separator: " ").localizedCaseInsensitiveContains(jobSearch) }
    }
    private var profileIsValid: Bool { !draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !draftEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var canAdvance: Bool {
        switch step {
        case .start: return startMode == .existing ? !baselineText.isEmpty : profileIsValid
        case .workLibrary: return !selectedExperienceIDs.isEmpty
        case .jobDescription: return selectedJob != nil
        case .summary: return !isLoading
        case .generated: return generatedDraft != nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            progressHeader
            Group {
                switch step {
                case .start: startPage
                case .workLibrary: workLibraryPage
                case .jobDescription: jobDescriptionPage
                case .summary: summaryPage
                case .generated: generatedPage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 40).onEnded { value in handleSwipe(value.translation.width) })
            navigationBar
        }
        .navigationTitle("Resume Wizard")
        .background(CVeeColors.page)
        .onAppear { loadProfileDraft() }
        .onChange(of: startMode) { _, mode in if mode == .fresh { baselineText = ""; selectedResumeID = nil } }
        .onChange(of: experiences.count) { _, count in if count > taskCountBeforeAdd, let newest = experiences.max(by: { $0.createdAt < $1.createdAt }) { selectedExperienceIDs.insert(newest.id) } }
        .onChange(of: jobs.count) { _, count in if count > jobCountBeforeAdd, let newest = jobs.first { selectedJobID = newest.id } }
        .sheet(isPresented: $showingAddTask) { WorkExperienceEditor(experience: WorkExperience(jobTitle: "", company: "")) }
        .sheet(isPresented: $showingAddJob) { AddJobView() }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.pdf]) { result in importPDF(result) }
    }

    private var progressHeader: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(ResumeWizardStep.allCases, id: \.rawValue) { item in
                VStack(spacing: 3) {
                    Circle()
                        .fill(item.rawValue < step.rawValue ? Color.green : item == step ? CVeeColors.blue : Color.secondary.opacity(0.25))
                        .frame(width: item == step ? 11 : 8, height: item == step ? 11 : 8)
                    Text(item.title)
                        .font(.system(size: item == step ? 12 : 9, weight: item == step ? .semibold : .regular))
                        .foregroundStyle(item == step ? .primary : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .frame(maxWidth: .infinity, minHeight: 14)
                }.frame(maxWidth: .infinity)
                if item != .generated { Rectangle().fill(item.rawValue < step.rawValue ? Color.green : Color.secondary.opacity(0.2)).frame(height: 2).padding(.bottom, 15) }
            }
        }
        .padding(.horizontal, 4).padding(.top, 6).padding(.bottom, 4).accessibilityElement(children: .ignore)
        .accessibilityIdentifier("wizard.progress")
        .accessibilityLabel("Step \(step.rawValue + 1) of \(ResumeWizardStep.allCases.count): \(step.title)")
    }

    private var startPage: some View {
        Form {
            Section { Picker("Start method", selection: $startMode) { ForEach(ResumeStartMode.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented) }
            if startMode == .fresh {
                Section("Your identity") {
                    TextField("Full name", text: $draftName).textContentType(.name).accessibilityIdentifier("wizard.full-name")
                    TextField("Email", text: $draftEmail).textContentType(.emailAddress).keyboardType(.emailAddress).accessibilityIdentifier("wizard.email")
                    TextField("Phone", text: $draftPhone).textContentType(.telephoneNumber).keyboardType(.phonePad)
                    TextField("Location", text: $draftLocation)
                    TextField("LinkedIn URL", text: $draftLinkedIn).textInputAutocapitalization(.never).keyboardType(.URL)
                    TextField("GitHub URL", text: $draftGitHub).textInputAutocapitalization(.never).keyboardType(.URL)
                    TextField("Education", text: $draftEducation)
                    TextField("Skills & abilities", text: $draftSkills)
                    TextField("Certifications", text: $draftCertifications)
                }
                if !profileIsValid { Text("Full name and email are required.").font(.caption).foregroundStyle(.secondary) }
            } else {
                Section("Resume baseline") {
                    Button("Upload PDF") { showingFileImporter = true }
                    if !resumes.isEmpty { ForEach(resumes) { resume in Button { selectedResumeID = resume.id; baselineText = resume.sections.sorted(by: { $0.order < $1.order }).map { $0.attributedText.string }.joined(separator: "\n") } label: { Label(resume.name, systemImage: selectedResumeID == resume.id ? "checkmark.circle.fill" : "doc.text") } } }
                    if !baselineText.isEmpty { Text("Baseline ready").font(.caption).foregroundStyle(.secondary) }
                }
            }
        }.formStyle(.grouped).accessibilityIdentifier("wizard.start")
    }

    private var workLibraryPage: some View {
        Form {
            Section { TextField("Search tasks", text: $taskSearch).textInputAutocapitalization(.never) }
            Section { HStack { Text("\(selectedExperienceIDs.count) selected"); Spacer(); Button("Select All") { selectedExperienceIDs = Set(filteredExperiences.map(\.id)) }; Button("Clear") { selectedExperienceIDs.removeAll() } } }
            Section("Work Library") {
                if filteredExperiences.isEmpty { ContentUnavailableView("No matching tasks", systemImage: "checklist") }
                ForEach(filteredExperiences) { experience in Button { toggleExperience(experience.id) } label: { HStack { VStack(alignment: .leading) { Text(experience.jobTitle).font(.headline); Text(experience.company).foregroundStyle(.secondary); Text(experience.tasks.first ?? "No task details").font(.caption).foregroundStyle(.secondary).lineLimit(2) }; Spacer(); Image(systemName: selectedExperienceIDs.contains(experience.id) ? "checkmark.circle.fill" : "circle").foregroundStyle(selectedExperienceIDs.contains(experience.id) ? CVeeColors.blue : .secondary) } }.buttonStyle(.plain) }
                Button { taskCountBeforeAdd = experiences.count; showingAddTask = true } label: { Label("Add task", systemImage: "plus") }
            }
        }.formStyle(.grouped).accessibilityIdentifier("wizard.work-library")
    }

    private var jobDescriptionPage: some View {
        Form {
            Section { TextField("Search saved jobs", text: $jobSearch).textInputAutocapitalization(.never) }
            Section("Job descriptions") {
                if filteredJobs.isEmpty { ContentUnavailableView("No saved jobs", systemImage: "briefcase", description: Text("Add a job description to continue.")) }
                ForEach(filteredJobs) { job in Button { selectedJobID = job.id } label: { HStack { VStack(alignment: .leading) { Text(job.parsedTitle ?? "Untitled job").font(.headline); Text(job.parsedCompany ?? "Unknown company").foregroundStyle(.secondary); Text(job.rawText).font(.caption).foregroundStyle(.secondary).lineLimit(3) }; Spacer(); Image(systemName: selectedJobID == job.id ? "checkmark.circle.fill" : "circle").foregroundStyle(selectedJobID == job.id ? CVeeColors.blue : .secondary) } }.buttonStyle(.plain) }
                Button { jobCountBeforeAdd = jobs.count; showingAddJob = true } label: { Label("Add job", systemImage: "plus") }
            }
        }.formStyle(.grouped).accessibilityIdentifier("wizard.job-description")
    }

    private var summaryPage: some View {
        Form {
            Section("Ready to generate") { LabeledContent("Start", value: startMode.rawValue); LabeledContent("Name", value: startMode == .fresh ? draftName : "Existing resume baseline"); LabeledContent("Tasks", value: "\(selectedExperiences.count) selected"); LabeledContent("Job", value: selectedJob?.parsedTitle ?? "Selected job") }
            Section("Selected tasks") { ForEach(selectedExperiences) { Text("\($0.jobTitle): \($0.tasks.first ?? "No task details")") } }
            if let selectedJob { Section("Job description") { Text(selectedJob.rawText).lineLimit(8) } }
            if isLoading { Section { ProgressView("Generating your resume…").accessibilityIdentifier("wizard.loader") } }
            if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
        }.formStyle(.grouped).accessibilityIdentifier("wizard.summary")
    }

    private var generatedPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if generatedDraft != nil {
                    if isEditingGenerated {
                        TextEditor(text: $generatedText)
                            .frame(minHeight: 420)
                            .padding(12)
                            .background(.background)
                    } else {
                        Text(AttributedString(NSAttributedString(string: generatedText)))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(24)
                            .background(.background)
                    }
                    Button(isEditingGenerated ? "Done editing" : "Edit resume") { isEditingGenerated.toggle() }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("wizard.edit-resume")
                    Button(isSaved ? "Saved to Resumes" : "Save Resume") { saveGeneratedResume() }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaved || generatedDraft == nil)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("wizard.save-resume")
                    if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .padding()
        }
        .accessibilityIdentifier("wizard.generated")
    }

    private var navigationBar: some View {
        HStack { if step != .start { Button("Back") { moveBack() }.accessibilityIdentifier("wizard.back") }; Spacer(); if step == .summary { Button(isLoading ? "Generating…" : "Generate Resume") { Task { await generate() } }.buttonStyle(.borderedProminent).disabled(!canAdvance).accessibilityIdentifier("wizard.generate") } else if step != .generated { Button("Next") { advance() }.buttonStyle(.borderedProminent).disabled(!canAdvance).accessibilityIdentifier("wizard.next") } }.padding(.horizontal).padding(.vertical, 10).background(.bar)
    }

    private func loadProfileDraft() { draftName = profileName; draftEmail = profileEmail; draftPhone = profilePhone; draftLocation = profileLocation; draftLinkedIn = profileLinkedIn; draftGitHub = profileGitHub; draftEducation = profileEducation; draftSkills = profileSkills; draftCertifications = profileCertifications }
    private func toggleExperience(_ id: UUID) { if selectedExperienceIDs.contains(id) { selectedExperienceIDs.remove(id) } else { selectedExperienceIDs.insert(id) } }
    private func advance() { if step == .start, startMode == .fresh { profileName = draftName; profileEmail = draftEmail; profilePhone = draftPhone; profileLocation = draftLocation; profileLinkedIn = draftLinkedIn; profileGitHub = draftGitHub; profileEducation = draftEducation; profileSkills = draftSkills; profileCertifications = draftCertifications }; generatedDraft = nil; generatedText = ""; isEditingGenerated = false; isSaved = false; errorMessage = nil; step = ResumeWizardStep(rawValue: step.rawValue + 1)! }
    private func moveBack() { step = ResumeWizardStep(rawValue: step.rawValue - 1)!; generatedDraft = nil; generatedText = ""; isEditingGenerated = false; isSaved = false; errorMessage = nil }
    private func handleSwipe(_ width: CGFloat) { if abs(width) < 40 { return }; if width < 0 { if step != .start { moveBack() } } else if step != .summary && step != .generated, canAdvance { advance() } }
    private func importPDF(_ result: Result<URL, Error>) { do { let url = try result.get(); let accessed = url.startAccessingSecurityScopedResource(); defer { if accessed { url.stopAccessingSecurityScopedResource() } }; guard let text = PDFDocument(url: url)?.string?.trimmingCharacters(in: .whitespacesAndNewlines), text.count > 40 else { errorMessage = "This PDF has no readable text. Choose a text-based PDF."; return }; baselineText = text; selectedResumeID = nil } catch { errorMessage = "The PDF could not be opened. Choose another file." } }
    private func generate() async { isLoading = true; errorMessage = nil; generatedDraft = nil; let availability = FoundationModelsAvailability().state(); guard availability == .ready else { if case .unavailable(let message) = availability { errorMessage = message }; isLoading = false; return }; do { generatedDraft = try await ResumeGenerationService().generate(jobText: selectedJob?.rawText ?? "", work: selectedExperiences, profileName: draftName, profileText: profileText, baselineText: baselineText.isEmpty ? nil : baselineText); generatedText = generatedDraft?.rawText.isEmpty == false ? generatedDraft?.rawText ?? "" : generatedDraft.map { JakesResumeTemplate().render(draft: $0).string } ?? ""; isEditingGenerated = false; step = .generated } catch { errorMessage = error.localizedDescription }; isLoading = false }
    private var profileText: String { [draftName, draftEmail, draftPhone, draftLocation, draftLinkedIn, draftGitHub, draftEducation, draftSkills, draftCertifications].joined(separator: "\n") }
    private func saveGeneratedResume() { guard let generatedDraft, let selectedJob else { return }; let resume = Resume(name: generatedDraft.name, jobTarget: selectedJob, workExperienceIDs: Array(selectedExperienceIDs), sections: [ResumeSection(kind: .summary, order: 0, title: "Resume", attributedText: NSAttributedString(string: generatedText))]); modelContext.insert(resume); do { try modelContext.save(); isSaved = true; onSaved() } catch { errorMessage = error.localizedDescription } }
}

struct ResumesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Resume.updatedAt, order: .reverse) private var resumes: [Resume]
    @State private var selected: Resume?

    var body: some View {
        List {
            if resumes.isEmpty { ContentUnavailableView("No saved resumes", systemImage: "doc.text", description: Text("Create your first tailored resume from the New resume tab.")) }
            ForEach(resumes) { resume in
                Button { selected = resume } label: { VStack(alignment: .leading, spacing: 4) { Text(resume.name).font(.headline); Text(resume.jobTarget?.parsedTitle ?? resume.jobTarget?.rawText.prefix(70).description ?? "Saved draft").font(.subheadline).foregroundStyle(.secondary); Text(resume.updatedAt, style: .date).font(.caption).foregroundStyle(.tertiary) } }.buttonStyle(.plain)
                    .listRowBackground(Color(uiColor: .systemBackground))
            }.onDelete { offsets in offsets.map { resumes[$0] }.forEach(modelContext.delete) }
        }
        .navigationTitle("Resumes")
        .scrollContentBackground(.hidden)
        .background(CVeeColors.page)
        .sheet(item: $selected) { ResumeEditorView(resume: $0) }
    }
}

struct ResumeEditorView: View {
    @Bindable var resume: Resume
    @State private var showShare = false
    @State private var shareItems: [Any] = []

    var body: some View {
        VStack(spacing: 0) {
            if let section = resume.sections.sorted(by: { $0.order < $1.order }).first { EditableResumeTextView(section: section) { resume.updatedAt = .now } } else { ContentUnavailableView("Resume is empty", systemImage: "doc.text") }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(resume.name).navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Menu { Button("Export PDF") { export(pdf: true) }; Button("Export RTF") { export(pdf: false) } } label: { Image(systemName: "square.and.arrow.up") }.accessibilityLabel("Export resume") } }
        .sheet(isPresented: $showShare) { ShareSheet(items: shareItems) }
    }

    private func export(pdf: Bool) {
        let service = ResumeExportService()
        if pdf { shareItems = [service.pdfData(for: resume)] }
        else { shareItems = [(try? service.rtfData(for: resume)) as Any].compactMap { $0 } }
        showShare = !shareItems.isEmpty
    }
}

struct ResumePreviewView: View {
    let resume: Resume

    var body: some View {
        ScrollView {
            if let section = resume.sections.sorted(by: { $0.order < $1.order }).first {
                Text(AttributedString(section.attributedText))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(28)
            } else {
                ContentUnavailableView("Resume is empty", systemImage: "doc.text")
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(resume.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditableResumeTextView: UIViewRepresentable {
    let section: ResumeSection
    let onChange: () -> Void
    func makeUIView(context: Context) -> UITextView { let view = UITextView(); view.delegate = context.coordinator; view.isEditable = true; view.backgroundColor = .systemBackground; view.textContainerInset = UIEdgeInsets(top: 28, left: 28, bottom: 28, right: 28); view.attributedText = section.attributedText; view.accessibilityLabel = "Editable resume"; return view }
    func updateUIView(_ uiView: UITextView, context: Context) { if !uiView.isFirstResponder { uiView.attributedText = section.attributedText } }
    func makeCoordinator() -> Coordinator { Coordinator(section: section, onChange: onChange) }
    final class Coordinator: NSObject, UITextViewDelegate { let section: ResumeSection; let onChange: () -> Void; init(section: ResumeSection, onChange: @escaping () -> Void) { self.section = section; self.onChange = onChange }; func textViewDidChange(_ textView: UITextView) { section.attributedText = textView.attributedText; onChange() } }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

#Preview { ContentView().modelContainer(for: [WorkExperience.self, JobTarget.self, Resume.self, ResumeSection.self], inMemory: true) }

#Preview("Accessibility text") {
    ContentView()
        .modelContainer(for: [WorkExperience.self, JobTarget.self, Resume.self, ResumeSection.self], inMemory: true)
        .environment(\.dynamicTypeSize, .accessibility3)
}
