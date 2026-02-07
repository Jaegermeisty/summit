//
//  ExerciseLog.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import Foundation
import SwiftData

@Model
final class ExerciseLog {
    var id: UUID
    var definition: ExerciseDefinition
    var weight: Double // Weight used in kg
    var reps: [Int] // Array of reps for each set (e.g., [8, 7, 6] for 3 sets)
    var notes: String? // Optional notes for this specific session
    var orderIndex: Int // For maintaining exercise order in the workout

    var session: WorkoutSession?

    init(
        id: UUID = UUID(),
        definition: ExerciseDefinition,
        weight: Double,
        reps: [Int],
        notes: String? = nil,
        orderIndex: Int = 0,
        session: WorkoutSession? = nil
    ) {
        self.id = id
        self.definition = definition
        self.weight = weight
        self.reps = reps
        self.notes = notes
        self.orderIndex = orderIndex
        self.session = session
    }

    var exerciseName: String {
        definition.name
    }

    var normalizedExerciseName: String {
        definition.normalizedName
    }

    /// Calculate the estimated 1RM using the best set (highest reps)
    /// Formula: 1RM = weight × (1 + reps/30)
    var estimatedOneRepMax: Double {
        guard let bestReps = reps.max(), bestReps > 0 else {
            return weight
        }
        return weight * (1 + Double(bestReps) / 30.0)
    }

    /// Get the best set (highest reps) for this exercise
    var bestSet: (setNumber: Int, reps: Int)? {
        guard let maxReps = reps.max(),
              let index = reps.firstIndex(of: maxReps) else {
            return nil
        }
        return (setNumber: index + 1, reps: maxReps)
    }
}
