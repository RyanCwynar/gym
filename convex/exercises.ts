import { mutation, query, internalMutation } from "./_generated/server";
import { v } from "convex/values";

// Validator for exercise type
const exerciseTypeValidator = v.union(
  v.literal("resistance"),
  v.literal("calisthenics"),
  v.literal("cardio")
);

// Return type for exercises
const exerciseReturnValidator = v.object({
  _id: v.id("exercises"),
  _creationTime: v.number(),
  name: v.string(),
  muscleGroup: v.string(),
  description: v.optional(v.string()),
  defaultWeight: v.optional(v.number()),
  defaultWeightUnit: v.optional(v.string()),
  isPrimary: v.optional(v.boolean()),
  exerciseType: exerciseTypeValidator,
});

/**
 * Get all exercises from the library.
 */
export const getExercises = query({
  args: {},
  returns: v.array(exerciseReturnValidator),
  handler: async (ctx) => {
    return await ctx.db.query("exercises").collect();
  },
});

/**
 * Get exercises by muscle group.
 */
export const getExercisesByMuscleGroup = query({
  args: {
    muscleGroup: v.string(),
  },
  returns: v.array(exerciseReturnValidator),
  handler: async (ctx, args) => {
    return await ctx.db
      .query("exercises")
      .withIndex("by_muscle_group", (q) => q.eq("muscleGroup", args.muscleGroup))
      .collect();
  },
});

/**
 * Get exercises by type.
 */
export const getExercisesByType = query({
  args: {
    exerciseType: exerciseTypeValidator,
  },
  returns: v.array(exerciseReturnValidator),
  handler: async (ctx, args) => {
    return await ctx.db
      .query("exercises")
      .withIndex("by_type", (q) => q.eq("exerciseType", args.exerciseType))
      .collect();
  },
});

/**
 * Search exercises by name.
 */
export const searchExercises = query({
  args: {
    searchTerm: v.string(),
  },
  returns: v.array(exerciseReturnValidator),
  handler: async (ctx, args) => {
    const allExercises = await ctx.db.query("exercises").collect();
    const searchLower = args.searchTerm.toLowerCase();

    return allExercises.filter(
      (ex) =>
        ex.name.toLowerCase().includes(searchLower) ||
        ex.muscleGroup.toLowerCase().includes(searchLower) ||
        (ex.description && ex.description.toLowerCase().includes(searchLower))
    );
  },
});

/**
 * Get a single exercise by name.
 */
export const getExerciseByName = query({
  args: {
    name: v.string(),
  },
  returns: v.union(exerciseReturnValidator, v.null()),
  handler: async (ctx, args) => {
    return await ctx.db
      .query("exercises")
      .withIndex("by_name", (q) => q.eq("name", args.name))
      .unique();
  },
});

/**
 * Create a new exercise.
 */
export const createExercise = mutation({
  args: {
    name: v.string(),
    muscleGroup: v.string(),
    description: v.optional(v.string()),
    defaultWeight: v.optional(v.number()),
    defaultWeightUnit: v.optional(v.string()),
    isPrimary: v.optional(v.boolean()),
    exerciseType: exerciseTypeValidator,
  },
  returns: v.id("exercises"),
  handler: async (ctx, args) => {
    // Check if exercise already exists
    const existing = await ctx.db
      .query("exercises")
      .withIndex("by_name", (q) => q.eq("name", args.name))
      .unique();

    if (existing) {
      throw new Error(`Exercise "${args.name}" already exists`);
    }

    return await ctx.db.insert("exercises", {
      name: args.name,
      muscleGroup: args.muscleGroup,
      description: args.description,
      defaultWeight: args.defaultWeight,
      defaultWeightUnit: args.defaultWeightUnit ?? "lbs",
      isPrimary: args.isPrimary ?? false,
      exerciseType: args.exerciseType,
    });
  },
});

/**
 * Internal mutation to seed exercises from the library.
 * Call this once to populate the database with default exercises.
 */
