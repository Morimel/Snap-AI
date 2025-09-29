//
//  APIService.swift
//  SnapAI
//
//  Created by Isa Melsov on 27/9/25.
//

import Foundation
import Security
import AuthenticationServices
import CryptoKit
import GoogleSignIn

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
    case validation([String: [String]])     
    case http(Int, String?)
    case decoding(String)
    case transport(Error)

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
    
    private struct EmptyResponse: Decodable {}

    private let baseURL = URL(string: "https://snap-ai-app.com")!
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


    // MARK: - POST with one-time 401 retry via refresh()
    private func post<T: Decodable>(_ path: String, _ body: [String: Any]) async throws -> T {
        do {
            // 1) первая попытка — без авто-рефреша
            return try await postNoRetry(path, body)
        } catch APIError.http(let code, _) where code == 401 && !path.hasPrefix("api/auth/refresh/") {
            // 2) если access истёк — обновляем и повторяем один раз
            _ = try await refresh()
            return try await postNoRetry(path, body)
        } catch {
            throw error
        }
    }

    
    
    private func postNoRetry<T: Decodable>(_ path: String, _ body: [String: Any]) async throws -> T {
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
            let isAuthless =
                path.hasPrefix("api/auth/register/")     ||
                path.hasPrefix("api/auth/google/")   ||
                path.hasPrefix("api/auth/apple/")    ||
                path.hasPrefix("api/auth/token/")        ||
                path.hasPrefix("api/auth/refresh/")

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
                    throw APIError.decoding(text)
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
    
    private func get<T: Decodable>(_ path: String) async throws -> T {
        do {
            return try await getNoRetry(path)
        } catch APIError.http(let code, _) where code == 401 && !path.hasPrefix("api/auth/refresh/") {
            _ = try await refresh()
            return try await getNoRetry(path)
        } catch { throw error }
    }

    private func getNoRetry<T: Decodable>(_ path: String) async throws -> T {
        let url = self.url(path)
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let isAuthless =
            path.hasPrefix("api/auth/register/") ||
            path.hasPrefix("api/auth/google/") ||
            path.hasPrefix("api/auth/apple/") ||
            path.hasPrefix("api/auth/token/") ||
            path.hasPrefix("api/auth/refresh/")
        if !isAuthless, let t = TokenStore.load() {
            req.addValue("Bearer \(t.access)", forHTTPHeaderField: "Authorization")
        }

        let (data, resp) = try await session.data(for: req)
        let text = String(data: data, encoding: .utf8) ?? ""
        guard let http = resp as? HTTPURLResponse else { throw APIError.decoding("Not an HTTP response") }

        if debugAPI {
            if let obj = try? JSONSerialization.jsonObject(with: data),
               let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
               let str = String(data: pretty, encoding: .utf8) {
                print("⬅️ \(http.statusCode) for \(url.lastPathComponent)\n\(str)\n")
            } else {
                print("⬅️ \(http.statusCode) for \(url.lastPathComponent)\n\(text)\n")
            }
        }
        
        if (200..<300).contains(http.statusCode) {
            do { return try JSONDecoder().decode(T.self, from: data) }
            catch { throw APIError.decoding(text) }
        } else {
            if let dict = try? JSONDecoder().decode([String: [String]].self, from: data) {
                throw APIError.validation(dict)
            }
            throw APIError.http(http.statusCode, text)
        }
    }
    
    
    
    //MARK: - sendJSON
    private func sendJSON<T: Decodable>(
        _ method: String,
        _ path: String,
        _ body: [String: Any]
    ) async throws -> T {
        do {
            return try await sendJSONNoRetry(method, path, body)
        } catch APIError.http(let code, _) where code == 401 && !path.hasPrefix("api/auth/refresh/") {
            _ = try await refresh()
            return try await sendJSONNoRetry(method, path, body)
        } catch {
            throw error
        }
    }

    private func sendJSONNoRetry<T: Decodable>(
        _ method: String,
        _ path: String,
        _ body: [String: Any]
    ) async throws -> T {
        let url = self.url(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let isAuthless =
            path.hasPrefix("api/auth/register/") ||
            path.hasPrefix("api/auth/google/")   ||
            path.hasPrefix("api/auth/apple/")    ||
            path.hasPrefix("api/auth/token/")    ||
            path.hasPrefix("api/auth/refresh/")
        if !isAuthless, let t = TokenStore.load() {
            req.addValue("Bearer \(t.access)", forHTTPHeaderField: "Authorization")
        }

        if debugAPI {
            let pretty = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            print("➡️ \(method) \(url.absoluteString)\n\(String(data: pretty ?? Data(), encoding: .utf8) ?? "")")
        }

        let (data, resp) = try await session.data(for: req)
        let text = String(data: data, encoding: .utf8) ?? ""
        guard let http = resp as? HTTPURLResponse else { throw APIError.decoding("Not an HTTP response") }

        if debugAPI { print("⬅️ \(http.statusCode) for \(url.lastPathComponent)\n\(text)\n") }

        if (200..<300).contains(http.statusCode) {
            do { return try JSONDecoder().decode(T.self, from: data) }
            catch { throw APIError.decoding(text) }
        } else {
            if let dict = try? JSONDecoder().decode([String: [String]].self, from: data) {
                throw APIError.validation(dict)
            }
            throw APIError.http(http.statusCode, text)
        }
    }


}

struct Profile: Decodable {
    struct User: Decodable { let id: Int; let email: String }
    
    let id: Int
    let user: User
    let gender: String?
    let date_of_birth: String?
    let units: String?
    let height_cm: Int?
    let weight_kg: Int?
    let activity: String?
    let goal: String?
    let desired_weight_kg: Int?
    let allergies: String?
    let has_premium: Bool?
    let trial_ends_at: String?
    let created_at: String?
    let updated_at: String?
}


extension Encodable {
    func prettyJSON() -> String {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? enc.encode(self),
           let str  = String(data: data, encoding: .utf8) {
            return str
        }
        return String(describing: self)
    }
}


extension AuthAPI {
    func getProfile(id: Int) async throws -> Profile {
        try await get("api/profile/\(id)/")
    }

    func patchProfile(id: Int, fields: [String: Any]) async throws {
        struct Empty: Decodable {}
        let _: Empty = try await sendJSON("PATCH", "api/profile/\(id)/", fields)
        await MainActor.run {
            NotificationCenter.default.post(name: .profileDidChange, object: nil)
        }
    }
}


struct AuthTokens: Codable {
    let access: String
    let refresh: String
}

//MARK: - TokenStore
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

//MARK: - UserStore
enum UserStore {
    private static let idKey = "auth.user.id"
    private static let emailKey = "auth.user.email"
    private static let profileIdKey = "auth.profile.id"
    
    static func save(id: Int?, email: String?) {
        if let id { UserDefaults.standard.set(id, forKey: idKey) }
        if let email { UserDefaults.standard.set(email, forKey: emailKey) }
    }
    static func id() -> Int? { UserDefaults.standard.object(forKey: idKey) as? Int }
    static func email() -> String? { UserDefaults.standard.string(forKey: emailKey) }
    
    static func saveProfileId(_ id: Int?) { if let id { UserDefaults.standard.set(id, forKey: profileIdKey) } }
        static func profileId() -> Int? { UserDefaults.standard.object(forKey: profileIdKey) as? Int }
}

enum JWTTools {
    static func payload(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var base = parts[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base.count % 4 != 0 { base.append("=") }
        guard let data = Data(base64Encoded: base),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return obj
    }

    static func userId(from token: String) -> Int? {
        guard let p = payload(token) else { return nil }

        if let id = p["user_id"] as? Int { return id }
        if let s = p["user_id"] as? String, let id = Int(s) { return id }

        if let id = p["id"] as? Int { return id }
        if let s = p["id"] as? String, let id = Int(s) { return id }
        if let s = p["sub"] as? String, let id = Int(s) { return id }

        return nil
    }

    static func email(from token: String) -> String? {
        guard let p = payload(token) else { return nil }
        return (p["email"] as? String)
            ?? (p["preferred_username"] as? String)
            ?? (p["upn"] as? String)
    }
}



enum CurrentUser {
    static func ensureIdFromJWTIfNeeded() {
        guard UserStore.id() == nil, let access = TokenStore.load()?.access else { return }

        if let pl = JWTTools.payload(access) {
            print("🔐 JWT payload:", pl)
        } else {
            print("🔐 No JWT payload decoded")
        }

        if let id = JWTTools.userId(from: access) {
            UserStore.save(id: id, email: JWTTools.email(from: access))
            print("✅ Saved user id from JWT:", id)
        } else {
            print("❌ Could not parse user id from JWT")
        }
    }
}





import GoogleSignIn
import UIKit

func signInWithGoogleAndRoute(router: OnboardingRouter) {
    guard let root = UIApplication.shared.connectedScenes
        .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
        .first else { return }

    GIDSignIn.sharedInstance.signIn(withPresenting: root) { result, error in
        guard error == nil, let idToken = result?.user.idToken?.tokenString else {
            print("Google sign-in error:", error?.localizedDescription ?? "nil")
            return
        }
        Task {
            do {
                let pair = try await AuthAPI.shared.socialGoogle(idToken: idToken)
                handleAuthSuccess(pair)
                CurrentUser.ensureIdFromJWTIfNeeded()
                await MainActor.run { router.replace(with: [.gender]) }
                UserDefaults.standard.set(true, forKey: AuthFlags.isRegistered)
                await MainActor.run { router.replace(with: [.gender]) }
            } catch {
                print("Google exchange failed:", error)
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
    func socialGoogle(idToken: String) async throws -> TokenPair {
        try await post("api/auth/google/", ["id_token": idToken])
    }
}


extension AuthAPI {
    func socialApple(idToken: String, nonce: String? = nil) async throws -> TokenPair {
        var body: [String: Any] = ["id_token": idToken]
        if let nonce { body["nonce"] = nonce }   // если бэк захочет сверять nonce — отправим
        return try await post("api/auth/apple/", body)
    }
}


extension AuthAPI {
    func token(email: String, password: String) async throws -> TokenPair {
        try await post("api/auth/token/", ["email": email, "password": password])
    }
}


struct RefreshResponse: Decodable {
    let access: String
    let refresh: String?

    enum CodingKeys: String, CodingKey { case access, refresh, access_token }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        access = try c.decodeIfPresent(String.self, forKey: .access)
              ?? c.decode(String.self, forKey: .access_token)

        refresh = try c.decodeIfPresent(String.self, forKey: .refresh)
    }
}



extension AuthAPI {
    func refresh() async throws -> AuthTokens {
        guard let t = TokenStore.load() else { throw APIError.http(401, "No refresh") }
        let r: RefreshResponse = try await postNoRetry("api/auth/refresh/", ["refresh": t.refresh])
        let new = AuthTokens(access: r.access, refresh: r.refresh ?? t.refresh)
        TokenStore.save(new)
        return new
    }
}


// Репозиторий, который использует AuthAPI
final class BackendOnboardingRepository: OnboardingRepository {
    private var lastPlan: PersonalPlan?

    func submitOnboarding(data: OnboardingData) async throws {
        _ = try await AuthAPI.shared.submitOnboarding(data)
    }

    func requestAiPersonalPlan(from data: OnboardingData) async throws {
        // 1) Явно генерим план через POST
        let dto = try await AuthAPI.shared.generatePersonalPlan()

        // 2) Если на бэке генерация асинхронная и вернулись нули — короткий polling GET
        var daily = dto.dailyCalories
        var prot  = dto.proteinG
        var fat   = dto.fatG
        var carbs = dto.carbsG

        if daily == 0 && prot == 0 && fat == 0 && carbs == 0 {
            for _ in 0..<5 {
                try await Task.sleep(nanoseconds: 600_000_000) // 0.6s
                let g = try await AuthAPI.shared.getCurrentPlan()
                if g.dailyCalories > 0 || g.proteinG > 0 || g.fatG > 0 || g.carbsG > 0 {
                    daily = g.dailyCalories; prot = g.proteinG; fat = g.fatG; carbs = g.carbsG
                    break
                }
            }
        }

        // 3) Собираем доменную модель
        let unitLabel = (data.unit == .imperial) ? "lbs" : "kg"
        lastPlan = PersonalPlan(
            weightUnit: unitLabel,
            maintainWeight: 0,
            dailyCalories: daily,
            protein: prot,
            fat: fat,
            carbs: carbs,
            meals: [],
            workouts: []
        )
    }

    func fetchSavedPlan() -> PersonalPlan? { lastPlan }
}




final class AppleSignInCoordinator: NSObject {
    private var completion: ((Result<(idToken: String, nonce: String?), Error>) -> Void)?
    private var currentNonce: String?

    func start(completion: @escaping (Result<(idToken: String, nonce: String?), Error>) -> Void) {
        self.completion = completion

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        // nonce: best practice для противодействия replay
        let rawNonce = randomNonceString()
        currentNonce = rawNonce
        request.nonce = sha256(rawNonce)

        let ctrl = ASAuthorizationController(authorizationRequests: [request])
        ctrl.delegate = self
        ctrl.presentationContextProvider = self
        ctrl.performRequests()
    }

    // MARK: - Nonce utils
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var bytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            if status != errSecSuccess { fatalError("Unable to generate nonce.") }
            bytes.forEach { byte in
                if remaining == 0 { return }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? UIWindow()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let token = String(data: tokenData, encoding: .utf8)
        else {
            completion?(.failure(NSError(domain: "apple", code: -1, userInfo: [NSLocalizedDescriptionKey: "No identityToken"])))
            completion = nil
            return
        }
        completion?(.success((idToken: token, nonce: currentNonce)))
        completion = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion?(.failure(error))
        completion = nil
    }
}

let appleSignInCoordinator = AppleSignInCoordinator()

func signInWithAppleAndRoute(router: OnboardingRouter) {
    appleSignInCoordinator.start { result in
        switch result {
        case .failure(let error):
            print("Apple sign-in error:", error.localizedDescription)
        case .success(let payload):
            Task {
                do {
                    let pair = try await AuthAPI.shared.socialApple(idToken: payload.idToken, nonce: payload.nonce)
                    handleAuthSuccess(pair)
                    CurrentUser.ensureIdFromJWTIfNeeded()
                    await MainActor.run { router.replace(with: [.gender]) }
                    UserDefaults.standard.set(true, forKey: AuthFlags.isRegistered)
                    await MainActor.run { router.replace(with: [.gender]) }
                } catch {
                    print("Apple token exchange failed:", error)
                }
            }
        }
    }
}



//MARK: - handleAuthSuccess
private func handleAuthSuccess(_ pair: TokenPair) {
    TokenStore.save(.init(access: pair.access, refresh: pair.refresh))
    if let u = pair.user {
        UserStore.save(id: u.id, email: u.email)
    } else if let id = JWTTools.userId(from: pair.access) {
        UserStore.save(id: id, email: JWTTools.email(from: pair.access))
    }
    UserDefaults.standard.set(true, forKey: AuthFlags.isRegistered)
}

func signInWithGoogle(onAuthSuccess: @escaping () -> Void) {
    guard let root = UIApplication.shared.connectedScenes
        .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
        .first else { return }

    GIDSignIn.sharedInstance.signIn(withPresenting: root) { result, error in
        guard error == nil, let idToken = result?.user.idToken?.tokenString else {
            print("Google sign-in error:", error?.localizedDescription ?? "nil")
            return
        }
        Task {
            do {
                let pair = try await AuthAPI.shared.socialGoogle(idToken: idToken)
                handleAuthSuccess(pair)
                await MainActor.run { onAuthSuccess() }
            } catch {
                print("Google exchange failed:", error)
            }
        }
    }
}

func signInWithApple(onAuthSuccess: @escaping () -> Void) {
    appleSignInCoordinator.start { result in
        switch result {
        case .failure(let error):
            print("Apple sign-in error:", error.localizedDescription)
        case .success(let payload):
            Task {
                do {
                    let pair = try await AuthAPI.shared.socialApple(idToken: payload.idToken, nonce: payload.nonce)
                    handleAuthSuccess(pair)
                    await MainActor.run { onAuthSuccess() }
                } catch {
                    print("Apple token exchange failed:", error)
                }
            }
        }
    }
}




extension AuthAPI {
    // POST /api/profile/onboarding/
    @discardableResult
        func submitOnboarding(_ data: OnboardingData) async throws -> Profile {
            let payload = data.backendPayload()
            print("📤 Onboarding payload -> \(payload)")

            let profile: Profile = try await post("api/profile/onboarding/", payload)

            await MainActor.run {
                UserStore.saveProfileId(profile.id)
                NotificationCenter.default.post(name: .profileDidChange, object: nil)
            }

            return profile
        }

    fileprivate func generatePersonalPlan() async throws -> GeneratePlanResponse {
        try await post("api/profile/generate-plan/", [:])
    }
}


//MARK: - updateProfile
extension AuthAPI {
    func updateProfile(from data: OnboardingData) async throws {
        CurrentUser.ensureIdFromJWTIfNeeded()
        guard let userId = UserStore.id() else { throw APIError.http(400, "No user id") }

        var fields: [String: Any] = [:]
        let units = (data.unit == .imperial) ? "imperial" : "metric"
        fields["units"] = units

        if let g = data.gender { fields["gender"] = g.rawValue }
        if let dob = data.birthDate {
            let df = DateFormatter(); df.timeZone = .init(secondsFromGMT: 0); df.dateFormat = "yyyy-MM-dd"
            fields["date_of_birth"] = df.string(from: dob)
        }

        func kg(_ w: Double?) -> Int? {
            guard let w else { return nil }
            return units == "imperial" ? Int(round(w * 0.45359237)) : Int(round(w))
        }
        func cm(_ h: Double?) -> Int? {
            guard let h else { return nil }
            return units == "imperial" ? Int(round(h * 2.54)) : Int(round(h))
        }

        if let wkg = kg(data.weight)        { fields["weight_kg"] = wkg }
        if let hcm = cm(data.height)        { fields["height_cm"] = hcm }
        if let dkg = kg(data.desiredWeight) { fields["desired_weight_kg"] = dkg }
        if let act = data.lifestyle         { fields["activity"] = act.rawValue }
        if let goal = data.goal             { fields["goal"] = goal.rawValue }

        try await patchProfile(id: userId, fields: fields) // <-- ИМЕННО userId
    }
}

extension Notification.Name {
    static let profileDidChange = Notification.Name("profileDidChange")
}


//MARK: - PlanGetResponse
// ===== GET /api/plan/get_plan/ =====
struct PlanGetResponse: Decodable {
    let dailyCalories: Int
    let proteinG: Int
    let fatG: Int
    let carbsG: Int
    let generatedAt: String?

    enum CodingKeys: String, CodingKey {
        case daily_calories, daily_kcal, calories
        case protein_g, protein
        case fat_g, fat, fats
        case carbs_g, carbs, carbohydrates
        case generated_at
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dailyCalories = try c.decodeFirstInt(for: [.daily_calories, .daily_kcal, .calories])
        proteinG      = try c.decodeFirstInt(for: [.protein_g, .protein])
        fatG          = try c.decodeFirstInt(for: [.fat_g, .fat, .fats])
        carbsG        = try c.decodeFirstInt(for: [.carbs_g, .carbs, .carbohydrates])
        generatedAt   = try c.decodeIfPresent(String.self, forKey: .generated_at)
    }
}

private struct GeneratePlanResponse: Decodable {
    let dailyCalories: Int
    let proteinG: Int
    let fatG: Int
    let carbsG: Int
    let meals: [MealDTO]?
    let workouts: [WorkoutDTO]?

    struct MealDTO: Decodable {
        let time: String
        let title: String
        let kcal: Int

        enum CodingKeys: String, CodingKey { case time, title, kcal, calories }

        init(from d: Decoder) throws {
            let c = try d.container(keyedBy: CodingKeys.self)
            time  = try c.decode(String.self, forKey: .time)
            title = try c.decode(String.self, forKey: .title)
            kcal  = try c.decodeFirstInt(for: [.kcal, .calories])
        }
    }


    struct WorkoutDTO: Decodable {
        let day: String
        let focus: String
        let durationMin: Int

        enum CodingKeys: String, CodingKey { case day, focus, duration_min, duration, minutes }

        init(from d: Decoder) throws {
            let c = try d.container(keyedBy: CodingKeys.self)
            day   = try c.decode(String.self, forKey: .day)
            focus = try c.decode(String.self, forKey: .focus)
//            durationMin =
//                (try? c.decode(Int.self, forKey: .duration_min))
//                ?? (try? c.decode(Int.self, forKey: .duration))
//                ?? (try  c.decode(Int.self, forKey: .minutes))
            durationMin = try c.decodeFirstInt(for: [.duration_min, .duration, .minutes])
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case daily_calories, daily_kcal, calories
        case protein_g, protein
        case fat_g, fat, fats
        case carbs_g, carbs, carbohydrates
        case meals, workouts
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dailyCalories = try c.decodeFirstInt(for: [.daily_calories, .daily_kcal, .calories])
        proteinG      = try c.decodeFirstInt(for: [.protein_g, .protein])
        fatG          = try c.decodeFirstInt(for: [.fat_g, .fat, .fats])
        carbsG        = try c.decodeFirstInt(for: [.carbs_g, .carbs, .carbohydrates])
        meals         = try c.decodeIfPresent([MealDTO].self, forKey: .meals)
        workouts      = try c.decodeIfPresent([WorkoutDTO].self, forKey: .workouts)
    }
}



private extension KeyedDecodingContainer {
    func decodeFlexibleInt(forKey key: Key) throws -> Int {
        if let i = try? decode(Int.self, forKey: key) { return i }
        if let d = try? decode(Double.self, forKey: key) { return Int(round(d)) }
        if let s = try? decode(String.self, forKey: key) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if let d = Double(t.replacingOccurrences(of: ",", with: ".")) { return Int(round(d)) }
        }
        throw DecodingError.typeMismatch(
            Int.self,
            .init(codingPath: codingPath + [key],
                  debugDescription: "Value is not Int/Double/numeric String")
        )
    }

    func decodeFirstInt(for keys: [Key]) throws -> Int {
        for k in keys where contains(k) {
            return try decodeFlexibleInt(forKey: k)
        }
        throw DecodingError.keyNotFound(
            keys.first!,
            .init(codingPath: codingPath, debugDescription: "None of keys present: \(keys)")
        )
    }
}

extension AuthAPI {
     func getCurrentPlan() async throws -> PlanGetResponse {
        try await get("api/plan/get_plan/")
    }
}



extension AuthAPI {
    // PATCH /api/plan/patch_plan/
    func patchPlan(calories: Int, proteinG: Int, fatG: Int, carbsG: Int) async throws {
        struct Empty: Decodable {}
        let _: Empty = try await sendJSON("PATCH", "api/plan/patch_plan/", [
            "calories":  calories,
            "protein_g": proteinG,
            "fat_g":     fatG,
            "carbs_g":   carbsG
        ])
    }
}


//MARK: - MealCreateDTO
extension AuthAPI {
    private struct AnalyzeDTO: Decodable {
        struct IngredientDTO: Decodable {
            let name: String
            let kcal: Int?

            enum CodingKeys: String, CodingKey { case name, title, ingredient, kcal, calories }

            init(from d: Decoder) throws {
                // допускаем и "просто строка"
                if let sv = try? d.singleValueContainer(), let str = try? sv.decode(String.self) {
                    name = str; kcal = nil; return
                }
                let c = try d.container(keyedBy: CodingKeys.self)
                name = (try? c.decode(String.self, forKey: .name))
                    ?? (try? c.decode(String.self, forKey: .title))
                    ?? (try? c.decode(String.self, forKey: .ingredient))
                    ?? ""
                // поддержим и "kcal" и "calories"
                if let i = try? c.decode(Int.self, forKey: .kcal) { kcal = i }
                else if let i = try? c.decode(Int.self, forKey: .calories) { kcal = i }
                else { kcal = nil }
            }
        }

        let title: String?
        let calories: Int
        let proteinG: Int
        let fatG: Int
        let carbsG: Int
        let servings: Int?
        let benefitScore: Int?
        let ingredients: [IngredientDTO]?

        enum CodingKeys: String, CodingKey {
            case title, name
            case calories, kcal
            case protein_g, protein
            case fat_g, fat, fats
            case carbs_g, carbs, carbohydrates
            case servings
            case benefit_score, benefitScore
            case ingredients
        }

        init(from d: Decoder) throws {
            let c = try d.container(keyedBy: CodingKeys.self)
            title        = (try? c.decode(String.self, forKey: .title)) ?? (try? c.decode(String.self, forKey: .name))
            calories     = try c.decodeFirstInt(for: [.calories, .kcal])
            proteinG     = try c.decodeFirstInt(for: [.protein_g, .protein])
            fatG         = try c.decodeFirstInt(for: [.fat_g, .fat, .fats])
            carbsG       = try c.decodeFirstInt(for: [.carbs_g, .carbs, .carbohydrates])
            servings     = try? c.decode(Int.self, forKey: .servings)
            benefitScore = try? c.decodeFirstInt(for: [.benefit_score, .benefitScore])
            ingredients  = try? c.decode([IngredientDTO].self, forKey: .ingredients)
        }

        func toMeal() -> Meal {
            Meal(
                title: title ?? "",
                calories: calories,
                proteins: proteinG,
                fats: fatG,
                carbs: carbsG,
                servings: servings ?? 1,
                benefitScore: benefitScore ?? 5,
                ingredients: (ingredients ?? []).map { Ingredient(name: $0.name, kcal: $0.kcal ?? 0) }
            )
        }
    }
}



private struct Multipart {
    let boundary = "Boundary-\(UUID().uuidString)"
    var data = Data()
    mutating func addText(name: String, value: String) {
        data += "--\(boundary)\r\n".data(using: .utf8)!
        data += "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!
        data += "\(value)\r\n".data(using: .utf8)!
    }
    mutating func addFile(name: String, filename: String, mime: String, file: Data) {
        data += "--\(boundary)\r\n".data(using: .utf8)!
        data += "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!
        data += "Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!
        data += file
        data += "\r\n".data(using: .utf8)!
    }
    mutating func finalize() { data += "--\(boundary)--\r\n".data(using: .utf8)! }
    var contentType: String { "multipart/form-data; boundary=\(boundary)" }
}

extension AuthAPI {
    func analyze(image: UIImage, title: String? = nil, servings: Int? = nil) async throws -> Meal {
        guard let jpeg = image.jpegData(compressionQuality: 0.9) else {
            throw APIError.decoding("Could not encode JPEG")
        }
        do {
            return try await analyzeSend(imageData: jpeg, title: title, servings: servings)
        } catch APIError.http(let code, _) where code == 413 {
            // только если сервер сказал "слишком большой" — уменьшим и повторим
            let scaled = imageDownscaledJPEG(image, maxDimension: 1600, quality: 0.7)
            return try await analyzeSend(imageData: scaled, title: title, servings: servings)
        }
    }

    private func analyzeSend(imageData: Data, title: String?, servings: Int?) async throws -> Meal {
            var mp = Multipart()
            if let title { mp.addText(name: "title", value: title) }
            if let servings { mp.addText(name: "servings", value: String(servings)) }
            mp.addFile(name: "image", filename: "meal.jpg", mime: "image/jpeg", file: imageData) // имя поля "image"
            mp.finalize()

            var req = URLRequest(url: url("api/analyze/"))
            req.httpMethod = "POST"
            req.setValue(mp.contentType, forHTTPHeaderField: "Content-Type")
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            if let t = TokenStore.load()?.access { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
            req.httpBody = mp.data

            if debugAPI { print("➡️ ANALYZE \(imageData.count) bytes -> /api/analyze/") }

            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else { throw APIError.decoding("Not an HTTP response") }

            // Лог исходного тела
            if debugAPI {
                if let obj = try? JSONSerialization.jsonObject(with: data),
                   let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
                   let str = String(data: pretty, encoding: .utf8) {
                    print("⬅️ \(http.statusCode) /api/analyze/\n\(str)\n")
                } else {
                    print("⬅️ \(http.statusCode) /api/analyze/ (raw \(data.count) bytes)\n\(String(data: data, encoding: .utf8) ?? "<non-utf8>")\n")
                }
            }

            guard (200..<300).contains(http.statusCode) else {
                // Попробуем распарсить валидационные ошибки
                if let dict = try? JSONDecoder().decode([String:[String]].self, from: data) {
                    throw APIError.validation(dict)
                }
                throw APIError.http(http.statusCode, String(data: data, encoding: .utf8))
            }

            guard !data.isEmpty else {
                // Вот источник «the data couldn’t be read because it is missing»
                throw APIError.decoding("Empty body from /api/analyze/ (status \(http.statusCode))")
            }

            // Попробуем несколько форм: { ... }, { "meal": { ... } }, [ { ... } ]
            let dec = JSONDecoder()
            if let dto = try? dec.decode(AnalyzeDTO.self, from: data) {
                return dto.toMeal()
            }
            if let wrap = try? dec.decode(MealWrapper.self, from: data) {
                return wrap.meal.toMeal()
            }
            if let arr = try? dec.decode([AnalyzeDTO].self, from: data), let first = arr.first {
                return first.toMeal()
            }

            throw APIError.decoding(String(data: data, encoding: .utf8) ?? "Unknown JSON")
        }

        private struct MealWrapper: Decodable { let meal: AnalyzeDTO }
    }

    private func imageDownscaledJPEG(_ image: UIImage, maxDimension: CGFloat, quality: CGFloat) -> Data {
        let w = image.size.width, h = image.size.height
        let scale = min(1, maxDimension / max(w, h))
        if scale >= 1, let full = image.jpegData(compressionQuality: quality) { return full }
        let target = CGSize(width: w*scale, height: h*scale)
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 1
        return UIGraphicsImageRenderer(size: target, format: fmt)
            .jpegData(withCompressionQuality: quality) { _ in
                image.draw(in: CGRect(origin: .zero, size: target))
            }
    }

