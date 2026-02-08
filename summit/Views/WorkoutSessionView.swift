//
//  WorkoutSessionView.swift
//  Summit
//
//  Created on 2026-02-07
//

import SwiftUI
import SwiftData

struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var session: WorkoutSession
    let workout: Workout

    @Query private var logs: [ExerciseLog]
    @State private var lastLogsByDefinition: [String: ExerciseLog] = [:]
    @State private var templatesByOrder: [Int: Exercise] = [:]
    @State private var showCompletionToast = false

    init(session: WorkoutSession, workout: Workout) {
        _session = Bindable(wrappedValue: session)
        self.workout = workout

        let sessionId = session.id
        _logs = Query(
            filter: #Predicate<ExerciseLog> { log in
                log.session?.id == sessionId
            },
            sort: \ExerciseLog.orderIndex,
            order: .forward
        )
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.workoutTemplateName)
                            .font(.headline)

                        if let phaseName = session.phaseName, !phaseName.isEmpty {
                            Text("Phase: \(phaseName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(session.isCompleted ? "Completed" : "In Progress")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !session.isCompleted {
                        Button {
                            finishSession()
                        } label: {
                            Text("End Workout")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            Section {
                if logs.isEmpty {
                    ContentUnavailableView {
                        Label("No Exercises", systemImage: "dumbbell")
                    } description: {
                        Text("Add exercises to this workout to start a session")
                    }
                } else {
                    ForEach(logs) { log in
                        ExerciseLogRowView(
                            log: log,
                            lastLog: lastLogsByDefinition[log.definition.normalizedName],
                            repRange: templatesByOrder[log.orderIndex].map { "\($0.targetRepsMin)-\($0.targetRepsMax) reps" }
                        )
                    }
                }
            } header: {
                Text("Exercises")
                    .textCase(nil)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.immediately)
        .overlay(alignment: .top) {
            if showCompletionToast {
                CompletionToastView()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .onAppear {
            loadLastLogs()
            loadTemplates()
        }
    }

    private func finishSession() {
        session.isCompleted = true
        session.completedAt = Date()

        do {
            try modelContext.save()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showCompletionToast = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                dismiss()
            }
        } catch {
            print("Error completing session: \(error)")
        }
    }

    private func loadLastLogs() {
        guard let lastSession = DataHelpers.lastCompletedSession(for: workout, excluding: session.id, in: modelContext) else {
            lastLogsByDefinition = [:]
            return
        }

        let logs = DataHelpers.logs(for: lastSession, in: modelContext)
        var mapping: [String: ExerciseLog] = [:]
        for log in logs {
            mapping[log.definition.normalizedName] = log
        }
        lastLogsByDefinition = mapping
    }

    private func loadTemplates() {
        let exercises = DataHelpers.exercises(for: workout, in: modelContext)
        var mapping: [Int: Exercise] = [:]
        for exercise in exercises {
            mapping[exercise.orderIndex] = exercise
        }
        templatesByOrder = mapping
    }
}

struct ExerciseLogRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var log: ExerciseLog
    let lastLog: ExerciseLog?
    let repRange: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(log.exerciseName)
                .font(.headline)

            if let repRange {
                Text(repRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let lastLog {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last time")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Label("\(formatWeight(lastLog.weight))kg", systemImage: "scalemass")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(repsSummary(lastLog.reps))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                Text("Weight")
                    .foregroundStyle(.secondary)

                Spacer()

                TextField("0", value: $log.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)

                Text("kg")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Set")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Reps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(log.reps.indices, id: \.self) { index in
                    HStack {
                        Text("Set \(index + 1)")
                            .frame(width: 60, alignment: .leading)
                            .foregroundStyle(.secondary)

                        TextField("Reps", value: bindingForRep(index), format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .onChange(of: log.weight) { _, _ in
            persist()
        }
        .onChange(of: log.reps) { _, _ in
            persist()
        }
    }

    private func bindingForRep(_ index: Int) -> Binding<Int> {
        Binding(
            get: {
                guard log.reps.indices.contains(index) else { return 0 }
                return log.reps[index]
            },
            set: { newValue in
                var updated = log.reps
                guard updated.indices.contains(index) else { return }
                updated[index] = newValue
                log.reps = updated
            }
        )
    }

    private func persist() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving log updates: \(error)")
        }
    }

    private func repsSummary(_ reps: [Int]) -> String {
        guard !reps.isEmpty else { return "" }
        return reps.map { String($0) }.joined(separator: ", ") + " reps"
    }

    private func formatWeight(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}

struct CompletionToastView: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Session completed")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.summitCardElevated)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    let plan = WorkoutPlan(name: "Push Pull Legs")
    let workout = Workout(name: "Push Day", orderIndex: 0, workoutPlan: plan)
    let benchDefinition = ExerciseDefinition(name: "Bench Press")
    let exercise = Exercise(
        definition: benchDefinition,
        targetWeight: 60.0,
        targetRepsMin: 6,
        targetRepsMax: 8,
        numberOfSets: 3,
        orderIndex: 0,
        workout: workout
    )
    let session = WorkoutSession(
        workoutTemplateId: workout.id,
        workoutTemplateName: workout.name,
        workoutPlanId: plan.id,
        workoutPlanName: plan.name
    )
    let log = ExerciseLog(
        definition: benchDefinition,
        weight: 60,
        reps: [8, 7, 6],
        orderIndex: 0,
        session: session
    )

    _ = exercise
    _ = log

    return NavigationStack {
        WorkoutSessionView(session: session, workout: workout)
            .modelContainer(ModelContainer.preview)
    }
}
