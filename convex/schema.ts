import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema(
  {
    // Exercise library/templates
    exercises: defineTable({
      name: v.string(),
      muscleGroup: v.string(),
      description: v.optional(v.string()),
      defaultWeight: v.optional(v.number()),
      defaultWeightUnit: v.optional(v.string()),
      isPrimary: v.optional(v.boolean()),
      exerciseType: v.union(
        v.literal("resistance"),
        v.literal("calisthenics"),
        v.literal("cardio")
      ),
    })
      .index("by_name", ["name"])
      .index("by_muscle_group", ["muscleGroup"])
      .index("by_type", ["exerciseType"]),

    // Individual workout sets
    sets: defineTable({
      // API key association for multi-user support
      apiKeyId: v.id("apiKeys"),

      // Exercise reference (can be from library or custom name)
      exerciseId: v.optional(v.id("exercises")),
      exerciseName: v.string(),

      // Set data
      weight: v.optional(v.number()),
      weightUnit: v.optional(v.string()), // "lbs", "kg"
      reps: v.optional(v.number()),
      workTime: v.optional(v.number()), // Time spent executing the set in seconds

      // Exercise type determines which fields are relevant
      exerciseType: v.union(
        v.literal("resistance"),
        v.literal("calisthenics"),
        v.literal("cardio")
      ),

      // Cardio-specific
      duration: v.optional(v.number()), // Duration in seconds for cardio

      // Metadata
      notes: v.optional(v.string()),
      isCompleted: v.optional(v.boolean()),
      completedAt: v.optional(v.number()), // Timestamp when completed

      // For grouping sets into workouts/sessions
      workoutId: v.optional(v.string()), // UUID from client to group sets
      setOrder: v.optional(v.number()), // Order within workout/exercise
    })
      .index("by_api_key", ["apiKeyId"])
      .index("by_workout", ["workoutId"])
      .index("by_api_key_and_exercise", ["apiKeyId", "exerciseName"])
      .index("by_api_key_and_type", ["apiKeyId", "exerciseType"]),

    // API keys for authentication
    apiKeys: defineTable({
      name: v.string(), // Human-readable name for the key
      keyHash: v.string(), // Hashed version of the API key (never store raw)
      keyPrefix: v.string(), // First 8 chars for identification
      isActive: v.boolean(),
      lastUsedAt: v.optional(v.number()),
      createdAt: v.number(),
    })
      .index("by_key_hash", ["keyHash"])
      .index("by_key_prefix", ["keyPrefix"])
      .index("by_active", ["isActive"]),
  },
  { schemaValidation: true }
);
