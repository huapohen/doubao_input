import Foundation

struct ChatMessage {
    let role: String
    let content: String
}

enum DeepSeekError: LocalizedError {
    case missingKey
    case invalidURL
    case unauthorized
    case rateLimited
    case server(Int)
    case network(String)
    case decoding
    case empty

    var errorDescription: String? {
        switch self {
        case .missingKey: return "未配置 API Key。可在设置 → AI 服务中填写，或使用本地示例。"
        case .invalidURL: return "Base URL 无效，请检查格式。"
        case .unauthorized: return "鉴权失败（401）。请检查 API Key 是否正确。"
        case .rateLimited: return "请求过于频繁（429），请稍后重试。"
        case .server(let code): return "服务端异常（\(code)），请稍后重试。"
        case .network(let message): return "网络错误：\(message)"
        case .decoding: return "响应格式无法解析。"
        case .empty: return "服务端返回了空内容。"
        }
    }
}

/// Minimal OpenAI-compatible chat completion client. The key is read at runtime from
/// the Keychain (or a build-time env var) and is never written to logs.
struct DeepSeekClient {
    var baseURL: String
    var model: String
    var key: String
    var timeout: TimeInterval = 20

    static func configured(baseURL: String, model: String) -> DeepSeekClient? {
        guard let key = KeychainStore.effectiveKey, !key.isEmpty else { return nil }
        return DeepSeekClient(baseURL: baseURL, model: model, key: key)
    }

    func chat(system: String, user: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard var components = URLComponents(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            completion(.failure(DeepSeekError.invalidURL)); return
        }
        var path = components.path
        if path.hasSuffix("/") { path.removeLast() }
        if !path.hasSuffix("/chat/completions") {
            path += "/chat/completions"
        }
        components.path = path
        if components.scheme == nil { components.scheme = "https" }
        guard let url = components.url else {
            completion(.failure(DeepSeekError.invalidURL)); return
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ],
            "temperature": 0.7,
            "stream": false
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            completion(.failure(DeepSeekError.decoding)); return
        }
        request.httpBody = data

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(DeepSeekError.network(error.localizedDescription)))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(DeepSeekError.network("无 HTTP 响应")))
                return
            }
            switch http.statusCode {
            case 200...299:
                break
            case 401, 403:
                completion(.failure(DeepSeekError.unauthorized)); return
            case 429:
                completion(.failure(DeepSeekError.rateLimited)); return
            default:
                completion(.failure(DeepSeekError.server(http.statusCode))); return
            }
            guard let data,
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = root["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                completion(.failure(DeepSeekError.decoding)); return
            }
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                completion(.failure(DeepSeekError.empty))
            } else {
                completion(.success(trimmed))
            }
        }.resume()
    }

    func test(completion: @escaping (Result<String, Error>) -> Void) {
        chat(system: "你是连接测试助手，请只回复 OK。", user: "ping", completion: completion)
    }
}

enum AIStudioMode: String, CaseIterable, Identifiable {
    case writing
    case organize
    case translate

    var id: String { rawValue }
    var title: String {
        switch self {
        case .writing: return "AI 写作"
        case .organize: return "智能整理"
        case .translate: return "翻译"
        }
    }
}

struct AIStudioRequest {
    var mode: AIStudioMode
    var action: String
    var input: String
    var toEnglish: Bool
    var punctuation: String
    var removeFillers: Bool
}

final class AIStudioModel: ObservableObject {
    @Published var output = ""
    @Published var isLoading = false
    @Published var errorText: String?
    @Published var usedOffline = false
    @Published var lastRequest: AIStudioRequest?

    private var task: URLSessionDataTask?

    func generate(_ request: AIStudioRequest, settings: AppSettings) {
        lastRequest = request
        errorText = nil
        output = ""
        if !settings.isSmartMode {
            output = localResult(request)
            usedOffline = true
            errorText = "基础输入模式：已使用本地示例，未发送网络请求。"
            return
        }
        guard let client = DeepSeekClient.configured(baseURL: settings.aiBaseURL, model: settings.aiModel) else {
            output = localResult(request)
            usedOffline = true
            errorText = "未配置 API Key：已使用本地示例。配置位置：设置 → AI 服务。"
            return
        }
        isLoading = true
        usedOffline = false
        let prompt = Self.prompt(for: request)
        client.chat(system: prompt.0, user: prompt.1) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let text):
                    self.output = text
                case .failure(let error):
                    self.errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    self.output = self.localResult(request)
                    self.usedOffline = true
                }
            }
        }
    }

    func retry(settings: AppSettings) {
        if let request = lastRequest { generate(request, settings: settings) }
    }

    private func localResult(_ request: AIStudioRequest) -> String {
        switch request.mode {
        case .writing:
            return LocalIntelligence.actionTemplates(request.action, context: request.input)
        case .organize:
            return LocalIntelligence.organize(request.input, removeFillers: request.removeFillers, blankLineParagraphs: false, punctuation: request.punctuation)
        case .translate:
            return LocalIntelligence.translate(request.input, toEnglish: request.toEnglish)
        }
    }

    private static func prompt(for request: AIStudioRequest) -> (String, String) {
        switch request.mode {
        case .writing:
            let system = "你是一个中文写作助手。直接输出成稿，不要解释过程。语言自然、具体、避免空话。场景：\(request.action)。"
            let input = request.input.isEmpty ? "请写一段适合该场景的内容。" : "参考信息：\(request.input)"
            return (system, input)
        case .organize:
            let system = "你是中文文字整理助手。去掉口水词和重复表达，补齐标点，保留原意，只输出整理后的文本。标点风格：\(request.punctuation)。"
            return (system, request.input)
        case .translate:
            let system = request.toEnglish ? "你是专业中英翻译。将用户的中文翻译成自然、准确的英文，只输出译文。" : "你是专业英中翻译。将用户的英文翻译成自然、准确的中文，只输出译文。"
            return (system, request.input)
        }
    }
}
