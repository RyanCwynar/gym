import { mutation, query, internalMutation, internalQuery } from "./_generated/server";
import { v } from "convex/values";

// Generate a random API key
function generateApiKey(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const segments = [8, 4, 4, 4, 12];
  
  return segments.map(len => {
    let segment = '';
    for (let i = 0; i < len; i++) {
      segment += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return segment;
  }).join('-');
}

// Create a new API key - INTERNAL ONLY (use from dashboard/CLI)
export const createKey = internalMutation({
  args: {
    name: v.string(),
  },
  handler: async (ctx, args) => {
    const key = generateApiKey();
    
    const id = await ctx.db.insert("apiKeys", {
      key,
      name: args.name,
      createdAt: Date.now(),
      isActive: true,
    });
    
    return { id, key, name: args.name };
  },
});

// Validate an API key and update last used
export const validateKey = mutation({
  args: {
    key: v.string(),
  },
  handler: async (ctx, args) => {
    const apiKey = await ctx.db
      .query("apiKeys")
      .withIndex("by_key", (q) => q.eq("key", args.key))
      .first();
    
    if (!apiKey) {
      return { valid: false, error: "API key not found" };
    }
    
    if (!apiKey.isActive) {
      return { valid: false, error: "API key is inactive" };
    }
    
    // Update last used timestamp
    await ctx.db.patch(apiKey._id, {
      lastUsedAt: Date.now(),
    });
    
    return { valid: true, name: apiKey.name };
  },
});

// List all API keys - INTERNAL ONLY (for admin/dashboard)
export const listKeys = internalQuery({
  args: {},
  handler: async (ctx) => {
    const keys = await ctx.db.query("apiKeys").collect();
    
    // Don't expose the full key, just show first/last few chars
    return keys.map(k => ({
      id: k._id,
      name: k.name,
      keyPreview: `${k.key.substring(0, 8)}...${k.key.substring(k.key.length - 4)}`,
      createdAt: k.createdAt,
      lastUsedAt: k.lastUsedAt,
      isActive: k.isActive,
    }));
  },
});

// Get full key details - INTERNAL ONLY
export const getKey = internalQuery({
  args: {
    id: v.id("apiKeys"),
  },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.id);
  },
});

// Deactivate an API key - INTERNAL ONLY
export const deactivateKey = internalMutation({
  args: {
    key: v.string(),
  },
  handler: async (ctx, args) => {
    const apiKey = await ctx.db
      .query("apiKeys")
      .withIndex("by_key", (q) => q.eq("key", args.key))
      .first();
    
    if (!apiKey) {
      return { success: false, error: "API key not found" };
    }
    
    await ctx.db.patch(apiKey._id, {
      isActive: false,
    });
    
    return { success: true };
  },
});

// Reactivate an API key - INTERNAL ONLY
export const reactivateKey = internalMutation({
  args: {
    key: v.string(),
  },
  handler: async (ctx, args) => {
    const apiKey = await ctx.db
      .query("apiKeys")
      .withIndex("by_key", (q) => q.eq("key", args.key))
      .first();
    
    if (!apiKey) {
      return { success: false, error: "API key not found" };
    }
    
    await ctx.db.patch(apiKey._id, {
      isActive: true,
    });
    
    return { success: true };
  },
});

// Delete an API key - INTERNAL ONLY
export const deleteKey = internalMutation({
  args: {
    key: v.string(),
    deleteData: v.optional(v.boolean()),
  },
  handler: async (ctx, args) => {
    const apiKey = await ctx.db
      .query("apiKeys")
      .withIndex("by_key", (q) => q.eq("key", args.key))
      .first();
    
    if (!apiKey) {
      return { success: false, error: "API key not found" };
    }
    
    // Optionally delete all exercise logs for this key
    if (args.deleteData) {
      const logs = await ctx.db
        .query("exerciseLogs")
        .withIndex("by_apiKeyId", (q) => q.eq("apiKeyId", apiKey._id))
        .collect();
      
      for (const log of logs) {
        await ctx.db.delete(log._id);
      }
    }
    
    await ctx.db.delete(apiKey._id);
    
    return { success: true };
  },
});

