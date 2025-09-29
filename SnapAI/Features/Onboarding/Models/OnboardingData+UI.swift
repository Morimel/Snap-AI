//
//  OnboardingData+UI.swift
//  SnapAI
//
//  Created by Isa Melsov on 23/9/25.
//

import SwiftUI

extension OnboardingData {
    var genderImage: Image {
        switch gender {
        case .male:   return AppImages.Goal.maleGoal
        case .female: return AppImages.Goal.femaleGoal
        case .other, .none: return AppImages.Goal.otherGoal
        }
    }
    var weightUnitLabel: String { unit == .imperial ? "lbs" : "kg" }
}

extension OnboardingData {
    func backendPayload() -> [String: Any] {
        var out: [String: Any] = [:]

        if let g = gender { out["gender"] = g.rawValue }

        if let dob = birthDate {
            let df = DateFormatter()
            df.calendar = Calendar(identifier: .iso8601)
            df.timeZone = TimeZone(secondsFromGMT: 0)
            df.dateFormat = "yyyy-MM-dd"
            out["date_of_birth"] = df.string(from: dob)
        }

        out["units"] = unit.rawValue

        if let h = height {
            let cm = unit == .metric ? h : h * 2.54
            out["height_cm"] = Int(round(cm))
        }

        if let w = weight {
            let kg = unit == .metric ? w : w * 0.45359237
            out["weight_kg"] = Int(round(kg))
        }

        if let act = lifestyle { out["activity"] = act.rawValue }   // "sedentary"/"normal"/"active"
        if let g = goal      { out["goal"] = g.rawValue }           // "lose"/"gain"/"maintain"

        if let dw = desiredWeight {
            let kg = unit == .metric ? dw : dw * 0.45359237
            out["desired_weight_kg"] = Int(round(kg))
        }

        if let email { out["email"] = email }
        return out
    }

    func goalCaption() -> String {
        let unitLabel = (unit == .imperial) ? "lbs" : "kg"
        guard let goal else { return "Maintain weight" }

        let deltaDisplay: Int = {
            guard let w = weight, let dw = desiredWeight else { return 0 }
            let delta = dw - w
            return unit == .imperial ? Int(round(abs(delta) * 2.20462262))
                                     : Int(round(abs(delta)))
        }()

        switch goal {
        case .maintain: return "Maintain weight"
        case .lose:     return deltaDisplay > 0 ? "Lose \(deltaDisplay) \(unitLabel)" : "Lose weight"
        case .gain:     return deltaDisplay > 0 ? "Gain \(deltaDisplay) \(unitLabel)" : "Gain weight"
        }
    }

    mutating func fill(from p: Profile) {
        // units
        let unitsStr = (p.units ?? "metric").lowercased()
        let units: UnitSystem = (unitsStr == "imperial") ? .imperial : .metric
        self.unit = units

        // gender
        if let g = p.gender?.lowercased() {
            switch g {
            case "male":   self.gender = .male
            case "female": self.gender = .female
            default:       self.gender = .other
            }
        }

        // dob
        if let dob = p.date_of_birth {
            let df = DateFormatter()
            df.calendar = Calendar(identifier: .iso8601)
            df.timeZone = .init(secondsFromGMT: 0)
            df.dateFormat = "yyyy-MM-dd"
            self.birthDate = df.date(from: dob) ?? ISO8601DateFormatter().date(from: dob)
        }

        // weight / height
        if let kg = p.weight_kg {
            self.weight = (units == .imperial) ? Double(kg) * 2.20462262 : Double(kg)
        }
        if let cm = p.height_cm {
            self.height = (units == .imperial) ? Double(cm) / 2.54 : Double(cm)
        }

        // activity -> lifestyle
        if let s = p.activity?.lowercased() {
            self.lifestyle = Lifestyle(rawValue: s) ?? self.lifestyle
        }

        // goal
        if let g = p.goal?.lowercased() {
            self.goal = Goal(rawValue: g) ?? self.goal
        }

        // desired
        if let targetKg = p.desired_weight_kg {
            self.desiredWeight = (units == .imperial) ? Double(targetKg) * 2.20462262 : Double(targetKg)
        }

        // email
        self.email = p.user.email
    }
}
