//
//  WorkoutSession.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var workoutTemplateId: UUID // Reference to the Workout template used
    var workoutTemplateName: String // Store name for historical reference
    var workoutPlanId: UUID // Reference to the WorkoutPlan
    var workoutPlanName: String // Store plan name for historical reference
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
    var exerciseLogs: [ExerciseLog]
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        workoutTemplateId: UUID,
        workoutTemplateName: String,
        workoutPlanId: UUID,
        workoutPlanName: String,
        exerciseLogs: [ExerciseLog] = []
    ) {
        self.id = id
        self.date = date
        self.workoutTemplateId = workoutTemplateId
        self.workoutTemplateName = workoutTemplateName
        self.workoutPlanId = workoutPlanId
        self.workoutPlanName = workoutPlanName
        self.exerciseLogs = exerciseLogs
    }
}
