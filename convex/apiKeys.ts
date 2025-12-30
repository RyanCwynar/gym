import {
  internalMutation,
  internalQuery,
  mutation,
  query,
} from "./_generated/server";
import { v } from "convex/values";
import { internal } from "./_generated/api";

// Simple hash function for API keys (in production, use a proper crypto hash)
function hashKey(key: string): string {
  let hash = 0;
  for (let i = 0; i < key.length; i++) {
    const char = key.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash = hash & hash; // Convert to 32bit integer
  }
  return Math.abs(hash).toString(16).padStart(8, "0");
}

// Generate a random API key
function generateApiKey(): string {
  const chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let result = "gym_";
  for (let i = 0; i < 32; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

/**
 * Internal action to create a new API key.
 * Returns the full key (only shown once) and the key ID.
 */
export const createApiKey = internalMutation({
  args: {
    name: v.string(),
  },
  returns: v.object({
    keyId: v.id("apiKeys"),
    apiKey: v.string(),
    keyPrefix: v.string(),
  }),
  handler: async (ctx, args) => {
    const apiKey = generateApiKey();
    const keyHash = hashKey(apiKey);
    const keyPrefix = apiKey.substring(0, 12); // "gym_" + 8 chars

    const keyId = await ctx.db.insert("apiKeys", {
      name: args.name,
      keyHash,
      keyPrefix,
      isActive: true,
      createdAt: Date.now(),
    });

    return {
      keyId,
      apiKey,
      keyPrefix,
    };
  },
});

/**
 * Validate an API key and return the key document if valid.
 */
export const validateApiKey = internalQuery({
  args: {
    apiKey: v.string(),
  },
  returns: v.union(
    v.object({
      _id: v.id("apiKeys"),
      _creationTime: v.number(),
      name: v.string(),
      keyHash: v.string(),
      keyPrefix: v.string(),
      isActive: v.boolean(),
      lastUsedAt: v.optional(v.number()),
      createdAt: v.number(),
    }),
    v.null()
  ),
  handler: async (ctx, args) => {
    const keyHash = hashKey(args.apiKey);

    const apiKeyDoc = await ctx.db
      .query("apiKeys")
      .withIndex("by_key_hash", (q) => q.eq("keyHash", keyHash))
      .unique();

    if (!apiKeyDoc || !apiKeyDoc.isActive) {
      return null;
    }

    return apiKeyDoc;
  },
});

/**
 * Update last used timestamp for an API key.
 */
export const touchApiKey = internalMutation({
  args: {
    keyId: v.id("apiKeys"),
  },
  returns: v.null(),
  handler: async (ctx, args) => {
    await ctx.db.patch(args.keyId, {
      lastUsedAt: Date.now(),
    });
    return null;
  },
});

/**
 * Deactivate an API key.
 */
export const deactivateApiKey = internalMutation({
  args: {
    keyId: v.id("apiKeys"),
  },
  returns: v.null(),
  handler: async (ctx, args) => {
    await ctx.db.patch(args.keyId, {
      isActive: false,
    });
    return null;
  },
});

/**
 * List all API keys (without sensitive data).
 */
export const listApiKeys = internalQuery({
  args: {},
  returns: v.array(
    v.object({
      _id: v.id("apiKeys"),
      name: v.string(),
      keyPrefix: v.string(),
      isActive: v.boolean(),
      lastUsedAt: v.optional(v.number()),
      createdAt: v.number(),
    })
  ),
  handler: async (ctx) => {
    const keys = await ctx.db.query("apiKeys").collect();
    return keys.map((key) => ({
      _id: key._id,
      name: key.name,
      keyPrefix: key.keyPrefix,
      isActive: key.isActive,
      lastUsedAt: key.lastUsedAt,
      createdAt: key.createdAt,
    }));
  },
});
