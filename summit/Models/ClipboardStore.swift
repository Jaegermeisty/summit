//
//  ClipboardStore.swift
//  Summit
//
//  Created on 2026-02-09
//

import Foundation
import SwiftUI
import Combine

final class ClipboardStore: ObservableObject {
    @Published private(set) var workouts: [WorkoutTemplate] = []
    @Published private(set) var exercises: [ExerciseTemplate] = []

    var hasWorkouts: Bool { !workouts.isEmpty }
    var hasExercises: Bool { !exercises.isEmpty }

    func setWorkouts(_ templates: [WorkoutTemplate]) {
        workouts = templates
        exercises = []
    }

    func setExercises(_ templates: [ExerciseTemplate]) {
        exercises = templates
        workouts = []
    }

    func clear() {
        workouts = []
        exercises = []
    }
}

struct WorkoutTemplate: Identifiable {
    let id = UUID()
    let name: String
    let notes: String?
    let exercises: [ExerciseTemplate]
}

struct ExerciseTemplate: Identifiable {
    let id = UUID()
    let name: String
    let targetWeight: Double
    let targetRepsMin: Int
    let targetRepsMax: Int
    let numberOfSets: Int
    let notes: String?
}
