# Summit - Gym Tracking App

**A simple, powerful workout logging app for iOS**

> *"Simple app that works brilliantly. No social features, no complexity—just logging workouts."*

---

## 📱 Project Overview

Summit is a minimalist iOS gym tracking application built with SwiftUI and SwiftData. Unlike traditional gym apps with pre-populated exercise libraries and social features, Summit empowers users to create fully custom workout plans tailored to their exact needs.

**Core Philosophy:** Complete user control without overwhelming complexity.

---

## 🎯 Vision & Philosophy

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

## 👥 Target Users

**Primary:** Beginners and intermediate lifters (6 months - 3 years experience)

**Why this audience?**
- They want structure but don't need advanced programming (periodization, deloads, etc.)
- They value simplicity over feature bloat
- They're building consistency and need reliable tracking
- They appreciate flexibility to adjust plans as they learn

**Not for:** Advanced lifters who need complex programming (wave loading, block periodization, auto-regulation). They'll likely want more sophisticated tools.

---

## 🎨 Design Principles

### Visual Identity

**Color Scheme:**
- **Primary Background:** Charcoal / dark grey (always dark mode)
- **Accent Color:** Orange
- **Reasoning:** Creates a serious, focused gym aesthetic. Orange pops against charcoal and conveys energy.

**Current UI feels "boring and generic"** - needs to maintain clean Apple-style foundation but with character. Think: **Apple Watch workout app meets minimalist gym vibes.**

**No light mode.** Summit is a dark-mode-only app. This reinforces the serious, focused atmosphere.

### Interaction Patterns (Maintain Consistency)

✅ **Swipe-to-delete** → Quick destructive actions (delete exercise, workout, plan)
✅ **Long-press context menus** → Secondary actions (set as active, choose workout)
✅ **Sheets/modals** → Creation flows (new plan, workout, exercise)
✅ **NavigationLinks** → Drill-down navigation (plan → workout → exercise)
✅ **Empty states with CTAs** → Always show helpful prompts when lists are empty

### Typography & Spacing

- Prefer `.headline`, `.subheadline`, `.caption` over custom sizes
- Use system font weights (`.semibold`, `.medium`)
- Generous padding/spacing for breathing room
- Clear visual hierarchy (big titles, secondary info smaller)

---

## 🏗️ Technical Architecture

### Stack

**Framework:** SwiftUI (declarative, modern, fast development)
**Persistence:** SwiftData (local-first, iCloud sync capable, type-safe)
**Platform:** iOS only (for now)

