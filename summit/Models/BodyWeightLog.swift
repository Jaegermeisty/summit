//
//  BodyWeightLog.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import Foundation
import SwiftData

@Model
final class BodyWeightLog {
    var id: UUID
    var date: Date
    var weight: Double // Weight in kg
    var notes: String? // Optional notes
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weight: Double,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.notes = notes
    }
}
