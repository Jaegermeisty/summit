//
//  CreateWorkoutView.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import SwiftUI
import SwiftData

struct CreateWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let workoutPlan: WorkoutPlan
    let preselectedPhaseId: UUID?
    @Query private var existingWorkouts: [Workout]
    @Query private var phases: [PlanPhase]

    @State private var workoutName: String = ""
    @State private var workoutNotes: String = ""
    @State private var selectedPhaseId: UUID?

    init(workoutPlan: WorkoutPlan, preselectedPhaseId: UUID? = nil) {
        self.workoutPlan = workoutPlan
        self.preselectedPhaseId = preselectedPhaseId
        let planId = workoutPlan.id
        _existingWorkouts = Query(
            filter: #Predicate<Workout> { workout in
                workout.planId == planId
            }
        )
        _phases = Query(
            filter: #Predicate<PlanPhase> { phase in
                phase.planId == planId
            },
            sort: \PlanPhase.orderIndex,
            order: .forward
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Workout Name", text: $workoutName)
                        .font(.body)
                } header: {
                    Text("Name")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                } footer: {
                    Text("e.g., Push Day, Pull Day, Leg Day, Upper Body, Day 1")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
                .listRowBackground(Color.summitCard)

                Section {
                    TextField("Notes (optional)", text: $workoutNotes, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.body)
                } header: {
                    Text("Notes")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                } footer: {
                    Text("Add notes about focus areas, intensity, or special instructions")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
                .listRowBackground(Color.summitCard)

                if !phases.isEmpty {
                    Section {
                        if isPhaseLocked, let phaseName = selectedPhase?.name {
                            HStack {
                                Text("Phase")
                                    .foregroundStyle(Color.summitTextSecondary)

                                Spacer()

                                Text(phaseName)
                                    .foregroundStyle(Color.summitText)
                            }
                        } else {
                            Picker("Phase", selection: $selectedPhaseId) {
                                ForEach(phases) { phase in
                                    Text(phase.name).tag(Optional(phase.id))
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    } header: {
                        Text("Phase")
                            .textCase(nil)
                            .font(.subheadline)
                            .foregroundStyle(Color.summitTextSecondary)
                    } footer: {
                        Text("Workouts must belong to a phase when phases are enabled. You can move them later.")
                            .font(.caption)
                            .foregroundStyle(Color.summitTextTertiary)
                    }
                    .listRowBackground(Color.summitCard)
                }

                Section {
                    HStack {
                        Text("Position in Plan")
                            .foregroundStyle(Color.summitTextSecondary)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Day \(workoutCount + 1)")
                                .foregroundStyle(Color.summitText)

                            if let phaseName = selectedPhase?.name {
                                Text(phaseName)
                                    .font(.caption)
                                    .foregroundStyle(Color.summitTextSecondary)
                            }
                        }
                    }
                } footer: {
                    Text(positionFooterText)
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
                .listRowBackground(Color.summitCard)
            }
            .scrollContentBackground(.hidden)
            .background(Color.summitBackground)
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.summitBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.summitTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createWorkout()
                    }
                    .disabled(workoutName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(workoutName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.summitTextTertiary : Color.summitOrange)
                }
            }
        }
        .onAppear {
            if selectedPhaseId == nil {
                if let preselectedPhaseId {
                    selectedPhaseId = preselectedPhaseId
                } else if let activePhase = DataHelpers.activePhase(for: workoutPlan, in: modelContext) {
                    selectedPhaseId = activePhase.id
                }
            }
        }
    }

    private func createWorkout() {
        let trimmedName = workoutName.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = workoutNotes.trimmingCharacters(in: .whitespaces)
        let phase = selectedPhase

        let newWorkout = Workout(
            name: trimmedName,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            orderIndex: workoutCount,
            planId: workoutPlan.id,
            phaseId: phase?.id
        )

        modelContext.insert(newWorkout)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving workout: \(error)")
        }
    }

    private var selectedPhase: PlanPhase? {
        guard !phases.isEmpty else { return nil }
        if let selectedPhaseId {
            return phases.first(where: { $0.id == selectedPhaseId }) ?? phases.first
        }
        return phases.first
    }

    private var workoutCount: Int {
        if let phase = selectedPhase {
            return DataHelpers.workouts(for: workoutPlan, in: modelContext, phase: phase).count
        }
        return existingWorkouts.count
    }

    private var isPhaseLocked: Bool {
        preselectedPhaseId != nil
    }

    private var positionFooterText: String {
        if let phaseName = selectedPhase?.name {
            return "This workout will be added as the next day in \(phaseName)."
        }
        return "This workout will be added as the next day in your plan rotation."
    }
}

#Preview {
    CreateWorkoutView(workoutPlan: WorkoutPlan(name: "Push Pull Legs"))
        .modelContainer(ModelContainer.preview)
}
