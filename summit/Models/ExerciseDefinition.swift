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

    init(
        id: UUID = UUID(),
        name: String,
        normalizedName: String? = nil,
        createdAt: Date = Date()
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.id = id
        self.name = trimmedName
        self.normalizedName = normalizedName ?? ExerciseDefinition.normalize(trimmedName)
        self.createdAt = createdAt
    }

    static func normalize(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
        return parts.joined(separator: " ").lowercased()
    }
}
