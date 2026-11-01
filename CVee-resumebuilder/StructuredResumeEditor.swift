import SwiftUI
import SwiftData
import PDFKit

enum ResumeSaveState: Equatable { case saved, saving, failed(String) }

struct StructuredResumeEditorView: View {
    @Bindable var resume: Resume
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var document: ResumeDocument
    @State private var mode = Mode.content
    @State private var previewPDFData = Data()
    @State private var pageCount = 0
    @State private var saveState: ResumeSaveState = .saved
    @State private var saveTask: Task<Void, Never>?
    @State private var undoStack: [ResumeDocument] = []
    @State private var redoStack: [ResumeDocument] = []
    /// Edits until the next autosave share one undo step, so Undo takes back a typed burst, not one letter.
    @State private var coalescingEdits = false
    @State private var pendingDelete: ResumeDocumentSection?
    @State private var showingImport = false
    @State private var showingExport = false
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
        .frame(maxWidth: 760).frame(maxWidth: .infinity)
        .background(CVeeColors.page)
        .navigationTitle(resume.name).navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .task { persistIfNeeded() }
        .task(id: document) {
            // Typing changes the document on every key, so redraw once the edits pause.
            if mode == .content && !previewPDFData.isEmpty { try? await Task.sleep(for: .milliseconds(500)) }
            guard !Task.isCancelled else { return }
            previewPDFData = ResumeDocumentRenderer().pdfData(for: document)
            pageCount = PDFDocument(data: previewPDFData)?.pageCount ?? 0
        }
        .onChange(of: scenePhase) { _, phase in if phase == .background { flushSave() } }
        .onDisappear { flushSave() }
        .onChange(of: saveState) { _, state in
            if case .failed(let message) = state { UIAccessibility.post(notification: .announcement, argument: "Couldn’t save. \(message)") }
        }
        .confirmationDialog("Delete section?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })) {
            if let section = pendingDelete { Button("Delete \(section.title)", role: .destructive) { mutate { document.sections.removeAll { $0.id == section.id } }; pendingDelete = nil } }
        } message: { Text("Undo restores the deleted section during this editing session.") }
        .confirmationDialog("Export resume", isPresented: $showingExport) {
            Button("Export PDF") { export(pdf: true) }.accessibilityIdentifier("resume.export-pdf")
            Button("Export RTF") { export(pdf: false) }.accessibilityIdentifier("resume.export-rtf")
        }
        .sheet(isPresented: $showShare) { ShareSheet(items: shareItems) }
        .sheet(isPresented: $showingImport) { LaTeXImportSheet { imported in createImportedCopy(imported) } }
    }

    private var content: some View {
        List {
            Section {
                LabeledContent("Document name") { TextField("Document name", text: Binding(get: { resume.name }, set: { resume.name = $0; changed() })) }
                Button("Export resume", systemImage: "square.and.arrow.up") { showingExport = true }
                    .accessibilityIdentifier("resume.export")
                Button("Import LaTeX text", systemImage: "doc.text") { showingImport = true }
                    .accessibilityIdentifier("resume.import-latex")
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
        }.listStyle(.insetGrouped).modifier(WorkspaceSurface())
    }

    private func sectionRow(_ section: ResumeDocumentSection) -> some View {
        DisclosureGroup {
            ResumeSectionForm(section: sectionBinding(section.id), onMoveUp: { moveSection(section.id, by: -1) }, onMoveDown: { moveSection(section.id, by: 1) }, onAdd: { addEntry(to: section.id) })
        } label: {
            HStack {
                Image(systemName: section.isVisible ? "eye" : "eye.slash").foregroundStyle(.secondary)
                Text(section.title).font(.headline)
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
                ResumePagePreview(pdfData: previewPDFData)
                    .accessibilityIdentifier("resume.structured-preview")
                    .accessibilityValue(PDFDocument(data: previewPDFData)?.string ?? "")
            }.padding()
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Hide keyboard") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Undo") { undo() }.disabled(undoStack.isEmpty).accessibilityIdentifier("resume.undo")
            Button("Redo") { redo() }.disabled(redoStack.isEmpty).accessibilityIdentifier("resume.redo")
        }
    }

    private var saveStateText: String { switch saveState { case .saved: "Saved"; case .saving: "Saving"; case .failed: "Couldn't save — Retry" } }
    private func sectionBinding(_ id: UUID) -> Binding<ResumeDocumentSection> {
        Binding(get: { document.sections.first(where: { $0.id == id }) ?? ResumeDocumentSection(kind: .custom, title: "Section", content: .custom(CustomContent())) }, set: { value in mutate { if let index = document.sections.firstIndex(where: { $0.id == id }) { document.sections[index] = value } } })
    }
    private func sectionTitleBinding(_ id: UUID) -> Binding<String> { Binding(get: { document.sections.first(where: { $0.id == id })?.title ?? "" }, set: { value in mutate { if let index = document.sections.firstIndex(where: { $0.id == id }) { document.sections[index].title = value } } }) }
    private func mutate(_ change: () -> Void) { if !coalescingEdits { undoStack.append(document); coalescingEdits = true }; redoStack.removeAll(); change(); changed() }
    private func changed() {
        saveState = .saving; saveTask?.cancel(); let snapshot = document
        saveTask = Task { @MainActor in try? await Task.sleep(for: .milliseconds(500)); guard !Task.isCancelled else { return }; save(snapshot) }
    }
    private func persistIfNeeded() { if resume.structuredDocumentData == nil { save(document) } }
    private func flushSave() { saveTask?.cancel(); save(document) }
    private func save(_ snapshot: ResumeDocument) { coalescingEdits = false; do { resume.structuredDocumentData = try snapshot.data(); resume.updatedAt = .now; try modelContext.save(); saveState = .saved } catch { saveState = .failed(error.localizedDescription) } }
    private func undo() { guard let previous = undoStack.popLast() else { return }; redoStack.append(document); document = previous; coalescingEdits = false; changed() }
    private func redo() { guard let next = redoStack.popLast() else { return }; undoStack.append(document); document = next; coalescingEdits = false; changed() }
    private func moveSection(_ id: UUID, by offset: Int) { mutate { guard let index = document.sections.firstIndex(where: { $0.id == id }), index + offset > 0, index + offset < document.sections.count else { return }; document.sections.swapAt(index, index + offset) } }
    private func toggleVisibility(_ id: UUID, in document: inout ResumeDocument) { guard let index = document.sections.firstIndex(where: { $0.id == id }), document.sections[index].kind != .header else { return }; document.sections[index].isVisible.toggle() }
    private func addSection(_ kind: ResumeSectionKind) { mutate { document.sections.append(ResumeDocumentSection(kind: kind, title: kind.title, content: defaultContent(for: kind))) } }
    private func defaultContent(for kind: ResumeSectionKind) -> ResumeSectionContent { switch kind { case .header: .contact(ContactContent()); case .summary: .summary(""); case .experience: .experience([]); case .projects: .projects([]); case .education: .education([]); case .skills: .skills([]); case .certifications: .certifications([]); case .custom: .custom(CustomContent()) } }
    private func addEntry(to id: UUID) { mutate { guard let index = document.sections.firstIndex(where: { $0.id == id }) else { return }; switch document.sections[index].content { case .experience(var value): value.append(ExperienceEntry()); document.sections[index].content = .experience(value); case .projects(var value): value.append(ProjectEntry()); document.sections[index].content = .projects(value); case .education(var value): value.append(EducationEntry()); document.sections[index].content = .education(value); case .skills(var value): value.append(SkillCategory()); document.sections[index].content = .skills(value); case .certifications(var value): value.append(CertificationEntry()); document.sections[index].content = .certifications(value); case .custom(var value): value.paragraphs.append(""); document.sections[index].content = .custom(value); default: break } } }
    private func export(pdf: Bool) {
        flushSave()
        guard saveState == .saved else { return }
        do {
            shareItems = pdf ? [ResumeDocumentRenderer().pdfData(for: document)] : [try ResumeExportService().rtfData(for: resume)]
            showShare = !shareItems.isEmpty
        } catch { saveState = .failed(error.localizedDescription) }
    }
    private func createImportedCopy(_ imported: ResumeDocument) {
        var copy: Resume?
        do {
            let data = try imported.data()
            let importedResume = Resume(name: "\(resume.name) — LaTeX import", jobTarget: resume.jobTarget, workExperienceIDs: resume.linkedWorkExperienceIDs, structuredDocumentData: data)
            copy = importedResume
            modelContext.insert(importedResume)
            try modelContext.save()
        } catch {
            if let copy { modelContext.delete(copy) }
            saveState = .failed(error.localizedDescription)
        }
    }
}

