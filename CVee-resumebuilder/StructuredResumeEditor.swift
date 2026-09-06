import SwiftUI
import SwiftData

enum ResumeSaveState: Equatable { case saved, saving, failed(String) }

struct StructuredResumeEditorView: View {
    @Bindable var resume: Resume
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var document: ResumeDocument
    @State private var mode = Mode.content
    @State private var saveState: ResumeSaveState = .saved
    @State private var saveTask: Task<Void, Never>?
    @State private var undoStack: [ResumeDocument] = []
    @State private var redoStack: [ResumeDocument] = []
    @State private var pendingDelete: ResumeDocumentSection?
    @State private var showingImport = false
    @State private var showShare = false
    @State private var shareItems: [Any] = []

    enum Mode: String, CaseIterable { case content, preview }

    init(resume: Resume) {
        self.resume = resume
        _document = State(initialValue: (try? ResumeDocumentConverter.document(for: resume)) ?? .empty)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Editor mode", selection: $mode) { Text("Content").tag(Mode.content); Text("Preview").tag(Mode.preview) }
                .pickerStyle(.segmented).padding().accessibilityIdentifier("resume.editor-mode")
            if mode == .content { content } else { preview }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(resume.name).navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .task { persistIfNeeded() }
        .onChange(of: scenePhase) { _, phase in if phase == .background { flushSave() } }
        .onDisappear { flushSave() }
        .confirmationDialog("Delete section?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })) {
            if let section = pendingDelete { Button("Delete \(section.title)", role: .destructive) { mutate { document.sections.removeAll { $0.id == section.id } }; pendingDelete = nil } }
        } message: { Text("Undo restores the deleted section during this editing session.") }
        .sheet(isPresented: $showShare) { ShareSheet(items: shareItems) }
        .sheet(isPresented: $showingImport) { LaTeXImportSheet { imported in createImportedCopy(imported) } }
    }

