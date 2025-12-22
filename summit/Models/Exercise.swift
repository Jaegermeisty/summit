//
//  Exercise.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var targetWeight: Double // Suggested starting weight in kg
    var targetRepsMin: Int // Minimum target reps (e.g., 6 in "6-8 reps")
    var targetRepsMax: Int // Maximum target reps (e.g., 8 in "6-8 reps")
    var numberOfSets: Int
    var notes: String? // Persistent notes like "rest-pause on last set"
    var orderIndex: Int // For ordering exercises within a workout
    
    var workout: Workout?
    
    init(
        id: UUID = UUID(),
        name: String,
        targetWeight: Double,
        targetRepsMin: Int,
        targetRepsMax: Int,
        numberOfSets: Int,
        notes: String? = nil,
        orderIndex: Int = 0,
        workout: Workout? = nil
    ) {
        self.id = id
        self.name = name
        self.targetWeight = targetWeight
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.numberOfSets = numberOfSets
        self.notes = notes
        self.orderIndex = orderIndex
        self.workout = workout
    }
}