struct ResumeSectionForm: View {
    @Binding var section: ResumeDocumentSection
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onAdd: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading) { Button("Move up", action: onMoveUp); Button("Move down", action: onMoveDown) }
            LabeledContent("Section title") { TextField("Section title", text: $section.title) }
            switch section.content {
            case .contact: ContactForm(content: contactBinding)
            case .summary: Text("Summary").font(.caption).foregroundStyle(CVeeColors.secondary); TextEditor(text: summaryBinding).accessibilityLabel("Resume summary").frame(minHeight: 100).overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.2)))
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
    private var experience: some View { Group { if case .experience(let entries) = section.content { ForEach(entries) { entry in ExperienceEntryForm(entry: experienceEntries.element(entry.id, or: entry)); VStack(alignment: .leading) { Button("Move up") { move(entry.id, by: -1, in: experienceEntries) }.disabled(entry.id == entries.first?.id); Button("Move down") { move(entry.id, by: 1, in: experienceEntries) }.disabled(entry.id == entries.last?.id); Button("Delete", role: .destructive) { experienceEntries.wrappedValue.removeAll { $0.id == entry.id } } } }; Button("Add experience", action: onAdd) } } }
    private var projects: some View { Group { if case .projects(let entries) = section.content { ForEach(entries) { entry in ProjectEntryForm(entry: projectEntries.element(entry.id, or: entry)); VStack(alignment: .leading) { Button("Move up") { move(entry.id, by: -1, in: projectEntries) }; Button("Move down") { move(entry.id, by: 1, in: projectEntries) }; Button("Delete", role: .destructive) { projectEntries.wrappedValue.removeAll { $0.id == entry.id } } } }; Button("Add project", action: onAdd) } } }
    private var education: some View { Group { if case .education(let entries) = section.content { ForEach(entries) { entry in EducationEntryForm(entry: educationEntries.element(entry.id, or: entry)); Button("Delete", role: .destructive) { educationEntries.wrappedValue.removeAll { $0.id == entry.id } } }; Button("Add education", action: onAdd) } } }
    private var skills: some View { Group { if case .skills(let entries) = section.content { ForEach(entries) { entry in SkillCategoryForm(category: skillCategories.element(entry.id, or: entry)); Button("Delete", role: .destructive) { skillCategories.wrappedValue.removeAll { $0.id == entry.id } } }; Button("Add category", action: onAdd) } } }
    private var certifications: some View { Group { if case .certifications(let entries) = section.content { ForEach(entries) { entry in CertificationEntryForm(entry: certificationEntries.element(entry.id, or: entry)); Button("Delete", role: .destructive) { certificationEntries.wrappedValue.removeAll { $0.id == entry.id } } }; Button("Add certification", action: onAdd) } } }
    private var custom: some View { Group { if case .custom(let value) = section.content { ForEach(value.paragraphs.indices, id: \.self) { index in Text("Paragraph \(index + 1)").font(.caption).foregroundStyle(CVeeColors.secondary); TextEditor(text: customParagraphBinding(index)).frame(minHeight: 70).accessibilityLabel("Paragraph \(index + 1)") }; ForEach(value.bullets) { bullet in HStack { ResumeTextField(label: "Achievement", text: customContent.bullets.element(bullet.id, or: bullet).text); Button("Delete", role: .destructive) { customContent.wrappedValue.bullets.removeAll { $0.id == bullet.id } } } }; Button("Add paragraph") { customContent.wrappedValue.paragraphs.append("") }; Button("Add bullet") { customContent.wrappedValue.bullets.append(ResumeBullet()) } } } }
    private var experienceEntries: Binding<[ExperienceEntry]> { Binding(get: { if case .experience(let value) = section.content { return value }; return [] }, set: { if case .experience = section.content { section.content = .experience($0) } }) }
    private var projectEntries: Binding<[ProjectEntry]> { Binding(get: { if case .projects(let value) = section.content { return value }; return [] }, set: { if case .projects = section.content { section.content = .projects($0) } }) }
    private var educationEntries: Binding<[EducationEntry]> { Binding(get: { if case .education(let value) = section.content { return value }; return [] }, set: { if case .education = section.content { section.content = .education($0) } }) }
    private var skillCategories: Binding<[SkillCategory]> { Binding(get: { if case .skills(let value) = section.content { return value }; return [] }, set: { if case .skills = section.content { section.content = .skills($0) } }) }
    private var certificationEntries: Binding<[CertificationEntry]> { Binding(get: { if case .certifications(let value) = section.content { return value }; return [] }, set: { if case .certifications = section.content { section.content = .certifications($0) } }) }
    private var customContent: Binding<CustomContent> { Binding(get: { if case .custom(let value) = section.content { return value }; return CustomContent() }, set: { if case .custom = section.content { section.content = .custom($0) } }) }
    // Paragraphs have no id; undo can shorten the list while a field still shows, so check the index.
    private func customParagraphBinding(_ index: Int) -> Binding<String> { Binding(get: { customContent.wrappedValue.paragraphs.indices.contains(index) ? customContent.wrappedValue.paragraphs[index] : "" }, set: { if customContent.wrappedValue.paragraphs.indices.contains(index) { customContent.wrappedValue.paragraphs[index] = $0 } }) }
    private func move<Item: Identifiable>(_ id: Item.ID, by offset: Int, in items: Binding<[Item]>) { guard let index = items.wrappedValue.firstIndex(where: { $0.id == id }), items.wrappedValue.indices.contains(index + offset) else { return }; items.wrappedValue.swapAt(index, index + offset) }
}

