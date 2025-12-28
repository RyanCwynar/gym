import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { Id } from "./_generated/dataModel";

// Helper to look up API key and return its ID if valid
async function getApiKeyId(ctx: any, apiKey: string): Promise<Id<"apiKeys"> | null> {
  const key = await ctx.db
    .query("apiKeys")
    .withIndex("by_key", (q: any) => q.eq("key", apiKey))
    .first();
  
  if (!key || !key.isActive) {
    return null;
  }
  
  // Update last used
  await ctx.db.patch(key._id, { lastUsedAt: Date.now() });
  return key._id;
}

// Sync a batch of exercise logs from the client
export const syncLogs = mutation({
  args: {
    apiKey: v.string(),
    logs: v.array(
      v.object({
        clientId: v.string(),
        exerciseName: v.string(),
        muscleGroup: v.string(),
        exerciseType: v.union(v.literal("strength"), v.literal("cardio")),
        reps: v.optional(v.number()),
        weight: v.optional(v.number()),
        setNumber: v.optional(v.number()),
        duration: v.optional(v.number()),
        workTime: v.optional(v.number()),
        performedAt: v.number(),
        isCompleted: v.boolean(),
      })
    ),
  },
  handler: async (ctx, args) => {
    // Look up API key and get its ID
    const apiKeyId = await getApiKeyId(ctx, args.apiKey);
    if (!apiKeyId) {
      return { success: false, error: "Invalid or inactive API key", results: [] };
    }
    
    const results = [];
    
    for (const log of args.logs) {
      // Check if this log already exists (by clientId)
      const existing = await ctx.db
        .query("exerciseLogs")
        .withIndex("by_clientId", (q) => q.eq("clientId", log.clientId))
        .first();
      
      if (existing) {
        // Only update if owned by this API key ID
        if (existing.apiKeyId !== apiKeyId) {
          results.push({ clientId: log.clientId, action: "skipped", reason: "owned by different key" });
          continue;
        }
        
        // Update existing record
        await ctx.db.patch(existing._id, {
          exerciseName: log.exerciseName,
          muscleGroup: log.muscleGroup,
          exerciseType: log.exerciseType,
          reps: log.reps,
          weight: log.weight,
          setNumber: log.setNumber,
          duration: log.duration,
          workTime: log.workTime,
          performedAt: log.performedAt,
          isCompleted: log.isCompleted,
        });
        results.push({ clientId: log.clientId, action: "updated" });
      } else {
        // Insert new record with API key ID
        await ctx.db.insert("exerciseLogs", {
          clientId: log.clientId,
          apiKeyId: apiKeyId,
          exerciseName: log.exerciseName,
          muscleGroup: log.muscleGroup,
          exerciseType: log.exerciseType,
          reps: log.reps,
          weight: log.weight,
          setNumber: log.setNumber,
          duration: log.duration,
          workTime: log.workTime,
          performedAt: log.performedAt,
          isCompleted: log.isCompleted,
        });
        results.push({ clientId: log.clientId, action: "created" });
      }
    }
    
    return { success: true, results };
  },
});

// Get all logs for an API key
export const getLogs = query({
  args: {
    apiKey: v.string(),
    since: v.optional(v.number()), // Unix timestamp to get logs after
  },
  handler: async (ctx, args) => {
    // Look up the API key to get its ID
    const key = await ctx.db
      .query("apiKeys")
      .withIndex("by_key", (q) => q.eq("key", args.apiKey))
      .first();
    
    if (!key) {
      return [];
    }
    
    // Get logs for this API key ID
    let logs = await ctx.db
      .query("exerciseLogs")
      .withIndex("by_apiKeyId", (q) => q.eq("apiKeyId", key._id))
      .collect();
    
    // Filter by date if provided
    if (args.since) {
      logs = logs.filter((log) => log.performedAt >= args.since);
    }
    
    return logs;
  },
});

// Get logs for a specific date range
export const getLogsByDateRange = query({
  args: {
    apiKey: v.string(),
    startDate: v.number(),
    endDate: v.number(),
  },
  handler: async (ctx, args) => {
    // Look up the API key to get its ID
    const key = await ctx.db
      .query("apiKeys")
      .withIndex("by_key", (q) => q.eq("key", args.apiKey))
      .first();
    
    if (!key) {
      return [];
    }
    
    const logs = await ctx.db
      .query("exerciseLogs")
      .withIndex("by_apiKeyId", (q) => q.eq("apiKeyId", key._id))
      .collect();
    
    return logs.filter(
      (log) => log.performedAt >= args.startDate && log.performedAt <= args.endDate
    );
  },
});

// Delete a log by clientId (must be owned by the API key)
export const deleteLog = mutation({
  args: {
    apiKey: v.string(),
    clientId: v.string(),
  },
  handler: async (ctx, args) => {
    // Look up the API key to get its ID
    const key = await ctx.db
      .query("apiKeys")
      .withIndex("by_key", (q) => q.eq("key", args.apiKey))
      .first();
    
    if (!key) {
      return { success: false, error: "Invalid API key" };
    }
    
    const existing = await ctx.db
      .query("exerciseLogs")
      .withIndex("by_clientId", (q) => q.eq("clientId", args.clientId))
      .first();
    
    if (!existing) {
      return { success: false, error: "Log not found" };
    }
    
    if (existing.apiKeyId !== key._id) {
      return { success: false, error: "Not authorized to delete this log" };
    }
    
    await ctx.db.delete(existing._id);
    return { success: true };
  },
});

// Get stats for an API key
export const getStats = query({
  args: {
    apiKey: v.string(),
  },
  handler: async (ctx, args) => {
    // Look up the API key to get its ID
    const key = await ctx.db
      .query("apiKeys")
      .withIndex("by_key", (q) => q.eq("key", args.apiKey))
      .first();
    
    if (!key) {
      return {
        totalLogs: 0,
        completedLogs: 0,
        totalVolume: 0,
        totalWorkTime: 0,
        uniqueExercises: 0,
        exerciseNames: [],
        firstLogDate: null,
        lastLogDate: null,
      };
    }
    
    const logs = await ctx.db
      .query("exerciseLogs")
      .withIndex("by_apiKeyId", (q) => q.eq("apiKeyId", key._id))
      .collect();
    
    const totalLogs = logs.length;
    const completedLogs = logs.filter((l) => l.isCompleted).length;
    const totalVolume = logs.reduce((sum, l) => {
      if (l.exerciseType === "strength" && l.weight && l.reps) {
        return sum + (l.weight * l.reps);
      }
      return sum;
    }, 0);
    const totalWorkTime = logs.reduce((sum, l) => sum + (l.workTime || 0), 0);
    
    // Get unique exercise names
    const exercises = [...new Set(logs.map((l) => l.exerciseName))];
    
    // Get date range
    const dates = logs.map((l) => l.performedAt).sort();
    
    return {
      totalLogs,
      completedLogs,
      totalVolume,
      totalWorkTime,
      uniqueExercises: exercises.length,
      exerciseNames: exercises,
      firstLogDate: dates[0] || null,
      lastLogDate: dates[dates.length - 1] || null,
    };
  },
});

