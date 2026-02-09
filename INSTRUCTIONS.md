# Summit - Gym Tracking App

**A simple, powerful workout logging app for iOS**

> *"Simple app that works brilliantly. No social features, no complexity—just logging workouts."*

---

## Project Overview

Summit is a minimalist iOS gym tracking application built with SwiftUI and SwiftData. Unlike traditional gym apps with pre-populated exercise libraries and social features, Summit empowers users to create fully custom workout plans tailored to their exact needs.

**Core Philosophy:** Complete user control without overwhelming complexity.

---

## Vision & Philosophy

### Why No Pre-Populated Exercise Library?

**The library is intentionally empty.** This design decision encourages users to:
- Build their own custom workout plans from scratch
- Own their training methodology completely
- Make small adjustments easily without fighting pre-defined templates
- Focus on what matters: their personal progression

### Future Vision: Shareable Workout Plans

While there's no built-in library, users will eventually be able to:
- Copy/paste workout plans via URLs
- Share plans on the internet
- Import others' plans into their app with one click
- Build a community-driven ecosystem without making Summit a "social app"

**This preserves simplicity while enabling knowledge sharing.**

---

## Target Users

**Primary:** Beginners and intermediate lifters (6 months - 3 years experience)

**Why this audience?**
- They want structure but don't need advanced programming (periodization, deloads, etc.)
- They value simplicity over feature bloat
- They're building consistency and need reliable tracking
- They appreciate flexibility to adjust plans as they learn

**Not for:** Advanced lifters who need complex programming (wave loading, block periodization, auto-regulation). They'll likely want more sophisticated tools.

---

## Design Principles

### Visual Identity

**Color Scheme:**
- **Primary Background:** Charcoal / dark grey (`#1C1C1E`) - always dark mode
- **Card Background:** `#2C2C2E` (standard), `#3A3A3C` (elevated)
- **Accent Color:** Orange (`#FF9500`)
- **Text:** White primary, `#AEAEB2` secondary, `#8E8E93` tertiary
- **Success:** Green (`#34C759`)
- **Destructive:** Red (`#FF3B30`)

**No light mode.** Summit is a dark-mode-only app. This reinforces the serious, focused atmosphere.

### Interaction Patterns (Maintain Consistency)

- **Swipe-to-delete** -> Quick destructive actions (delete exercise, workout, plan)
- **Long-press context menus** -> Secondary actions (set as active, choose workout)
- **Sheets/modals** -> Creation flows (new plan, workout, exercise)
- **NavigationLinks** -> Drill-down navigation (plan -> workout -> exercise)
- **Empty states with CTAs** -> Always show helpful prompts when lists are empty
- **Tab bar** -> Primary navigation between Home and Analytics

### Typography & Spacing

- Prefer `.headline`, `.subheadline`, `.caption` over custom sizes
- Use system font weights (`.semibold`, `.medium`)
- Generous padding/spacing for breathing room
- Clear visual hierarchy (big titles, secondary info smaller)

---

## Technical Architecture

### Stack

**Framework:** SwiftUI (declarative, modern, fast development)
**Persistence:** SwiftData (local-first, iCloud sync capable, type-safe)
**Platform:** iOS only (for now)

### Navigation Structure

The app uses a **TabView** with two tabs:
- **Home** (`ContentView`) — Workout plans, active plan card, start workouts
- **Analytics** (`AnalyticsView`) — Exercise progress charts, plan strength/volume

Each tab has its own **NavigationStack** for drill-down navigation. History is accessible from the Home tab toolbar as a sheet.

**Entry point:** `summitApp.swift` -> `MainTabView` -> `TabView` with Home + Analytics

### Code Organization

```
summit/
├── Models/               # SwiftData models + helpers
│   ├── WorkoutPlan.swift
│   ├── PlanPhase.swift
│   ├── Workout.swift
│   ├── Exercise.swift
│   ├── ExerciseDefinition.swift
│   ├── WorkoutSession.swift
│   ├── ExerciseLog.swift
│   ├── BodyWeightLog.swift
│   ├── DataHelpers.swift
│   └── ModelContainer+Extensions.swift
├── Views/                # SwiftUI views
│   ├── AnalyticsView.swift
│   ├── CreateExerciseView.swift
│   ├── CreateWorkoutPlanView.swift
│   ├── CreateWorkoutView.swift
│   ├── EditExerciseView.swift
│   ├── HistoryView.swift
│   ├── PhaseDetailView.swift
│   ├── WorkoutDetailView.swift
│   ├── WorkoutPlanDetailView.swift
│   └── WorkoutSessionView.swift
├── Theme/
│   └── Colors.swift      # Summit color palette
├── ContentView.swift     # Home tab (plans list, active plan card)
├── MainTabView.swift     # Root TabView (Home + Analytics)
└── summitApp.swift       # App entry point
```

