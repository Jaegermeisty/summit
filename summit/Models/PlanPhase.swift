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

    var workoutPlan: WorkoutPlan?

    @Relationship(deleteRule: .cascade, inverse: \Workout.phase)
    var workouts: [Workout]

    init(
        id: UUID = UUID(),
        name: String,
        orderIndex: Int = 0,
        createdAt: Date = Date(),
        isActive: Bool = false,
        workoutPlan: WorkoutPlan? = nil,
        workouts: [Workout] = []
    ) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.isActive = isActive
        self.workoutPlan = workoutPlan
        self.workouts = workouts
    }
}
