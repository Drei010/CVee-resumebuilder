import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let titleField = UITextField()
    private let preview = UITextView()
    private let saveButton = UIButton(type: .system)
    private let status = UILabel()
    private var items: [SharedItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Save to CVee"
        titleField.placeholder = "Optional title"
        titleField.borderStyle = .roundedRect
        preview.isEditable = false
        preview.layer.borderWidth = 1
        preview.layer.borderColor = UIColor.separator.cgColor
        preview.layer.cornerRadius = 8
        preview.font = .preferredFont(forTextStyle: .body)
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        status.numberOfLines = 0
        status.textColor = .secondaryLabel
        let stack = UIStackView(arrangedSubviews: [titleField, preview, status, saveButton])
        stack.axis = .vertical; stack.spacing = 12; stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            preview.heightAnchor.constraint(greaterThanOrEqualToConstant: 180)
        ])
        loadSharedItems()
    }

    private func loadSharedItems() {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? []).flatMap { $0.attachments ?? [] }
        guard !providers.isEmpty else { status.text = "Nothing was shared."; return }
        let group = DispatchGroup()
        let lock = NSLock()
        for provider in providers {
            group.enter()
            load(provider) { item in lock.lock(); if let item { self.items.append(item) }; lock.unlock(); group.leave() }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.preview.text = self.items.map { $0.text ?? $0.url ?? $0.filename }.joined(separator: "\n\n")
            self.status.text = self.items.contains(where: { !$0.attachments.isEmpty }) ? "Attachment ready. Saved locally before this extension closes." : "Ready to save to the CVee inbox."
        }
    }

    private func load(_ provider: NSItemProvider, completion: @escaping (SharedItem?) -> Void) {
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.plainText.identifier) { data, _ in completion(data.flatMap { String(data: $0, encoding: .utf8) }.map { SharedItem(text: $0) }) }; return
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            provider.loadObject(ofClass: NSURL.self) { object, _ in completion((object as? NSURL).flatMap { $0.absoluteString }.map { SharedItem(url: $0) }) }; return
        }
        let type = provider.registeredTypeIdentifiers.first(where: { typeIdentifier in
            guard let type = UTType(typeIdentifier) else { return false }
            return type.conforms(to: .pdf) || type.conforms(to: .image) || type == .data
        })
        guard let type else { completion(nil); return }
        provider.loadDataRepresentation(forTypeIdentifier: type) { data, _ in
            guard let data else { completion(nil); return }
            let filename = provider.suggestedName ?? "shared-attachment"
            completion(SharedItem(filename: filename, contentType: type, data: data))
        }
    }

    @objc private func save() {
        saveButton.isEnabled = false
        do {
            try ShareInboxWriter().save(items: items, title: titleField.text)
            status.text = "Saved to CVee inbox."
            extensionContext?.completeRequest(returningItems: nil)
        } catch {
            saveButton.isEnabled = true
            status.text = "Could not save. Try again."
        }
    }
}

private struct SharedItem {
    var text: String?
    var url: String?
    var filename: String = ""
    var contentType: String = ""
    var data: Data?
    var attachments: [SharedItem] { data == nil ? [] : [self] }
    init(text: String) { self.text = text; url = nil; data = nil }
    init(url: String) { text = nil; self.url = url; data = nil }
    init(filename: String, contentType: String, data: Data) { text = nil; url = nil; self.filename = filename; self.contentType = contentType; self.data = data }
}

private struct ShareInboxWriter {
    private let fileManager = FileManager.default
    private let groupID = "group.com.drei010.CVee-resumebuilder"

    func save(items: [SharedItem], title: String?) throws {
        guard !items.isEmpty else { throw CocoaError(.fileNoSuchFile) }
        let id = UUID()
        let root = (fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupID) ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("CVee"))
            .appendingPathComponent("JobCapture/Inbox", isDirectory: true)
        let staging = root.appendingPathComponent(".staging-\(id.uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: staging) }
        let text = items.compactMap(\.text).joined(separator: "\n\n")
        let sourceURL = items.compactMap(\.url).first
        var attachments: [[String: String]] = []
        var attachmentBytes = 0
        for item in items.flatMap(\.attachments) {
            guard let data = item.data else { throw CocoaError(.fileNoSuchFile) }
            attachmentBytes += data.count
            guard attachmentBytes <= 10_000_000 else { throw CocoaError(.fileWriteOutOfSpace) }
            let filename = item.filename.replacingOccurrences(of: "/", with: "-")
            try data.write(to: staging.appendingPathComponent(filename), options: .atomic)
            attachments.append(["filename": item.filename, "relativePath": filename, "contentType": item.contentType])
        }
        var object: [String: Any] = ["version": 1, "id": id.uuidString, "createdAt": Date.now.timeIntervalSinceReferenceDate, "text": text, "attachments": attachments]
        if let sourceURL { object["sourceURL"] = sourceURL }
        if let title, !title.isEmpty { object["title"] = title }
        let json = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try json.write(to: staging.appendingPathComponent("package.json"), options: .atomic)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        try fileManager.moveItem(at: staging, to: root.appendingPathComponent(id.uuidString, isDirectory: true))
    }
}
