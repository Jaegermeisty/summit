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
    @State private var planToDelete: WorkoutPlan?
    @State private var showingDeleteConfirmation = false
    @State private var sessionToStart: WorkoutSession?
    @State private var animateIn = false

    private var activePlan: WorkoutPlan? {
        workoutPlans.first(where: { $0.isActive && !$0.isArchived })
    }

    private var otherPlans: [WorkoutPlan] {
        workoutPlans.filter { !$0.isActive && !$0.isArchived }
    }

    private var archivedPlans: [WorkoutPlan] {
        workoutPlans.filter { $0.isArchived }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                homeBackground

                Group {
                    if workoutPlans.isEmpty {
                        emptyStateView
                    } else {
                        mainContentView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.summitBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingHistory = true
                    } label: {
                        Image(systemName: "clock")
                            .foregroundStyle(Color.summitOrange)
                    }
                    .accessibilityLabel("History")
                }

                ToolbarItem(placement: .principal) {
                    Text("Summit")
                        .font(.custom("Avenir Next", size: 18))
                        .fontWeight(.bold)
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
            .sheet(isPresented: $showingHistory) {
                NavigationStack {
                    HistoryView()
                }
            }
            .navigationDestination(item: $sessionToStart) { session in
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
                Text("Are you sure you want to delete '\(plan.name)'? All workouts and exercises in this plan will be permanently deleted. Exercise history will be kept. This cannot be undone.")
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateIn = true
                }
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Workout Plans", systemImage: "figure.strengthtraining.traditional")
                .foregroundStyle(Color.summitText)
                .font(.custom("Avenir Next", size: 16))
        } description: {
            Text("Create your first workout plan to start tracking your progress")
                .foregroundStyle(Color.summitTextSecondary)
                .font(.custom("Avenir Next", size: 14))
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
                        startSession: { workout in
                            sessionToStart = DataHelpers.startSession(for: workout, in: modelContext)
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 14)
                    .contextMenu {
                        Button {
                            archivePlan(active)
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }

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
                            .font(.custom("Avenir Next", size: 16))
                    } description: {
                        Text("Set a plan as active to show the next workout here")
                            .foregroundStyle(Color.summitTextSecondary)
                            .font(.custom("Avenir Next", size: 14))
                    }
                    .listRowBackground(Color.clear)
                }
            } header: {
                sectionHeader(title: "Active Plan")
            }

            if !otherPlans.isEmpty {
                Section {
                    ForEach(otherPlans) { plan in
                        NavigationLink(destination: WorkoutPlanDetailView(plan: plan)) {
                            PlanRowView(plan: plan)
                        }
                        .listRowBackground(Color.clear)
                        .contextMenu {
                            Button {
                                setActivePlan(plan)
                            } label: {
                                Label("Set as Active", systemImage: "star.fill")
                            }

                            Button {
                                archivePlan(plan)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }

                            Button(role: .destructive) {
                                planToDelete = plan
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Plan", systemImage: "trash")
                            }
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)
                        .animation(.easeOut(duration: 0.5).delay(0.05), value: animateIn)
                    }
                    .onDelete(perform: deleteOtherPlans)
                } header: {
                    sectionHeader(title: "Other Plans")
                }
            }

            if !archivedPlans.isEmpty {
                Section {
                    ForEach(archivedPlans) { plan in
                        NavigationLink(destination: WorkoutPlanDetailView(plan: plan)) {
                            PlanRowView(plan: plan)
                        }
                        .listRowBackground(Color.clear)
                        .contextMenu {
                            Button {
                                restorePlan(plan)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.left")
                            }

                            Button {
                                restoreAndActivatePlan(plan)
                            } label: {
                                Label("Restore & Set Active", systemImage: "star.fill")
                            }

                            Button(role: .destructive) {
                                planToDelete = plan
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Plan", systemImage: "trash")
                            }
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)
                        .animation(.easeOut(duration: 0.5).delay(0.08), value: animateIn)
                    }
                    .onDelete(perform: deleteArchivedPlans)
                } header: {
                    sectionHeader(title: "Archived Plans")
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private var homeBackground: some View {
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
                .fill(Color.summitOrange.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 160, y: -120)

            Circle()
                .fill(Color.summitOrange.opacity(0.08))
                .frame(width: 220, height: 220)
                .blur(radius: 80)
                .offset(x: -160, y: 220)
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

    private func deleteOtherPlans(at offsets: IndexSet) {
        for index in offsets {
            let plan = otherPlans[index]
            planToDelete = plan
            showingDeleteConfirmation = true
        }
    }

    private func deleteArchivedPlans(at offsets: IndexSet) {
        for index in offsets {
            let plan = archivedPlans[index]
            planToDelete = plan
            showingDeleteConfirmation = true
        }
    }

    private func deletePlan(_ plan: WorkoutPlan) {
        let pid = plan.id
        // Manually cascade: delete workouts and phases for this plan
        let workoutDesc = FetchDescriptor<Workout>(predicate: #Predicate<Workout> { w in w.planId == pid })
        let phaseDesc = FetchDescriptor<PlanPhase>(predicate: #Predicate<PlanPhase> { p in p.planId == pid })
        if let workouts = try? modelContext.fetch(workoutDesc) {
            for w in workouts { modelContext.delete(w) }
        }
        if let phases = try? modelContext.fetch(phaseDesc) {
            for p in phases { modelContext.delete(p) }
        }
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
        plan.isArchived = false
        plan.isActive = true

        do {
            try modelContext.save()
        } catch {
            print("Error setting active plan: \(error)")
        }
    }

    private func archivePlan(_ plan: WorkoutPlan) {
        plan.isArchived = true
        plan.isActive = false

        do {
            try modelContext.save()
        } catch {
            print("Error archiving plan: \(error)")
        }
    }

    private func restorePlan(_ plan: WorkoutPlan) {
        plan.isArchived = false

        do {
            try modelContext.save()
        } catch {
            print("Error restoring plan: \(error)")
        }
    }

    private func restoreAndActivatePlan(_ plan: WorkoutPlan) {
        for p in workoutPlans {
            p.isActive = false
        }
        plan.isArchived = false
        plan.isActive = true

        do {
            try modelContext.save()
        } catch {
            print("Error restoring plan: \(error)")
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
                workout.planId == planId
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(plan.isActive ? Color.summitOrange : Color.summitOrange.opacity(0.4))
                    .frame(width: 6)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(plan.name)
                            .font(.custom("Avenir Next", size: 18))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.summitText)

                        Spacer()

                        if plan.isArchived {
                            statusPill(title: "Archived", color: Color.gray)
                        } else if plan.isActive {
                            statusPill(title: "Active", color: Color.summitOrange)
                        }
                    }

                    if let description = plan.planDescription {
                        Text(description)
                            .font(.custom("Avenir Next", size: 13))
                            .foregroundStyle(Color.summitTextSecondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 10) {
                        Label("\(workouts.count)", systemImage: "list.bullet")
                            .font(.custom("Avenir Next", size: 12))
                            .foregroundStyle(Color.summitTextTertiary)

                        Text(workouts.count == 1 ? "workout" : "workouts")
                            .font(.custom("Avenir Next", size: 12))
                            .foregroundStyle(Color.summitTextTertiary)
                    }
                }
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

    private func statusPill(title: String, color: Color) -> some View {
        Text(title)
            .font(.custom("Avenir Next", size: 11))
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}

struct ActivePlanCardView: View {
    let plan: WorkoutPlan
    let startSession: (Workout) -> Void

    @Query private var workouts: [Workout]
    @Query private var phases: [PlanPhase]
    @Query private var sessions: [WorkoutSession]

    init(plan: WorkoutPlan, startSession: @escaping (Workout) -> Void) {
        self.plan = plan
        self.startSession = startSession
        let planId = plan.id
        _workouts = Query(
            filter: #Predicate<Workout> { workout in
                workout.planId == planId
            },
            sort: \Workout.orderIndex,
            order: .forward
        )
        _phases = Query(
            filter: #Predicate<PlanPhase> { phase in
                phase.planId == planId
            },
            sort: \PlanPhase.orderIndex,
            order: .forward
        )
        _sessions = Query(
            filter: #Predicate<WorkoutSession> { session in
                session.workoutPlanId == planId && session.isCompleted == true
            },
            sort: \WorkoutSession.date,
            order: .reverse
        )
    }

    // All computed from @Query — no modelContext fetches
    private var activePhase: PlanPhase? {
        guard !phases.isEmpty else { return nil }
        return phases.first(where: { $0.isActive }) ?? phases.first
    }

    private var activePhaseName: String? {
        activePhase?.name
    }

    private var filteredWorkouts: [Workout] {
        if let phase = activePhase {
            return workouts.filter { $0.phaseId == phase.id }
        }
        return Array(workouts)
    }

    private var nextWorkout: Workout? {
        let available = filteredWorkouts
        guard !available.isEmpty else { return nil }

        let relevantSessions: [WorkoutSession]
        if let phase = activePhase {
            relevantSessions = sessions.filter { $0.phaseId == phase.id }
        } else {
            relevantSessions = Array(sessions)
        }

        guard let lastSession = relevantSessions.first else {
            return available.first
        }

        if let lastIndex = available.firstIndex(where: { $0.id == lastSession.workoutTemplateId }) {
            let nextIndex = (lastIndex + 1) % available.count
            return available[nextIndex]
        }

        return available.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    NavigationLink(destination: WorkoutPlanDetailView(plan: plan)) {
                        HStack(spacing: 6) {
                            Text(plan.name)
                                .font(.custom("Avenir Next", size: 24))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.summitText)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.summitTextSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if let phaseName = activePhaseName {
                    infoChip(text: phaseName, icon: "flag.checkered")
                }
            }

            if let description = plan.planDescription {
                Text(description)
                    .font(.custom("Avenir Next", size: 14))
                    .foregroundStyle(Color.summitTextSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: 10) {
                infoChip(text: "\(workouts.count) workouts", icon: "list.bullet")
                infoChip(text: "\(sessions.count) sessions", icon: "clock")
            }

            if let workout = nextWorkout {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Up")
                        .font(.custom("Avenir Next", size: 12))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.summitTextTertiary)
                        .textCase(.uppercase)

                    Text(workout.name)
                        .font(.custom("Avenir Next", size: 18))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.summitText)

                    Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundStyle(Color.summitTextSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.summitOrange.opacity(0.18),
                                    Color.summitCardElevated.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

                Button {
                    startSession(workout)
                } label: {
                    HStack {
                        Spacer()
                        Label("Start Workout", systemImage: "play.fill")
                            .font(.custom("Avenir Next", size: 16))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                }
                .background(
                    LinearGradient(
                        colors: [Color.summitOrange, Color(hex: "#FF6A00")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.summitOrange.opacity(0.35), radius: 10, x: 0, y: 6)
                .buttonStyle(.plain)
            } else {
                Text("Add workouts to this plan to get started")
                    .font(.custom("Avenir Next", size: 14))
                    .foregroundStyle(Color.summitTextSecondary)
                    .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.summitCardElevated, Color.summitCard],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.summitOrange.opacity(0.18), lineWidth: 1)
            }
        )
    }

    private func infoChip(text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.custom("Avenir Next", size: 11))
        }
        .foregroundStyle(Color.summitTextSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.summitCard)
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainer.preview)
}