export const seedExercises = internalMutation({
  args: {},
  returns: v.object({
    created: v.number(),
    skipped: v.number(),
  }),
  handler: async (ctx) => {
    const exerciseLibrary = [
      // Chest - resistance
      { name: "Bench Press", muscleGroup: "Chest", description: "Barbell bench press", isPrimary: true, defaultWeight: 135, exerciseType: "resistance" as const },
      { name: "Incline Bench Press", muscleGroup: "Chest", description: "Incline barbell press", defaultWeight: 115, exerciseType: "resistance" as const },
      { name: "Dumbbell Bench Press", muscleGroup: "Chest", description: "Flat dumbbell press", defaultWeight: 50, exerciseType: "resistance" as const },
      { name: "Incline Dumbbell Press", muscleGroup: "Chest", description: "Incline dumbbell press", defaultWeight: 45, exerciseType: "resistance" as const },
      { name: "Cable Flyes", muscleGroup: "Chest", description: "Cable chest flyes", defaultWeight: 30, exerciseType: "resistance" as const },
      { name: "Dumbbell Flyes", muscleGroup: "Chest", description: "Flat dumbbell flyes", defaultWeight: 30, exerciseType: "resistance" as const },
      { name: "Machine Chest Press", muscleGroup: "Chest", description: "Machine press", defaultWeight: 140, exerciseType: "resistance" as const },
      { name: "Pec Deck", muscleGroup: "Chest", description: "Pec deck machine", defaultWeight: 120, exerciseType: "resistance" as const },
      // Chest - calisthenics
      { name: "Push-Ups", muscleGroup: "Chest", description: "Bodyweight push-ups", defaultWeight: 0, exerciseType: "calisthenics" as const },
      { name: "Chest Dips", muscleGroup: "Chest", description: "Weighted or bodyweight dips", defaultWeight: 0, exerciseType: "calisthenics" as const },

      // Back - resistance
      { name: "Deadlift", muscleGroup: "Back", description: "Conventional deadlift", isPrimary: true, defaultWeight: 185, exerciseType: "resistance" as const },
      { name: "Barbell Row", muscleGroup: "Back", description: "Bent over barbell row", defaultWeight: 135, exerciseType: "resistance" as const },
      { name: "Dumbbell Row", muscleGroup: "Back", description: "Single arm dumbbell row", defaultWeight: 55, exerciseType: "resistance" as const },
      { name: "Lat Pulldown", muscleGroup: "Back", description: "Cable lat pulldown", defaultWeight: 120, exerciseType: "resistance" as const },
      { name: "Seated Cable Row", muscleGroup: "Back", description: "Seated row machine", defaultWeight: 120, exerciseType: "resistance" as const },
      { name: "T-Bar Row", muscleGroup: "Back", description: "T-bar row", defaultWeight: 90, exerciseType: "resistance" as const },
      { name: "Face Pulls", muscleGroup: "Back", description: "Cable face pulls", defaultWeight: 50, exerciseType: "resistance" as const },
      { name: "Romanian Deadlift", muscleGroup: "Back", description: "RDL for hamstrings and lower back", defaultWeight: 135, exerciseType: "resistance" as const },
      // Back - calisthenics
      { name: "Pull-Ups", muscleGroup: "Back", description: "Bodyweight or weighted pull-ups", isPrimary: true, defaultWeight: 0, exerciseType: "calisthenics" as const },
      { name: "Chin-Ups", muscleGroup: "Back", description: "Underhand grip pull-ups", defaultWeight: 0, exerciseType: "calisthenics" as const },

      // Shoulders - resistance
      { name: "Overhead Press", muscleGroup: "Shoulders", description: "Standing barbell press", isPrimary: true, defaultWeight: 95, exerciseType: "resistance" as const },
      { name: "Dumbbell Shoulder Press", muscleGroup: "Shoulders", description: "Seated dumbbell press", defaultWeight: 40, exerciseType: "resistance" as const },
      { name: "Lateral Raises", muscleGroup: "Shoulders", description: "Dumbbell side raises", defaultWeight: 20, exerciseType: "resistance" as const },
      { name: "Front Raises", muscleGroup: "Shoulders", description: "Dumbbell front raises", defaultWeight: 20, exerciseType: "resistance" as const },
      { name: "Rear Delt Flyes", muscleGroup: "Shoulders", description: "Bent over rear delt flyes", defaultWeight: 15, exerciseType: "resistance" as const },
      { name: "Arnold Press", muscleGroup: "Shoulders", description: "Rotating dumbbell press", defaultWeight: 35, exerciseType: "resistance" as const },
      { name: "Upright Row", muscleGroup: "Shoulders", description: "Barbell or dumbbell upright row", defaultWeight: 65, exerciseType: "resistance" as const },
      { name: "Shrugs", muscleGroup: "Shoulders", description: "Barbell or dumbbell shrugs", defaultWeight: 60, exerciseType: "resistance" as const },
      { name: "Machine Shoulder Press", muscleGroup: "Shoulders", description: "Seated machine press", defaultWeight: 100, exerciseType: "resistance" as const },

      // Biceps - resistance
      { name: "Barbell Curl", muscleGroup: "Biceps", description: "Standing barbell curl", isPrimary: true, defaultWeight: 65, exerciseType: "resistance" as const },
      { name: "Dumbbell Curl", muscleGroup: "Biceps", description: "Standing or seated dumbbell curls", defaultWeight: 30, exerciseType: "resistance" as const },
      { name: "Hammer Curl", muscleGroup: "Biceps", description: "Neutral grip dumbbell curls", defaultWeight: 30, exerciseType: "resistance" as const },
      { name: "Preacher Curl", muscleGroup: "Biceps", description: "EZ bar or dumbbell preacher curls", defaultWeight: 50, exerciseType: "resistance" as const },
      { name: "Incline Dumbbell Curl", muscleGroup: "Biceps", description: "Incline bench curls", defaultWeight: 25, exerciseType: "resistance" as const },
      { name: "Cable Curl", muscleGroup: "Biceps", description: "Standing cable curls", defaultWeight: 50, exerciseType: "resistance" as const },
      { name: "Concentration Curl", muscleGroup: "Biceps", description: "Seated single arm curls", defaultWeight: 25, exerciseType: "resistance" as const },
      { name: "EZ Bar Curl", muscleGroup: "Biceps", description: "EZ bar curls", defaultWeight: 60, exerciseType: "resistance" as const },

      // Triceps - resistance
      { name: "Tricep Pushdown", muscleGroup: "Triceps", description: "Cable pushdowns", isPrimary: true, defaultWeight: 60, exerciseType: "resistance" as const },
      { name: "Skull Crushers", muscleGroup: "Triceps", description: "Lying tricep extension", defaultWeight: 55, exerciseType: "resistance" as const },
      { name: "Close Grip Bench Press", muscleGroup: "Triceps", description: "Narrow grip bench press", defaultWeight: 115, exerciseType: "resistance" as const },
      { name: "Overhead Tricep Extension", muscleGroup: "Triceps", description: "Cable or dumbbell overhead extension", defaultWeight: 45, exerciseType: "resistance" as const },
      { name: "Rope Pushdown", muscleGroup: "Triceps", description: "Rope cable pushdowns", defaultWeight: 50, exerciseType: "resistance" as const },
      { name: "Kickbacks", muscleGroup: "Triceps", description: "Dumbbell tricep kickbacks", defaultWeight: 20, exerciseType: "resistance" as const },
      // Triceps - calisthenics
      { name: "Tricep Dips", muscleGroup: "Triceps", description: "Bench or parallel bar dips", defaultWeight: 0, exerciseType: "calisthenics" as const },
      { name: "Diamond Push-Ups", muscleGroup: "Triceps", description: "Close hand push-ups", defaultWeight: 0, exerciseType: "calisthenics" as const },

      // Legs - resistance
      { name: "Squat", muscleGroup: "Legs", description: "Barbell back squat", isPrimary: true, defaultWeight: 155, exerciseType: "resistance" as const },
      { name: "Leg Press", muscleGroup: "Legs", description: "Machine leg press", isPrimary: true, defaultWeight: 270, exerciseType: "resistance" as const },
      { name: "Lunges", muscleGroup: "Legs", description: "Walking or stationary lunges", defaultWeight: 40, exerciseType: "resistance" as const },
      { name: "Leg Extension", muscleGroup: "Legs", description: "Machine leg extension", defaultWeight: 100, exerciseType: "resistance" as const },
      { name: "Leg Curl", muscleGroup: "Legs", description: "Lying or seated leg curl", defaultWeight: 80, exerciseType: "resistance" as const },
      { name: "Calf Raises", muscleGroup: "Legs", description: "Standing or seated calf raises", defaultWeight: 150, exerciseType: "resistance" as const },
      { name: "Bulgarian Split Squat", muscleGroup: "Legs", description: "Rear foot elevated split squat", defaultWeight: 35, exerciseType: "resistance" as const },
      { name: "Hack Squat", muscleGroup: "Legs", description: "Machine hack squat", defaultWeight: 180, exerciseType: "resistance" as const },
      { name: "Front Squat", muscleGroup: "Legs", description: "Barbell front squat", defaultWeight: 115, exerciseType: "resistance" as const },
      { name: "Hip Thrust", muscleGroup: "Legs", description: "Barbell hip thrust", defaultWeight: 135, exerciseType: "resistance" as const },
      { name: "Goblet Squat", muscleGroup: "Legs", description: "Dumbbell or kettlebell squat", defaultWeight: 50, exerciseType: "resistance" as const },

      // Core - calisthenics
      { name: "Plank", muscleGroup: "Core", description: "Front plank hold", isPrimary: true, defaultWeight: 0, exerciseType: "calisthenics" as const },
      { name: "Crunches", muscleGroup: "Core", description: "Bodyweight crunches", defaultWeight: 0, exerciseType: "calisthenics" as const },
      { name: "Hanging Leg Raise", muscleGroup: "Core", description: "Hanging from bar", defaultWeight: 0, exerciseType: "calisthenics" as const },
      { name: "Ab Wheel Rollout", muscleGroup: "Core", description: "Ab wheel exercise", defaultWeight: 0, exerciseType: "calisthenics" as const },
      { name: "Mountain Climbers", muscleGroup: "Core", description: "Dynamic plank exercise", defaultWeight: 0, exerciseType: "calisthenics" as const },
      { name: "Dead Bug", muscleGroup: "Core", description: "Core stability exercise", defaultWeight: 0, exerciseType: "calisthenics" as const },
      { name: "Side Plank", muscleGroup: "Core", description: "Lateral core hold", defaultWeight: 0, exerciseType: "calisthenics" as const },
      // Core - resistance
      { name: "Cable Crunch", muscleGroup: "Core", description: "Kneeling cable crunch", defaultWeight: 80, exerciseType: "resistance" as const },
      { name: "Russian Twist", muscleGroup: "Core", description: "Weighted or bodyweight twists", defaultWeight: 25, exerciseType: "resistance" as const },

      // Cardio
      { name: "Treadmill", muscleGroup: "Cardio", description: "Running or walking", defaultWeight: 0, exerciseType: "cardio" as const },
      { name: "Stationary Bike", muscleGroup: "Cardio", description: "Cycling", defaultWeight: 0, exerciseType: "cardio" as const },
      { name: "Rowing Machine", muscleGroup: "Cardio", description: "Rowing ergometer", defaultWeight: 0, exerciseType: "cardio" as const },
      { name: "Elliptical", muscleGroup: "Cardio", description: "Elliptical machine", defaultWeight: 0, exerciseType: "cardio" as const },
      { name: "Stair Climber", muscleGroup: "Cardio", description: "Stair stepper", defaultWeight: 0, exerciseType: "cardio" as const },
      { name: "Jump Rope", muscleGroup: "Cardio", description: "Skipping rope", defaultWeight: 0, exerciseType: "cardio" as const },
    ];

    let created = 0;
    let skipped = 0;

    for (const exercise of exerciseLibrary) {
      const existing = await ctx.db
        .query("exercises")
        .withIndex("by_name", (q) => q.eq("name", exercise.name))
        .unique();

      if (existing) {
        skipped++;
        continue;
      }

      await ctx.db.insert("exercises", {
        name: exercise.name,
        muscleGroup: exercise.muscleGroup,
        description: exercise.description,
        defaultWeight: exercise.defaultWeight,
        defaultWeightUnit: "lbs",
        isPrimary: exercise.isPrimary ?? false,
        exerciseType: exercise.exerciseType,
      });
      created++;
    }

    return { created, skipped };
  },
});
