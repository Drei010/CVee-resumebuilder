import SwiftUI
import SwiftData
import UIKit
import PDFKit
import UniformTypeIdentifiers

// THESIS: CVee's reusable experience library in the supplied Asana list language.
// OWN-WORLD: coral actions, white/charcoal canvas, flat rows and tinted metadata.
// STORY: capture experience, select relevant facts, generate and export a resume.
// FIRST VIEWPORT: native large title, company sections, persistent trailing coral add action.
// FORM: user-pinned Asana reference overrides concept seed 3f85a9cc.
// FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, and DESIGN.md
private enum CVeeColors {
    static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                           green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
    }
    static let coral = adaptive(0xF06A6A, 0xF06A6A)
    static let page = adaptive(0xFFFFFF, 0x1E1F21)
    static let card = adaptive(0xF9F8F8, 0x252628)
    static let divider = adaptive(0xEDEBE9, 0x35363A)
    static let ink = adaptive(0x1E1F21, 0xF5F4F2)
    static let buttonInk = adaptive(0x1E1F21, 0x1E1F21)
    static let secondary = adaptive(0x6D6E6F, 0xA9A9AA)
    static let green = adaptive(0x62D26F, 0x62D26F)
    // Darker foregrounds preserve contrast on the reference's soft object tints.
    static let objectInk = adaptive(0x2855A2, 0xA8C5FF)
    static let objectTint = adaptive(0x4573D2, 0x4573D2)
}

private struct CoralButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var horizontalPadding: CGFloat = 26
    var verticalPadding: CGFloat = 13
    var minimumHeight: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(CVeeColors.buttonInk)
            .padding(.horizontal, horizontalPadding).padding(.vertical, verticalPadding)
            .frame(minHeight: minimumHeight)
            .background(CVeeColors.coral.opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4),
                        in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct WorkspaceSurface: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(CVeeColors.page)
            .listRowBackground(CVeeColors.card)
    }
}

private struct MetadataPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(CVeeColors.objectInk)
            .padding(.horizontal, 9).padding(.vertical, 3)
            .background(CVeeColors.objectTint.opacity(0.16), in: Capsule())
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct SelectionCircle: View {
    let isSelected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title3)
            .foregroundStyle(isSelected ? CVeeColors.green : CVeeColors.secondary)
            .scaleEffect(isSelected ? 1.05 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isSelected)
            .sensoryFeedback(.selection, trigger: isSelected)
            .accessibilityHidden(true)
    }
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
        .tint(CVeeColors.coral)
        .foregroundStyle(CVeeColors.ink)
        .scrollContentBackground(.hidden)
        .background(CVeeColors.page)
        .toolbarBackground(CVeeColors.page, for: .tabBar, .navigationBar)
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
                Label("CVee is a focused workspace for organizing your experience, saving target jobs, and building tailored resumes from the facts you provide.", systemImage: "person.2")
                Label("Create reusable tasks, connect them to resumes, review job descriptions, and export polished drafts when you are ready to apply.", systemImage: "checklist")
                Label("AI uses Apple on-device when selected, or your configured provider.", systemImage: "lock.shield")
                    .foregroundStyle(.secondary)
                Label("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")", systemImage: "info.circle")
                NavigationLink { TermsAndConditionsView() } label: {
                    Label("Terms and conditions", systemImage: "doc.text")
                }
                Link(destination: URL(string: "mailto:andreihidalgo16@gmail.com")!) {
                    Label("Contact support · andreihidalgo16@gmail.com", systemImage: "envelope")
                }
            }
            Section("Advanced settings") {
                NavigationLink {
                    AIProviderView()
                } label: {
                    LabeledContent("AI Provider", value: AIProviderSelection().provider()?.name ?? "Not configured")
                }
                .accessibilityIdentifier("profile.ai-provider")
                Button("Clear all data", role: .destructive) { showingClearPrompt = true }
            }
        }
        .modifier(WorkspaceSurface())
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
        AIProviderSelection().clear()
    }
}

struct AIProviderView: View {
    private let selection = AIProviderSelection()
    @State private var provider = AIProvider.apple
    @State private var modelID = AIProvider.apple.defaultModel.id
    @State private var showingKeyEditor = false
    @State private var hasSavedKey = false

    private var appleUnavailable: Bool { FoundationModelsAvailability().state().description == "This device does not support Apple Intelligence generation." }
    private var modelSelection: Binding<String> {
        Binding(
            get: { provider.models.contains(where: { $0.id == modelID }) ? modelID : provider.defaultModel.id },
            set: { newValue in
                modelID = newValue
                if let model = provider.models.first(where: { $0.id == newValue }) { selection.setModel(model, for: provider) }
            }
        )
    }

