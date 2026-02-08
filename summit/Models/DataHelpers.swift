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
        let normalizedName = ExerciseDefinition.normalize(exerciseName)
        let descriptor = FetchDescriptor<ExerciseLog>(
            predicate: #Predicate<ExerciseLog> { log in
                log.definition.normalizedName == normalizedName
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
        let normalizedName = ExerciseDefinition.normalize(exerciseName)
        let descriptor = FetchDescriptor<ExerciseLog>(
            predicate: #Predicate<ExerciseLog> { log in
                log.definition.normalizedName == normalizedName
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
        let descriptor = FetchDescriptor<ExerciseDefinition>(
            sortBy: [SortDescriptor(\ExerciseDefinition.name, order: .forward)]
        )
        
        do {
            let definitions = try context.fetch(descriptor)
            return definitions.map { $0.name }
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

            let activePhase = activePhase(for: plan, in: context)
            let planSessions = allSessions.filter { session in
                guard session.workoutPlanId == plan.id && session.isCompleted else { return false }
                if let activePhase, let phaseId = session.phaseId {
                    return phaseId == activePhase.id
                }
                return activePhase == nil
            }

            let filteredWorkouts = workouts(for: plan, in: context, phase: activePhase)

            guard let lastSession = planSessions.first else {
                return filteredWorkouts.first
            }
            
            // Find the next workout in the rotation
            let sortedWorkouts = filteredWorkouts
            
            if let lastWorkoutIndex = sortedWorkouts.firstIndex(where: { $0.id == lastSession.workoutTemplateId }) {
                let nextIndex = (lastWorkoutIndex + 1) % sortedWorkouts.count
                return sortedWorkouts[nextIndex]
            }
            
            // Fallback to first workout
            return sortedWorkouts.first
        } catch {
            print("Error finding next workout: \(error)")
            return workouts(for: plan, in: context, phase: activePhase(for: plan, in: context)).first
        }
    }

    /// Fetch the most recent completed session for a workout template
    static func lastCompletedSession(
        for workout: Workout,
        excluding sessionId: UUID? = nil,
        in context: ModelContext
    ) -> WorkoutSession? {
        let workoutId = workout.id
        let descriptor: FetchDescriptor<WorkoutSession>
        if let sessionId {
            descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate<WorkoutSession> { session in
                    session.workoutTemplateId == workoutId &&
                    session.isCompleted == true &&
                    session.id != sessionId
                },
                sortBy: [SortDescriptor(\WorkoutSession.date, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate<WorkoutSession> { session in
                    session.workoutTemplateId == workoutId && session.isCompleted == true
                },
                sortBy: [SortDescriptor(\WorkoutSession.date, order: .reverse)]
            )
        }

        do {
            return try context.fetch(descriptor).first
        } catch {
            print("Error fetching last completed session: \(error)")
            return nil
        }
    }

    /// Fetch an active (in-progress) session for a workout template
    static func activeSession(
        for workout: Workout,
        in context: ModelContext
    ) -> WorkoutSession? {
        let workoutId = workout.id
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.workoutTemplateId == workoutId && session.isCompleted == false
            },
            sortBy: [SortDescriptor(\WorkoutSession.date, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor).first
        } catch {
            print("Error fetching active session: \(error)")
            return nil
        }
    }

    /// Create or resume a session for the workout template
    static func startSession(
        for workout: Workout,
        in context: ModelContext
    ) -> WorkoutSession {
        if let existing = activeSession(for: workout, in: context) {
            return existing
        }

        let plan = workout.workoutPlan
        let phase = workout.phase
        let session = WorkoutSession(
            workoutTemplateId: workout.id,
            workoutTemplateName: workout.name,
            workoutPlanId: plan?.id ?? UUID(),
            workoutPlanName: plan?.name ?? "Unknown Plan",
            phaseId: phase?.id,
            phaseName: phase?.name
        )
        context.insert(session)

        let sortedExercises = exercises(for: workout, in: context)
        for (index, exercise) in sortedExercises.enumerated() {
            let reps = Array(repeating: 0, count: exercise.numberOfSets)
            let log = ExerciseLog(
                definition: exercise.definition,
                weight: exercise.targetWeight,
                reps: reps,
                orderIndex: index,
                session: session
            )
            context.insert(log)
        }

        do {
            try context.save()
        } catch {
            print("Error starting session: \(error)")
        }

        return session
    }

    /// Fetch logs for a specific session
    static func logs(
        for session: WorkoutSession,
        in context: ModelContext
    ) -> [ExerciseLog] {
        let sessionId = session.id
        let descriptor = FetchDescriptor<ExerciseLog>(
            predicate: #Predicate<ExerciseLog> { log in
                log.session?.id == sessionId
            },
            sortBy: [SortDescriptor(\ExerciseLog.orderIndex, order: .forward)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching session logs: \(error)")
            return []
        }
    }

    /// Fetch exercises for a workout template
    static func exercises(
        for workout: Workout,
        in context: ModelContext
    ) -> [Exercise] {
        let workoutId = workout.id
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.workout?.id == workoutId
            },
            sortBy: [SortDescriptor(\Exercise.orderIndex, order: .forward)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching exercises: \(error)")
            return []
        }
    }

    /// Fetch workouts for a plan
    static func workouts(
        for plan: WorkoutPlan,
        in context: ModelContext
    ) -> [Workout] {
        workouts(for: plan, in: context, phase: nil)
    }

    /// Fetch workouts for a plan and optional phase
    static func workouts(
        for plan: WorkoutPlan,
        in context: ModelContext,
        phase: PlanPhase?
    ) -> [Workout] {
        let planId = plan.id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                if let phaseId = phase?.id {
                    return workout.workoutPlan?.id == planId && workout.phase?.id == phaseId
                }
                return workout.workoutPlan?.id == planId
            },
            sortBy: [SortDescriptor(\Workout.orderIndex, order: .forward)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching workouts: \(error)")
            return []
        }
    }

    /// Fetch phases for a plan
    static func phases(
        for plan: WorkoutPlan,
        in context: ModelContext
    ) -> [PlanPhase] {
        let planId = plan.id
        let descriptor = FetchDescriptor<PlanPhase>(
            predicate: #Predicate<PlanPhase> { phase in
                phase.workoutPlan?.id == planId
            },
            sortBy: [SortDescriptor(\PlanPhase.orderIndex, order: .forward)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching phases: \(error)")
            return []
        }
    }

    /// Get the active phase for a plan, if any
    static func activePhase(
        for plan: WorkoutPlan,
        in context: ModelContext
    ) -> PlanPhase? {
        let phases = phases(for: plan, in: context)
        return phases.first(where: { $0.isActive }) ?? phases.first
    }

    /// Fetch completed sessions for a plan
    static func completedSessions(
        for plan: WorkoutPlan,
        in context: ModelContext
    ) -> [WorkoutSession] {
        let planId = plan.id
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.workoutPlanId == planId && session.isCompleted == true
            },
            sortBy: [SortDescriptor(\WorkoutSession.date, order: .forward)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching completed sessions: \(error)")
            return []
        }
    }

    /// Fetch a workout by id
    static func workout(
        with id: UUID,
        in context: ModelContext
    ) -> Workout? {
        let workoutId = id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.id == workoutId
            }
        )

        do {
            return try context.fetch(descriptor).first
        } catch {
            print("Error fetching workout: \(error)")
            return nil
        }
    }

    /// Get the most recently logged weight for a canonical exercise
    static func lastLoggedWeight(
        for definition: ExerciseDefinition,
        in context: ModelContext
    ) -> Double? {
        let normalizedName = definition.normalizedName
        let descriptor = FetchDescriptor<ExerciseLog>(
            predicate: #Predicate<ExerciseLog> { log in
                log.definition.normalizedName == normalizedName
            },
            sortBy: [SortDescriptor(\ExerciseLog.session?.date, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor).first?.weight
        } catch {
            print("Error fetching last logged weight: \(error)")
            return nil
        }
    }

    /// Get the most recently created exercise template for a canonical exercise
    static func lastExerciseTemplate(
        for definition: ExerciseDefinition,
        in context: ModelContext
    ) -> Exercise? {
        let normalizedName = definition.normalizedName
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.definition.normalizedName == normalizedName
            },
            sortBy: [SortDescriptor(\Exercise.createdAt, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor).first
        } catch {
            print("Error fetching last exercise template: \(error)")
            return nil
        }
    }

    /// Suggested starting weight based on last logged data (if any) or last template
    static func suggestedTargetWeight(
        for definition: ExerciseDefinition,
        in context: ModelContext
    ) -> Double? {
        if let loggedWeight = lastLoggedWeight(for: definition, in: context) {
            return loggedWeight
        }
        return lastExerciseTemplate(for: definition, in: context)?.targetWeight
    }
}
