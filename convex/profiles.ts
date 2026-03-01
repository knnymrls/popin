import { v } from "convex/values";
import { mutation, query, internalQuery } from "./_generated/server";

export const upsert = mutation({
  args: {
    userId: v.string(),
    name: v.string(),
    phoneNumber: v.optional(v.string()),
    avatarEmoji: v.optional(v.string()),
    budget: v.optional(v.string()),
    vibes: v.array(v.string()),
    foodLoves: v.array(v.string()),
    foodAvoids: v.array(v.string()),
    activities: v.array(v.string()),
    dealbreakers: v.array(v.string()),
    notes: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("profiles")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .first();

    if (existing) {
      await ctx.db.patch(existing._id, {
        name: args.name,
        phoneNumber: args.phoneNumber,
        avatarEmoji: args.avatarEmoji,
        budget: args.budget,
        vibes: args.vibes,
        foodLoves: args.foodLoves,
        foodAvoids: args.foodAvoids,
        activities: args.activities,
        dealbreakers: args.dealbreakers,
        notes: args.notes,
      });
      return existing._id;
    }

    return await ctx.db.insert("profiles", args);
  },
});

export const get = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("profiles")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .first();
  },
});

export const list = query({
  args: {},
  handler: async (ctx) => {
    return await ctx.db.query("profiles").collect();
  },
});

export const getInternal = internalQuery({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("profiles")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .first();
  },
});
