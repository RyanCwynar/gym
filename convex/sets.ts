import { mutation, query, internalQuery } from "./_generated/server";
import { v } from "convex/values";
import { internal } from "./_generated/api";
import { Id } from "./_generated/dataModel";

// Validator for exercise type
const exerciseTypeValidator = v.union(
  v.literal("resistance"),
  v.literal("calisthenics"),
  v.literal("cardio")
);

// Return type for sets
const setReturnValidator = v.object({
  _id: v.id("sets"),
  _creationTime: v.number(),
  apiKeyId: v.id("apiKeys"),
  exerciseId: v.optional(v.id("exercises")),
  exerciseName: v.string(),
  weight: v.optional(v.number()),
  weightUnit: v.optional(v.string()),
  reps: v.optional(v.number()),
  workTime: v.optional(v.number()),
  exerciseType: exerciseTypeValidator,
  duration: v.optional(v.number()),
  notes: v.optional(v.string()),
  isCompleted: v.optional(v.boolean()),
  completedAt: v.optional(v.number()),
  workoutId: v.optional(v.string()),
  setOrder: v.optional(v.number()),
});

/**
 * Create a new set.
 */
export const createSet = mutation({
  args: {
    apiKeyId: v.id("apiKeys"),
    exerciseId: v.optional(v.id("exercises")),
    exerciseName: v.string(),
    weight: v.optional(v.number()),
    weightUnit: v.optional(v.string()),
    reps: v.optional(v.number()),
    workTime: v.optional(v.number()),
    exerciseType: exerciseTypeValidator,
    duration: v.optional(v.number()),
    notes: v.optional(v.string()),
    isCompleted: v.optional(v.boolean()),
    workoutId: v.optional(v.string()),
    setOrder: v.optional(v.number()),
  },
  returns: v.id("sets"),
  handler: async (ctx, args) => {
    // Verify API key exists and is active
    const apiKey = await ctx.db.get(args.apiKeyId);
    if (!apiKey || !apiKey.isActive) {
      throw new Error("Invalid or inactive API key");
    }

    // Auto-mark as completed if work time is logged
    const hasWorkTime = args.workTime !== undefined && args.workTime > 0;
    const hasDuration = args.duration !== undefined && args.duration > 0;
    const isCompleted = args.isCompleted ?? hasWorkTime ?? hasDuration ?? false;

    const setId = await ctx.db.insert("sets", {
      apiKeyId: args.apiKeyId,
      exerciseId: args.exerciseId,
      exerciseName: args.exerciseName,
      weight: args.weight,
      weightUnit: args.weightUnit ?? "lbs",
      reps: args.reps,
      workTime: args.workTime,
      exerciseType: args.exerciseType,
      duration: args.duration,
      notes: args.notes,
      isCompleted,
      completedAt: isCompleted ? Date.now() : undefined,
      workoutId: args.workoutId,
      setOrder: args.setOrder,
    });

    return setId;
  },
});

/**
 * Update a set.
 */
export const updateSet = mutation({
  args: {
    setId: v.id("sets"),
    apiKeyId: v.id("apiKeys"),
    weight: v.optional(v.number()),
    weightUnit: v.optional(v.string()),
    reps: v.optional(v.number()),
    workTime: v.optional(v.number()),
    duration: v.optional(v.number()),
    notes: v.optional(v.string()),
    isCompleted: v.optional(v.boolean()),
  },
  returns: v.null(),
  handler: async (ctx, args) => {
    const set = await ctx.db.get(args.setId);
    if (!set) {
      throw new Error("Set not found");
    }

    // Verify ownership
    if (set.apiKeyId !== args.apiKeyId) {
      throw new Error("Unauthorized");
    }

    const updates: Partial<typeof set> = {};

    if (args.weight !== undefined) updates.weight = args.weight;
    if (args.weightUnit !== undefined) updates.weightUnit = args.weightUnit;
    if (args.reps !== undefined) updates.reps = args.reps;
    if (args.workTime !== undefined) updates.workTime = args.workTime;
    if (args.duration !== undefined) updates.duration = args.duration;
    if (args.notes !== undefined) updates.notes = args.notes;

    // Auto-mark as completed if work time or duration is logged
    const hasNewWorkTime = args.workTime !== undefined && args.workTime > 0;
    const hasNewDuration = args.duration !== undefined && args.duration > 0;

    if (args.isCompleted !== undefined) {
      updates.isCompleted = args.isCompleted;
      if (args.isCompleted) {
        updates.completedAt = Date.now();
      }
    } else if ((hasNewWorkTime || hasNewDuration) && !set.isCompleted) {
      // Auto-complete when work time/duration is first logged
      updates.isCompleted = true;
      updates.completedAt = Date.now();
    }

    await ctx.db.patch(args.setId, updates);
    return null;
  },
});

/**
 * Delete a set.
 */
export const deleteSet = mutation({
  args: {
    setId: v.id("sets"),
    apiKeyId: v.id("apiKeys"),
  },
  returns: v.null(),
  handler: async (ctx, args) => {
    const set = await ctx.db.get(args.setId);
    if (!set) {
      throw new Error("Set not found");
    }

    // Verify ownership
    if (set.apiKeyId !== args.apiKeyId) {
      throw new Error("Unauthorized");
    }

    await ctx.db.delete(args.setId);
    return null;
  },
});

/**
 * Get sets for a specific day (by creation time).
 * Returns sets created on the given date (in user's timezone offset).
 */
