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
    var notes: String? // Optional notes about the workout
    var orderIndex: Int // For ordering workouts within a plan (e.g., Day 1, Day 2)

    var workoutPlan: WorkoutPlan?
    var phase: PlanPhase?

    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
    var exercises: [Exercise]

    init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        orderIndex: Int = 0,
        workoutPlan: WorkoutPlan? = nil,
        phase: PlanPhase? = nil,
        exercises: [Exercise] = []
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.orderIndex = orderIndex
        self.workoutPlan = workoutPlan
        self.phase = phase
        self.exercises = exercises
    }
}
