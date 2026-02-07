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
            Exercise.self,
            WorkoutSession.self,
            ExerciseLog.self,
            BodyWeightLog.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    /// Preview model container with sample data for development
    @MainActor
    static var preview: ModelContainer = {
        let schema = Schema([
            WorkoutPlan.self,
            Workout.self,
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
            
            // Create Push Day workout
            let pushDay = Workout(
                name: "Push Day",
                orderIndex: 0,
                workoutPlan: plan
            )
            context.insert(pushDay)
            
            // Add exercises to Push Day
            let benchPress = Exercise(
                name: "Bench Press",
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
                name: "Shoulder Press",
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
                workoutPlan: plan
            )
            context.insert(pullDay)
            
            let deadlift = Exercise(
                name: "Deadlift",
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
                workoutTemplateId: pushDay.id,
                workoutTemplateName: pushDay.name,
                workoutPlanId: plan.id,
                workoutPlanName: plan.name
            )
            context.insert(session)
            
            let benchLog = ExerciseLog(
                exerciseName: "Bench Press",
                weights: [60.0, 60.0, 57.5],
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