    private var content: some View {
        List {
            Section {
                TextField("Document name", text: Binding(get: { resume.name }, set: { resume.name = $0; changed() }))
                HStack {
                    Label(saveStateText, systemImage: saveState == .saving ? "arrow.triangle.2.circlepath" : saveState == .saved ? "checkmark.circle" : "exclamationmark.triangle")
                        .foregroundStyle(saveState == .saved ? Color.secondary : saveState == .saving ? Color.orange : Color.red)
                    Spacer()
                    Text("\(pageCount) \(pageCount == 1 ? "page" : "pages") · target \(document.layout.targetPages)").font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Sections") {
                ForEach(document.sections) { section in sectionRow(section) }
                Menu { ForEach(ResumeSectionKind.allCases.filter { $0 != .header }, id: \.rawValue) { kind in Button(kind.title) { addSection(kind) } } } label: { Label("Add section", systemImage: "plus") }.accessibilityIdentifier("resume.add-section")
            }
            Section("Page target") {
                Picker("Target", selection: Binding(get: { document.layout.targetPages }, set: { value in mutate { document.layout.targetPages = value } })) {
                    Text("1 page").tag(1); Text("2 pages").tag(2)
                }.pickerStyle(.segmented)
            }
            if !document.conversionNotes.isEmpty {
                Section("Conversion review") {
                    ForEach(document.conversionNotes, id: \.self) { Text($0).font(.caption).foregroundStyle(.orange) }
                    if let source = document.originalSource { DisclosureGroup("Original source") { Text(source).font(.system(.caption, design: .monospaced)).textSelection(.enabled) } }
                }
            }
        }.listStyle(.insetGrouped).scrollContentBackground(.hidden)
    }

    private func sectionRow(_ section: ResumeDocumentSection) -> some View {
        DisclosureGroup {
            ResumeSectionForm(section: sectionBinding(section.id), onMoveUp: { moveSection(section.id, by: -1) }, onMoveDown: { moveSection(section.id, by: 1) }, onAdd: { addEntry(to: section.id) })
        } label: {
            HStack {
                Image(systemName: section.isVisible ? "eye" : "eye.slash").foregroundStyle(.secondary)
                TextField("Section title", text: sectionTitleBinding(section.id))
                Spacer()
                Button(section.isVisible ? "Hide" : "Show") { mutate { toggleVisibility(section.id, in: &document) } }.buttonStyle(.borderless)
            }
        }
        .swipeActions { if section.kind != .header { Button("Delete", role: .destructive) { pendingDelete = section } } }
        .contextMenu {
            Button("Move Up") { moveSection(section.id, by: -1) }.disabled(section.kind == .header)
            Button("Move Down") { moveSection(section.id, by: 1) }
            if section.kind != .header { Button("Delete", role: .destructive) { pendingDelete = section } }
        }
        .accessibilityIdentifier("resume.section.\(section.id.uuidString)")
    }

    private var preview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(pageCount) \(pageCount == 1 ? "page" : "pages") · target \(document.layout.targetPages)").font(.caption).foregroundStyle(.secondary)
                ResumePagePreview(pdfData: ResumeDocumentRenderer().pdfData(for: document)).accessibilityIdentifier("resume.structured-preview")
            }.padding()
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Undo") { undo() }.disabled(undoStack.isEmpty).accessibilityIdentifier("resume.undo")
            Button("Redo") { redo() }.disabled(redoStack.isEmpty).accessibilityIdentifier("resume.redo")
            Menu {
                Button("Import LaTeX text") { showingImport = true }.accessibilityIdentifier("resume.import-latex")
                Button("Export PDF") { export(pdf: true) }.accessibilityIdentifier("resume.export-pdf")
                Button("Export RTF") { export(pdf: false) }.accessibilityIdentifier("resume.export-rtf")
            } label: { Image(systemName: "ellipsis.circle") }.accessibilityLabel("Resume actions").accessibilityIdentifier("resume.export")
        }
    }

    private var saveStateText: String { switch saveState { case .saved: "Saved"; case .saving: "Saving"; case .failed: "Couldn't save — Retry" } }
    private var pageCount: Int { ResumeDocumentRenderer().pageCount(for: document) }
    private func sectionBinding(_ id: UUID) -> Binding<ResumeDocumentSection> {
        Binding(get: { document.sections.first(where: { $0.id == id }) ?? ResumeDocumentSection(kind: .custom, title: "Section", content: .custom(CustomContent())) }, set: { value in mutate { if let index = document.sections.firstIndex(where: { $0.id == id }) { document.sections[index] = value } } })
    }
    private func sectionTitleBinding(_ id: UUID) -> Binding<String> { Binding(get: { document.sections.first(where: { $0.id == id })?.title ?? "" }, set: { value in mutate { if let index = document.sections.firstIndex(where: { $0.id == id }) { document.sections[index].title = value } } }) }
    private func mutate(_ change: () -> Void) { undoStack.append(document); redoStack.removeAll(); change(); changed() }
    private func changed() {
        saveState = .saving; saveTask?.cancel(); let snapshot = document
        saveTask = Task { @MainActor in try? await Task.sleep(for: .milliseconds(500)); guard !Task.isCancelled else { return }; save(snapshot) }
    }
    private func persistIfNeeded() { if resume.structuredDocumentData == nil { save(document) } }
    private func flushSave() { saveTask?.cancel(); save(document) }
    private func save(_ snapshot: ResumeDocument) { do { resume.structuredDocumentData = try snapshot.data(); resume.updatedAt = .now; try modelContext.save(); saveState = .saved } catch { saveState = .failed(error.localizedDescription) } }
    private func undo() { guard let previous = undoStack.popLast() else { return }; redoStack.append(document); document = previous; changed() }
    private func redo() { guard let next = redoStack.popLast() else { return }; undoStack.append(document); document = next; changed() }
    private func moveSection(_ id: UUID, by offset: Int) { mutate { guard let index = document.sections.firstIndex(where: { $0.id == id }), index + offset > 0, index + offset < document.sections.count else { return }; document.sections.swapAt(index, index + offset) } }
    private func toggleVisibility(_ id: UUID, in document: inout ResumeDocument) { guard let index = document.sections.firstIndex(where: { $0.id == id }), document.sections[index].kind != .header else { return }; document.sections[index].isVisible.toggle() }
    private func addSection(_ kind: ResumeSectionKind) { mutate { document.sections.append(ResumeDocumentSection(kind: kind, title: kind.title, content: defaultContent(for: kind))) } }
    private func defaultContent(for kind: ResumeSectionKind) -> ResumeSectionContent { switch kind { case .header: .contact(ContactContent()); case .summary: .summary(""); case .experience: .experience([]); case .projects: .projects([]); case .education: .education([]); case .skills: .skills([]); case .certifications: .certifications([]); case .custom: .custom(CustomContent()) } }
    private func addEntry(to id: UUID) { mutate { guard let index = document.sections.firstIndex(where: { $0.id == id }) else { return }; switch document.sections[index].content { case .experience(var value): value.append(ExperienceEntry()); document.sections[index].content = .experience(value); case .projects(var value): value.append(ProjectEntry()); document.sections[index].content = .projects(value); case .education(var value): value.append(EducationEntry()); document.sections[index].content = .education(value); case .skills(var value): value.append(SkillCategory()); document.sections[index].content = .skills(value); case .certifications(var value): value.append(CertificationEntry()); document.sections[index].content = .certifications(value); case .custom(var value): value.paragraphs.append(""); document.sections[index].content = .custom(value); default: break } } }
    private func export(pdf: Bool) {
        let service = ResumeExportService()
        shareItems = pdf ? [ResumeDocumentRenderer().pdfData(for: document)] : [(try? service.rtfData(for: resume)) as Any].compactMap { $0 }
        showShare = !shareItems.isEmpty
    }
    private func createImportedCopy(_ imported: ResumeDocument) {
        guard let data = try? imported.data() else { return }
        let copy = Resume(name: "\(resume.name) — LaTeX import", jobTarget: resume.jobTarget, workExperienceIDs: resume.linkedWorkExperienceIDs, structuredDocumentData: data)
        modelContext.insert(copy); try? modelContext.save()
    }
}

