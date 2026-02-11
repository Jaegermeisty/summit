//
//  WeightUnit.swift
//  Summit
//
//  Created on 2026-02-10
//

import Foundation

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg
    case lb

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .kg:
            return "kg"
        case .lb:
            return "lb"
        }
    }

    var displayName: String {
        switch self {
        case .kg:
            return "Kilograms"
        case .lb:
            return "Pounds"
        }
    }

    static let poundsPerKg: Double = 2.2046226218
    static let storageKey = "weightUnit"

    static func current() -> WeightUnit {
        if let raw = UserDefaults.standard.string(forKey: storageKey),
           let unit = WeightUnit(rawValue: raw) {
            return unit
        }
        return .kg
    }

    func fromKg(_ value: Double) -> Double {
        switch self {
        case .kg:
            return value
        case .lb:
            return value * WeightUnit.poundsPerKg
        }
    }

    func toKg(_ value: Double) -> Double {
        switch self {
        case .kg:
            return value
        case .lb:
            return value / WeightUnit.poundsPerKg
        }
    }

    func format(_ kgValue: Double) -> String {
        let value = fromKg(kgValue)
        if value == floor(value) {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
