import { v } from "convex/values";
import { internalMutation, mutation, query } from "./_generated/server";

export const addToSearch = mutation({
  args: {
    searchId: v.id("searches"),
    placeId: v.string(),
    name: v.string(),
    latitude: v.number(),
    longitude: v.number(),
    address: v.string(),
    photoUrl: v.optional(v.string()),
    rating: v.optional(v.number()),
    priceLevel: v.optional(v.number()),
    oneLiner: v.string(),
    vibeTags: v.array(v.string()),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("spots", args);
  },
});

export const addToSearchInternal = internalMutation({
  args: {
    searchId: v.id("searches"),
    placeId: v.string(),
    name: v.string(),
    latitude: v.number(),
    longitude: v.number(),
    address: v.string(),
    photoUrl: v.optional(v.string()),
    rating: v.optional(v.number()),
    priceLevel: v.optional(v.number()),
    oneLiner: v.string(),
    vibeTags: v.array(v.string()),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("spots", args);
  },
});

export const getBySearch = query({
  args: { searchId: v.id("searches") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("spots")
      .withIndex("by_search", (q) => q.eq("searchId", args.searchId))
      .collect();
  },
});

export const setDeepDetail = mutation({
  args: {
    spotId: v.id("spots"),
    deepDetail: v.string(),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.spotId, { deepDetail: args.deepDetail });
  },
});