struct ResumeSectionForm: View {
    @Binding var section: ResumeDocumentSection
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onAdd: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Button("Move up", action: onMoveUp); Button("Move down", action: onMoveDown) }
            switch section.content {
            case .contact: ContactForm(content: contactBinding)
            case .summary: TextEditor(text: summaryBinding).frame(minHeight: 100).overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.2)))
            case .experience: experience
            case .projects: projects
            case .education: education
            case .skills: skills
            case .certifications: certifications
            case .custom: custom
            }
        }.padding(.vertical, 4)
    }
    private var contactBinding: Binding<ContactContent> { Binding(get: { if case .contact(let value) = section.content { return value }; return ContactContent() }, set: { section.content = .contact($0) }) }
    private var summaryBinding: Binding<String> { Binding(get: { if case .summary(let value) = section.content { return value }; return "" }, set: { section.content = .summary($0) }) }
    private var experience: some View { Group { if case .experience(let entries) = section.content { ForEach(entries.indices, id: \.self) { index in ExperienceEntryForm(entry: experienceBinding(index)); HStack { Button("Move up") { moveEntry(index, by: -1) }.disabled(index == 0); Button("Move down") { moveEntry(index, by: 1) }.disabled(index == entries.count - 1); Button("Delete", role: .destructive) { deleteEntry(index) } } }; Button("Add experience", action: onAdd) } } }
    private var projects: some View { Group { if case .projects(let entries) = section.content { ForEach(entries.indices, id: \.self) { index in ProjectEntryForm(entry: projectBinding(index)); HStack { Button("Move up") { moveEntry(index, by: -1) }; Button("Move down") { moveEntry(index, by: 1) }; Button("Delete", role: .destructive) { deleteEntry(index) } } }; Button("Add project", action: onAdd) } } }
    private var education: some View { Group { if case .education(let entries) = section.content { ForEach(entries.indices, id: \.self) { index in EducationEntryForm(entry: educationBinding(index)); Button("Delete", role: .destructive) { deleteEntry(index) } }; Button("Add education", action: onAdd) } } }
    private var skills: some View { Group { if case .skills(let entries) = section.content { ForEach(entries.indices, id: \.self) { index in SkillCategoryForm(category: skillBinding(index)); Button("Delete", role: .destructive) { deleteEntry(index) } }; Button("Add category", action: onAdd) } } }
    private var certifications: some View { Group { if case .certifications(let entries) = section.content { ForEach(entries.indices, id: \.self) { index in CertificationEntryForm(entry: certificationBinding(index)); Button("Delete", role: .destructive) { deleteEntry(index) } }; Button("Add certification", action: onAdd) } } }
    private var custom: some View { Group { if case .custom(let value) = section.content { ForEach(value.paragraphs.indices, id: \.self) { index in TextEditor(text: customParagraphBinding(index)).frame(minHeight: 70) }; ForEach(value.bullets.indices, id: \.self) { index in HStack { TextField("Bullet", text: customBulletBinding(index)); Button("Delete", role: .destructive) { var copy = value; copy.bullets.remove(at: index); section.content = .custom(copy) } } }; Button("Add paragraph") { var copy = value; copy.paragraphs.append(""); section.content = .custom(copy) }; Button("Add bullet") { var copy = value; copy.bullets.append(ResumeBullet()); section.content = .custom(copy) } } } }
    private func experienceBinding(_ index: Int) -> Binding<ExperienceEntry> { Binding(get: { if case .experience(let value) = section.content { return value[index] }; return ExperienceEntry() }, set: { if case .experience(var value) = section.content { value[index] = $0; section.content = .experience(value) } }) }
    private func projectBinding(_ index: Int) -> Binding<ProjectEntry> { Binding(get: { if case .projects(let value) = section.content { return value[index] }; return ProjectEntry() }, set: { if case .projects(var value) = section.content { value[index] = $0; section.content = .projects(value) } }) }
    private func educationBinding(_ index: Int) -> Binding<EducationEntry> { Binding(get: { if case .education(let value) = section.content { return value[index] }; return EducationEntry() }, set: { if case .education(var value) = section.content { value[index] = $0; section.content = .education(value) } }) }
    private func skillBinding(_ index: Int) -> Binding<SkillCategory> { Binding(get: { if case .skills(let value) = section.content { return value[index] }; return SkillCategory() }, set: { if case .skills(var value) = section.content { value[index] = $0; section.content = .skills(value) } }) }
    private func certificationBinding(_ index: Int) -> Binding<CertificationEntry> { Binding(get: { if case .certifications(let value) = section.content { return value[index] }; return CertificationEntry() }, set: { if case .certifications(var value) = section.content { value[index] = $0; section.content = .certifications(value) } }) }
    private func customParagraphBinding(_ index: Int) -> Binding<String> { Binding(get: { if case .custom(let value) = section.content { return value.paragraphs[index] }; return "" }, set: { if case .custom(var value) = section.content { value.paragraphs[index] = $0; section.content = .custom(value) } }) }
    private func customBulletBinding(_ index: Int) -> Binding<String> { Binding(get: { if case .custom(let value) = section.content { return value.bullets[index].text }; return "" }, set: { if case .custom(var value) = section.content { value.bullets[index].text = $0; section.content = .custom(value) } }) }
    private func moveEntry(_ index: Int, by offset: Int) { switch section.content { case .experience(var value): guard index + offset >= 0, index + offset < value.count else { return }; value.swapAt(index, index + offset); section.content = .experience(value); case .projects(var value): guard index + offset >= 0, index + offset < value.count else { return }; value.swapAt(index, index + offset); section.content = .projects(value); default: break } }
    private func deleteEntry(_ index: Int) { switch section.content { case .experience(var value): value.remove(at: index); section.content = .experience(value); case .projects(var value): value.remove(at: index); section.content = .projects(value); case .education(var value): value.remove(at: index); section.content = .education(value); case .skills(var value): value.remove(at: index); section.content = .skills(value); case .certifications(var value): value.remove(at: index); section.content = .certifications(value); default: break } }
}

