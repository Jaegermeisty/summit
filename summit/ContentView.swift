//
//  ContentView.swift
//  summit
//
//  Created on 2025-10-14
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var workoutPlans: [WorkoutPlan]

    @State private var showingCreatePlan = false
    @State private var showingHistory = false
    @State private var showingAnalytics = false
    @State private var selectedSession: WorkoutSession?
    @State private var planToDelete: WorkoutPlan?
    @State private var showingDeleteConfirmation = false

    private var activePlan: WorkoutPlan? {
        workoutPlans.first(where: { $0.isActive })
    }

    private var otherPlans: [WorkoutPlan] {
        workoutPlans.filter { !$0.isActive }
    }

    var body: some View {
        NavigationStack {
            Group {
                if workoutPlans.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.summitBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        Button {
                            showingAnalytics = true
                        } label: {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(Color.summitOrange)
                        }
                        .accessibilityLabel("Analytics")

                        Button {
                            showingHistory = true
                        } label: {
                            Image(systemName: "clock")
                                .foregroundStyle(Color.summitOrange)
                        }
                        .accessibilityLabel("History")
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Summit")
                        .font(.system(size: 18, weight: .bold))
                        .italic()
                        .foregroundStyle(Color.summitOrange)
                        .fixedSize()
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreatePlan = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.summitOrange)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlan) {
                CreateWorkoutPlanView()
            }
            .sheet(isPresented: $showingAnalytics) {
                NavigationStack {
                    AnalyticsView()
                }
            }
            .sheet(isPresented: $showingHistory) {
                NavigationStack {
                    HistoryView()
                }
            }
            .navigationDestination(item: $selectedSession) { session in
                if let workout = DataHelpers.workout(with: session.workoutTemplateId, in: modelContext) {
                    WorkoutSessionView(session: session, workout: workout)
                } else {
                    WorkoutSessionView(session: session, workout: Workout(name: session.workoutTemplateName))
                }
            }
            .alert("Delete Workout Plan", isPresented: $showingDeleteConfirmation, presenting: planToDelete) { plan in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deletePlan(plan)
                }
            } message: { plan in
                Text("Are you sure you want to delete '\(plan.name)'? All workouts and exercises in this plan will be permanently deleted. This cannot be undone.")
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Workout Plans", systemImage: "figure.strengthtraining.traditional")
                .foregroundStyle(Color.summitText)
        } description: {
            Text("Create your first workout plan to start tracking your progress")
                .foregroundStyle(Color.summitTextSecondary)
        } actions: {
            Button {
                showingCreatePlan = true
            } label: {
                Text("Create Plan")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.summitOrange)
            .controlSize(.large)
        }
    }

    private var mainContentView: some View {
        List {
            Section {
                if let active = activePlan {
                    ActivePlanCardView(
                        plan: active,
                        nextWorkout: DataHelpers.nextWorkout(in: active, context: modelContext),
                        onStartWorkout: { workout in
                            selectedSession = DataHelpers.startSession(for: workout, in: modelContext)
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
                    .contextMenu {
                        Button(role: .destructive) {
                            planToDelete = active
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Plan", systemImage: "trash")
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Active Plan", systemImage: "flag.circle")
                            .foregroundStyle(Color.summitText)
                    } description: {
                        Text("Set a plan as active to show the next workout here")
                            .foregroundStyle(Color.summitTextSecondary)
                    }
                    .listRowBackground(Color.clear)
                }
            } header: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Plan")
                        .textCase(nil)
                        .font(.headline)
                        .foregroundStyle(Color.summitText)

                    Rectangle()
                        .fill(Color.summitOrange)
                        .frame(height: 2)
                }
                .padding(.bottom, 4)
            }

            if !otherPlans.isEmpty {
                Section {
                    ForEach(otherPlans) { plan in
                        NavigationLink(destination: WorkoutPlanDetailView(plan: plan)) {
                            PlanRowView(plan: plan)
                        }
                        .listRowBackground(Color.summitCard)
                        .contextMenu {
                            Button {
                                setActivePlan(plan)
                            } label: {
                                Label("Set as Active", systemImage: "star.fill")
                            }

                            Button(role: .destructive) {
                                planToDelete = plan
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Plan", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteOtherPlans)
                } header: {
                    Text("Other Plans")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                } footer: {
                    Text("Swipe left to delete • Long press to set active")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.summitBackground)
    }

    private func deleteOtherPlans(at offsets: IndexSet) {
        for index in offsets {
            let plan = otherPlans[index]
            planToDelete = plan
            showingDeleteConfirmation = true
        }
    }

    private func deletePlan(_ plan: WorkoutPlan) {
        modelContext.delete(plan)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting plan: \(error)")
        }
    }

    private func setActivePlan(_ plan: WorkoutPlan) {
        for p in workoutPlans {
            p.isActive = false
        }
        plan.isActive = true

        do {
            try modelContext.save()
        } catch {
            print("Error setting active plan: \(error)")
        }
    }
}

struct PlanRowView: View {
    @Bindable var plan: WorkoutPlan
    @Query private var workouts: [Workout]

    init(plan: WorkoutPlan) {
        _plan = Bindable(wrappedValue: plan)
        let planId = plan.id
        _workouts = Query(
            filter: #Predicate<Workout> { workout in
                workout.workoutPlan?.id == planId
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(plan.name)
                    .font(.headline)
                    .foregroundStyle(Color.summitText)

                if plan.isActive {
                    Spacer()

                    Text("Active")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.summitOrange)
                        )
                }
            }

            if let description = plan.planDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                Label("\(workouts.count)", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(Color.summitTextTertiary)

                Text(workouts.count == 1 ? "workout" : "workouts")
                    .font(.caption)
                    .foregroundStyle(Color.summitTextTertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActivePlanCardView: View {
    @Environment(\.modelContext) private var modelContext
    let plan: WorkoutPlan
    let nextWorkout: Workout?
    let onStartWorkout: (Workout) -> Void

    private var workoutCount: Int {
        DataHelpers.workouts(for: plan, in: modelContext).count
    }

    private var activePhaseName: String? {
        DataHelpers.activePhase(for: plan, in: modelContext)?.name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(plan.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.summitText)

                    Spacer()

                    NavigationLink(destination: WorkoutPlanDetailView(plan: plan)) {
                        Image(systemName: "chevron.right")
                            .font(.body)
                            .foregroundStyle(Color.summitTextSecondary)
                    }
                }

                if let description = plan.planDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                        .lineLimit(2)
                }

                if let phaseName = activePhaseName {
                    Text("Phase: \(phaseName)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.summitTextSecondary)
                }

                HStack(spacing: 12) {
                    Label("\(workoutCount)", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)

                    Text(workoutCount == 1 ? "workout" : "workouts")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
            }

            if let workout = nextWorkout {
                let exerciseCount = DataHelpers.exercises(for: workout, in: modelContext).count
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Workout")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.summitTextTertiary)
                        .textCase(.uppercase)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workout.name)
                                .font(.headline)
                                .foregroundStyle(Color.summitText)

                            Text("\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(Color.summitTextSecondary)
                        }

                        Spacer()
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.summitOrange.opacity(0.15))
                )

                Button {
                    onStartWorkout(workout)
                } label: {
                    HStack {
                        Spacer()
                        Label("Start Workout", systemImage: "play.fill")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                }
                .background(Color.summitOrange)
                .cornerRadius(10)
            } else {
                Text("Add workouts to this plan to get started")
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)
                    .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.summitCardElevated)
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainer.preview)
}