    var body: some View {
        Form {
            Section("Provider") {
                Picker("Provider", selection: $provider) {
                    ForEach(AIProvider.allCases) { item in
                        Text(item.name).tag(item).disabled(item == .apple && appleUnavailable)
                    }
                }
                .accessibilityIdentifier("ai-provider.selector")
                LabeledContent("Status", value: provider == .apple ? (appleUnavailable ? "Unavailable" : "On-device") : (hasSavedKey ? "Configured" : "Needs API key"))
                    .foregroundStyle(.secondary)
                .onChange(of: provider) { _, newProvider in
                    modelID = selection.model(for: newProvider).id
                    hasSavedKey = selection.hasKey(for: newProvider)
                }
            }
            Section("Model") {
                if provider == .apple {
                    LabeledContent("Model", value: "System Model")
                    Text(appleUnavailable ? FoundationModelsAvailability().state().description : "Apple selects the on-device model automatically.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Picker("Model", selection: modelSelection) {
                        ForEach(provider.models) { model in Text(model.name).tag(model.id) }
                    }
                    .accessibilityIdentifier("ai-provider.model")
                }
            }
            if provider.requiresKey {
                Section("API key") {
                    if hasSavedKey {
                        Label("API key saved", systemImage: "checkmark.shield.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(CVeeColors.green)
                    }
                    Button {
                        showingKeyEditor = true
                    } label: {
                        Label(hasSavedKey ? "Edit API key" : "Add API key", systemImage: hasSavedKey ? "pencil" : "key.fill")
                    }
                    .accessibilityIdentifier("ai-provider.edit-key")
                }
            }
            Section {
                Text("Apple Intelligence processes content on this device. Third-party providers receive the relevant resume, profile, job, or task text and may charge your provider account.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .modifier(WorkspaceSurface())
        .navigationTitle("AI Provider")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingKeyEditor) {
            AIProviderKeyView(provider: provider, appleUnavailable: appleUnavailable)
        }
        .onChange(of: showingKeyEditor) { _, isPresented in
            if !isPresented { hasSavedKey = selection.hasKey(for: provider) }
        }
        .onAppear {
            if let saved = selection.provider() { provider = saved }
            modelID = selection.model(for: provider).id
            hasSavedKey = selection.hasKey(for: provider)
        }
    }
}

struct AIProviderKeyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let provider: AIProvider
    let appleUnavailable: Bool
    private let selection = AIProviderSelection()
    @State private var keyDraft = ""
    @State private var showingDeletePrompt = false
    @State private var message: String?

    private var hasKey: Bool { selection.hasKey(for: provider) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Connect " + provider.name, systemImage: "key.fill")
                        .font(.headline)
                    Text("Your key is stored securely on this device and used only when you run an AI feature.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if hasKey {
                        Label("API key saved", systemImage: "checkmark.shield.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(CVeeColors.green)
                    }
                    SecureField(hasKey ? "Replace saved API key" : "Paste API key", text: $keyDraft)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.password)
                        .accessibilityIdentifier("ai-provider.api-key")
                    Group {
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(alignment: .leading, spacing: 12) {
                                keyActions
                            }
                        } else {
                            HStack {
                                keyActions
                            }
                        }
                    }
                }
            }
            .modifier(WorkspaceSurface())
            .navigationTitle(hasKey ? "Edit API key" : "Add API key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .confirmationDialog("Delete this API key?", isPresented: $showingDeletePrompt, titleVisibility: .visible) {
                Button("Delete API key", role: .destructive) {
                    selection.keyStore.delete(for: provider)
                    if selection.provider() == provider { selection.setProvider(appleUnavailable ? nil : .apple) }
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You will need to enter it again before using " + provider.name + ".")
            }
            .alert("API key", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) { message = nil }
            } message: { Text(message ?? "") }
        }
    }

    @ViewBuilder
    private var keyActions: some View {
        if hasKey {
            Button(role: .destructive) {
                showingDeletePrompt = true
            } label: {
                Text("Delete API key")
                    .fixedSize(horizontal: true, vertical: false)
            }
            .buttonStyle(.borderless)
            .accessibilityHint("Removes the saved key after confirmation")
            .accessibilityIdentifier("ai-provider.remove-key")
            if !dynamicTypeSize.isAccessibilitySize { Spacer() }
        }
        Button {
            let key = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { return }
            do {
                try selection.keyStore.save(key, for: provider)
                selection.setProvider(provider)
                keyDraft = ""
                dismiss()
            } catch { message = error.localizedDescription }
        } label: {
            Text("Save")
                .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(CoralButtonStyle(horizontalPadding: 16, verticalPadding: 8))
        .fixedSize(horizontal: true, vertical: false)
        .disabled(keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .accessibilityHint("Saves the entered key and activates this provider")
        .accessibilityIdentifier("ai-provider.save-key")
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
                termsSection("5. Privacy Policy", "CVee stores saved tasks, jobs, resumes, and profile information in the app’s local data store. Apple Intelligence processing runs on-device when selected. If you choose a third-party AI provider, relevant resume, profile, job, or task text is sent to that provider under your API key and its terms. CVee does not require an account for local app use. Deleting the app or using Clear all data may permanently remove this information. Keep your own backup of content you need to retain.")
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
                    .buttonStyle(CoralButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(!invalidURLFields.isEmpty)
                }
            }
            .modifier(WorkspaceSurface())
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
            .modifier(WorkspaceSurface())
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
    @State private var showingImport = false
    @State private var searchText = ""
    @State private var selectedCompany = "All companies"
    @State private var collapsedCompanies = Set<String>()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            ForEach(Array(Set(filteredExperiences.map(\.company))).sorted(), id: \.self) { company in
                Section {
                    if !collapsedCompanies.contains(company) {
                        ForEach(filteredExperiences.filter { $0.company == company }) { experience in
                            Button { selected = experience } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "text.badge.checkmark")
                                        .font(.system(size: 20))
                                        .foregroundStyle(CVeeColors.secondary)
                                        .frame(width: 22).accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(experience.jobTitle).font(.subheadline.weight(.medium))
                                        Text(experience.tasks.first ?? "No task details yet")
                                            .font(.subheadline).foregroundStyle(CVeeColors.secondary).lineLimit(2)
                                        MetadataPill(text: experience.company.isEmpty ? "Work history" : experience.company)
                                        Text(experience.dateRange).font(.caption).monospacedDigit()
                                            .foregroundStyle(CVeeColors.secondary)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 11)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(CVeeColors.page)
                            .listRowSeparatorTint(CVeeColors.divider)
                            .accessibilityHint("Opens this work experience for editing")
                            .swipeActions { Button("Delete", role: .destructive) { modelContext.delete(experience) } }
                        }
                    }
                } header: {
                    Button {
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                            if collapsedCompanies.contains(company) { collapsedCompanies.remove(company) }
                            else { collapsedCompanies.insert(company) }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: collapsedCompanies.contains(company) ? "chevron.right" : "chevron.down")
                            Text(company.isEmpty ? "Work history" : company)
                            Spacer()
                            Text("\(filteredExperiences.filter { $0.company == company }.count)").monospacedDigit()
                                .foregroundStyle(CVeeColors.secondary)
                        }
                        .font(.caption.weight(.bold)).foregroundStyle(CVeeColors.ink)
                        .frame(minHeight: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain).textCase(nil)
                    .accessibilityValue(collapsedCompanies.contains(company) ? "Collapsed" : "Expanded")
                    .accessibilityIdentifier("tasks.company-section")
                }
            }
        }
        .listStyle(.plain)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .safeAreaPadding(.bottom, 80)
        .navigationTitle("Tasks")
        .searchable(text: $searchText, prompt: "Search tasks")
        .scrollContentBackground(.hidden)
        .background(CVeeColors.page)
        .overlay(alignment: .bottomTrailing) {
            Menu {
                Button("Add manually") { showingAddTask = true }
                Button("Import Tasks List") { showingImport = true }
            } label: {
                Image(systemName: "plus").font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(CVeeColors.buttonInk)
                    .frame(width: 56, height: 56)
                    .background(CVeeColors.coral, in: Circle())
                    .shadow(color: CVeeColors.coral.opacity(0.45), radius: 10, x: 0, y: 8)
            }
            .accessibilityLabel("Add task")
            .accessibilityHint("Choose whether to add a task manually or import a task list")
            .accessibilityIdentifier("tasks.add")
            .padding(.trailing, 18).padding(.bottom, 16)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("All companies") { selectedCompany = "All companies" }
                    ForEach(companies, id: \.self) { company in
                        Button(company) { selectedCompany = company }
                    }
                } label: { Label(selectedCompany == "All companies" ? "Filter" : selectedCompany, systemImage: "line.3.horizontal.decrease.circle") }
                .accessibilityLabel("Filter tasks by company")
            }
        }
        .sheet(item: $selected) { experience in TaskDetailView(experience: experience) }
        .sheet(isPresented: $showingAddTask) { WorkExperienceEditor(experience: WorkExperience(jobTitle: "", company: "")) }
        .sheet(isPresented: $showingImport) { TaskImportView() }
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
                        .buttonStyle(CoralButtonStyle())
                        .frame(maxWidth: .infinity)
                    } else {
                        Button("Edit") { isEditing = true }
                            .frame(maxWidth: .infinity)
                            .tint(CVeeColors.coral)
                            .accessibilityIdentifier("task.edit")
                        Button("Delete", role: .destructive) { showingDeleteAlert = true }
                            .frame(maxWidth: .infinity)
                            .tint(.red)
                            .accessibilityIdentifier("task.delete")
                    }
                }
            }
            .modifier(WorkspaceSurface())
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
                ContentUnavailableView("No saved jobs", systemImage: "bookmark", description: Text("Add a job description to tailor your next resume."))
            }
            ForEach(filteredJobs) { job in
                Button { selectedJob = job } label: {
                    VStack(alignment: .leading, spacing: 5) {
                    Text(job.parsedTitle ?? job.rawText.split(whereSeparator: \.isNewline).first.map(String.init) ?? "Untitled job")
                        .font(.headline)
                    MetadataPill(text: job.parsedCompany ?? "Job target")
                    Text(job.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(CVeeColors.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                .listRowBackground(CVeeColors.page)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Opens saved job details")
            }
            .onDelete { offsets in
                offsets.map { filteredJobs[$0] }.forEach(modelContext.delete)
                do { try modelContext.save() } catch { saveError = error.localizedDescription }
            }
        }
        .listStyle(.plain)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
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
                                        .foregroundStyle(CVeeColors.secondary)
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
                        .buttonStyle(CoralButtonStyle())
                        .frame(maxWidth: .infinity)
                    } else {
                        Button("Edit") { isEditing = true }
                            .frame(maxWidth: .infinity)
                        Button("Delete", role: .destructive) { showingDeleteAlert = true }
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .modifier(WorkspaceSurface())
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
                    .buttonStyle(CoralButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(!canSave)
                }
            }
            .modifier(WorkspaceSurface())
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
                        .accessibilityLabel("Enhance task details with AI")
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
                    .buttonStyle(CoralButtonStyle())
                    .frame(maxWidth: .infinity)
                    .disabled(jobTitle.trimmingCharacters(in: .whitespaces).isEmpty || company.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier("task.save")
                }
            }
            .modifier(WorkspaceSurface())
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

struct TaskImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    var onSaved: ([UUID]) -> Void = { _ in }
    @State private var showingPicker = false
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var sourceText = ""
    @State private var jobTitle = ""
    @State private var company = ""
    @State private var startDate = Date.now
    @State private var endDate: Date?
    @State private var drafts: [ImportedTask] = []

    private var canSave: Bool { !jobTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && drafts.contains(where: \ImportedTask.isSelected) }
    var body: some View {
        NavigationStack {
            Form {
                Section("Workplace") { TextField("Job title", text: $jobTitle).accessibilityIdentifier("import.job-title"); TextField("Company", text: $company).accessibilityIdentifier("import.company"); DatePicker("Start date", selection: $startDate, displayedComponents: .date); Toggle("Currently working here", isOn: Binding(get: { endDate == nil }, set: { endDate = $0 ? nil : .now })); if endDate != nil { DatePicker("End date", selection: Binding($endDate)!, displayedComponents: .date) } }
                if drafts.isEmpty { Section { Button("Choose document") { showingPicker = true }.accessibilityIdentifier("import.choose-document"); if isAnalyzing { ProgressView("Analyzing tasks…") }; if !sourceText.isEmpty && !isAnalyzing { Text("Document loaded. Choose Analyze to preview tasks.").foregroundStyle(.secondary) } } }
                if !drafts.isEmpty { Section("Preview (\(drafts.filter(\.isSelected).count) selected)") { ForEach($drafts) { $draft in HStack { Button { draft.isSelected.toggle() } label: { SelectionCircle(isSelected: draft.isSelected).frame(width: 44, height: 44) }.buttonStyle(.plain).accessibilityLabel("Include task in import").accessibilityValue(draft.isSelected ? "Selected" : "Not selected"); TextField("Task or contribution", text: $draft.text, axis: .vertical).lineLimit(2...5) } }; DisclosureGroup("Source document") { Text(sourceText).font(.caption).textSelection(.enabled) } } }
                if !sourceText.isEmpty && drafts.isEmpty && !isAnalyzing { Section { Button("Analyze with AI") { analyze() }.disabled(isAnalyzing).accessibilityIdentifier("import.analyze") } }
                if !drafts.isEmpty { Section { Button("Add \(drafts.filter(\.isSelected).count) tasks") { save() }.disabled(!canSave).accessibilityIdentifier("import.save") } }
            }
            .modifier(WorkspaceSurface())
            .navigationTitle("Import Tasks List").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .fileImporter(isPresented: $showingPicker, allowedContentTypes: [UTType.pdf, .plainText, UTType(filenameExtension: "docx")!]) { result in load(result) }
            .alert("Import failed", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) { Button("OK", role: .cancel) { errorMessage = nil } } message: { Text(errorMessage ?? "Try again.") }
        }
    }
    private func load(_ result: Result<URL, Error>) { do { let url = try result.get(); let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }; sourceText = try TaskDocumentReader().read(url); drafts = [] } catch { errorMessage = (error as? LocalizedError)?.errorDescription ?? "The document could not be opened." } }
    private func analyze() { isAnalyzing = true; Task { do { drafts = try await TaskImportService().split(sourceText).map { ImportedTask(text: $0) }; if drafts.isEmpty { errorMessage = "No separate tasks were found." } } catch { errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }; isAnalyzing = false } }
    private func save() { let selected = drafts.filter(\.isSelected); let newItems = selected.map { WorkExperience(jobTitle: jobTitle.trimmingCharacters(in: .whitespacesAndNewlines), company: company.trimmingCharacters(in: .whitespacesAndNewlines), startDate: startDate, endDate: endDate, tasks: [$0.text.trimmingCharacters(in: .whitespacesAndNewlines)]) }; newItems.forEach(modelContext.insert); do { try modelContext.save(); onSaved(newItems.map(\.id)); dismiss() } catch { newItems.forEach(modelContext.delete); errorMessage = error.localizedDescription } }
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
    @State private var showingImport = false
    @State private var showingAddJob = false
    @State private var taskCountBeforeAdd = 0
    @State private var jobCountBeforeAdd = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var generatedDraft: ResumeDraft?
    @State private var generatedText = ""
    @State private var generatedLaTeX = ""
    @State private var generatedEditorMode = EditorMode.formatted
    @State private var isEditingGenerated = false
    @State private var isSaved = false

    private enum EditorMode { case formatted, latex }

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
            .gesture(DragGesture(minimumDistance: 40).onEnded { value in handleSwipe(value.translation) })
            navigationBar
        }
        .navigationTitle("Resume Wizard")
        .background(CVeeColors.page)
        .onAppear { loadProfileDraft() }
        .onChange(of: startMode) { _, mode in if mode == .fresh { baselineText = ""; selectedResumeID = nil } }
        .onChange(of: experiences.count) { _, count in if count > taskCountBeforeAdd, let newest = experiences.max(by: { $0.createdAt < $1.createdAt }) { selectedExperienceIDs.insert(newest.id) } }
        .onChange(of: jobs.count) { _, count in if count > jobCountBeforeAdd, let newest = jobs.first { selectedJobID = newest.id } }
        .sheet(isPresented: $showingAddTask) { WorkExperienceEditor(experience: WorkExperience(jobTitle: "", company: "")) }
        .sheet(isPresented: $showingImport) { TaskImportView { ids in selectedExperienceIDs.formUnion(ids) } }
        .sheet(isPresented: $showingAddJob) { AddJobView() }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.pdf]) { result in importPDF(result) }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(step.title).font(.headline)
                Spacer()
                Text("\(step.rawValue + 1) of \(ResumeWizardStep.allCases.count)")
                    .font(.caption).monospacedDigit().foregroundStyle(CVeeColors.secondary)
            }
            HStack(spacing: 4) {
                ForEach(ResumeWizardStep.allCases, id: \.rawValue) { item in
                    Rectangle().fill(item.rawValue < step.rawValue ? CVeeColors.green : item == step ? CVeeColors.coral : CVeeColors.divider)
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("wizard.progress")
        .accessibilityLabel("Step \(step.rawValue + 1) of \(ResumeWizardStep.allCases.count): \(step.title)")
    }

    private var startPage: some View {
        Form {
            Section { Picker("Start method", selection: $startMode) { ForEach(ResumeStartMode.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented) }
            if startMode == .fresh {
                Section("Your identity") {
                    if !profileIsValid { Text("Full name and email are required.").font(.caption).foregroundStyle(CVeeColors.secondary) }
                    TextField("Full name", text: $draftName, prompt: Text("Full name").foregroundStyle(CVeeColors.secondary)).textContentType(.name).accessibilityIdentifier("wizard.full-name")
                    TextField("Email", text: $draftEmail, prompt: Text("Email").foregroundStyle(CVeeColors.secondary)).textContentType(.emailAddress).keyboardType(.emailAddress).accessibilityIdentifier("wizard.email")
                    TextField("Phone", text: $draftPhone, prompt: Text("Phone").foregroundStyle(CVeeColors.secondary)).textContentType(.telephoneNumber).keyboardType(.phonePad)
                    TextField("Location", text: $draftLocation, prompt: Text("Location").foregroundStyle(CVeeColors.secondary))
                    TextField("LinkedIn URL", text: $draftLinkedIn, prompt: Text("LinkedIn URL").foregroundStyle(CVeeColors.secondary)).textInputAutocapitalization(.never).keyboardType(.URL)
                    TextField("GitHub URL", text: $draftGitHub, prompt: Text("GitHub URL").foregroundStyle(CVeeColors.secondary)).textInputAutocapitalization(.never).keyboardType(.URL)
                    TextField("Education", text: $draftEducation, prompt: Text("Education").foregroundStyle(CVeeColors.secondary))
                    TextField("Skills & abilities", text: $draftSkills, prompt: Text("Skills & abilities").foregroundStyle(CVeeColors.secondary))
                    TextField("Certifications", text: $draftCertifications, prompt: Text("Certifications").foregroundStyle(CVeeColors.secondary))
                }
            } else {
                Section("Resume baseline") {
                    Button("Upload PDF") { showingFileImporter = true }
                    if !resumes.isEmpty { ForEach(resumes) { resume in Button { selectedResumeID = resume.id; baselineText = resume.sections.sorted(by: { $0.order < $1.order }).map { $0.attributedText.string }.joined(separator: "\n") } label: { Label(resume.name, systemImage: selectedResumeID == resume.id ? "checkmark.circle.fill" : "doc.text") } } }
                    if !baselineText.isEmpty { Text("Baseline ready").font(.caption).foregroundStyle(.secondary) }
                }
            }
        }.formStyle(.grouped).modifier(WorkspaceSurface()).accessibilityIdentifier("wizard.start")
    }

    private var workLibraryPage: some View {
        Form {
            Section { TextField("Search tasks", text: $taskSearch).textInputAutocapitalization(.never) }
            Section {
                HStack {
                    Text("\(selectedExperiences.count) selected")
                    Spacer()
                    Button("Select All") { selectAllExperiences() }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("wizard.select-all")
                    Button("Clear") { clearSelectedExperiences() }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("wizard.clear-selection")
                }
            }
            Section("Work Library") {
                if filteredExperiences.isEmpty { ContentUnavailableView("No matching tasks", systemImage: "checklist") }
                ForEach(filteredExperiences) { experience in Button { toggleExperience(experience.id) } label: { HStack { VStack(alignment: .leading) { Text(experience.jobTitle).font(.subheadline.weight(.medium)); MetadataPill(text: experience.company).foregroundStyle(.secondary); Text(experience.tasks.first ?? "No task details").font(.caption).foregroundStyle(.secondary).lineLimit(2) }; Spacer(); SelectionCircle(isSelected: selectedExperienceIDs.contains(experience.id)) } }.buttonStyle(.plain).accessibilityValue(selectedExperienceIDs.contains(experience.id) ? "Selected" : "Not selected") }
                Menu { Button("Add manually") { taskCountBeforeAdd = experiences.count; showingAddTask = true }; Button("Import Tasks List") { showingImport = true } } label: { Label("Add task", systemImage: "plus") }
            }
        }.formStyle(.grouped).modifier(WorkspaceSurface()).accessibilityIdentifier("wizard.work-library")
    }

    private var jobDescriptionPage: some View {
        Form {
            Section { TextField("Search saved jobs", text: $jobSearch).textInputAutocapitalization(.never) }
            Section("Job descriptions") {
                if filteredJobs.isEmpty { ContentUnavailableView("No saved jobs", systemImage: "briefcase", description: Text("Add a job description to continue.")) }
                ForEach(filteredJobs) { job in Button { selectedJobID = job.id } label: { HStack { VStack(alignment: .leading) { Text(job.parsedTitle ?? "Untitled job").font(.headline); Text(job.parsedCompany ?? "Unknown company").foregroundStyle(.secondary); Text(job.rawText).font(.caption).foregroundStyle(.secondary).lineLimit(3) }; Spacer(); SelectionCircle(isSelected: selectedJobID == job.id) } }.buttonStyle(.plain).accessibilityValue(selectedJobID == job.id ? "Selected" : "Not selected") }
                Button { jobCountBeforeAdd = jobs.count; showingAddJob = true } label: { Label("Add job", systemImage: "plus") }
            }
        }.formStyle(.grouped).modifier(WorkspaceSurface()).accessibilityIdentifier("wizard.job-description")
    }

    private var summaryPage: some View {
        Form {
            Section("Ready to generate") { LabeledContent("Start", value: startMode.rawValue); LabeledContent("Name", value: startMode == .fresh ? draftName : "Existing resume baseline"); LabeledContent("Tasks", value: "\(selectedExperiences.count) selected"); LabeledContent("Job", value: selectedJob?.parsedTitle ?? "Selected job") }
            Section("Selected tasks") { ForEach(selectedExperiences) { Text("\($0.jobTitle): \($0.tasks.first ?? "No task details")") } }
            if let selectedJob { Section("Job description") { Text(selectedJob.rawText).lineLimit(8) } }
            if isLoading { Section { ProgressView("Generating your resume…").accessibilityIdentifier("wizard.loader") } }
            if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
        }.formStyle(.grouped).modifier(WorkspaceSurface()).accessibilityIdentifier("wizard.summary")
    }

    private var generatedPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if generatedDraft != nil {
                    if isEditingGenerated {
                        HStack {
                            Button("Formatted") { generatedEditorMode = .formatted }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("wizard.formatted-mode")
                            Button("LaTeX") { generatedLaTeX = ResumeLaTeXFormatter.source(from: ResumeTextFormatter.format(generatedText)); generatedEditorMode = .latex }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("wizard.latex-mode")
                        }
                        if generatedEditorMode == .latex {
                            TextEditor(text: $generatedLaTeX)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 420)
                                .padding(12)
                                .background(.background)
                                .accessibilityLabel("LaTeX resume editor")
                                .accessibilityIdentifier("wizard.latex-editor")
                        } else {
                            TextEditor(text: $generatedText)
                                .frame(minHeight: 420)
                                .padding(12)
                                .background(.background)
                        }
                    } else {
                        ResumePagePreview(pdfData: ResumeExportService().pdfData(for: ResumeTextFormatter.format(generatedText)))
                    }
                    Button(isEditingGenerated ? "Done editing" : "Edit resume") { if isEditingGenerated && generatedEditorMode == .latex { generatedText = ResumeLaTeXFormatter.attributedText(from: generatedLaTeX).string }; isEditingGenerated.toggle() }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("wizard.edit-resume")
                    Button(isSaved ? "Saved to Resumes" : "Save Resume") { saveGeneratedResume() }
                        .buttonStyle(CoralButtonStyle())
                        .disabled(isSaved || generatedDraft == nil)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("wizard.save-resume")
                    if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .padding()
        }
        .accessibilityIdentifier("wizard.generated")
        .onChange(of: generatedLaTeX) { _, source in if generatedEditorMode == .latex { generatedText = ResumeLaTeXFormatter.attributedText(from: source).string } }
    }

    private var navigationBar: some View {
        HStack { if step != .start { Button("Back") { moveBack() }.accessibilityIdentifier("wizard.back") }; Spacer(); if step == .summary { Button(isLoading ? "Generating…" : "Generate Resume") { Task { await generate() } }.buttonStyle(CoralButtonStyle()).disabled(!canAdvance).accessibilityIdentifier("wizard.generate") } else if step != .generated { Button("Next") { advance() }.buttonStyle(CoralButtonStyle()).disabled(!canAdvance).accessibilityIdentifier("wizard.next") } }.padding(.horizontal).padding(.vertical, 10).background(.bar)
    }

    private func loadProfileDraft() { draftName = profileName; draftEmail = profileEmail; draftPhone = profilePhone; draftLocation = profileLocation; draftLinkedIn = profileLinkedIn; draftGitHub = profileGitHub; draftEducation = profileEducation; draftSkills = profileSkills; draftCertifications = profileCertifications }
    private func toggleExperience(_ id: UUID) { if selectedExperienceIDs.contains(id) { selectedExperienceIDs.remove(id) } else { selectedExperienceIDs.insert(id) } }
    private func selectAllExperiences() { selectedExperienceIDs = Set(experiences.map(\.id)) }
    private func clearSelectedExperiences() { selectedExperienceIDs.removeAll() }
    private func advance() { if step == .start, startMode == .fresh { profileName = draftName; profileEmail = draftEmail; profilePhone = draftPhone; profileLocation = draftLocation; profileLinkedIn = draftLinkedIn; profileGitHub = draftGitHub; profileEducation = draftEducation; profileSkills = draftSkills; profileCertifications = draftCertifications }; generatedDraft = nil; generatedText = ""; generatedLaTeX = ""; generatedEditorMode = .formatted; isEditingGenerated = false; isSaved = false; errorMessage = nil; step = ResumeWizardStep(rawValue: step.rawValue + 1)! }
    private func moveBack() { step = ResumeWizardStep(rawValue: step.rawValue - 1)!; generatedDraft = nil; generatedText = ""; generatedLaTeX = ""; generatedEditorMode = .formatted; isEditingGenerated = false; isSaved = false; errorMessage = nil }
    private func handleSwipe(_ translation: CGSize) {
        let horizontal = abs(translation.width)
        let vertical = abs(translation.height)
        guard horizontal >= 40, horizontal > vertical * 1.25 else { return }
        if translation.width < 0 {
            if step != .start { moveBack() }
        } else if step != .summary && step != .generated, canAdvance {
            advance()
        }
    }
    private func importPDF(_ result: Result<URL, Error>) { do { let url = try result.get(); let accessed = url.startAccessingSecurityScopedResource(); defer { if accessed { url.stopAccessingSecurityScopedResource() } }; guard let text = PDFDocument(url: url)?.string?.trimmingCharacters(in: .whitespacesAndNewlines), text.count > 40 else { errorMessage = "This PDF has no readable text. Choose a text-based PDF."; return }; baselineText = text; selectedResumeID = nil } catch { errorMessage = "The PDF could not be opened. Choose another file." } }
    private func generate() async { isLoading = true; errorMessage = nil; generatedDraft = nil; if ProcessInfo.processInfo.arguments.contains("-resume-format-fixture") { generatedDraft = ResumeDraft(name: "Andrei Hidalgo — Full Stack AI Developer", summary: "AI developer focused on reliable, user-centered software.", experience: selectedExperiences.map { ($0.jobTitle, $0.tasks) }, skills: ["SwiftUI", "SwiftData", "Python"]); generatedText = JakesResumeTemplate().render(draft: generatedDraft!).string; isEditingGenerated = false; step = .generated; isLoading = false; return }; do { generatedDraft = try await ResumeGenerationService().generate(jobText: selectedJob?.rawText ?? "", work: selectedExperiences, profileName: draftName, profileText: profileText, baselineText: baselineText.isEmpty ? nil : baselineText); generatedText = generatedDraft?.rawText.isEmpty == false ? generatedDraft?.rawText ?? "" : generatedDraft.map { JakesResumeTemplate().render(draft: $0).string } ?? ""; isEditingGenerated = false; step = .generated } catch { errorMessage = error.localizedDescription }; isLoading = false }
    private var profileText: String { [draftName, draftEmail, draftPhone, draftLocation, draftLinkedIn, draftGitHub, draftEducation, draftSkills, draftCertifications].joined(separator: "\n") }
    private func saveGeneratedResume() { guard let generatedDraft, let selectedJob else { return }; let resume = Resume(name: generatedDraft.name, jobTarget: selectedJob, workExperienceIDs: Array(selectedExperienceIDs), sections: [ResumeSection(kind: .summary, order: 0, title: "Resume", attributedText: ResumeTextFormatter.format(generatedText))]); modelContext.insert(resume); do { try modelContext.save(); isSaved = true; onSaved() } catch { errorMessage = error.localizedDescription } }
}

