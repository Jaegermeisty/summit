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
            ZStack {
                formBackground

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        formHeader

                        fieldCard(
                            title: "Name",
                            helper: "e.g., Push Day, Pull Day, Leg Day, Upper Body, Day 1"
                        ) {
                            TextField("Workout Name", text: $workoutName)
                                .textInputAutocapitalization(.words)
                        }

                        fieldCard(
                            title: "Notes",
                            helper: "Add notes about focus areas, intensity, or special instructions"
                        ) {
                            TextField("Notes (optional)", text: $workoutNotes, axis: .vertical)
                                .lineLimit(2...4)
                        }

                        if !phases.isEmpty {
                            fieldCard(
                                title: "Phase",
                                helper: "Workouts must belong to a phase when phases are enabled. You can move them later."
                            ) {
                                if isPhaseLocked, let phaseName = selectedPhase?.name {
                                    HStack {
                                        Text(phaseName)
                                            .foregroundStyle(Color.summitText)
                                        Spacer()
                                        Image(systemName: "lock.fill")
                                            .foregroundStyle(Color.summitTextTertiary)
                                    }
                                } else {
                                    Menu {
                                        ForEach(phases) { phase in
                                            Button(phase.name) {
                                                selectedPhaseId = phase.id
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(selectedPhase?.name ?? "Select Phase")
                                            Spacer()
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.caption)
                                        }
                                        .foregroundStyle(Color.summitText)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.summitCardElevated)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        fieldCard(
                            title: "Position in Plan",
                            helper: positionFooterText
                        ) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Day \(workoutCount + 1)")
                                        .foregroundStyle(Color.summitText)
                                    if let phaseName = selectedPhase?.name {
                                        Text(phaseName)
                                            .font(.caption)
                                            .foregroundStyle(Color.summitTextSecondary)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
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

    private var formHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Create workout")
                .font(.custom("Avenir Next", size: 22))
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitText)
        }
    }

    private func fieldCard<Content: View>(
        title: String,
        helper: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("Avenir Next", size: 13))
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitTextSecondary)

            content()
                .font(.custom("Avenir Next", size: 16))
                .foregroundStyle(Color.summitText)
                .accentColor(Color.summitOrange)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.summitCardElevated)
                )

            Text(helper)
                .font(.custom("Avenir Next", size: 12))
                .foregroundStyle(Color.summitTextTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.summitCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.summitOrange.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var formBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.summitBackground,
                    Color(hex: "#111114")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.summitOrange.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: 140, y: -140)
        }
        .ignoresSafeArea()
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
