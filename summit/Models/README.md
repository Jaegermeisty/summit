# GymTrack Data Model

This folder contains the complete SwiftData model for the GymTrack app.

## File Structure

### Core Models
- **WorkoutPlan.swift** - Top-level container for a training program
- **Workout.swift** - Individual training day (e.g., "Push Day", "Pull Day")
- **Exercise.swift** - Exercise template within a workout (defines target weight, reps, sets)
- **WorkoutSession.swift** - Completed workout instance (historical record)
- **ExerciseLog.swift** - Logged exercise data (weight + reps per set) for a session
- **BodyWeightLog.swift** - Body weight tracking over time

### Utilities
- **ModelContainer+Extensions.swift** - Shared and preview model containers
- **DataHelpers.swift** - Helper functions for querying and calculations
- **GymTrackApp.swift** - Main app file with SwiftData configuration

## Data Model Relationships

```
WorkoutPlan (1) ──→ (many) Workout
                     │
                     └──→ (many) Exercise

WorkoutSession ──references──→ Workout (template)
    │
    └──→ (many) ExerciseLog

BodyWeightLog (independent)
```

## How to Integrate into Xcode

1. **Create a "Models" folder in your Xcode project:**
   - Right-click on your project in Xcode
   - Select "New Group"
   - Name it "Models"

2. **Add the model files:**
   - Drag and drop these files into the Models folder:
     - WorkoutPlan.swift
     - Workout.swift
     - Exercise.swift
     - WorkoutSession.swift
     - ExerciseLog.swift
     - BodyWeightLog.swift
     - ModelContainer+Extensions.swift
     - DataHelpers.swift

3. **Update your App file:**
   - Replace the content of `summitApp.swift` (or your main app file) with the content from `GymTrackApp.swift`
   - Make sure to update the struct name to match your app name (e.g., `summitApp` instead of `GymTrackApp`)

4. **Test the setup:**
   - Build and run the app
   - You should see a basic list view
   - Tap the "+" button to create a sample plan
   - Verify that data persists after closing and reopening the app

## Key Features

### 1. Smart Exercise Recognition
The `DataHelpers.lastSession(for:in:)` function finds the most recent logged data for any exercise name, enabling auto-fill of previous weights.

### 2. Estimated 1RM Calculation
The `ExerciseLog.estimatedOneRepMax` computed property automatically calculates the estimated one-rep max using the formula:
```
1RM = weight × (1 + bestReps / 30)
```

### 3. Next Workout Suggestion
The `DataHelpers.nextWorkout(in:context:)` function determines which workout should be performed next based on the rotation pattern.

### 4. Exercise History Tracking
The `DataHelpers.exerciseHistory(for:in:)` function retrieves all historical data for an exercise, enabling progress graphs.

## Usage Examples

### Creating a Workout Plan
```swift
let plan = WorkoutPlan(name: "Push Pull Legs")
modelContext.insert(plan)

let pushDay = Workout(name: "Push Day", orderIndex: 0, workoutPlan: plan)
modelContext.insert(pushDay)

let benchPress = Exercise(
    name: "Bench Press",
    targetWeight: 60.0,
    targetRepsMin: 6,
    targetRepsMax: 8,
    numberOfSets: 3,
    notes: "Pause at bottom",
    workout: pushDay
)
modelContext.insert(benchPress)

try? modelContext.save()
```

### Logging a Workout Session
```swift
let session = WorkoutSession(
    workoutTemplateId: workout.id,
    workoutTemplateName: workout.name,
    workoutPlanId: plan.id,
    workoutPlanName: plan.name
)
modelContext.insert(session)

let log = ExerciseLog(
    exerciseName: "Bench Press",
    weight: 62.5,
    reps: [8, 7, 7],
    session: session
)
modelContext.insert(log)

try? modelContext.save()
```

### Getting Last Session for Auto-fill
```swift
if let lastLog = DataHelpers.lastSession(for: "Bench Press", in: modelContext) {
    // Auto-fill weight with: lastLog.weight
    // Show last performance: lastLog.reps
    // Calculate 1RM: lastLog.estimatedOneRepMax
}
```

## Future-Proof Design

This data model is designed to support future features:
- ✅ iCloud sync (SwiftData supports this natively)
- ✅ Exercise progress graphs (historical data preserved)
- ✅ Plan comparison (workout plan metadata stored)
- ✅ Data export (all data easily queryable)

## Notes

- All IDs are UUIDs for future cloud sync compatibility
- WorkoutSession stores template IDs AND names for historical reference (in case templates are modified later)
- Exercise names are stored as strings (not references) in ExerciseLog to maintain history even if templates are deleted
- The `orderIndex` fields maintain consistent ordering of workouts and exercises
