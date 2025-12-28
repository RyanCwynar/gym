import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // API Keys - used to identify users/devices
  apiKeys: defineTable({
    // The actual key (a random string)
    key: v.string(),
    
    // Human-readable name for the key
    name: v.string(),
    
    // When the key was created
    createdAt: v.number(),
    
    // Optional: when the key was last used
    lastUsedAt: v.optional(v.number()),
    
    // Whether the key is active
    isActive: v.boolean(),
  })
    .index("by_key", ["key"]),

  // Exercise logs - each set logged by the user
  exerciseLogs: defineTable({
    // Client-generated UUID for offline-first sync
    clientId: v.string(),
    
    // Reference to the API key that owns this log
    apiKeyId: v.id("apiKeys"),
    
    // Exercise info
    exerciseName: v.string(),
    muscleGroup: v.string(),
    exerciseType: v.union(v.literal("strength"), v.literal("cardio")),
    
    // For strength exercises
    reps: v.optional(v.number()),
    weight: v.optional(v.number()),
    setNumber: v.optional(v.number()),
    
    // For cardio exercises
    duration: v.optional(v.number()), // in seconds
    
    // Work time (time under tension for strength, or duration for cardio)
    workTime: v.optional(v.number()), // in seconds
    
    // When the exercise was performed
    performedAt: v.number(), // Unix timestamp
    
    // Completion status
    isCompleted: v.boolean(),
  })
    .index("by_clientId", ["clientId"])
    .index("by_apiKeyId", ["apiKeyId"])
    .index("by_performedAt", ["performedAt"])
    .index("by_exerciseName", ["exerciseName"]),
});

