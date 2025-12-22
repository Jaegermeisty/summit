//
//  DataHelpers.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import Foundation
import SwiftData

/// Helper functions for querying workout data
struct DataHelpers {
    
    /// Find the most recent session for a specific exercise
    static func lastSession(
        for exerciseName: String,
        in context: ModelContext
    ) -> ExerciseLog? {
        let descriptor = FetchDescriptor<ExerciseLog>(
            predicate: #Predicate<ExerciseLog> { log in
                log.exerciseName == exerciseName
            },
            sortBy: [SortDescriptor(\ExerciseLog.session?.date, order: .reverse)]
        )
        
        do {
            let logs = try context.fetch(descriptor)
            return logs.first
        } catch {
            print("Error fetching last session: \(error)")
            return nil
        }
    }
    
    /// Get all exercise logs for a specific exercise, sorted by date
    static func exerciseHistory(
        for exerciseName: String,
        in context: ModelContext
    ) -> [ExerciseLog] {
        let descriptor = FetchDescriptor<ExerciseLog>(
            predicate: #Predicate<ExerciseLog> { log in
                log.exerciseName == exerciseName
            },
            sortBy: [SortDescriptor(\ExerciseLog.session?.date, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching exercise history: \(error)")
            return []
        }
    }
    
    /// Get all unique exercise names that have been logged
    static func allExerciseNames(in context: ModelContext) -> [String] {
        let descriptor = FetchDescriptor<ExerciseLog>()
        
        do {
            let logs = try context.fetch(descriptor)
            let uniqueNames = Set(logs.map { $0.exerciseName })
            return Array(uniqueNames).sorted()
        } catch {
            print("Error fetching exercise names: \(error)")
            return []
        }
    }
    
    /// Get the active workout plan (most recently created active plan)
    static func activeWorkoutPlan(in context: ModelContext) -> WorkoutPlan? {
        let descriptor = FetchDescriptor<WorkoutPlan>(
            predicate: #Predicate<WorkoutPlan> { plan in
                plan.isActive == true
            },
            sortBy: [SortDescriptor(\WorkoutPlan.createdAt, order: .reverse)]
        )
        
        do {
            let plans = try context.fetch(descriptor)
            return plans.first
        } catch {
            print("Error fetching active workout plan: \(error)")
            return nil
        }
    }
    
    /// Calculate progress percentage between two 1RM values
    static func progressPercentage(from oldMax: Double, to newMax: Double) -> Double {
        guard oldMax > 0 else { return 0 }
        return ((newMax - oldMax) / oldMax) * 100
    }
    
    /// Get the next workout to perform based on the last completed session
    static func nextWorkout(
        in plan: WorkoutPlan,
        context: ModelContext
    ) -> Workout? {
        // Get all sessions and filter manually (simpler and more reliable)
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\WorkoutSession.date, order: .reverse)]
        )
        
        do {
            let allSessions = try context.fetch(descriptor)
            
            // Filter to sessions from this plan
            let planSessions = allSessions.filter { $0.workoutPlanId == plan.id }
            
            guard let lastSession = planSessions.first else {
                // No sessions yet, return first workout
                return plan.workouts.sorted(by: { $0.orderIndex < $1.orderIndex }).first
            }
            
            // Find the next workout in the rotation
            let sortedWorkouts = plan.workouts.sorted(by: { $0.orderIndex < $1.orderIndex })
            
            if let lastWorkoutIndex = sortedWorkouts.firstIndex(where: { $0.id == lastSession.workoutTemplateId }) {
                let nextIndex = (lastWorkoutIndex + 1) % sortedWorkouts.count
                return sortedWorkouts[nextIndex]
            }
            
            // Fallback to first workout
            return sortedWorkouts.first
        } catch {
            print("Error finding next workout: \(error)")
            return plan.workouts.sorted(by: { $0.orderIndex < $1.orderIndex }).first
        }
    }
}
