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
    var repsData: Data? // Stored reps for each set
    var notes: String? // Optional notes for this specific session
    var orderIndex: Int // For maintaining exercise order in the workout

    var sessionId: UUID? // Plain UUID for queries (avoids relationship traversal in predicates)
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
        self.repsData = ExerciseLog.encodeReps(reps)
        self.notes = notes
        self.orderIndex = orderIndex
        self.sessionId = session?.id
        self.session = session
    }

    /// Array of reps for each set (e.g., [8, 7, 6] for 3 sets)
    var reps: [Int] {
        get { ExerciseLog.decodeReps(from: repsData) }
        set { repsData = ExerciseLog.encodeReps(newValue) }
    }

    var exerciseName: String {
        definition.name
    }

    var normalizedExerciseName: String {
        definition.normalizedName
    }

    private static func encodeReps(_ reps: [Int]) -> Data {
        (try? JSONEncoder().encode(reps)) ?? Data()
    }

    private static func decodeReps(from data: Data?) -> [Int] {
        guard let data else { return [] }
        return (try? JSONDecoder().decode([Int].self, from: data)) ?? []
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
