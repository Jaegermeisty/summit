//
//  Workout.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import Foundation
import SwiftData

@Model
final class Workout: Identifiable {
    var id: UUID
    var name: String
    var notes: String?
    var orderIndex: Int

    var planId: UUID?
    var phaseId: UUID?

    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
    var exercises: [Exercise]

    init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        orderIndex: Int = 0,
        planId: UUID? = nil,
        phaseId: UUID? = nil,
        exercises: [Exercise] = []
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.orderIndex = orderIndex
        self.planId = planId
        self.phaseId = phaseId
        self.exercises = exercises
    }
}
