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
    @AppStorage(WeightUnit.storageKey) private var weightUnitRaw: String = WeightUnit.kg.rawValue

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

    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    var body: some View {
        analyticsContent
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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

    private var analyticsContent: some View {
        ZStack {
            analyticsBackground

            ScrollView {
                VStack(spacing: 20) {
                    analyticsModePicker

                    if mode == .exercise {
                        exerciseSection
                    } else {
                        planSection
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private var exerciseSection: some View {
        let pinnedIds = pinnedExerciseIds

        return VStack(spacing: 16) {
            infoCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Text("Exercise")
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundStyle(Color.summitTextSecondary)
                        Button {
                            showingExerciseInfo = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(Color.summitTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 10) {
                        Button {
                            showingExercisePicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Text(selectedExerciseName)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .font(.custom("Avenir Next", size: 16))
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

                        Button {
                            togglePinForSelectedExercise()
                        } label: {
                            Image(systemName: isSelectedExercisePinned ? "pin.slash" : "pin")
                                .foregroundStyle(isSelectedExercisePinned ? Color.summitTextSecondary : Color.summitOrange)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.summitCardElevated)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedExerciseId == nil)
                    }
                }
            }
            .padding(.horizontal, 16)

            if !purchaseManager.isPro {
                infoCard {
                    lockedAnalyticsCard(
                        title: "Unlock Pro",
                        message: "See exercise 1RM trends and progress over time.",
                        actionTitle: "Unlock Pro"
                    )
                }
                .padding(.horizontal, 16)
            } else if exerciseSeries.isEmpty {
                infoCard {
                    ContentUnavailableView {
                        Label("No Exercise Data", systemImage: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(Color.summitText)
                    } description: {
                        Text("Complete a workout to see your progress here")
                            .foregroundStyle(Color.summitTextSecondary)
                    }
                }
                .padding(.horizontal, 16)
            } else {
                infoCard {
                    Chart(exerciseSeries) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("1RM", weightUnit.fromKg(point.oneRepMax))
                        )
                        .foregroundStyle(Color.summitOrange)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("1RM", weightUnit.fromKg(point.oneRepMax))
                        )
                        .foregroundStyle(Color.summitOrange)

                        if let selected = selectedExercisePoint {
                            RuleMark(x: .value("Date", selected.date))
                                .foregroundStyle(Color.summitOrange.opacity(0.3))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                            PointMark(
                                x: .value("Date", selected.date),
                                y: .value("1RM", weightUnit.fromKg(selected.oneRepMax))
                            )
                            .symbolSize(60)
                            .foregroundStyle(Color.summitOrange)
                            .annotation(position: .top, alignment: .leading) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selected.date, format: .dateTime.month().day())
                                        .font(.caption2)
                                        .foregroundStyle(Color.summitTextSecondary)
                                    Text("\(weightUnit.format(selected.oneRepMax)) \(weightUnit.symbol)")
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
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine()
                                .foregroundStyle(Color.summitTextTertiary.opacity(0.2))
                            AxisValueLabel(format: .dateTime.month().day())
                                .foregroundStyle(Color.summitTextSecondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine()
                                .foregroundStyle(Color.summitTextTertiary.opacity(0.2))
                            AxisValueLabel()
                                .foregroundStyle(Color.summitTextSecondary)
                        }
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
                    .frame(height: 240)
                }
                .padding(.horizontal, 16)
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
            infoCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Plan")
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundStyle(Color.summitTextSecondary)

                    Menu {
                        ForEach(plans) { plan in
                            Button(plan.name) {
                                selectedPlanId = plan.id
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedPlanName)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .font(.custom("Avenir Next", size: 16))
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
            .padding(.horizontal, 16)

            if !purchaseManager.isPro {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Text("Plan Strength Score")
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundStyle(Color.summitTextSecondary)
                        Button {
                            showingPlanStrengthInfo = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(Color.summitTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    infoCard {
                        lockedAnalyticsCard(
                            title: "Unlock Pro",
                            message: "See plan strength score over each full cycle.",
                            actionTitle: "Unlock Pro"
                        )
                    }
                    .padding(.horizontal, 16)

                    HStack(spacing: 6) {
                        Text("Plan Volume")
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundStyle(Color.summitTextSecondary)
                        Button {
                            showingPlanVolumeInfo = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(Color.summitTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    infoCard {
                        lockedAnalyticsCard(
                            title: "Unlock Pro",
                            message: "Track plan volume trends across cycles.",
                            actionTitle: "Unlock Pro"
                        )
                    }
                    .padding(.horizontal, 16)
                }
            } else if planSeries.isEmpty {
                infoCard {
                    ContentUnavailableView {
                        Label("No Plan Data", systemImage: "chart.bar.xaxis")
                            .foregroundStyle(Color.summitText)
                    } description: {
                        Text("Complete workouts in this plan to see progress")
                            .foregroundStyle(Color.summitTextSecondary)
                    }
                }
                .padding(.horizontal, 16)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Text("Plan Strength Score")
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundStyle(Color.summitTextSecondary)
                        Button {
                            showingPlanStrengthInfo = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(Color.summitTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    infoCard {
                        strengthChart
                    }
                    .padding(.horizontal, 16)

                    HStack(spacing: 6) {
                        Text("Plan Volume")
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundStyle(Color.summitTextSecondary)
                        Button {
                            showingPlanVolumeInfo = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(Color.summitTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    infoCard {
                        volumeChart
                    }
                    .padding(.horizontal, 16)
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

    private var selectedPlanName: String {
        guard let selectedPlanId else { return "Select Plan" }
        return plans.first(where: { $0.id == selectedPlanId })?.name ?? "Select Plan"
    }

    private func exercisePickerSheet(pinnedIds: Set<UUID>) -> some View {
        let pinned = definitions.filter { pinnedIds.contains($0.id) }
        let unpinned = definitions.filter { !pinnedIds.contains($0.id) }

        return NavigationStack {
            ZStack {
                analyticsBackground

                List {
                    if !pinned.isEmpty {
                        Section {
                            ForEach(pinned) { definition in
                                exercisePickerRow(definition, pinned: true)
                            }
                        } header: {
                            sectionHeader(title: "Pinned")
                        }
                    }

                    if !unpinned.isEmpty {
                        Section {
                            ForEach(unpinned) { definition in
                                exercisePickerRow(definition, pinned: false)
                            }
                        } header: {
                            sectionHeader(title: pinned.isEmpty ? "Exercises" : "All Exercises")
                        }
                    }

                    if pinned.isEmpty && unpinned.isEmpty {
                        infoCard {
                            ContentUnavailableView {
                                Label("No Exercises", systemImage: "dumbbell")
                                    .foregroundStyle(Color.summitText)
                            } description: {
                                Text("Add exercises to see them here.")
                                    .foregroundStyle(Color.summitTextSecondary)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Choose Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
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
                y: .value("Strength", weightUnit.fromKg(point.strengthScore))
            )
            .foregroundStyle(Color.summitOrange)
            PointMark(
                x: .value("Date", point.date),
                y: .value("Strength", weightUnit.fromKg(point.strengthScore))
            )
            .foregroundStyle(Color.summitOrange)

            if let selected = selectedPlanStrengthPoint {
                RuleMark(x: .value("Date", selected.date))
                    .foregroundStyle(Color.summitOrange.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("Strength", weightUnit.fromKg(selected.strengthScore))
                )
                .symbolSize(60)
                .foregroundStyle(Color.summitOrange)
                .annotation(position: .top, alignment: .leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selected.date, format: .dateTime.month().day())
                            .font(.caption2)
                            .foregroundStyle(Color.summitTextSecondary)
                        Text("\(weightUnit.format(selected.strengthScore)) \(weightUnit.symbol)")
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
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.summitTextTertiary.opacity(0.2))
                AxisValueLabel(format: .dateTime.month().day())
                    .foregroundStyle(Color.summitTextSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.summitTextTertiary.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(Color.summitTextSecondary)
            }
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
    }

    private var volumeChart: some View {
        Chart(planSeries) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Volume", weightUnit.fromKg(point.volume))
            )
            .foregroundStyle(Color.summitOrange)
            PointMark(
                x: .value("Date", point.date),
                y: .value("Volume", weightUnit.fromKg(point.volume))
            )
            .foregroundStyle(Color.summitOrange)

            if let selected = selectedPlanVolumePoint {
                RuleMark(x: .value("Date", selected.date))
                    .foregroundStyle(Color.summitOrange.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("Volume", weightUnit.fromKg(selected.volume))
                )
                .symbolSize(60)
                .foregroundStyle(Color.summitOrange)
                .annotation(position: .top, alignment: .leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selected.date, format: .dateTime.month().day())
                            .font(.caption2)
                            .foregroundStyle(Color.summitTextSecondary)
                        Text("\(weightUnit.format(selected.volume)) \(weightUnit.symbol)")
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
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.summitTextTertiary.opacity(0.2))
                AxisValueLabel(format: .dateTime.month().day())
                    .foregroundStyle(Color.summitTextSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.summitTextTertiary.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(Color.summitTextSecondary)
            }
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
    }

    private var analyticsModePicker: some View {
        HStack(spacing: 8) {
            ForEach(AnalyticsMode.allCases) { option in
                Button {
                    mode = option
                } label: {
                    Text(option.rawValue)
                        .font(.custom("Avenir Next", size: 14))
                        .fontWeight(mode == option ? .semibold : .regular)
                        .foregroundStyle(mode == option ? Color.summitText : Color.summitTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(mode == option ? Color.summitCardElevated : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.summitCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.summitOrange.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    private func exercisePickerRow(_ definition: ExerciseDefinition, pinned: Bool) -> some View {
        Button {
            selectedExerciseId = definition.id
            showingExercisePicker = false
        } label: {
            HStack(spacing: 12) {
                if pinned {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(Color.summitOrange)
                }
                Text(definition.name)
                    .font(.custom("Avenir Next", size: 15))
                    .foregroundStyle(Color.summitText)
                Spacer()
                if selectedExerciseId == definition.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.summitOrange)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.summitCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.summitOrange.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var analyticsBackground: some View {
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
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 150, y: -160)
        }
        .ignoresSafeArea()
    }

    private func sectionHeader(title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.custom("Avenir Next", size: 12))
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

    private func lockedAnalyticsCard(title: String, message: String, actionTitle: String) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.summitOrange.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color.summitOrange)
            }

            Text(title)
                .font(.custom("Avenir Next", size: 18))
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitText)

            Text(message)
                .font(.custom("Avenir Next", size: 13))
                .foregroundStyle(Color.summitTextSecondary)
                .multilineTextAlignment(.center)

            Button(actionTitle) {
                Task { await purchaseManager.purchase() }
            }
            .font(.custom("Avenir Next", size: 14))
            .fontWeight(.semibold)
            .foregroundStyle(Color.summitBackground)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.summitOrange)
            )
            .buttonStyle(.plain)

            Button("Restore Purchase") {
                Task { await purchaseManager.restorePurchases() }
            }
            .font(.custom("Avenir Next", size: 12))
            .foregroundStyle(Color.summitTextTertiary)
        }
        .frame(maxWidth: .infinity)
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
                    partial + (log.effectiveLoad * Double(log.reps.reduce(0, +)))
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
        let values = planSeries.map { weightUnit.fromKg($0.strengthScore) }
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...1
        }
        return paddedDomain(min: minValue, max: maxValue, floor: 0)
    }

    private var planVolumeDomain: ClosedRange<Double> {
        let values = planSeries.map { weightUnit.fromKg($0.volume) }
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