export const getSetsByDay = query({
  args: {
    apiKeyId: v.id("apiKeys"),
    // Unix timestamp for start of day (midnight in user's timezone)
    dayStartTimestamp: v.number(),
    // Unix timestamp for end of day
    dayEndTimestamp: v.number(),
  },
  returns: v.array(setReturnValidator),
  handler: async (ctx, args) => {
    // Get all sets for this API key
    const allSets = await ctx.db
      .query("sets")
      .withIndex("by_api_key", (q) => q.eq("apiKeyId", args.apiKeyId))
      .collect();

    // Filter by creation time range
    const setsForDay = allSets.filter(
      (set) =>
        set._creationTime >= args.dayStartTimestamp &&
        set._creationTime < args.dayEndTimestamp
    );

    return setsForDay;
  },
});

/**
 * Get all sets for a user (paginated by default).
 */
export const getSets = query({
  args: {
    apiKeyId: v.id("apiKeys"),
    limit: v.optional(v.number()),
  },
  returns: v.array(setReturnValidator),
  handler: async (ctx, args) => {
    const limit = args.limit ?? 100;

    const sets = await ctx.db
      .query("sets")
      .withIndex("by_api_key", (q) => q.eq("apiKeyId", args.apiKeyId))
      .order("desc")
      .take(limit);

    return sets;
  },
});

/**
 * Get sets by workout ID.
 */
export const getSetsByWorkout = query({
  args: {
    apiKeyId: v.id("apiKeys"),
    workoutId: v.string(),
  },
  returns: v.array(setReturnValidator),
  handler: async (ctx, args) => {
    const sets = await ctx.db
      .query("sets")
      .withIndex("by_workout", (q) => q.eq("workoutId", args.workoutId))
      .collect();

    // Filter by API key ownership
    return sets.filter((set) => set.apiKeyId === args.apiKeyId);
  },
});

/**
 * Get total work time for a day.
 */
export const getDayWorkTime = query({
  args: {
    apiKeyId: v.id("apiKeys"),
    dayStartTimestamp: v.number(),
    dayEndTimestamp: v.number(),
  },
  returns: v.object({
    totalWorkTime: v.number(),
    totalDuration: v.number(), // For cardio
    setCount: v.number(),
  }),
  handler: async (ctx, args) => {
    const allSets = await ctx.db
      .query("sets")
      .withIndex("by_api_key", (q) => q.eq("apiKeyId", args.apiKeyId))
      .collect();

    const setsForDay = allSets.filter(
      (set) =>
        set._creationTime >= args.dayStartTimestamp &&
        set._creationTime < args.dayEndTimestamp
    );

    const totalWorkTime = setsForDay.reduce(
      (sum, set) => sum + (set.workTime ?? 0),
      0
    );

    const totalDuration = setsForDay
      .filter((set) => set.exerciseType === "cardio")
      .reduce((sum, set) => sum + (set.duration ?? 0), 0);

    return {
      totalWorkTime,
      totalDuration,
      setCount: setsForDay.length,
    };
  },
});

/**
 * Get stats by exercise type for a day.
 */
export const getDayStatsByType = query({
  args: {
    apiKeyId: v.id("apiKeys"),
    dayStartTimestamp: v.number(),
    dayEndTimestamp: v.number(),
  },
  returns: v.object({
    resistance: v.object({
      setCount: v.number(),
      totalVolume: v.number(), // weight * reps
      totalWorkTime: v.number(),
    }),
    calisthenics: v.object({
      setCount: v.number(),
      totalReps: v.number(),
      totalWorkTime: v.number(),
    }),
    cardio: v.object({
      sessionCount: v.number(),
      totalDuration: v.number(),
    }),
  }),
  handler: async (ctx, args) => {
    const allSets = await ctx.db
      .query("sets")
      .withIndex("by_api_key", (q) => q.eq("apiKeyId", args.apiKeyId))
      .collect();

    const setsForDay = allSets.filter(
      (set) =>
        set._creationTime >= args.dayStartTimestamp &&
        set._creationTime < args.dayEndTimestamp
    );

    const resistanceSets = setsForDay.filter(
      (s) => s.exerciseType === "resistance"
    );
    const calisthenicsSets = setsForDay.filter(
      (s) => s.exerciseType === "calisthenics"
    );
    const cardioSets = setsForDay.filter((s) => s.exerciseType === "cardio");

    return {
      resistance: {
        setCount: resistanceSets.length,
        totalVolume: resistanceSets.reduce(
          (sum, s) => sum + (s.weight ?? 0) * (s.reps ?? 0),
          0
        ),
        totalWorkTime: resistanceSets.reduce(
          (sum, s) => sum + (s.workTime ?? 0),
          0
        ),
      },
      calisthenics: {
        setCount: calisthenicsSets.length,
        totalReps: calisthenicsSets.reduce((sum, s) => sum + (s.reps ?? 0), 0),
        totalWorkTime: calisthenicsSets.reduce(
          (sum, s) => sum + (s.workTime ?? 0),
          0
        ),
      },
      cardio: {
        sessionCount: cardioSets.length,
        totalDuration: cardioSets.reduce((sum, s) => sum + (s.duration ?? 0), 0),
      },
    };
  },
});

/**
 * Get exercise history - last N sets for a specific exercise.
 */
export const getExerciseHistory = query({
  args: {
    apiKeyId: v.id("apiKeys"),
    exerciseName: v.string(),
    limit: v.optional(v.number()),
  },
  returns: v.array(setReturnValidator),
  handler: async (ctx, args) => {
    const limit = args.limit ?? 20;

    const sets = await ctx.db
      .query("sets")
      .withIndex("by_api_key_and_exercise", (q) =>
        q.eq("apiKeyId", args.apiKeyId).eq("exerciseName", args.exerciseName)
      )
      .order("desc")
      .take(limit);

    return sets;
  },
});