struct ResumesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Resume.updatedAt, order: .reverse) private var resumes: [Resume]
    var body: some View {
        List {
            if resumes.isEmpty { ContentUnavailableView("No saved resumes", systemImage: "doc.text", description: Text("Create your first tailored resume from the Resume Wizard tab.")) }
            ForEach(resumes) { resume in
                NavigationLink { ResumeEditorView(resume: resume) } label: { VStack(alignment: .leading, spacing: 4) { Text(resume.name).font(.headline); Text(resume.jobTarget?.parsedTitle ?? resume.jobTarget?.rawText.prefix(70).description ?? "Saved draft").font(.subheadline).foregroundStyle(.secondary); Text(resume.updatedAt, style: .date).font(.caption).foregroundStyle(CVeeColors.secondary) } }.accessibilityIdentifier("resume.saved-row")
                    .listRowBackground(CVeeColors.page)
            }.onDelete { offsets in offsets.map { resumes[$0] }.forEach(modelContext.delete) }
        }
        .listStyle(.plain)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .navigationTitle("Resumes")
        .scrollContentBackground(.hidden)
        .background(CVeeColors.page)
    }
}

struct ResumeEditorView: View {
    @Bindable var resume: Resume
    @State private var showShare = false
    @State private var shareItems: [Any] = []
    @State private var editorMode = EditorMode.formatted
    @State private var latexText = ""

