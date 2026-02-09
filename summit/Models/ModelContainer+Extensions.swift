//
//  ModelContainer+Extensions.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import Foundation
import SwiftData

extension ModelContainer {
    /// Shared model container for the app
    static var shared: ModelContainer = {
        let schema = Schema([
            WorkoutPlan.self,
            Workout.self,
            PlanPhase.self,
            ExerciseDefinition.self,
            Exercise.self,
            WorkoutSession.self,
            ExerciseLog.self,
            BodyWeightLog.self
        ])

        let storeURL = defaultStoreURL()
        let modelConfiguration = ModelConfiguration(
            "default",
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            #if DEBUG
            // If the store is incompatible during development, recreate it.
            destroyStore(at: storeURL)
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            } catch {
                fatalError("Could not recreate ModelContainer: \(error)")
            }
            #else
            fatalError("Could not create ModelContainer: \(error)")
            #endif
        }
    }()
    
    /// Preview model container with sample data for development
    @MainActor
    static var preview: ModelContainer = {
        let schema = Schema([
            WorkoutPlan.self,
            Workout.self,
            PlanPhase.self,
            ExerciseDefinition.self,
            Exercise.self,
            WorkoutSession.self,
            ExerciseLog.self,
            BodyWeightLog.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Add sample data
            let context = container.mainContext
            
            // Create a sample workout plan
            let plan = WorkoutPlan(
                name: "Push Pull Legs",
                planDescription: "Classic 3-day split focusing on push, pull, and leg movements"
            )
            context.insert(plan)

            let phaseOne = PlanPhase(
                name: "Phase 1",
                orderIndex: 0,
                isActive: true,
                planId: plan.id
            )
            context.insert(phaseOne)
            
            // Create Push Day workout
            let pushDay = Workout(
                name: "Push Day",
                orderIndex: 0,
                planId: plan.id,
                phaseId: phaseOne.id
            )
            context.insert(pushDay)
            
            // Add exercises to Push Day
            let benchDefinition = ExerciseDefinition(name: "Bench Press")
            let shoulderDefinition = ExerciseDefinition(name: "Shoulder Press")
            context.insert(benchDefinition)
            context.insert(shoulderDefinition)

            let benchPress = Exercise(
                definition: benchDefinition,
                targetWeight: 60.0,
                targetRepsMin: 6,
                targetRepsMax: 8,
                numberOfSets: 3,
                notes: "Pause at bottom",
                orderIndex: 0,
                workout: pushDay
            )
            context.insert(benchPress)
            
            let shoulderPress = Exercise(
                definition: shoulderDefinition,
                targetWeight: 40.0,
                targetRepsMin: 8,
                targetRepsMax: 10,
                numberOfSets: 3,
                orderIndex: 1,
                workout: pushDay
            )
            context.insert(shoulderPress)
            
            // Create Pull Day workout
            let pullDay = Workout(
                name: "Pull Day",
                orderIndex: 1,
                planId: plan.id,
                phaseId: phaseOne.id
            )
            context.insert(pullDay)

            let deadliftDefinition = ExerciseDefinition(name: "Deadlift")
            context.insert(deadliftDefinition)

            let deadlift = Exercise(
                definition: deadliftDefinition,
                targetWeight: 100.0,
                targetRepsMin: 5,
                targetRepsMax: 6,
                numberOfSets: 3,
                notes: "Mixed grip on heavy sets",
                orderIndex: 0,
                workout: pullDay
            )
            context.insert(deadlift)
            
            // Create a sample workout session
            let session = WorkoutSession(
                date: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                isCompleted: true,
                completedAt: Date().addingTimeInterval(-86400 * 3),
                workoutTemplateId: pushDay.id,
                workoutTemplateName: pushDay.name,
                workoutPlanId: plan.id,
                workoutPlanName: plan.name,
                phaseId: phaseOne.id,
                phaseName: phaseOne.name
            )
            context.insert(session)
            
            let benchLog = ExerciseLog(
                definition: benchDefinition,
                weight: 60.0,
                reps: [8, 7, 6],
                orderIndex: 0,
                session: session
            )
            context.insert(benchLog)
            
            // Add a body weight log
            let bodyWeight = BodyWeightLog(
                date: Date(),
                weight: 75.0,
                notes: "Morning weight"
            )
            context.insert(bodyWeight)
            
            try context.save()
            
            return container
        } catch {
            fatalError("Could not create preview ModelContainer: \(error)")
        }
    }()
}

private func defaultStoreURL() -> URL {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    let baseURL = appSupport.first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    return baseURL.appendingPathComponent("default.store")
}

private func destroyStore(at url: URL) {
    let fm = FileManager.default
    let basePath = url.path
    let sidecars = [basePath, basePath + "-shm", basePath + "-wal"]
    for path in sidecars {
        try? fm.removeItem(atPath: path)
    }
}