**Philosophy:** Keep it flat and simple. Don't create deep folder hierarchies or premature abstractions.

---

## Data Model & Relationships

### Model Linking Strategy

**IMPORTANT: Models are linked by plain UUID properties, NOT by SwiftData `@Relationship`.**

The relationship between WorkoutPlan, PlanPhase, and Workout uses plain UUID fields:
- `Workout.planId: UUID?` — links to WorkoutPlan
- `Workout.phaseId: UUID?` — links to PlanPhase
- `PlanPhase.planId: UUID?` — links to WorkoutPlan
- `Exercise.workoutId: UUID?` — used for `@Query`/`FetchDescriptor` predicates
- `ExerciseLog.sessionId: UUID?` — used for `@Query`/`FetchDescriptor` predicates

The `Exercise` and `ExerciseLog` models still have `@Relationship` to `Workout` and `WorkoutSession` respectively (for cascade delete), but **all query predicates use the plain UUID fields** to avoid SwiftData observation loops. See the "SwiftData Known Issues" section below for details.

### Relationship Diagram

```
WorkoutPlan
   ├── (many) PlanPhase     [linked by PlanPhase.planId]
   └── (many) Workout       [linked by Workout.planId]
                                  └── Workout.phaseId -> PlanPhase (optional)
                                  └── (many) Exercise [relationship + Exercise.workoutId]
                                        └── ExerciseDefinition

WorkoutSession ──references──> Workout (by template ID)
    └── (many) ExerciseLog [relationship + ExerciseLog.sessionId]
          └── ExerciseDefinition

BodyWeightLog (independent)
```

### Cascade Delete

Since WorkoutPlan -> Workout and WorkoutPlan -> PlanPhase don't use `@Relationship`, cascade deletes are handled **manually** in the delete functions (e.g., `deletePlan()` in `ContentView`, `deletePhase()` in `WorkoutPlanDetailView`).

The Exercise -> Workout relationship still uses `@Relationship(deleteRule: .cascade)` so deleting a Workout automatically deletes its Exercises.

---

## SwiftData Known Issues & Lessons Learned

### CRITICAL: @Query + NavigationLink = Infinite Loop

**This is a known SwiftData/SwiftUI bug confirmed on Apple Developer Forums.**

**The problem:** When a `NavigationLink` pushes a view that contains `@Query` properties with `#Predicate`, SwiftData's observation system can create an infinite re-evaluation loop that freezes the entire UI. The CPU pegs at 100% and the app becomes unresponsive.

**When it happens:**
- A parent view has `@Query` results displayed in a `ForEach`
- Each row is a `NavigationLink` to a detail view
- The detail view has its own `@Query` with a `#Predicate`
- The more `@Query` properties involved, the worse it gets
- Relationship traversal in predicates (e.g., `exercise.workout?.id`) makes it much worse

**Our experience:** Adding phases (PlanPhase) to workout plans caused the app to freeze whenever a user tapped on a phase to navigate into `PhaseDetailView`. The view had 3 `@Query` properties, and each `WorkoutRowView` inside it had its own `@Query` — the combination triggered the infinite loop.

### Rules to Follow (Prevent Future Freezes)

1. **NEVER use relationship traversal in `#Predicate`**
   ```swift
   // BAD — causes observation tracking on the entire relationship graph
   #Predicate<Exercise> { $0.workout?.id == workoutId }

   // GOOD — plain UUID comparison, no relationship observation
   #Predicate<Exercise> { $0.workoutId == workoutId }
   ```
   Always add a plain UUID field alongside any relationship and use it in predicates.

2. **Avoid `@Query` in views pushed by NavigationLink**
   If a detail view (pushed via NavigationLink) needs data, prefer `@State` arrays loaded via `FetchDescriptor` in `.onAppear` instead of `@Query`. This avoids the observation system entirely.
   ```swift
   // BAD — @Query in a NavigationLink destination
   struct DetailView: View {
       @Query private var items: [Item]  // Can cause infinite loop
   }

   // GOOD — FetchDescriptor in .onAppear
   struct DetailView: View {
       @State private var items: [Item] = []

       var body: some View {
           List { ... }
           .onAppear { refreshData() }
       }

       private func refreshData() {
           let descriptor = FetchDescriptor<Item>(...)
           items = (try? modelContext.fetch(descriptor)) ?? []
       }
   }
   ```
   Call `refreshData()` again after any mutations (add/delete/move).

