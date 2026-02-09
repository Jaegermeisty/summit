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
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @Bindable var session: WorkoutSession
    let workout: Workout

    @Query private var logs: [ExerciseLog]
    @State private var lastLogsByDefinition: [String: ExerciseLog] = [:]
    @State private var templatesByOrder: [Int: Exercise] = [:]
    @State private var showCompletionToast = false
    @State private var showingPaywall = false
    @State private var showingEndConfirmation = false
    @State private var animatedProgress: Double = 0

    init(session: WorkoutSession, workout: Workout) {
        _session = Bindable(wrappedValue: session)
        self.workout = workout

        let sessionId = session.id
        _logs = Query(
            filter: #Predicate<ExerciseLog> { log in
                log.sessionId == sessionId
            },
            sort: \ExerciseLog.orderIndex,
            order: .forward
        )
    }

    var body: some View {
        ZStack {
            sessionBackground

            List {
                Section {
                    if logs.isEmpty {
                        infoCard {
                            ContentUnavailableView {
                                Label("No Exercises", systemImage: "dumbbell")
                                    .foregroundStyle(Color.summitText)
                            } description: {
                                Text("Add exercises to this workout to start a session")
                                    .foregroundStyle(Color.summitTextSecondary)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(logs) { log in
                            ExerciseLogRowView(
                                log: log,
                                lastLog: lastLogsByDefinition[log.definition.normalizedName],
                                repRange: templatesByOrder[log.orderIndex].map { "\($0.targetRepsMin)-\($0.targetRepsMax) reps" }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(session.workoutTemplateName)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.immediately)
        .overlay(alignment: .top) {
            if showCompletionToast {
                CompletionToastView()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .safeAreaInset(edge: .top) {
            sessionControlBar
        }
        .alert("End workout?", isPresented: $showingEndConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Workout", role: .destructive) {
                finishSession()
            }
        } message: {
            Text("Are you sure you want to end this session? You can still edit it later in history.")
        }
        .onAppear {
            loadLastLogs()
            loadTemplates()
            animatedProgress = progressFraction
        }
        .onChange(of: progressFraction) { _, newValue in
            withAnimation(.easeOut(duration: 0.7)) {
                animatedProgress = newValue
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(
                title: "Unlock Pro",
                subtitle: "Save workout history and unlock analytics.",
                features: [
                    "Save completed workouts",
                    "Full history access",
                    "Progress analytics"
                ],
                primaryTitle: "Unlock Pro",
                primaryAction: { attemptUnlockAndComplete() },
                secondaryTitle: "Finish Without Saving",
                secondaryRole: .destructive,
                secondaryAction: {
                    showingPaywall = false
                    discardSession()
                },
                showsRestore: true,
                restoreAction: { attemptRestoreAndComplete() },
                showsClose: true,
                closeAction: {
                    showingPaywall = false
                }
            )
        }
    }

    private var progressFraction: Double {
        let totalSets = logs.reduce(0) { $0 + $1.reps.count }
        guard totalSets > 0 else { return 0 }
        let completedSets = logs.reduce(0) { count, log in
            count + log.reps.filter { $0 > 0 }.count
        }
        return Double(completedSets) / Double(totalSets)
    }

    private var sessionControlBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(session.isCompleted ? Color.summitTextSecondary : Color.summitOrange)
                        .frame(width: 6, height: 6)
                    Text(session.isCompleted ? "Completed" : "Live Session")
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundStyle(Color.summitTextSecondary)
                }

                Spacer()

                if !session.isCompleted {
                    Button {
                        showingEndConfirmation = true
                    } label: {
                        Text("End Workout")
                            .font(.custom("Avenir Next", size: 12))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.summitBackground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.summitOrange)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.summitCardElevated)
                    Capsule()
                        .fill(Color.summitOrange)
                        .frame(width: max(8, geo.size.width * animatedProgress))
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(
            Color.summitBackground.opacity(0.98)
        )
    }

    private var sessionBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#0B0B0D"),
                    Color.summitBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.summitOrange.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 150, y: -180)
        }
        .ignoresSafeArea()
    }

    private func sectionHeader(title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.custom("Avenir Next", size: 13))
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitTextSecondary)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.summitOrange, Color.summitOrange.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .cornerRadius(1)
        }
        .padding(.bottom, 4)
    }

    private func infoCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.summitCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.summitOrange.opacity(0.12), lineWidth: 1)
                    )
            )
    }

    private func finishSession() {
        guard purchaseManager.isPro else {
            showingPaywall = true
            return
        }

        completeAndSaveSession()
    }

    private func completeAndSaveSession() {
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

    private func discardSession() {
        modelContext.delete(session)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error discarding session: \(error)")
        }
    }

    private func attemptUnlockAndComplete() {
        Task {
            await purchaseManager.purchase()
            if purchaseManager.isPro {
                showingPaywall = false
                completeAndSaveSession()
            }
        }
    }

    private func attemptRestoreAndComplete() {
        Task {
            await purchaseManager.restorePurchases()
            if purchaseManager.isPro {
                showingPaywall = false
                completeAndSaveSession()
            }
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
        VStack(alignment: .leading, spacing: 12) {
            Text(log.exerciseName)
                .font(.custom("Avenir Next", size: 17))
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitText)

            if let repRange {
                infoChip(text: repRange, systemImage: "repeat")
            }

            if let lastLog {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Last time")
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundStyle(Color.summitTextSecondary)

                    HStack(spacing: 10) {
                        if lastLog.usesBodyweight {
                            if lastLog.bodyweightKg > 0 {
                                infoChip(text: "BW \(formatWeight(lastLog.bodyweightKg))kg", systemImage: "person.fill")
                            }
                            if lastLog.weight != 0 {
                                infoChip(text: "+\(formatWeight(lastLog.weight))kg", systemImage: "scalemass")
                            }
                        } else {
                            infoChip(text: "\(formatWeight(lastLog.weight))kg", systemImage: "scalemass")
                        }
                        infoChip(text: repsSummary(lastLog.reps), systemImage: "clock.arrow.circlepath")
                    }
                }
            }

            if log.usesBodyweight {
                HStack {
                    Text("Bodyweight")
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundStyle(Color.summitTextSecondary)

                    Spacer()

                    TextField("0", value: $log.bodyweightKg, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.custom("Avenir Next", size: 15))
                        .foregroundStyle(Color.summitText)

                    Text("kg")
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundStyle(Color.summitTextSecondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.summitCardElevated)
                )

                HStack {
                    Text("External Weight")
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundStyle(Color.summitTextSecondary)

                    Spacer()

                    TextField("0", value: $log.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.custom("Avenir Next", size: 15))
                        .foregroundStyle(Color.summitText)

                    Text("kg")
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundStyle(Color.summitTextSecondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.summitCardElevated)
                )
            } else {
                HStack {
                    Text("Weight")
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundStyle(Color.summitTextSecondary)

                    Spacer()

                    TextField("0", value: $log.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.custom("Avenir Next", size: 15))
                        .foregroundStyle(Color.summitText)

                    Text("kg")
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundStyle(Color.summitTextSecondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.summitCardElevated)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Set")
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundStyle(Color.summitTextSecondary)
                    Spacer()
                    Text("Reps")
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundStyle(Color.summitTextSecondary)
                }

                ForEach(log.reps.indices, id: \.self) { index in
                    HStack {
                        Text("Set \(index + 1)")
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundStyle(Color.summitTextSecondary)
                            .frame(width: 60, alignment: .leading)

                        Spacer()

                        TextField("0", value: bindingForRep(index), format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.custom("Avenir Next", size: 15))
                            .foregroundStyle(Color.summitText)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.summitCardElevated)
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.summitCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.summitOrange.opacity(0.12), lineWidth: 1)
                )
        )
        .onChange(of: log.weight) { _, _ in
            persist()
        }
        .onChange(of: log.bodyweightKg) { _, _ in
            persist()
        }
        .onChange(of: log.reps) { _, _ in
            persist()
        }
    }

    private func infoChip(text: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption)
            Text(text)
                .font(.custom("Avenir Next", size: 12))
        }
        .foregroundStyle(Color.summitTextSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.summitCardElevated)
        )
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
        if log.usesBodyweight, log.bodyweightKg > 0 {
            log.definition.lastBodyweightKg = log.bodyweightKg
        }
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
    let workout = Workout(name: "Push Day", orderIndex: 0, planId: plan.id)
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
            .environmentObject(PurchaseManager())
    }
}
