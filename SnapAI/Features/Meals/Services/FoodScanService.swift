////
////  FoodScanService.swift
////  SnapAI
////
////  Created by Isa Melsov on 23/9/25.
////
//
//import SwiftUI
//
////MARK: - FoodScanService
//struct FoodScanService {
//    struct ScanResult: Codable { let meal: Meal }
//
//    static func scan(image: UIImage, apiKey: String) async throws -> Meal {
//        let url = URL(string: "")!
//        let jpeg = image.jpegData(compressionQuality: 0.9) ?? Data()
//        let b64 = jpeg.base64EncodedString()
//
//        let prompt = """
//        You are a nutrition expert. Return ONLY minified JSON for a single meal with keys:
//        { "title": String, "calories": Int, "proteins": Int, "fats": Int, "carbs": Int, "servings": Int,
//          "benefitScore": Int (0-10),
//          "ingredients": [ { "name": String, "kcal": Int }, ... ] }.
//        Values in grams for macros. If uncertain, best estimate.
//        """
//
//        let body: [String: Any] = [
//            "model": "gpt-4o-mini",
//            "temperature": 0.2,
//            "messages": [
//                ["role": "system", "content": prompt],
//                ["role": "user",
//                 "content": [
//                    ["type": "text", "text": "What is in this photo? Return JSON as specified."],
//                    ["type": "image_url",
//                     "image_url": ["url": "data:image/jpeg;base64,\(b64)"]]
//                 ]
//                ]
//            ]
//        ]
//
//        var req = URLRequest(url: url)
//        req.httpMethod = "POST"
//        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        req.httpBody = try JSONSerialization.data(withJSONObject: body)
//
//        let (data, _) = try await URLSession.shared.data(for: req)
//
//        struct APIResponse: Decodable {
//            struct Choice: Decodable {
//                struct Message: Decodable {
//                    let content: String
//                }
//                let message: Message
//            }
//            let choices: [Choice]
//        }
//
//        let resp = try JSONDecoder().decode(APIResponse.self, from: data)
//
//        var content = resp.choices.first?.message.content ?? ""
//        if content.hasPrefix("```") {
//            content = content
//                .replacingOccurrences(of: "```json", with: "")
//                .replacingOccurrences(of: "```", with: "")
//                .trimmingCharacters(in: .whitespacesAndNewlines)
//        }
//
//        guard let jsonData = content.data(using: .utf8) else {
//            throw NSError(domain: "Scan", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid content"])
//        }
//
//        return try JSONDecoder().decode(Meal.self, from: jsonData)
//
//    }
//}