3. **Don't give row views their own `@Query`**
   Row views inside a `ForEach` should receive data from their parent, not run their own queries. Each `@Query` adds an observer that fires on every SwiftData change app-wide.
   ```swift
   // BAD — N+1 queries, one per row
   struct WorkoutRow: View {
       @Query private var exercises: [Exercise]  // Fires for every row
   }

   // GOOD — parent passes data down
   struct WorkoutRow: View {
       let workout: Workout
       let exerciseCount: Int  // Passed from parent
   }
   ```

4. **`@Query` is fine for top-level/root views**
   The Home screen (`ContentView`) and Analytics tab use `@Query` safely because they are root-level views, not pushed by NavigationLink. `@Query` works well when:
   - The view is at the root of a NavigationStack
   - The view is a tab in a TabView
   - The view is presented as a `.sheet`

5. **Any SwiftData change rebuilds ALL @Query views**
   Apple has confirmed this behavior: modifying ANY model property (even setting it to the same value) causes EVERY `@Query` in the app to re-fire. Keep `@Query` usage to a minimum and in stable (root) views.

### References
- Apple Developer Forums thread 751448 (NavigationLink + @Query infinite loop)
- Apple Developer Forums thread 774561 (SwiftData over-notification confirmed by Apple DTS)
- Apple Developer Forums thread 727307 (NavigationStack hang with @Query)

---

## Data Model Decisions

### Why Exercise Names Are Strings (Not References)

**Problem:** If exercise templates are referenced by ID, deleting/renaming a template breaks workout history.

**Solution:** Store exercise names as strings in `ExerciseLog` (via `ExerciseDefinition`).

**Result:**
- Your history is permanent and immutable
- Even if you delete "Bench Press" from your current plan, old sessions still show "Bench Press"
- Stats can aggregate all "Bench Press" logs across all workouts/plans by normalized name
- Exercise name auto-suggestions work by querying `ExerciseDefinition` entries

### Why Template IDs + Names Are Stored in WorkoutSession

**Problem:** If you rename "Push Day" to "Upper Body," old sessions would reflect the new name.

**Solution:** Store both `workoutTemplateId` (for linking) and `workoutTemplateName` (for display).

**Result:**
- Sessions from 2 months ago show "Push Day"
- Sessions from today show "Upper Body"
- Historically accurate without breaking relationships

### Why Plain UUIDs Instead of @Relationship for Plan/Phase/Workout

**Problem:** SwiftData `@Relationship` with `inverse:` between WorkoutPlan, PlanPhase, and Workout created circular observation chains that froze the UI.

**Solution:** Remove all `@Relationship` between these three models. Use plain UUID properties (`planId`, `phaseId`) for linking and querying. Handle cascade deletes manually.

**Result:**
- No observation loops between plan/phase/workout
- Predicates use simple value comparison instead of relationship traversal
- Manual cascade delete in a few functions (small trade-off for stability)

---

## Monetization Strategy

### Two-Tier Model

**Free Tier (Local Only):**
- Create unlimited workout plans, workouts, exercises
- Log workouts with full functionality
- Auto-fill from LAST session only (for convenience)
- No workout history beyond "last session"
- No progress stats or charts
- No iCloud sync

