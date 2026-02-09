//
//  ExerciseDefinition.swift
//  Summit
//
//  Created on 2026-02-07
//

import Foundation
import SwiftData

@Model
final class ExerciseDefinition {
    var id: UUID
    var name: String
    var normalizedName: String
    var createdAt: Date
    var usesBodyweight: Bool
    var bodyweightFactor: Double
    var lastBodyweightKg: Double

    init(
        id: UUID = UUID(),
        name: String,
        normalizedName: String? = nil,
        createdAt: Date = Date(),
        usesBodyweight: Bool = false,
        bodyweightFactor: Double = 1.0,
        lastBodyweightKg: Double = 0
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.id = id
        self.name = trimmedName
        self.normalizedName = normalizedName ?? ExerciseDefinition.normalize(trimmedName)
        self.createdAt = createdAt
        self.usesBodyweight = usesBodyweight
        self.bodyweightFactor = bodyweightFactor
        self.lastBodyweightKg = lastBodyweightKg
    }

    static func normalize(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
        return parts.joined(separator: " ").lowercased()
    }

    static func defaultBodyweightFactor(for name: String) -> Double {
        let normalized = normalize(name)

        if normalized.contains("knee push") {
            return 0.55
        }

        if normalized.contains("push up") || normalized.contains("push-up") || normalized.contains("pushup") {
            return 0.70
        }

        if normalized.contains("pull up") ||
            normalized.contains("pull-up") ||
            normalized.contains("pullup") ||
            normalized.contains("chin up") ||
            normalized.contains("chin-up") ||
            normalized.contains("chinup") ||
            normalized.contains("dip") {
            return 1.0
        }

        return 1.0
    }
}
