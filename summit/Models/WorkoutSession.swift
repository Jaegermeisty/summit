//
//  WorkoutSession.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import Foundation
import SwiftData

@Model
final class WorkoutSession: Identifiable {
    var id: UUID
    var date: Date
    var isCompleted: Bool
    var completedAt: Date?
    var workoutTemplateId: UUID // Reference to the Workout template used
    var workoutTemplateName: String // Store name for historical reference
    var workoutPlanId: UUID // Reference to the WorkoutPlan
    var workoutPlanName: String // Store plan name for historical reference
    var phaseId: UUID?
    var phaseName: String?
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
    var exerciseLogs: [ExerciseLog]
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        workoutTemplateId: UUID,
        workoutTemplateName: String,
        workoutPlanId: UUID,
        workoutPlanName: String,
        phaseId: UUID? = nil,
        phaseName: String? = nil,
        exerciseLogs: [ExerciseLog] = []
    ) {
        self.id = id
        self.date = date
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.workoutTemplateId = workoutTemplateId
        self.workoutTemplateName = workoutTemplateName
        self.workoutPlanId = workoutPlanId
        self.workoutPlanName = workoutPlanName
        self.phaseId = phaseId
        self.phaseName = phaseName
        self.exerciseLogs = exerciseLogs
    }
}
