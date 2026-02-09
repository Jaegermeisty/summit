//
//  PlanPhase.swift
//  Summit
//
//  Created on 2026-02-08
//

import Foundation
import SwiftData

@Model
final class PlanPhase: Identifiable {
    var id: UUID
    var name: String
    var orderIndex: Int
    var createdAt: Date
    var isActive: Bool
    var notes: String?
    var planId: UUID?

    init(
        id: UUID = UUID(),
        name: String,
        orderIndex: Int = 0,
        createdAt: Date = Date(),
        isActive: Bool = false,
        notes: String? = nil,
        planId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.isActive = isActive
        self.notes = notes
        self.planId = planId
    }
}
