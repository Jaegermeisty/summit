//
//  AnalyticsView.swift
//  Summit
//
//  Created on 2026-02-08
//

import SwiftUI
import SwiftData
import Charts

private enum AnalyticsMode: String, CaseIterable, Identifiable {
    case exercise = "Exercise"
    case plan = "Plan"

    var id: String { rawValue }
}

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Query(sort: \ExerciseDefinition.name, order: .forward) private var definitions: [ExerciseDefinition]
    @Query(
        filter: #Predicate<WorkoutPlan> { plan in
            plan.isArchived == false
        },
        sort: \WorkoutPlan.createdAt,
        order: .reverse
    ) private var plans: [WorkoutPlan]

    @State private var mode: AnalyticsMode = .exercise
    @State private var selectedExerciseId: UUID?
    @State private var selectedPlanId: UUID?
    @AppStorage("pinnedExerciseIds") private var pinnedExerciseIdsData: Data = Data()

    @State private var exerciseSeries: [ExerciseMetricPoint] = []
    @State private var planSeries: [PlanMetricPoint] = []
    @State private var showingPlanStrengthInfo = false
    @State private var showingPlanVolumeInfo = false
    @State private var showingExerciseInfo = false
    @State private var showingExercisePicker = false
    @State private var selectedExercisePoint: ExerciseMetricPoint?
    @State private var selectedPlanStrengthPoint: PlanMetricPoint?
    @State private var selectedPlanVolumePoint: PlanMetricPoint?

    var body: some View {
        VStack(spacing: 16) {
            if purchaseManager.isPro {
                Picker("Mode", selection: $mode) {
                    ForEach(AnalyticsMode.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }

            if purchaseManager.isPro {
                if mode == .exercise {
                    exerciseSection
                } else {
                    planSection
                }
            } else {
                analyticsPaywall
            }

            Spacer()
        }
        .background(Color.summitBackground)
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.summitBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Summit")
                    .font(.system(size: 18, weight: .bold))
                    .italic()
                    .foregroundStyle(Color.summitOrange)
                    .fixedSize()
            }
        }
        .onAppear {
            if selectedExerciseId == nil {
                selectedExerciseId = definitions.first?.id
            }
            if selectedPlanId == nil {
                selectedPlanId = plans.first?.id
            }
            prunePinnedIds(using: definitions)
            reloadExerciseSeries()
            reloadPlanSeries()
        }
        .onChange(of: definitions) { _, newDefinitions in
            prunePinnedIds(using: newDefinitions)
            if selectedExerciseId == nil || !newDefinitions.contains(where: { $0.id == selectedExerciseId }) {
                selectedExerciseId = newDefinitions.first?.id
            }
        }
        .onChange(of: plans) { _, newPlans in
            if selectedPlanId == nil || !newPlans.contains(where: { $0.id == selectedPlanId }) {
                selectedPlanId = newPlans.first?.id
            }
        }
        .onChange(of: selectedExerciseId) { _, _ in
            reloadExerciseSeries()
        }
        .onChange(of: selectedPlanId) { _, _ in
            reloadPlanSeries()
        }
    }

    private var exerciseSection: some View {
        let pinnedIds = pinnedExerciseIds

        return VStack(spacing: 16) {
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Text("Exercise")
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                    Button {
                        showingExerciseInfo = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(Color.summitTextSecondary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    Button {
                        showingExercisePicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedExerciseName)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.summitOrange)
                    }
                    .buttonStyle(.plain)

                    Button {
                        togglePinForSelectedExercise()
                    } label: {
                        Image(systemName: isSelectedExercisePinned ? "pin.slash" : "pin")
                            .foregroundStyle(isSelectedExercisePinned ? Color.summitTextSecondary : Color.summitOrange)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedExerciseId == nil)
                }
            }
            .padding(.horizontal)

            if exerciseSeries.isEmpty {
                ContentUnavailableView {
                    Label("No Exercise Data", systemImage: "chart.line.uptrend.xyaxis")
                } description: {
                    Text("Complete a workout to see your progress here")
                }
                .padding(.top, 20)
            } else {
                Chart(exerciseSeries) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", point.oneRepMax)
                    )
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", point.oneRepMax)
                    )

                    if let selected = selectedExercisePoint {
                        RuleMark(x: .value("Date", selected.date))
                            .foregroundStyle(Color.summitOrange.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                        PointMark(
                            x: .value("Date", selected.date),
                            y: .value("1RM", selected.oneRepMax)
                        )
                        .symbolSize(60)
                        .foregroundStyle(Color.summitOrange)
                        .annotation(position: .top, alignment: .leading) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selected.date, format: .dateTime.month().day())
                                    .font(.caption2)
                                    .foregroundStyle(Color.summitTextSecondary)
                                Text("\(Int(selected.oneRepMax)) 1RM")
                                    .font(.caption)
                                    .foregroundStyle(Color.summitText)
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.summitCardElevated)
                            )
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        if let plotFrameAnchor = proxy.plotFrame {
                            let plotFrame = geometry[plotFrameAnchor]
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let x = value.location.x - plotFrame.origin.x
                                            guard x >= 0, x <= plotFrame.size.width else { return }
                                            if let date: Date = proxy.value(atX: x) {
                                                selectedExercisePoint = nearestExercisePoint(to: date)
                                            }
                                        }
                                        .onEnded { _ in
                                            selectedExercisePoint = nil
                                        }
                                )
                        }
                    }
                }
                .frame(height: 260)
                .padding(.horizontal)
            }
        }
        .alert("Exercise Progress", isPresented: $showingExerciseInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Each point shows your best-set estimated 1RM for that exercise on that day (weight × (1 + reps/30)).")
        }
        .sheet(isPresented: $showingExercisePicker) {
            exercisePickerSheet(pinnedIds: pinnedIds)
        }
    }

    private var planSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Plan")
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)

                Spacer()

                Picker("Plan", selection: $selectedPlanId) {
                    Text("Select Plan").tag(Optional<UUID>.none)
                    ForEach(plans) { plan in
                        Text(plan.name).tag(Optional(plan.id))
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal)

            if planSeries.isEmpty {
                ContentUnavailableView {
                    Label("No Plan Data", systemImage: "chart.bar.xaxis")
                } description: {
                    Text("Complete workouts in this plan to see progress")
                }
                .padding(.top, 20)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Text("Plan Strength Score")
                            .font(.subheadline)
                            .foregroundStyle(Color.summitTextSecondary)
                        Button {
                            showingPlanStrengthInfo = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(Color.summitTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    strengthChart

                    HStack(spacing: 6) {
                        Text("Plan Volume")
                            .font(.subheadline)
                            .foregroundStyle(Color.summitTextSecondary)
                        Button {
                            showingPlanVolumeInfo = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(Color.summitTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    volumeChart
                }
            }
        }
        .alert("Plan Strength Score", isPresented: $showingPlanStrengthInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("One point per full plan cycle. For each workout in the cycle, we take each exercise’s best set and estimate 1RM (weight × (1 + reps/30)). The score is the sum of those estimates across the cycle. Big lifts naturally contribute more.")
        }
        .alert("Plan Volume", isPresented: $showingPlanVolumeInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("One point per full plan cycle. Total volume is the sum of weight × reps across all sets and exercises in that cycle.")
        }
    }

    private var analyticsPaywall: some View {
        PaywallView(
            title: "Unlock Analytics",
            subtitle: "See your progress over time with exercise and plan analytics.",
            features: [
                "Exercise 1RM trends",
                "Plan strength score",
                "Plan volume tracking"
            ],
            primaryTitle: "Unlock Pro",
            primaryAction: {
                Task { await purchaseManager.purchase() }
            },
            showsRestore: true,
            restoreAction: {
                Task { await purchaseManager.restorePurchases() }
            }
        )
    }

    private var pinnedExerciseIds: Set<UUID> {
        guard !pinnedExerciseIdsData.isEmpty else { return [] }
        let decoded = (try? JSONDecoder().decode([UUID].self, from: pinnedExerciseIdsData)) ?? []
        return Set(decoded)
    }

    private var isSelectedExercisePinned: Bool {
        guard let selectedExerciseId else { return false }
        return pinnedExerciseIds.contains(selectedExerciseId)
    }

    private func togglePinForSelectedExercise() {
        guard let selectedExerciseId else { return }
        var ids = pinnedExerciseIds
        if ids.contains(selectedExerciseId) {
            ids.remove(selectedExerciseId)
        } else {
            ids.insert(selectedExerciseId)
        }
        setPinnedExerciseIds(ids)
    }

    private func prunePinnedIds(using definitions: [ExerciseDefinition]) {
        let existing = Set(definitions.map(\.id))
        let filtered = pinnedExerciseIds.intersection(existing)
        if filtered != pinnedExerciseIds {
            setPinnedExerciseIds(filtered)
        }
    }

    private func setPinnedExerciseIds(_ ids: Set<UUID>) {
        pinnedExerciseIdsData = (try? JSONEncoder().encode(Array(ids))) ?? Data()
    }

    private var selectedExerciseName: String {
        guard let selectedExerciseId else { return "Select Exercise" }
        return definitions.first(where: { $0.id == selectedExerciseId })?.name ?? "Select Exercise"
    }

    private func exercisePickerSheet(pinnedIds: Set<UUID>) -> some View {
        let pinned = definitions.filter { pinnedIds.contains($0.id) }
        let unpinned = definitions.filter { !pinnedIds.contains($0.id) }

        return NavigationStack {
            List {
                if !pinned.isEmpty {
                    Section("Pinned") {
                        ForEach(pinned) { definition in
                            Button {
                                selectedExerciseId = definition.id
                                showingExercisePicker = false
                            } label: {
                                HStack {
                                    Label(definition.name, systemImage: "pin.fill")
                                    Spacer()
                                    if selectedExerciseId == definition.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.summitOrange)
                                    }
                                }
                            }
                            .listRowBackground(Color.summitCard)
                        }
                    }
                }

                if !unpinned.isEmpty {
                    Section(pinned.isEmpty ? "Exercises" : "All Exercises") {
                        ForEach(unpinned) { definition in
                            Button {
                                selectedExerciseId = definition.id
                                showingExercisePicker = false
                            } label: {
                                HStack {
                                    Text(definition.name)
                                    Spacer()
                                    if selectedExerciseId == definition.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.summitOrange)
                                    }
                                }
                            }
                            .listRowBackground(Color.summitCard)
                        }
                    }
                }

                if pinned.isEmpty && unpinned.isEmpty {
                    ContentUnavailableView {
                        Label("No Exercises", systemImage: "dumbbell")
                    } description: {
                        Text("Add exercises to see them here.")
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.summitBackground)
            .navigationTitle("Choose Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.summitBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showingExercisePicker = false
                    }
                }
            }
        }
    }

    private var strengthChart: some View {
        Chart(planSeries) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Strength", point.strengthScore)
            )
            PointMark(
                x: .value("Date", point.date),
                y: .value("Strength", point.strengthScore)
            )

            if let selected = selectedPlanStrengthPoint {
                RuleMark(x: .value("Date", selected.date))
                    .foregroundStyle(Color.summitOrange.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("Strength", selected.strengthScore)
                )
                .symbolSize(60)
                .foregroundStyle(Color.summitOrange)
                .annotation(position: .top, alignment: .leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selected.date, format: .dateTime.month().day())
                            .font(.caption2)
                            .foregroundStyle(Color.summitTextSecondary)
                        Text("\(Int(selected.strengthScore)) strength")
                            .font(.caption)
                            .foregroundStyle(Color.summitText)
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.summitCardElevated)
                    )
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartYScale(domain: planStrengthDomain)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let plotFrameAnchor = proxy.plotFrame {
                    let plotFrame = geometry[plotFrameAnchor]
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let x = value.location.x - plotFrame.origin.x
                                    guard x >= 0, x <= plotFrame.size.width else { return }
                                    if let date: Date = proxy.value(atX: x) {
                                        selectedPlanStrengthPoint = nearestPlanPoint(to: date)
                                    }
                                }
                                .onEnded { _ in
                                    selectedPlanStrengthPoint = nil
                                }
                        )
                }
            }
        }
        .frame(height: 220)
        .padding(.horizontal)
    }

    private var volumeChart: some View {
        Chart(planSeries) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Volume", point.volume)
            )
            PointMark(
                x: .value("Date", point.date),
                y: .value("Volume", point.volume)
            )

            if let selected = selectedPlanVolumePoint {
                RuleMark(x: .value("Date", selected.date))
                    .foregroundStyle(Color.summitOrange.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("Volume", selected.volume)
                )
                .symbolSize(60)
                .foregroundStyle(Color.summitOrange)
                .annotation(position: .top, alignment: .leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selected.date, format: .dateTime.month().day())
                            .font(.caption2)
                            .foregroundStyle(Color.summitTextSecondary)
                        Text("\(Int(selected.volume)) volume")
                            .font(.caption)
                            .foregroundStyle(Color.summitText)
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.summitCardElevated)
                    )
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartYScale(domain: planVolumeDomain)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let plotFrameAnchor = proxy.plotFrame {
                    let plotFrame = geometry[plotFrameAnchor]
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let x = value.location.x - plotFrame.origin.x
                                    guard x >= 0, x <= plotFrame.size.width else { return }
                                    if let date: Date = proxy.value(atX: x) {
                                        selectedPlanVolumePoint = nearestPlanPoint(to: date)
                                    }
                                }
                                .onEnded { _ in
                                    selectedPlanVolumePoint = nil
                                }
                        )
                }
            }
        }
        .frame(height: 220)
        .padding(.horizontal)
    }

    private func reloadExerciseSeries() {
        guard let selectedExerciseId,
              let definition = definitions.first(where: { $0.id == selectedExerciseId }) else {
            exerciseSeries = []
            return
        }

        let logs = DataHelpers.exerciseHistory(for: definition.name, in: modelContext)
        let points = logs.compactMap { log -> ExerciseMetricPoint? in
            guard let session = log.session, session.isCompleted else { return nil }
            return ExerciseMetricPoint(
                date: session.date,
                oneRepMax: log.estimatedOneRepMax
            )
        }
        exerciseSeries = points.sorted(by: { $0.date < $1.date })
    }

    private func reloadPlanSeries() {
        guard let selectedPlanId,
              let plan = plans.first(where: { $0.id == selectedPlanId }) else {
            planSeries = []
            return
        }

        let sessions = DataHelpers.completedSessions(for: plan, in: modelContext)
            .sorted(by: { $0.date < $1.date })
        let phases = DataHelpers.phases(for: plan, in: modelContext)
        var phasesById: [UUID: PlanPhase] = [:]
        for phase in phases {
            phasesById[phase.id] = phase
        }

        var points: [PlanMetricPoint] = []
        var currentPhaseKey: String?
        var expectedWorkoutIds: Set<UUID> = []
        var cycleSessionsByWorkout: [UUID: WorkoutSession] = [:]

        func workoutIdsForPhaseKey(_ phaseKey: String?) -> Set<UUID> {
            if let phaseKey, let phaseId = UUID(uuidString: phaseKey),
               let phase = phasesById[phaseId] {
                let workouts = DataHelpers.workouts(for: plan, in: modelContext, phase: phase)
                return Set(workouts.map(\.id))
            }
            let workouts = DataHelpers.workouts(for: plan, in: modelContext, phase: nil)
            return Set(workouts.map(\.id))
        }

        func closeCycleIfComplete() {
            guard !expectedWorkoutIds.isEmpty,
                  cycleSessionsByWorkout.count == expectedWorkoutIds.count else { return }

            let cycleSessions = expectedWorkoutIds.compactMap { cycleSessionsByWorkout[$0] }
            let strengthScore = cycleSessions.reduce(0.0) { total, session in
                let logs = DataHelpers.logs(for: session, in: modelContext)
                return total + logs.reduce(0.0) { partial, log in
                    partial + log.estimatedOneRepMax
                }
            }
            let volume = cycleSessions.reduce(0.0) { total, session in
                let logs = DataHelpers.logs(for: session, in: modelContext)
                return total + logs.reduce(0.0) { partial, log in
                    partial + (log.weight * Double(log.reps.reduce(0, +)))
                }
            }
            let cycleDate = cycleSessions.map(\.date).max() ?? Date()
            points.append(PlanMetricPoint(date: cycleDate, volume: volume, strengthScore: strengthScore))
            cycleSessionsByWorkout.removeAll()
        }

        for session in sessions {
            let phaseKey = session.phaseId?.uuidString
            if expectedWorkoutIds.isEmpty {
                currentPhaseKey = phaseKey
                expectedWorkoutIds = workoutIdsForPhaseKey(phaseKey)
            } else if currentPhaseKey != phaseKey {
                // Phase changed: close only if complete, otherwise discard in-progress cycle.
                closeCycleIfComplete()
                cycleSessionsByWorkout.removeAll()
                currentPhaseKey = phaseKey
                expectedWorkoutIds = workoutIdsForPhaseKey(phaseKey)
            }

            guard !expectedWorkoutIds.isEmpty else { continue }
            guard expectedWorkoutIds.contains(session.workoutTemplateId) else { continue }

            // If a workout repeats before the cycle completes, use the latest session.
            cycleSessionsByWorkout[session.workoutTemplateId] = session

            closeCycleIfComplete()
        }

        planSeries = points.sorted(by: { $0.date < $1.date })
    }

    private func nearestExercisePoint(to date: Date) -> ExerciseMetricPoint? {
        guard !exerciseSeries.isEmpty else { return nil }
        return exerciseSeries.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    private func nearestPlanPoint(to date: Date) -> PlanMetricPoint? {
        guard !planSeries.isEmpty else { return nil }
        return planSeries.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    private var planStrengthDomain: ClosedRange<Double> {
        let values = planSeries.map(\.strengthScore)
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...1
        }
        return paddedDomain(min: minValue, max: maxValue, floor: 0)
    }

    private var planVolumeDomain: ClosedRange<Double> {
        let values = planSeries.map(\.volume)
        guard let maxValue = values.max() else {
            return 0...1
        }
        let upper = maxValue == 0 ? 1 : maxValue * 1.08
        return 0...upper
    }

    private func paddedDomain(min minValue: Double, max maxValue: Double, floor: Double) -> ClosedRange<Double> {
        if minValue == maxValue {
            let pad = maxValue == 0 ? 1 : maxValue * 0.05
            let lower = Swift.max(0, minValue - pad)
            let upper = maxValue + pad
            return Swift.max(lower, floor)...Swift.max(upper, floor + 1)
        }

        let pad = (maxValue - minValue) * 0.1
        let lower = Swift.max(floor, minValue - pad)
        let upper = maxValue + pad
        return lower...upper
    }
}

private struct ExerciseMetricPoint: Identifiable {
    let id = UUID()
    let date: Date
    let oneRepMax: Double
}

private struct PlanMetricPoint: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Double
    let strengthScore: Double
}

#Preview {
    NavigationStack {
        AnalyticsView()
            .modelContainer(ModelContainer.preview)
    }
}
