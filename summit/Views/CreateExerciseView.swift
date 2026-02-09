//
//  CreateExerciseView.swift
//  Summit
//
//  Created on 2026-02-07
//

import SwiftUI
import SwiftData

struct CreateExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExerciseDefinition.name, order: .forward) private var definitions: [ExerciseDefinition]
    @Query private var existingExercises: [Exercise]

    let workout: Workout

    @State private var exerciseName: String = ""
    @State private var selectedDefinition: ExerciseDefinition?
    @State private var targetWeight: Double = 0
    @State private var targetRepsMin: Int = 6
    @State private var targetRepsMax: Int = 8
    @State private var numberOfSets: Int = 3
    @State private var notes: String = ""
    @State private var usesBodyweight: Bool = false
    @State private var bodyweightFactor: Double = 1.0
    @State private var bodyweightKg: Double = 0
    @State private var showingBodyweightInfo = false

    private var normalizedName: String {
        ExerciseDefinition.normalize(exerciseName)
    }

    private var suggestions: [ExerciseDefinition] {
        let query = normalizedName
        guard !query.isEmpty else { return [] }

        let prefixMatches = definitions.filter { $0.normalizedName.hasPrefix(query) }
        if !prefixMatches.isEmpty {
            return Array(prefixMatches.prefix(6))
        }

        let containsMatches = definitions.filter { $0.normalizedName.contains(query) }
        return Array(containsMatches.prefix(6))
    }

    private var canSave: Bool {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && targetRepsMin > 0 && targetRepsMax >= targetRepsMin && numberOfSets > 0
    }

    init(workout: Workout) {
        self.workout = workout
        let workoutId = workout.id
        _existingExercises = Query(
            filter: #Predicate<Exercise> { exercise in
                exercise.workoutId == workoutId
            }
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
                            helper: "Names are matched case-insensitively, so “bench press” and “Bench Press” are the same exercise."
                        ) {
                            TextField("Exercise Name", text: $exerciseName)
                                .textInputAutocapitalization(.words)
                        }

                        if !suggestions.isEmpty {
                            fieldCard(title: "Suggestions") {
                                VStack(spacing: 0) {
                                    ForEach(suggestions, id: \.id) { definition in
                                        Button {
                                            applyDefinition(definition)
                                        } label: {
                                            HStack {
                                                Text(definition.name)
                                                    .foregroundStyle(Color.summitText)
                                                Spacer()
                                                if selectedDefinition?.id == definition.id {
                                                    Image(systemName: "checkmark")
                                                        .foregroundStyle(Color.summitOrange)
                                                }
                                            }
                                            .padding(.vertical, 8)
                                        }
                                        .buttonStyle(.plain)

                                        if definition.id != suggestions.last?.id {
                                            Divider()
                                                .overlay(Color.summitTextTertiary.opacity(0.25))
                                        }
                                    }
                                }
                            }
                        }

                        fieldCard(
                            title: "Targets",
                            helper: usesBodyweight
                                ? "External weight is optional for weighted reps."
                                : "Set your goal range and sets for each session."
                        ) {
                            VStack(spacing: 12) {
                                HStack {
                                    Text(usesBodyweight ? "External Weight" : "Target Weight")
                                        .foregroundStyle(Color.summitTextSecondary)
                                    Spacer()
                                    TextField("0", value: $targetWeight, format: .number)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 90)
                                    Text("kg")
                                        .foregroundStyle(Color.summitTextSecondary)
                                }
                                .font(.custom("Avenir Next", size: 15))

                                Divider()
                                    .overlay(Color.summitTextTertiary.opacity(0.25))

                                Stepper(value: $targetRepsMin, in: 1...30) {
                                    HStack {
                                        Text("Min Reps")
                                        Spacer()
                                        Text("\(targetRepsMin)")
                                            .foregroundStyle(Color.summitTextSecondary)
                                    }
                                }
                                .font(.custom("Avenir Next", size: 15))

                                Stepper(value: $targetRepsMax, in: 1...30) {
                                    HStack {
                                        Text("Max Reps")
                                        Spacer()
                                        Text("\(targetRepsMax)")
                                            .foregroundStyle(Color.summitTextSecondary)
                                    }
                                }
                                .font(.custom("Avenir Next", size: 15))

                                Stepper(value: $numberOfSets, in: 1...20) {
                                    HStack {
                                        Text("Sets")
                                        Spacer()
                                        Text("\(numberOfSets)")
                                            .foregroundStyle(Color.summitTextSecondary)
                                    }
                                }
                                .font(.custom("Avenir Next", size: 15))
                            }
                        }

                        fieldCard(
                            title: "Bodyweight",
                            helper: "Use for pull-ups, push-ups, dips, and other bodyweight movements."
                        ) {
                            VStack(spacing: 12) {
                                Toggle("Bodyweight exercise", isOn: $usesBodyweight)
                                    .onChange(of: usesBodyweight) { _, newValue in
                                        if newValue {
                                            bodyweightFactor = ExerciseDefinition.defaultBodyweightFactor(for: exerciseName)
                                            autofillBodyweightIfNeeded(from: selectedDefinition)
                                        }
                                    }

                                if usesBodyweight {
                                    HStack {
                                        Text("Bodyweight (kg)")
                                            .foregroundStyle(Color.summitTextSecondary)
                                        Spacer()
                                        TextField("0", value: $bodyweightKg, format: .number)
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 90)
                                    }
                                    .font(.custom("Avenir Next", size: 15))

                                    Divider()
                                        .overlay(Color.summitTextTertiary.opacity(0.25))

                                    HStack(spacing: 8) {
                                        Text("Bodyweight factor")
                                            .font(.custom("Avenir Next", size: 14))
                                            .foregroundStyle(Color.summitTextSecondary)
                                        Button {
                                            showingBodyweightInfo = true
                                        } label: {
                                            Image(systemName: "questionmark.circle")
                                                .foregroundStyle(Color.summitTextSecondary)
                                        }
                                        .buttonStyle(.plain)

                                        Spacer()

                                        Text(String(format: "%.2f", bodyweightFactor))
                                            .font(.custom("Avenir Next", size: 14))
                                            .foregroundStyle(Color.summitText)
                                    }

                                    Slider(value: $bodyweightFactor, in: 0.3...1.2, step: 0.05)
                                        .tint(Color.summitOrange)
                                }
                            }
                        }

                        fieldCard(
                            title: "Notes",
                            helper: "Optional cues or reminders for this movement."
                        ) {
                            TextField("Notes (optional)", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("New Exercise")
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
                        createExercise()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                    .foregroundStyle(canSave ? Color.summitOrange : Color.summitTextTertiary)
                }
            }
            .onChange(of: exerciseName) { _, _ in
                let normalized = normalizedName
                if let match = definitions.first(where: { $0.normalizedName == normalized }) {
                    if selectedDefinition?.id != match.id {
                        selectedDefinition = match
                        usesBodyweight = match.usesBodyweight
                        bodyweightFactor = match.bodyweightFactor
                        bodyweightKg = match.lastBodyweightKg
                    }
                    autofillWeightIfNeeded(from: match)
                    autofillBodyweightIfNeeded(from: match)
                } else if let selectedDefinition, selectedDefinition.normalizedName != normalized {
                    self.selectedDefinition = nil
                    usesBodyweight = false
                    bodyweightFactor = ExerciseDefinition.defaultBodyweightFactor(for: exerciseName)
                }
            }
            .onChange(of: targetRepsMin) { _, newValue in
                if newValue > targetRepsMax {
                    targetRepsMax = newValue
                }
            }
            .onChange(of: targetRepsMax) { _, newValue in
                if newValue < targetRepsMin {
                    targetRepsMin = newValue
                }
            }
            .alert("Bodyweight factor", isPresented: $showingBodyweightInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The factor estimates how much of your bodyweight contributes to the lift. 1.0 = full bodyweight (pull-ups). 0.70 is a common estimate for push-ups. Adjust if the movement uses less or more of your body.")
            }
        }
    }

    private var formHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Create an exercise")
                .font(.custom("Avenir Next", size: 22))
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitText)
        }
    }

    private func fieldCard<Content: View>(
        title: String,
        helper: String? = nil,
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

            if let helper {
                Text(helper)
                    .font(.custom("Avenir Next", size: 12))
                    .foregroundStyle(Color.summitTextTertiary)
            }
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
                .frame(width: 220, height: 220)
                .blur(radius: 60)
                .offset(x: 140, y: -140)
        }
        .ignoresSafeArea()
    }

    private func createExercise() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let definition = resolveDefinition(for: trimmedName)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if usesBodyweight {
            definition.usesBodyweight = true
            definition.bodyweightFactor = bodyweightFactor
            if bodyweightKg > 0 {
                definition.lastBodyweightKg = bodyweightKg
            }
        } else {
            definition.usesBodyweight = false
            definition.bodyweightFactor = 1.0
        }

        let newExercise = Exercise(
            definition: definition,
            targetWeight: targetWeight,
            targetRepsMin: targetRepsMin,
            targetRepsMax: targetRepsMax,
            numberOfSets: numberOfSets,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            orderIndex: existingExercises.count,
            workout: workout
        )

        modelContext.insert(newExercise)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving exercise: \(error)")
        }
    }

    private func resolveDefinition(for name: String) -> ExerciseDefinition {
        let normalized = ExerciseDefinition.normalize(name)

        if let selectedDefinition, selectedDefinition.normalizedName == normalized {
            return selectedDefinition
        }

        if let existing = definitions.first(where: { $0.normalizedName == normalized }) {
            return existing
        }

        let definition = ExerciseDefinition(name: name)
        modelContext.insert(definition)
        return definition
    }

    private func applyDefinition(_ definition: ExerciseDefinition) {
        selectedDefinition = definition
        exerciseName = definition.name
        autofillWeightIfNeeded(from: definition)
        autofillBodyweightIfNeeded(from: definition)
    }

    private func autofillWeightIfNeeded(from definition: ExerciseDefinition) {
        guard targetWeight == 0 else { return }
        if let suggestedWeight = DataHelpers.suggestedTargetWeight(for: definition, in: modelContext) {
            targetWeight = suggestedWeight
        }
    }

    private func autofillBodyweightIfNeeded(from definition: ExerciseDefinition?) {
        guard usesBodyweight else { return }
        guard bodyweightKg == 0, let definition else { return }
        if let suggested = DataHelpers.suggestedBodyweight(for: definition, in: modelContext) {
            bodyweightKg = suggested
        }
    }
}

#Preview {
    CreateExerciseView(workout: Workout(name: "Push Day", orderIndex: 0))
        .modelContainer(ModelContainer.preview)
}