**Why SwiftData over Core Data?**
- Simpler API with less boilerplate
- Native Swift types (no `@NSManaged`, `NSManagedObject`)
- Built-in iCloud sync support
- Future-proof (Apple's recommended path)

### Code Organization

```
summit/
├── Models/           # SwiftData models + helpers
│   ├── WorkoutPlan.swift
│   ├── Workout.swift
│   ├── Exercise.swift
│   ├── WorkoutSession.swift
│   ├── ExerciseLog.swift
│   ├── BodyWeightLog.swift
│   ├── DataHelpers.swift
│   └── ModelContainer+Extensions.swift
├── Views/            # SwiftUI views
│   ├── ContentView.swift (home screen)
│   ├── CreateWorkoutPlanView.swift
│   ├── WorkoutPlanDetailView.swift
│   ├── CreateWorkoutView.swift
│   ├── WorkoutDetailView.swift
│   ├── CreateExerciseView.swift
│   ├── EditExerciseView.swift
│   └── ActiveWorkoutSessionView.swift
└── summitApp.swift   # App entry point
```

**Philosophy:** Keep it flat and simple. Don't create deep folder hierarchies or premature abstractions.

---

## 💾 Data Model Decisions

### Why Exercise Names Are Strings (Not References)

**Problem:** If exercise templates are referenced by ID, deleting/renaming a template breaks workout history.

**Solution:** Store exercise names as strings in `ExerciseLog`.

**Result:**
- Your history is permanent and immutable
- Even if you delete "Bench Press" from your current plan, old sessions still show "Bench Press"
- Stats can aggregate all "Bench Press" logs across all workouts/plans by name
- Exercise name auto-suggestions work by querying unique names from logs

**Trade-off:** No global rename (if you change "Bench Press" to "Flat Bench," they're treated as separate exercises). This is acceptable—users rarely rename exercises globally.

### Why Template IDs + Names Are Stored in WorkoutSession

**Problem:** If you rename "Push Day" to "Upper Body," old sessions would reflect the new name.

**Solution:** Store both `workoutTemplateId` (for linking) and `workoutTemplateName` (for display).

**Result:**
- Sessions from 2 months ago show "Push Day"
- Sessions from today show "Upper Body"
- Historically accurate without breaking relationships

### Why Weight Per Set (Not Per Exercise)

**Problem:** Sometimes you drop weight on the last set, or pyramid up/down.

**Solution:** `ExerciseLog.weights` is an array: `[60.0, 60.0, 57.5]` for 3 sets.

**Result:**
- Full flexibility for drop sets, rest-pause, pyramids
- Accurate historical data (you can see you did 60kg × 8, then 57.5kg × 7)
- Auto-fill is smarter (suggests exact weights from last session per set)

---

## 💰 Monetization Strategy

### Two-Tier Model

**Free Tier (Local Only):**
- ✅ Create unlimited workout plans, workouts, exercises
- ✅ Log workouts with full functionality
- ✅ Auto-fill from LAST session only (for convenience)
- ❌ No workout history beyond "last session"
- ❌ No progress stats or charts
- ❌ No iCloud sync

**Paid Tier ($5 USD one-time purchase):**
- ✅ Full workout history (forever)
- ✅ Progress stats and charts
- ✅ Exercise-level analytics (e.g., all "Bench Press" sessions across all plans)
- ✅ iCloud sync (works across all user's devices)
- ✅ Sign in with Apple (no custom account system needed)

### Technical Implementation

**Free users:**
- SwiftData local storage only
- Store last session per exercise for auto-fill (queries most recent `ExerciseLog` by name)
- No complex backend needed

**Paid users:**
- Enable CloudKit sync in SwiftData (one toggle)
- Store full history locally + iCloud
- Sign in with Apple handles authentication
- No server costs for you (iCloud storage is on user's account)

**Storage Impact:**
- A year of workouts = ~1-2MB (just numbers, dates, text)
- Negligible for users
- Zero cost for you

---

## 🚀 Feature Roadmap

### ✅ Completed (v1.0)

- [x] Workout plan creation with description
- [x] Workout creation with optional notes
- [x] Exercise creation with all parameters (weight, reps range, sets, notes)
- [x] Active workout session with weight-per-set logging
- [x] Progress bar (smooth orange animation)
- [x] Smart workout rotation (auto-detects next workout)
- [x] Active plan management (set active, delete with confirmations)
- [x] Swipe-to-delete with cascade warnings
- [x] Empty states with helpful CTAs

### 🎯 Priority Features (Next)

**1. Manual Workout Override**
- Button next to "Start Workout" → "Choose Different Workout"
- Allows user to manually select any workout from active plan
- Useful for skipping ahead or repeating a session

**2. Workout History View (Free + Paid)**
- List of completed workout sessions by date
- Tap to view full session details (exercises, weights, reps)
- Free tier: Only shows last session per workout type
- Paid tier: Shows all sessions with infinite scroll

**3. Progress Visualization (Paid Only)**
- Line charts for exercise progression over time
- 1RM estimates tracked per exercise
- Volume tracking (total weight lifted)
- Comparison across workout plans

**4. Body Weight Logging**
- Quick log interface (date + weight + optional notes)
- Simple list view
- Optional chart (paid tier)

**5. Exercise Name Auto-Suggestions**
- When creating an exercise, show dropdown of previously used names
- Tap to auto-fill (user can still create new)
- Links exercises across workouts/plans for stats

### ❌ Features to NEVER Build

- ❌ Social features (sharing workouts, following users, leaderboards)
- ❌ Rest timers (use notes or iPhone timer)
- ❌ Supersets/circuits (use notes to document)
- ❌ AI coaching or workout recommendations
- ❌ Gamification (streaks, achievements, badges)
- ❌ Complex periodization tools
- ❌ Video exercise tutorials

**Reasoning:** Summit is a logging tool, not a coaching app. Keep it simple.

---

## 🛠️ Development Guidelines

### Code Style

**Avoid over-engineering:**
- No premature abstractions
- No "just in case" features
- Keep solutions simple and direct
- Three similar lines of code > premature helper function

**Example (Good):**
```swift
plan.isActive = true
plan2.isActive = false
plan3.isActive = false
```

**Example (Over-engineered):**
```swift
PlanActivationManager.shared.setActivePlan(plan, deactivatingOthers: [plan2, plan3])
```

### Error Handling

**Current approach:** `print("Error: ...")` statements.

**Better approach (implement gradually):**
- Show alerts to users for critical operations (save failures, deletion errors)
- Keep print statements for debugging
- Don't overwhelm users with error details—friendly messages only

**Example:**
```swift
do {
    try modelContext.save()
} catch {
    print("Error saving plan: \(error)")
    showErrorAlert = true
    errorMessage = "Couldn't save your workout plan. Please try again."
}
```

### Commit Messages

**Continue current style:**
- Clear title summarizing change
- Detailed body explaining what/why
- Bullet points for multiple changes
- Call out breaking changes or migrations

### File Organization

**Keep it simple:**
- Models folder for data models
- Views folder for SwiftUI views
- No need for "Helpers", "Utilities", "Services" folders until actually needed
- Group related views (e.g., all workout-related views) in subfolders only if Views/ gets too crowded

### Testing Strategy

**Current:** Manual testing in simulator/device.

**Future (optional):**
- Unit tests for DataHelpers functions
- Preview tests for UI components
- Keep tests lightweight—this is a small app

---

## 🎨 UI/UX Patterns to Maintain

### Empty States

**Always include:**
- Icon (SF Symbol)
- Title (what's missing)
- Description (why it matters)
- CTA button (how to fix it)

**Example:**
```swift
ContentUnavailableView {
    Label("No Exercises", systemImage: "dumbbell")
} description: {
    Text("Add exercises to this workout to get started")
} actions: {
    Button("Add Exercise") { ... }
}
```

### Confirmation Dialogs

**For destructive actions (delete plan, delete workout):**
- Use `.alert()` modifier
- Clear title: "Delete Workout Plan"
- Explain consequences: "All workouts and exercises in this plan will be permanently deleted. This cannot be undone."
- Cancel button (default)
- Destructive button (red)

**Example:**
```swift
.alert("Delete Workout Plan", isPresented: $showingDeleteConfirmation) {
    Button("Cancel", role: .cancel) { }
    Button("Delete", role: .destructive) { deletePlan() }
} message: {
    Text("All workouts and exercises will be permanently deleted. This cannot be undone.")
}
```

### Notes Fields

**Philosophy:** Let users capture context anywhere.

- Workout plans have `planDescription` (what's the overall goal?)
- Workouts have `notes` (intensity, focus areas)
- Exercises have `notes` (technique cues, special instructions)
- Exercise logs have `notes` (how did it feel today?)
- Body weight logs have `notes` (cutting, bulking, maintenance)

**Keep these optional** but always available.

---

## 📐 Technical Constraints & Future-Proofing

### iCloud Sync (Paid Feature)

**How it works:**
- SwiftData has built-in CloudKit sync
- Toggle on: `ModelConfiguration(isStoredInMemoryOnly: false, cloudKitDatabase: .private)`
- User signs in with Apple ID (already authenticated on device)
- Data syncs automatically across user's devices
- **Zero backend code needed**
- **Zero hosting costs**

**Migration from Free → Paid:**
1. User purchases Pro
2. Enable CloudKit sync in ModelConfiguration
3. Local data automatically uploads to iCloud
4. Done!

### Workout Rotation Logic

**Current implementation:**
```swift
DataHelpers.nextWorkout(in: plan, context: modelContext)
```

**How it works:**
1. Get all sessions for this plan (sorted by date, newest first)
2. Find the last completed workout
3. Return the next workout in the rotation (wraps around)
4. If no sessions exist, return first workout

**Future enhancement:**
- User can manually override with "Choose Different Workout" button
- This doesn't break the rotation—next time it continues from the manually selected workout

### Exercise Name Matching for Stats

**Current:** Exercise names are strings.

**For stats (paid tier):**
```swift
let descriptor = FetchDescriptor<ExerciseLog>(
    predicate: #Predicate { $0.exerciseName == "Bench Press" }
)
let allBenchPressSessions = try context.fetch(descriptor)
```

**This aggregates:**
- "Bench Press" from Push Day in Plan A
- "Bench Press" from Upper Body in Plan B
- "Bench Press" from Full Body in Plan C

**Auto-suggestions:**
```swift
let allExerciseNames = Set(allLogs.map { $0.exerciseName }).sorted()
// Show in dropdown when creating exercise
```

---

## 🚫 Anti-Patterns to Avoid

### Don't Add Features Preemptively

❌ "Users might want to track cardio, let's add a cardio section"
✅ Wait until users actually request it

❌ "We should support multiple active plans in case someone wants it"
✅ Keep one active plan—simpler is better

### Don't Over-Validate

❌ "What if user enters 9999kg? Add validation!"
✅ Trust users. If they enter nonsense, it's their data.

### Don't Abstract Too Early

❌ Create `ExerciseViewModel`, `WorkoutService`, `PlanRepository`
✅ Keep data and views simple. SwiftData handles persistence. SwiftUI handles state.

### Don't Add Empty Folders "For Later"

❌ Create `Helpers/`, `Utilities/`, `Extensions/` folders before they're needed
✅ Add folders when you actually have 3+ files that belong together

---

## 🔄 Workflow with Claude Code

### When Starting a New Session

1. **Read this INSTRUCTIONS.md file first**
2. Review recent commits to understand current state
3. Ask clarifying questions if anything is unclear
4. Break complex tasks into small, testable steps

### When Implementing Features

1. **Plan before coding:**
   - What views are needed?
   - What data model changes?
   - What edge cases exist?

2. **Build incrementally:**
   - One view at a time
   - Commit after each complete feature
   - Test in simulator before moving on

3. **Match existing patterns:**
   - Follow established UI/UX patterns
   - Use existing color scheme
   - Maintain consistent spacing/typography

### When Unsure

**Ask Mathias!** Better to clarify than assume.

**Examples of good questions:**
- "Should this be a sheet or a full-screen view?"
- "What should happen if the user deletes all workouts from a plan?"
- "Should we show a loading indicator during iCloud sync?"

---

## 📝 Notes Fields Philosophy

**Every entity has optional notes:**
- `WorkoutPlan.planDescription`
- `Workout.notes`
- `Exercise.notes`
- `ExerciseLog.notes`
- `BodyWeightLog.notes`

**Why?**
Lifting is personal. Users might want to capture:
- "Felt strong today"
- "Lower back tight, go easier next time"
- "Rest-pause on last set"
- "Starting cut phase"

**Don't remove these.** Flexibility is a core value.

---

## 🎯 Success Metrics (Internal)

**What makes Summit successful?**

1. **Users create custom plans** (not asking for pre-built templates)
2. **Users log workouts consistently** (app is simple enough to use every session)
3. **Users feel in control** (not fighting the app's opinions)
4. **Users upgrade to Pro** (they find value in tracking progress)

**What would indicate failure?**

1. Users abandon after one session (too complex)
2. Users request social features (wrong audience)
3. Users complain about missing features that bloat the app (losing focus)

---

## 🔮 Long-Term Vision (5+ Years)

**Shareable Workout Plans:**
- Generate URL from workout plan
- Share on Reddit, Discord, forums
- Others import with one tap
- Community-driven ecosystem without social features in-app

**Apple Watch Companion:**
- Start workout from watch
- Log sets/reps with Digital Crown
- See rest timer (if we add it)
- Sync to iPhone automatically

**Progressive Web App (PWA):**
- For users who want web access
- Same data via iCloud sync
- View history on desktop

**What Summit will NEVER be:**
- A social network
- An AI coach
- A marketplace
- A content platform

---

## 🎨 UI Redesign Notes (Pending)

**Current state:** Default iOS colors, feels generic/boring.

**Planned changes:**
- **Background:** Charcoal (#2C2C2E or similar dark grey)
- **Accent:** Orange (#FF9500 or custom)
- **Secondary text:** Light grey (#AEAEB2)
- **Cards:** Slightly lighter grey than background (#3A3A3C)
- **Always dark mode** (no light theme toggle)

**Design inspiration:**
- Apple Watch workout app (serious, focused)
- Things 3 (clean but not boring)
- Strong app (gym-focused aesthetic)

**Maintain:**
- Clean Apple-style foundation
- Generous spacing
- Clear hierarchy
- Smooth animations

---

## 🙋 Questions for Future Features

**Before implementing, ask:**

1. **Does this align with "simple app that works brilliantly"?**
2. **Is this a paid or free feature?**
3. **Can this be solved with existing notes fields instead?**
4. **Will this make the app harder to use?**
5. **Is there a simpler way?**

**If uncertain, ask Mathias before building.**

---

## 📚 Resources

**SwiftUI Documentation:**
- https://developer.apple.com/documentation/swiftui

**SwiftData Guide:**
- https://developer.apple.com/documentation/swiftdata

**SF Symbols:**
- https://developer.apple.com/sf-symbols/

**Design Guidelines:**
- https://developer.apple.com/design/human-interface-guidelines/

---

## ✅ Current Status (Last Updated: 2025-12-23)

**Completed:**
- Full workout plan → workout → exercise creation flow
- Active workout session with weight-per-set logging
- Smart workout rotation
- Progress bar with smooth animation
- Plan management (set active, delete)
- All data models complete

**In Progress:**
- INSTRUCTIONS.md documentation ← You are here

**Next Up:**
- UI redesign (charcoal + orange theme)
- Manual workout override button
- Workout history view
- Exercise name auto-suggestions
- Monetization implementation (Free vs Pro)

---

## 🏁 Final Words

Summit is a **logging tool, not a coaching app.**

The goal is not to have the most features—it's to have the right features, executed brilliantly.

Keep it simple. Keep it focused. Keep it fast.

**When in doubt, ask: "Does this help users log their workouts better?" If not, don't build it.**

---

*This document is living and should be updated as the project evolves.*
