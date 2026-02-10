import Foundation

enum LLMError: Error, LocalizedError, Equatable {
    case invalidURL
    case connectionFailed(String)
    case requestFailed(Int)
    case noData
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL. Check your settings."
        case .connectionFailed(let detail):
            return "Cannot connect to LLM server: \(detail)"
        case .requestFailed(let code):
            return "LLM server returned HTTP \(code)."
        case .noData:
            return "No response from LLM server."
        case .decodingFailed(let detail):
            return "Failed to parse LLM server response: \(detail)"
        }
    }
}

final class LLMService {
    static let shared = LLMService()

    let session: URLSession
    let settingsProvider: () -> (serverURL: String, modelName: String)

    init(session: URLSession, settingsProvider: @escaping () -> (serverURL: String, modelName: String)) {
        self.session = session
        self.settingsProvider = settingsProvider
    }

    private convenience init() {
        self.init(session: .shared, settingsProvider: {
            let s = Settings.shared
            return (s.serverURL, s.modelName)
        })
    }

    func generate(prompt: String, completion: @escaping (Result<String, LLMError>) -> Void) {
        let settings = settingsProvider()
        guard let url = URL(string: "\(settings.serverURL)/v1/chat/completions") else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let body: [String: Any] = [
            "model": settings.modelName,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "stream": false
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(.decodingFailed(error.localizedDescription)))
            return
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.connectionFailed(error.localizedDescription)))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(.failure(.requestFailed(httpResponse.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let message = first["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                completion(.failure(.noData))
                return
            }

            completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        task.resume()
    }

    func fetchModels(completion: @escaping ([String]) -> Void) {
        let settings = settingsProvider()
        guard let url = URL(string: "\(settings.serverURL)/v1/models") else {
            completion([])
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        session.dataTask(with: request) { data, response, _ in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let models = json["data"] as? [[String: Any]] else {
                completion([])
                return
            }
            let names = models.compactMap { $0["id"] as? String }.sorted()
            completion(names)
        }.resume()
    }
}
