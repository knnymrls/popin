import { v } from "convex/values";
import { mutation, query } from "./_generated/server";

export const add = mutation({
  args: {
    userId: v.string(),
    name: v.string(),
    address: v.string(),
    photoUrl: v.optional(v.string()),
    priceLevel: v.optional(v.number()),
    rating: v.optional(v.number()),
    types: v.array(v.string()),
    description: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    // Dedup by userId + name
    const existing = await ctx.db
      .query("favorites")
      .withIndex("by_user_name", (q) =>
        q.eq("userId", args.userId).eq("name", args.name)
      )
      .first();

    if (existing) return existing._id;

    return await ctx.db.insert("favorites", args);
  },
});

export const remove = mutation({
  args: {
    userId: v.string(),
    name: v.string(),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("favorites")
      .withIndex("by_user_name", (q) =>
        q.eq("userId", args.userId).eq("name", args.name)
      )
      .first();

    if (existing) {
      await ctx.db.delete(existing._id);
    }
  },
});

export const list = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("favorites")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .collect();
  },
});
