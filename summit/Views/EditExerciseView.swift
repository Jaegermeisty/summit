//
//  EditExerciseView.swift
//  summit
//
//  Created on 2025-12-22
//

import SwiftUI
import SwiftData

struct EditExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise
    @Query(sort: \ExerciseDefinition.name, order: .forward) private var definitions: [ExerciseDefinition]
    @AppStorage(WeightUnit.storageKey) private var weightUnitRaw: String = WeightUnit.kg.rawValue

    @State private var exerciseName: String
    @State private var targetWeight: String
    @State private var targetRepsMin: String
    @State private var targetRepsMax: String
    @State private var numberOfSets: String
    @State private var exerciseNotes: String
    @State private var usesBodyweight: Bool
    @State private var bodyweightFactor: Double
    @State private var bodyweightKg: String
    @State private var showingBodyweightInfo = false

    @FocusState private var focusedField: Field?

    enum Field {
        case name, weight, repsMin, repsMax, sets, notes
    }

    init(exercise: Exercise) {
        self.exercise = exercise
        let unit = WeightUnit.current()
        _exerciseName = State(initialValue: exercise.name)
        _targetWeight = State(initialValue: unit.format(exercise.targetWeight))
        _targetRepsMin = State(initialValue: "\(exercise.targetRepsMin)")
        _targetRepsMax = State(initialValue: "\(exercise.targetRepsMax)")
        _numberOfSets = State(initialValue: "\(exercise.numberOfSets)")
        _exerciseNotes = State(initialValue: exercise.notes ?? "")
        _usesBodyweight = State(initialValue: exercise.definition.usesBodyweight)
        _bodyweightFactor = State(initialValue: exercise.definition.bodyweightFactor)
        _bodyweightKg = State(initialValue: exercise.definition.lastBodyweightKg > 0 ? unit.format(exercise.definition.lastBodyweightKg) : "")
    }

    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    private var isFormValid: Bool {
        !exerciseName.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(targetWeight) != nil &&
        Int(targetRepsMin) != nil &&
        Int(targetRepsMax) != nil &&
        Int(numberOfSets) != nil &&
        (!usesBodyweight || bodyweightKg.isEmpty || Double(bodyweightKg) != nil)
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
                            helper: "Update the exercise label shown in your workouts."
                        ) {
                            TextField("Exercise Name", text: $exerciseName)
                                .textInputAutocapitalization(.words)
                                .focused($focusedField, equals: .name)
                        }

                        fieldCard(
                            title: "Targets",
                            helper: usesBodyweight
                                ? "External weight is optional for weighted reps."
                                : "Adjust your goal weight, rep range, and sets."
                        ) {
                            VStack(spacing: 12) {
                                HStack {
                                    Text(usesBodyweight ? "External Weight (\(weightUnit.symbol))" : "Target Weight (\(weightUnit.symbol))")
                                        .foregroundStyle(Color.summitTextSecondary)
                                    Spacer()
                                    TextField("0", text: $targetWeight)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .focused($focusedField, equals: .weight)
                                        .frame(width: 90)
                                }
                                .font(.custom("Avenir Next", size: 15))

                                Divider()
                                    .overlay(Color.summitTextTertiary.opacity(0.25))

                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Min Reps")
                                            .font(.custom("Avenir Next", size: 12))
                                            .foregroundStyle(Color.summitTextSecondary)
                                        TextField("6", text: $targetRepsMin)
                                            .keyboardType(.numberPad)
                                            .focused($focusedField, equals: .repsMin)
                                    }

                                    Spacer()

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Max Reps")
                                            .font(.custom("Avenir Next", size: 12))
                                            .foregroundStyle(Color.summitTextSecondary)
                                        TextField("8", text: $targetRepsMax)
                                            .keyboardType(.numberPad)
                                            .focused($focusedField, equals: .repsMax)
                                    }

                                    Spacer()

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Sets")
                                            .font(.custom("Avenir Next", size: 12))
                                            .foregroundStyle(Color.summitTextSecondary)
                                        TextField("3", text: $numberOfSets)
                                            .keyboardType(.numberPad)
                                            .focused($focusedField, equals: .sets)
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
                                        }
                                    }

                                if usesBodyweight {
                                    HStack {
                                        Text("Bodyweight (\(weightUnit.symbol))")
                                            .foregroundStyle(Color.summitTextSecondary)
                                        Spacer()
                                        TextField("0", text: $bodyweightKg)
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
                            TextField("Notes (optional)", text: $exerciseNotes, axis: .vertical)
                                .lineLimit(2...4)
                                .focused($focusedField, equals: .notes)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Edit Exercise")
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
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                    .foregroundStyle(isFormValid ? Color.summitOrange : Color.summitTextTertiary)
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundStyle(Color.summitOrange)
                }
            }
            .alert("Bodyweight factor", isPresented: $showingBodyweightInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The factor estimates how much of the total load (bodyweight + any added weight) contributes to the lift. 1.0 = full bodyweight (pull-ups). 0.70 is a common estimate for push-ups. Adjust if the movement uses less or more of your body.")
            }
        }
    }

    private var formHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Edit your exercise")
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

    private func saveChanges() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = exerciseNotes.trimmingCharacters(in: .whitespaces)

        guard let weightDisplay = Double(targetWeight),
              let repsMin = Int(targetRepsMin),
              let repsMax = Int(targetRepsMax),
              let sets = Int(numberOfSets) else {
            return
        }
        let weight = weightUnit.toKg(weightDisplay)
        let parsedBodyweight = weightUnit.toKg(Double(bodyweightKg) ?? 0)

        let normalized = ExerciseDefinition.normalize(trimmedName)
        let definition: ExerciseDefinition
        if let existing = definitions.first(where: { $0.normalizedName == normalized }) {
            definition = existing
        } else {
            let newDefinition = ExerciseDefinition(name: trimmedName)
            modelContext.insert(newDefinition)
            definition = newDefinition
        }

        if usesBodyweight {
            definition.usesBodyweight = true
            definition.bodyweightFactor = bodyweightFactor
            if parsedBodyweight > 0 {
                definition.lastBodyweightKg = parsedBodyweight
            }
        } else {
            definition.usesBodyweight = false
            definition.bodyweightFactor = 1.0
        }

        exercise.definition = definition
        exercise.targetWeight = weight
        exercise.targetRepsMin = repsMin
        exercise.targetRepsMax = repsMax
        exercise.numberOfSets = sets
        exercise.notes = trimmedNotes.isEmpty ? nil : trimmedNotes

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving exercise changes: \(error)")
        }
    }
}

#Preview {
    EditExerciseView(exercise: {
        let workout = Workout(name: "Push Day", orderIndex: 0)
        let definition = ExerciseDefinition(name: "Bench Press")
        let exercise = Exercise(
            definition: definition,
            targetWeight: 60.0,
            targetRepsMin: 6,
            targetRepsMax: 8,
            numberOfSets: 3,
            notes: "Pause at bottom",
            orderIndex: 0,
            workout: workout
        )
        return exercise
    }())
    .modelContainer(ModelContainer.preview)
}