**Paid Tier ($5 USD one-time purchase):**
- Full workout history (forever)
- Progress stats and charts
- Exercise-level analytics (e.g., all "Bench Press" sessions across all plans)
- iCloud sync (works across all user's devices)
- Sign in with Apple (no custom account system needed)

---

## Feature Roadmap

### Completed

- [x] Workout plan creation with description
- [x] Workout creation with optional notes
- [x] Exercise creation with all parameters (weight, reps range, sets, notes)
- [x] Active workout session with weight-per-set logging
- [x] Progress bar (smooth orange animation)
- [x] Smart workout rotation (auto-detects next workout)
- [x] Active plan management (set active, delete with confirmations)
- [x] Swipe-to-delete with cascade warnings
- [x] Empty states with helpful CTAs
- [x] UI redesign (charcoal + orange dark theme)
- [x] Exercise name auto-suggestions (via ExerciseDefinition catalog)
- [x] Workout history view (last 5 completed sessions)
- [x] Session completion toast
- [x] Plan phases (blocks) with active phase selection
- [x] Phase-aware next workout rotation
- [x] Analytics — exercise 1RM progress chart
- [x] Analytics — plan strength score + volume charts
- [x] Tab bar navigation (Home + Analytics)

### Next Up

1. **Paywall** — One-time purchase gating history + analytics
2. **Plan comparison view** — Side-by-side or overlay charts
3. **Phase management polish** — Rename phase, multi-select move/copy workouts
4. **Exercise search/filter in Analytics** — Favorites, search bar

### Features to NEVER Build

- Social features (sharing workouts, following users, leaderboards)
- Rest timers (use notes or iPhone timer)
- Supersets/circuits (use notes to document)
- AI coaching or workout recommendations
- Gamification (streaks, achievements, badges)
- Complex periodization tools
- Video exercise tutorials

**Reasoning:** Summit is a logging tool, not a coaching app. Keep it simple.

---

## Development Guidelines

### Code Style

**Avoid over-engineering:**
- No premature abstractions
- No "just in case" features
- Keep solutions simple and direct
- Three similar lines of code > premature helper function

### Error Handling

**Current approach:** `print("Error: ...")` statements with `try modelContext.save()`.

**Better approach (implement gradually):**
- Show alerts to users for critical operations (save failures, deletion errors)
- Keep print statements for debugging
- Don't overwhelm users with error details -- friendly messages only

### File Organization

**Keep it simple:**
- Models folder for data models
- Views folder for SwiftUI views
- Theme folder for colors/styling
- No need for "Helpers", "Utilities", "Services" folders until actually needed

---

## UI/UX Patterns to Maintain

### Empty States

**Always include:**
- Icon (SF Symbol)
- Title (what's missing)
- Description (why it matters)
- CTA button (how to fix it)

### Confirmation Dialogs

**For destructive actions (delete plan, delete workout):**
- Use `.alert()` modifier
- Clear title: "Delete Workout Plan"
- Explain consequences: "All workouts and exercises will be permanently deleted. This cannot be undone."
- Cancel button (default)
- Destructive button (red)

### Notes Fields

**Every entity has optional notes:**
- `WorkoutPlan.planDescription`
- `Workout.notes`
- `Exercise.notes`
- `ExerciseLog.notes`
- `BodyWeightLog.notes`

**Don't remove these.** Flexibility is a core value.

---

## Anti-Patterns to Avoid

### Don't Add Features Preemptively

- Wait until users actually request it
- Keep one active plan -- simpler is better

### Don't Over-Validate

- Trust users. If they enter nonsense, it's their data.

### Don't Abstract Too Early

- Keep data and views simple. SwiftData handles persistence. SwiftUI handles state.

### Don't Use @Query in NavigationLink Destinations

- See "SwiftData Known Issues" section above. Use `FetchDescriptor` + `.onAppear` instead.

---

## Technical Constraints & Future-Proofing

### iCloud Sync (Paid Feature)

- SwiftData has built-in CloudKit sync
- Toggle on: `ModelConfiguration(cloudKitDatabase: .private)`
- User signs in with Apple ID (already authenticated on device)
- Data syncs automatically across user's devices
- Zero backend code needed, zero hosting costs

### Workout Rotation Logic

1. Get all sessions for this plan (sorted by date, newest first)
2. If phases are enabled, filter to sessions from the active phase
3. Find the last completed workout
4. Return the next workout in the rotation (wraps around)
5. If no sessions exist, return first workout

### Exercise Name Matching for Stats

Exercise names are normalized via `ExerciseDefinition.normalizedName` (lowercased, trimmed). This aggregates all logs for the same exercise across different plans and workouts.

---

## Long-Term Vision (5+ Years)

**Shareable Workout Plans:**
- Generate URL from workout plan
- Share on Reddit, Discord, forums
- Others import with one tap

**Apple Watch Companion:**
- Start workout from watch
- Log sets/reps with Digital Crown
- Sync to iPhone automatically

**What Summit will NEVER be:**
- A social network
- An AI coach
- A marketplace
- A content platform

---

## Current Status (Last Updated: 2026-02-09)

**Completed:**
- Full workout plan -> workout -> exercise creation flow
- Active workout session with weight-per-set logging
- Smart workout rotation (phase-aware)
- Plan phases (blocks) with active phase selection
- Tab bar navigation (Home + Analytics tabs)
- Analytics: exercise 1RM charts, plan strength/volume charts
- History view (last 5 completed sessions)
- UI redesign: charcoal + orange dark theme
- Exercise name auto-suggestions via ExerciseDefinition

**Next Up:**
- Paywall (one-time purchase for history + analytics)
- Plan comparison view
- Phase management polish (rename, multi-select move/copy)

---

**When in doubt, ask: "Does this help users log their workouts better?" If not, don't build it.**

*This document is living and should be updated as the project evolves.*
