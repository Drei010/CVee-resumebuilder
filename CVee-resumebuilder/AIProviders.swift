import Foundation
import Security
#if canImport(FoundationModels)
import FoundationModels
#endif

struct AIModelOption: Identifiable, Hashable { let id: String; let name: String }

enum AIProvider: String, CaseIterable, Identifiable {
    case apple, openAI, gemini, claude
    var id: String { rawValue }
    var name: String { switch self { case .apple: "Apple Intelligence"; case .openAI: "OpenAI"; case .gemini: "Gemini"; case .claude: "Claude" } }
    var models: [AIModelOption] {
        switch self {
        case .apple: [AIModelOption(id: "system", name: "System Model")]
        case .openAI: ["gpt-5.6-luna|GPT-5.6 Luna", "gpt-5.6-terra|GPT-5.6 Terra", "gpt-5.6-sol|GPT-5.6 Sol"].map(Self.option)
        case .gemini: ["gemini-3.5-flash-lite|Gemini 3.5 Flash-Lite", "gemini-3.6-flash|Gemini 3.6 Flash", "gemini-3.8-flash|Gemini 3.8 Flash"].map(Self.option)
        case .claude: ["claude-haiku-4-5-20251001|Claude Haiku 4.5", "claude-sonnet-5|Claude Sonnet 5", "claude-opus-5|Claude Opus 5"].map(Self.option)
        }
    }
    private static func option(_ value: String) -> AIModelOption { let parts = value.split(separator: "|", maxSplits: 1).map(String.init); return AIModelOption(id: parts[0], name: parts[1]) }
    var defaultModel: AIModelOption { models.count == 1 ? models[0] : models[1] }
    var requiresKey: Bool { self != .apple }
}

struct APIKeyStore {
    private let service = "com.drei010.CVee-resumebuilder.ai-keys"
    func key(for provider: AIProvider) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: provider.rawValue, kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    func save(_ key: String, for provider: AIProvider) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: provider.rawValue]
        let update: [String: Any] = [kSecValueData as String: Data(key.utf8), kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        if SecItemUpdate(query as CFDictionary, update as CFDictionary) == errSecItemNotFound {
            var add = query; add.merge(update) { _, new in new }; guard SecItemAdd(add as CFDictionary, nil) == errSecSuccess else { throw AIProviderError.keychain }
        }
    }
    func delete(for provider: AIProvider) { let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: provider.rawValue]; SecItemDelete(query as CFDictionary) }
    func deleteAll() { AIProvider.allCases.filter(\.requiresKey).forEach(delete(for:)) }
}

struct AIProviderSelection {
    let keyStore = APIKeyStore()
    func provider() -> AIProvider? {
        if let raw = UserDefaults.standard.string(forKey: "ai.provider"), let value = AIProvider(rawValue: raw) { return value }
        return FoundationModelsAvailability().state().description == "This device does not support Apple Intelligence generation." ? nil : .apple
    }
    func setProvider(_ provider: AIProvider?) { if let provider { UserDefaults.standard.set(provider.rawValue, forKey: "ai.provider") } else { UserDefaults.standard.removeObject(forKey: "ai.provider") } }
    func model(for provider: AIProvider) -> AIModelOption { let id = UserDefaults.standard.string(forKey: "ai.model.\(provider.rawValue)"); return provider.models.first(where: { $0.id == id }) ?? provider.defaultModel }
    func setModel(_ model: AIModelOption, for provider: AIProvider) { UserDefaults.standard.set(model.id, forKey: "ai.model.\(provider.rawValue)") }
    func hasKey(for provider: AIProvider) -> Bool { keyStore.key(for: provider) != nil }
    func clear() { setProvider(nil); AIProvider.allCases.forEach { UserDefaults.standard.removeObject(forKey: "ai.model.\($0.rawValue)") }; keyStore.deleteAll() }
}

enum AIProviderError: LocalizedError {
    case notConfigured, unavailable(String), authentication, quota, network, provider, decoding, empty, keychain
    var errorDescription: String? {
        switch self { case .notConfigured: "Choose an AI provider and add its API key in Profile → AI Provider."; case .unavailable(let message): message; case .authentication: "The saved API key was rejected. Replace it in Profile → AI Provider."; case .quota: "This provider has reached its rate or usage limit."; case .network: "The AI provider could not be reached. Check your internet connection."; case .provider: "The selected AI provider returned an error."; case .decoding: "The AI provider returned an unreadable response."; case .empty: "The AI provider returned no text."; case .keychain: "The API key could not be saved securely." }
    }
}

struct AITextGenerationService {
    let selection = AIProviderSelection()
    func generate(instructions: String, prompt: String, maxOutputTokens: Int) async throws -> String {
        guard let provider = selection.provider() else { throw AIProviderError.notConfigured }
        if provider == .apple {
            #if canImport(FoundationModels)
            if #available(iOS 26.0, *) { guard case .available = SystemLanguageModel.default.availability else { throw AIProviderError.unavailable(FoundationModelsAvailability().state().description) }; return try await LanguageModelSession(instructions: instructions).respond(to: prompt).content }
            #endif
            throw AIProviderError.unavailable(FoundationModelsAvailability().state().description)
        }
        guard let key = selection.keyStore.key(for: provider) else { throw AIProviderError.notConfigured }
        let model = selection.model(for: provider)
        var request: URLRequest
        switch provider {
        case .openAI:
            request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!); request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization"); request.httpBody = try JSONSerialization.data(withJSONObject: ["model": model.id, "instructions": instructions, "input": prompt, "max_output_tokens": maxOutputTokens])
        case .gemini:
            request = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model.id):generateContent")!); request.setValue(key, forHTTPHeaderField: "x-goog-api-key"); request.httpBody = try JSONSerialization.data(withJSONObject: ["system_instruction": ["parts": [["text": instructions]]], "contents": [["parts": [["text": prompt]]]], "generationConfig": ["maxOutputTokens": maxOutputTokens]])
        case .claude:
            request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!); request.setValue(key, forHTTPHeaderField: "x-api-key"); request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version"); request.httpBody = try JSONSerialization.data(withJSONObject: ["model": model.id, "system": instructions, "max_tokens": maxOutputTokens, "messages": [["role": "user", "content": prompt]]])
        case .apple: fatalError()
        }
        request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let (data, response) = try await URLSession.shared.data(for: request); guard let http = response as? HTTPURLResponse else { throw AIProviderError.network }; guard (200..<300).contains(http.statusCode) else { if [401, 403].contains(http.statusCode) { throw AIProviderError.authentication }; if http.statusCode == 429 { throw AIProviderError.quota }; throw AIProviderError.provider }
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]; let text: String?
            switch provider {
            case .openAI: text = (object?["output"] as? [[String: Any]])?.flatMap { ($0["content"] as? [[String: Any]]) ?? [] }.compactMap { $0["text"] as? String }.joined()
            case .gemini: text = (object?["candidates"] as? [[String: Any]])?.flatMap { (($0["content"] as? [String: Any])?["parts"] as? [[String: Any]]) ?? [] }.compactMap { $0["text"] as? String }.joined()
            case .claude: text = (object?["content"] as? [[String: Any]])?.compactMap { $0["text"] as? String }.joined()
            case .apple: text = nil
            }
            guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw AIProviderError.empty }; return text
        } catch let error as AIProviderError { throw error } catch is DecodingError { throw AIProviderError.decoding } catch { throw AIProviderError.network }
    }
}
