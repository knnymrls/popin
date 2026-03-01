import { v } from "convex/values";
import { mutation, query } from "./_generated/server";

export const create = mutation({
  args: {
    userId: v.optional(v.string()),
    title: v.string(),
    aiSummary: v.string(),
    estimatedCost: v.optional(v.string()),
    spotIds: v.array(v.id("spots")),
    suggestedTimes: v.optional(v.array(v.string())),
  },
  handler: async (ctx, args) => {
    const shareId = crypto.randomUUID().slice(0, 8);
    const planId = await ctx.db.insert("plans", {
      userId: args.userId,
      title: args.title,
      aiSummary: args.aiSummary,
      estimatedCost: args.estimatedCost,
      shareId,
      createdAt: Date.now(),
    });

    for (let i = 0; i < args.spotIds.length; i++) {
      await ctx.db.insert("planSpots", {
        planId,
        spotId: args.spotIds[i],
        order: i,
        suggestedTime: args.suggestedTimes?.[i],
      });
    }

    return { planId, shareId };
  },
});

export const getByShareId = query({
  args: { shareId: v.string() },
  handler: async (ctx, args) => {
    const plan = await ctx.db
      .query("plans")
      .withIndex("by_share_id", (q) => q.eq("shareId", args.shareId))
      .first();

    if (!plan) return null;

    const planSpots = await ctx.db
      .query("planSpots")
      .withIndex("by_plan", (q) => q.eq("planId", plan._id))
      .collect();

    const spots = await Promise.all(
      planSpots
        .sort((a, b) => a.order - b.order)
        .map(async (ps) => {
          const spot = await ctx.db.get(ps.spotId);
          return { ...spot, suggestedTime: ps.suggestedTime, notes: ps.notes };
        })
    );

    return { ...plan, spots };
  },
});

export const getByUser = query({
  args: { userId: v.optional(v.string()) },
  handler: async (ctx, args) => {
    if (!args.userId) return [];
    return await ctx.db
      .query("plans")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .order("desc")
      .take(20);
  },
});
