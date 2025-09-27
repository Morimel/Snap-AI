//
//  APIService.swift
//  SnapAI
//
//  Created by Isa Melsov on 27/9/25.
//

import Foundation
import Security

struct RegisterStartResponse: Decodable {
    let session_id: String
    let email: String?
    let ttl_seconds: Int?
    let debug_hint: String?
    let email_sent: Bool?

    private enum CodingKeys: String, CodingKey { case session_id, email, ttl_seconds, debug_hint, email_sent }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        session_id  = try c.decode(String.self, forKey: .session_id)
        email       = try? c.decode(String.self, forKey: .email)
        ttl_seconds = try? c.decode(Int.self, forKey: .ttl_seconds)
        debug_hint  = try? c.decode(String.self, forKey: .debug_hint)

        if let b = try? c.decode(Bool.self, forKey: .email_sent) {
            email_sent = b
        } else if var arr = try? c.nestedUnkeyedContainer(forKey: .email_sent) {
            email_sent = (try? arr.decode(Bool.self)) ?? nil
        } else {
            email_sent = nil
        }
    }
}



struct TokenPair: Decodable {
    let access: String
    let refresh: String
    let user: User?

    struct User: Decodable {
        let id: Int
        let email: String
    }

    enum CodingKeys: String, CodingKey {
        case access, refresh, user
        case access_token, refresh_token
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let a = try? c.decode(String.self, forKey: .access),
           let r = try? c.decode(String.self, forKey: .refresh) {
            access = a
            refresh = r
        } else {
            access = try c.decode(String.self, forKey: .access_token)
            refresh = try c.decode(String.self, forKey: .refresh_token)
        }
        user = try? c.decode(User.self, forKey: .user)
    }
}


enum APIError: Error, LocalizedError {
    case validation([String: [String]])     // {"email":["…"],"password":["…"],"otp":["…"]}
    case http(Int, String?)                 // статус + тело как строка
    case decoding(String)                   // не смогли распарсить
    case transport(Error)                   // сеть и т.п.

    var errorDescription: String? {
        switch self {
        case .validation(let map): return map.values.first?.first ?? "Validation error"
        case .http(let code, let body): return "HTTP \(code): \(body ?? "")"
        case .decoding(let msg): return "Decoding error: \(msg)"
        case .transport(let err): return err.localizedDescription
        }
    }
}

final class AuthAPI {
    static let shared = AuthAPI()

    // ⚠️ Поставь свой базовый хост; без завершающего слеша.
    private let baseURL = URL(string: "https://snapaibackend.pythonanywhere.com")!
    private let debugAPI = true
    
    private func url(_ path: String) -> URL {
            let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
            return baseURL.appendingPathComponent(trimmed)
        }

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 60
        return URLSession(configuration: cfg)
    }()

    // MARK: Endpoints

    func registerStart(email: String, password: String) async throws -> RegisterStartResponse {
        try await post("api/auth/register/start/", ["email": email, "password": password])
    }

    func resend(sessionId: String) async throws {
        struct Empty: Decodable {}
        let _: Empty = try await post("api/auth/register/resend/", ["session_id": sessionId])
    }

    func verify(sessionId: String, otp: String, password: String) async throws -> TokenPair {
        try await post("api/auth/register/verify/", ["session_id": sessionId, "otp": otp, "password": password])
    }

    // MARK: - Generic POST

    private func post<T: Decodable>(_ path: String, _ body: [String: Any]) async throws -> T {
        let url = self.url(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        if debugAPI {
            let pretty = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            print("➡️ POST \(url.absoluteString)\n\(String(data: pretty ?? Data(), encoding: .utf8) ?? "")")
        }

        do {
            // Не кладём авторизацию на публичные методы регистрации/verify
            let isAuthless = path.hasPrefix("api/auth/register/")
            if !isAuthless, let t = TokenStore.load() {
                req.addValue("Bearer \(t.access)", forHTTPHeaderField: "Authorization")
            }
            let (data, response) = try await session.data(for: req)
            let text = String(data: data, encoding: .utf8) ?? ""
            guard let http = response as? HTTPURLResponse else {
                throw APIError.decoding("Not an HTTP response")
            }

            if debugAPI {
                print("⬅️ \(http.statusCode) for \(url.lastPathComponent)\n\(text)\n")
            }

            if (200..<300).contains(http.statusCode) {
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    if debugAPI {
                        print("❗️Decoding failed for \(url.lastPathComponent): \(error)\nBody: \(text)")
                    }
                    throw APIError.decoding(text)   // ← вместо .transport
                }
            } else {
                if let dict = try? JSONDecoder().decode([String: [String]].self, from: data) {
                    throw APIError.validation(dict)
                }
                throw APIError.http(http.statusCode, text)
            }
        } catch {
            if let api = error as? APIError { throw api }
            throw APIError.transport(error)
        }
    }
}


struct AuthTokens: Codable {
    let access: String
    let refresh: String
}

enum TokenStore {
    private static let service = "com.snapai.auth"
    private static let account = "tokens"

    static func save(_ t: AuthTokens) {
        let data = try! JSONEncoder().encode(t)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        SecItemAdd(attrs as CFDictionary, nil)
    }

    static func load() -> AuthTokens? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess, let data = out as? Data else { return nil }
        return try? JSONDecoder().decode(AuthTokens.self, from: data)
    }

    static func clear() {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(q as CFDictionary)
    }
}


import GoogleSignIn
import UIKit

func signInWithGoogleAndRoute(router: OnboardingRouter) {
    guard let root = UIApplication.shared.topMostViewController() else { return }
    GIDSignIn.sharedInstance.signIn(withPresenting: root) { result, error in
        guard error == nil, let idToken = result?.user.idToken?.tokenString else { return }
        Task {
            do {
                let pair = try await AuthAPI.shared.socialToken(provider: "google", idToken: idToken)
                TokenStore.save(.init(access: pair.access, refresh: pair.refresh))
                await MainActor.run {
                    router.replace(with: [.gender])   // или первый шаг онбординга
                }
            } catch {
                print("Google exchange failed: \(error)")
            }
        }
    }
}

extension UIApplication {
    func topMostViewController(_ base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController { return topMostViewController(nav.visibleViewController) }
        if let tab = base as? UITabBarController { return topMostViewController(tab.selectedViewController) }
        if let presented = base?.presentedViewController { return topMostViewController(presented) }
        return base
    }
}

extension AuthAPI {
    func socialToken(provider: String, idToken: String, nonce: String? = nil) async throws -> TokenPair {
        var body: [String: Any] = ["provider": provider, "id_token": idToken]
        if let nonce { body["nonce"] = nonce }
        return try await post("api/auth/token/", body) // путь проверь в своём Swagger
    }
}
