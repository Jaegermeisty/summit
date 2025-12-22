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
    var exerciseName: String
    var weights: [Double] // Array of weights for each set (in kg)
    var reps: [Int] // Array of reps for each set (e.g., [8, 7, 6] for 3 sets)
    var notes: String? // Optional notes for this specific session
    var orderIndex: Int // For maintaining exercise order in the workout

    var session: WorkoutSession?

    init(
        id: UUID = UUID(),
        exerciseName: String,
        weights: [Double],
        reps: [Int],
        notes: String? = nil,
        orderIndex: Int = 0,
        session: WorkoutSession? = nil
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.weights = weights
        self.reps = reps
        self.notes = notes
        self.orderIndex = orderIndex
        self.session = session
    }

    /// Calculate the estimated 1RM using the best set (highest reps with heaviest weight)
    /// Formula: 1RM = weight × (1 + reps/30)
    var estimatedOneRepMax: Double {
        guard !weights.isEmpty, !reps.isEmpty else { return 0 }

        var bestEstimate: Double = 0
        for (index, weight) in weights.enumerated() {
            guard index < reps.count else { continue }
            let repCount = reps[index]
            let estimate = weight * (1 + Double(repCount) / 30.0)
            if estimate > bestEstimate {
                bestEstimate = estimate
            }
        }

        return bestEstimate
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
