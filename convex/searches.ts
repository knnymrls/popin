import { v } from "convex/values";
import { mutation, query } from "./_generated/server";

export const create = mutation({
  args: {
    userId: v.optional(v.string()),
    query: v.string(),
    latitude: v.number(),
    longitude: v.number(),
    aiBlurb: v.string(),
    searchTerms: v.array(v.string()),
    vibeTags: v.array(v.string()),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("searches", {
      ...args,
      createdAt: Date.now(),
    });
  },
});

export const getRecent = query({
  args: { userId: v.optional(v.string()) },
  handler: async (ctx, args) => {
    if (!args.userId) return [];
    return await ctx.db
      .query("searches")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .order("desc")
      .take(20);
  },
});
