//
//  SeedData.swift
//  Summit
//
//  Created on 2026-02-09
//

import Foundation
import SwiftData

enum SeedData {
    static func seedIfNeeded(in context: ModelContext) {
        guard !hasAnyPlan(in: context) else { return }

        let plan = WorkoutPlan(
            name: "3-Day Split",
            planDescription: "Push / Pull / Legs template"
        )
        context.insert(plan)

        let seedWorkouts = defaultSeedWorkouts()
        var definitionsByName: [String: ExerciseDefinition] = [:]
        var workoutsByName: [String: Workout] = [:]

        for (workoutIndex, seedWorkout) in seedWorkouts.enumerated() {
            let workout = Workout(
                name: seedWorkout.name,
                orderIndex: workoutIndex,
                planId: plan.id
            )
            context.insert(workout)
            workoutsByName[seedWorkout.name] = workout

            for (exerciseIndex, seedExercise) in seedWorkout.exercises.enumerated() {
                let normalized = ExerciseDefinition.normalize(seedExercise.name)
                let definition: ExerciseDefinition
                if let existing = definitionsByName[normalized] {
                    definition = existing
                } else {
                    let created = ExerciseDefinition(name: seedExercise.name)
                    context.insert(created)
                    definitionsByName[normalized] = created
                    definition = created
                }

                let exercise = Exercise(
                    definition: definition,
                    targetWeight: seedExercise.startWeight,
                    targetRepsMin: seedExercise.repMin,
                    targetRepsMax: seedExercise.repMax,
                    numberOfSets: seedExercise.sets,
                    orderIndex: exerciseIndex,
                    workout: workout
                )
                context.insert(exercise)
            }
        }

        let calendar = Calendar.current
        let endDate = calendar.date(
            byAdding: .day,
            value: -1,
            to: calendar.startOfDay(for: Date())
        ) ?? Date()
        let startDate = calendar.date(byAdding: .day, value: -55, to: endDate) ?? endDate

        var progressByExercise: [String: ExerciseProgress] = [:]
        var sessionDate = startDate
        var workoutIndex = 0

        while sessionDate <= endDate {
            let seedWorkout = seedWorkouts[workoutIndex % seedWorkouts.count]
            guard let workout = workoutsByName[seedWorkout.name] else { break }

            let session = WorkoutSession(
                date: sessionDate,
                isCompleted: true,
                completedAt: sessionDate,
                workoutTemplateId: workout.id,
                workoutTemplateName: workout.name,
                workoutPlanId: plan.id,
                workoutPlanName: plan.name
            )
            context.insert(session)

            for (exerciseIndex, seedExercise) in seedWorkout.exercises.enumerated() {
                let normalized = ExerciseDefinition.normalize(seedExercise.name)
                guard let definition = definitionsByName[normalized] else { continue }

                let nextProgress = updatedProgress(
                    previous: progressByExercise[normalized],
                    spec: seedExercise
                )
                let log = ExerciseLog(
                    definition: definition,
                    weight: nextProgress.weight,
                    reps: nextProgress.reps,
                    orderIndex: exerciseIndex,
                    session: session
                )
                context.insert(log)
                progressByExercise[normalized] = nextProgress
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 3, to: sessionDate) else { break }
            sessionDate = nextDate
            workoutIndex += 1
        }

        do {
            try context.save()
        } catch {
            print("SeedData: Failed to save seed data: \(error)")
        }
    }

    private static func hasAnyPlan(in context: ModelContext) -> Bool {
        var descriptor = FetchDescriptor<WorkoutPlan>()
        descriptor.fetchLimit = 1
        do {
            return !(try context.fetch(descriptor)).isEmpty
        } catch {
            print("SeedData: Failed to check existing plans: \(error)")
            return true
        }
    }

    private static func updatedProgress(
        previous: ExerciseProgress?,
        spec: SeedExercise
    ) -> ExerciseProgress {
        if let previous {
            let hitMax = previous.reps.allSatisfy { $0 >= spec.repMax }
            if hitMax {
                return ExerciseProgress(
                    weight: previous.weight + spec.weightIncrement,
                    reps: initialReps(for: spec)
                )
            }
            let reps = previous.reps.map { min($0 + 1, spec.repMax) }
            return ExerciseProgress(weight: previous.weight, reps: reps)
        }

        return ExerciseProgress(weight: spec.startWeight, reps: initialReps(for: spec))
    }

    private static func initialReps(for spec: SeedExercise) -> [Int] {
        guard spec.sets > 0 else { return [] }
        return (0..<spec.sets).map { index in
            max(spec.repMin - index, 1)
        }
    }

    private static func defaultSeedWorkouts() -> [SeedWorkout] {
        [
            SeedWorkout(
                name: "Push Day",
                exercises: [
                    SeedExercise(name: "Bench Press", sets: 3, repMin: 6, repMax: 8, startWeight: 60, weightIncrement: 5),
                    SeedExercise(name: "Shoulder Press", sets: 3, repMin: 6, repMax: 8, startWeight: 40, weightIncrement: 2.5),
                    SeedExercise(name: "Incline Dumbbell Press", sets: 3, repMin: 8, repMax: 12, startWeight: 22.5, weightIncrement: 2.5),
                    SeedExercise(name: "Triceps Pushdown", sets: 3, repMin: 8, repMax: 12, startWeight: 25, weightIncrement: 2.5)
                ]
            ),
            SeedWorkout(
                name: "Pull Day",
                exercises: [
                    SeedExercise(name: "Deadlift", sets: 3, repMin: 5, repMax: 6, startWeight: 100, weightIncrement: 5),
                    SeedExercise(name: "Barbell Row", sets: 3, repMin: 6, repMax: 8, startWeight: 60, weightIncrement: 2.5),
                    SeedExercise(name: "Lat Pulldown", sets: 3, repMin: 8, repMax: 12, startWeight: 50, weightIncrement: 2.5),
                    SeedExercise(name: "Biceps Curl", sets: 3, repMin: 8, repMax: 12, startWeight: 20, weightIncrement: 2.5)
                ]
            ),
            SeedWorkout(
                name: "Leg Day",
                exercises: [
                    SeedExercise(name: "Back Squat", sets: 3, repMin: 6, repMax: 8, startWeight: 80, weightIncrement: 5),
                    SeedExercise(name: "Romanian Deadlift", sets: 3, repMin: 6, repMax: 8, startWeight: 70, weightIncrement: 5),
                    SeedExercise(name: "Leg Press", sets: 3, repMin: 10, repMax: 12, startWeight: 140, weightIncrement: 5),
                    SeedExercise(name: "Calf Raise", sets: 3, repMin: 10, repMax: 12, startWeight: 60, weightIncrement: 5)
                ]
            )
        ]
    }
}

private struct SeedWorkout {
    let name: String
    let exercises: [SeedExercise]
}

private struct SeedExercise {
    let name: String
    let sets: Int
    let repMin: Int
    let repMax: Int
    let startWeight: Double
    let weightIncrement: Double
}

private struct ExerciseProgress {
    let weight: Double
    let reps: [Int]
}
