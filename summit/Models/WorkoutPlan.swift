//
//  WorkoutPlan.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import Foundation
import SwiftData

@Model
final class WorkoutPlan: Identifiable {
    var id: UUID
    var name: String
    var planDescription: String?
    var createdAt: Date
    var isActive: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \Workout.workoutPlan)
    var workouts: [Workout]
    
    init(
        id: UUID = UUID(),
        name: String,
        planDescription: String? = nil,
        createdAt: Date = Date(),
        isActive: Bool = true,
        workouts: [Workout] = []
    ) {
        self.id = id
        self.name = name
        self.planDescription = planDescription
        self.createdAt = createdAt
        self.isActive = isActive
        self.workouts = workouts
    }
}