extension Binding {
    /// The item with this id, found again on every read and write, so a row SwiftUI reads once more after its item is deleted gets the fallback instead of an out-of-range index.
    func element<Item: Identifiable>(_ id: Item.ID, or fallback: Item) -> Binding<Item> where Value == [Item] {
        Binding<Item>(get: { wrappedValue.first { $0.id == id } ?? fallback }, set: { item in if let index = wrappedValue.firstIndex(where: { $0.id == id }) { wrappedValue[index] = item } })
    }
}

private struct ResumeTextField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(CVeeColors.secondary)
            TextField(label, text: $text, axis: .vertical)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress || keyboard == .URL ? .never : .sentences)
                .autocorrectionDisabled(keyboard == .emailAddress || keyboard == .URL)
                .lineLimit(1...6)
        }
    }
}

struct ContactForm: View { @Binding var content: ContactContent; var body: some View { VStack { ResumeTextField(label: "Name", text: $content.name); ResumeTextField(label: "Email", text: $content.email, keyboard: .emailAddress); ResumeTextField(label: "Phone", text: $content.phone, keyboard: .phonePad); ResumeTextField(label: "Location or other contact details", text: $content.location); ForEach(content.links) { link in HStack { ResumeTextField(label: "Label", text: $content.links.element(link.id, or: link).label); ResumeTextField(label: "URL", text: $content.links.element(link.id, or: link).url, keyboard: .URL); Button("Delete", role: .destructive) { content.links.removeAll { $0.id == link.id } } } }; Button("Add link") { content.links.append(LabeledLink()) } } } }
struct ExperienceEntryForm: View { @Binding var entry: ExperienceEntry; var body: some View { VStack(alignment: .leading) { ResumeTextField(label: "Role", text: $entry.role); ResumeTextField(label: "Employer", text: $entry.employer); ResumeTextField(label: "Location", text: $entry.location); ResumeTextField(label: "Dates", text: $entry.dates); ForEach(entry.bullets) { bullet in HStack { ResumeTextField(label: "Achievement", text: $entry.bullets.element(bullet.id, or: bullet).text); Button("Delete", role: .destructive) { entry.bullets.removeAll { $0.id == bullet.id } } } }; Button("Add achievement") { entry.bullets.append(ResumeBullet()) } } } }
struct ProjectEntryForm: View { @Binding var entry: ProjectEntry; var body: some View { VStack { ResumeTextField(label: "Name", text: $entry.name); ResumeTextField(label: "Description", text: $entry.description); ResumeTextField(label: "Technologies", text: $entry.technologies); ResumeTextField(label: "Link", text: $entry.link, keyboard: .URL); ForEach(entry.bullets) { bullet in HStack { ResumeTextField(label: "Achievement", text: $entry.bullets.element(bullet.id, or: bullet).text); Button("Delete", role: .destructive) { entry.bullets.removeAll { $0.id == bullet.id } } } }; Button("Add achievement") { entry.bullets.append(ResumeBullet()) } } } }
struct EducationEntryForm: View { @Binding var entry: EducationEntry; var body: some View { VStack { ResumeTextField(label: "Institution", text: $entry.institution); ResumeTextField(label: "Qualification", text: $entry.qualification); ResumeTextField(label: "Location", text: $entry.location); ResumeTextField(label: "Dates", text: $entry.dates); ResumeTextField(label: "Honors", text: $entry.honors) } } }
struct SkillCategoryForm: View { @Binding var category: SkillCategory; var body: some View { VStack { ResumeTextField(label: "Category", text: $category.name); ResumeTextField(label: "Skills, comma separated", text: Binding(get: { category.items.joined(separator: ", ") }, set: { category.items = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } })) } } }
struct CertificationEntryForm: View { @Binding var entry: CertificationEntry; var body: some View { VStack { ResumeTextField(label: "Name", text: $entry.name); ResumeTextField(label: "Issuer", text: $entry.issuer); ResumeTextField(label: "Date", text: $entry.date); ResumeTextField(label: "Credential link", text: $entry.credentialLink, keyboard: .URL) } } }

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