    private enum EditorMode: String, CaseIterable { case formatted, latex }

    var body: some View {
        VStack(spacing: 0) {
            if let section = resume.sections.sorted(by: { $0.order < $1.order }).first {
                HStack {
                    Button("Formatted") { editorMode = .formatted }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("resume.formatted-mode")
                    Button("LaTeX") { editorMode = .latex }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("resume.latex-mode")
                }
                .padding()
                .accessibilityIdentifier("resume.editor-format")

                if editorMode == .formatted {
                    EditableResumeTextView(section: section) { resume.updatedAt = .now }
                        .accessibilityIdentifier("resume.editor")
                } else {
                    TextEditor(text: $latexText)
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                        .accessibilityLabel("LaTeX resume editor")
                        .accessibilityIdentifier("resume.latex-editor")
                }
            } else { ContentUnavailableView("Resume is empty", systemImage: "doc.text") }
        }
        .background(CVeeColors.card)
        .navigationTitle(resume.name).navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let section = resume.sections.sorted(by: { $0.order < $1.order }).first { latexText = ResumeLaTeXFormatter.source(from: section.attributedText) }
        }
        .onChange(of: editorMode) { _, mode in
            guard let section = resume.sections.sorted(by: { $0.order < $1.order }).first else { return }
            if mode == .latex { latexText = ResumeLaTeXFormatter.source(from: section.attributedText) }
            else { section.attributedText = ResumeLaTeXFormatter.attributedText(from: latexText); resume.updatedAt = .now }
        }
        .onChange(of: latexText) { _, text in
            guard editorMode == .latex, let section = resume.sections.sorted(by: { $0.order < $1.order }).first else { return }
            section.attributedText = ResumeLaTeXFormatter.attributedText(from: text)
            resume.updatedAt = .now
        }
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Menu { Button("Export PDF") { export(pdf: true) }.accessibilityIdentifier("resume.export-pdf"); Button("Export RTF") { export(pdf: false) }.accessibilityIdentifier("resume.export-rtf") } label: { Image(systemName: "square.and.arrow.up") }.accessibilityLabel("Export resume").accessibilityIdentifier("resume.export") } }
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
            ResumePagePreview(pdfData: ResumeExportService().pdfData(for: resume))
        }
        .background(CVeeColors.card)
        .navigationTitle(resume.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ResumePagePreview: View {
    let pdfData: Data

    var body: some View {
        ResumePDFView(pdfData: pdfData)
            .aspectRatio(612.0 / 792.0, contentMode: .fit)
            .background(CVeeColors.card)
            .accessibilityIdentifier("wizard.generated.pdf")
    }
}

struct ResumePDFView: UIViewRepresentable {
    let pdfData: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePage
        view.displayDirection = .vertical
        view.backgroundColor = .systemGroupedBackground
        view.document = PDFDocument(data: pdfData)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: pdfData)
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