struct ContactForm: View { @Binding var content: ContactContent; var body: some View { VStack { TextField("Name", text: $content.name); TextField("Email", text: $content.email); TextField("Phone", text: $content.phone); TextField("Location", text: $content.location); ForEach(content.links.indices, id: \.self) { index in HStack { TextField("Label", text: $content.links[index].label); TextField("URL", text: $content.links[index].url); Button("Delete", role: .destructive) { content.links.remove(at: index) } } }; Button("Add link") { content.links.append(LabeledLink()) } } } }
struct ExperienceEntryForm: View { @Binding var entry: ExperienceEntry; var body: some View { VStack(alignment: .leading) { TextField("Role", text: $entry.role); TextField("Employer", text: $entry.employer); TextField("Location", text: $entry.location); TextField("Dates", text: $entry.dates); ForEach(entry.bullets.indices, id: \.self) { index in HStack { TextField("Achievement", text: $entry.bullets[index].text); Button("Delete", role: .destructive) { entry.bullets.remove(at: index) } } }; Button("Add achievement") { entry.bullets.append(ResumeBullet()) } } } }
struct ProjectEntryForm: View { @Binding var entry: ProjectEntry; var body: some View { VStack { TextField("Name", text: $entry.name); TextField("Description", text: $entry.description); TextField("Technologies", text: $entry.technologies); TextField("Link", text: $entry.link); ForEach(entry.bullets.indices, id: \.self) { index in HStack { TextField("Achievement", text: $entry.bullets[index].text); Button("Delete", role: .destructive) { entry.bullets.remove(at: index) } } }; Button("Add achievement") { entry.bullets.append(ResumeBullet()) } } } }
struct EducationEntryForm: View { @Binding var entry: EducationEntry; var body: some View { VStack { TextField("Institution", text: $entry.institution); TextField("Qualification", text: $entry.qualification); TextField("Location", text: $entry.location); TextField("Dates", text: $entry.dates); TextField("Honors", text: $entry.honors) } } }
struct SkillCategoryForm: View { @Binding var category: SkillCategory; var body: some View { VStack { TextField("Category", text: $category.name); TextField("Skills, comma separated", text: Binding(get: { category.items.joined(separator: ", ") }, set: { category.items = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } })) } } }
struct CertificationEntryForm: View { @Binding var entry: CertificationEntry; var body: some View { VStack { TextField("Name", text: $entry.name); TextField("Issuer", text: $entry.issuer); TextField("Date", text: $entry.date); TextField("Credential link", text: $entry.credentialLink) } } }

struct LaTeXImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var source = ""
    @State private var result: ResumeLaTeXImporter.Result?
    let accept: (ResumeDocument) -> Void
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $source).font(.system(.body, design: .monospaced)).padding(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.25))).onChange(of: source) { _, value in result = ResumeLaTeXImporter.convert(value) }
                if let result { ScrollView { VStack(alignment: .leading) { if !result.unsupportedCommands.isEmpty { Text("Unsupported commands retained for review: \(result.unsupportedCommands.joined(separator: ", "))").foregroundStyle(.orange) }; Text(result.text).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }.padding() } }
                Spacer()
            }.padding().navigationTitle("Import LaTeX text").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Create copy") { let converted = result ?? ResumeLaTeXImporter.convert(source); var document = ResumeDocumentConverter.document(from: converted.text); document.originalSource = source; document.conversionNotes = converted.unsupportedCommands.isEmpty ? [] : ["Unsupported commands are preserved in Original source for review: \(converted.unsupportedCommands.joined(separator: ", "))"]; accept(document); dismiss() }.disabled(source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
        }
    }
}
