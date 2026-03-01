import { v } from "convex/values";
import { mutation, query, internalMutation } from "./_generated/server";

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

export const createWithStops = mutation({
  args: {
    userId: v.optional(v.string()),
    title: v.string(),
    aiSummary: v.string(),
    estimatedCost: v.optional(v.string()),
    totalDistance: v.optional(v.string()),
    totalTime: v.optional(v.string()),
    profiles: v.optional(v.array(v.string())),
    stops: v.array(
      v.object({
        spotId: v.optional(v.id("spots")),
        emoji: v.optional(v.string()),
        name: v.optional(v.string()),
        cost: v.optional(v.string()),
        suggestedTime: v.optional(v.string()),
        notes: v.optional(v.string()),
      })
    ),
  },
  handler: async (ctx, args) => {
    const shareId = crypto.randomUUID().slice(0, 8);
    const planId = await ctx.db.insert("plans", {
      userId: args.userId,
      title: args.title,
      aiSummary: args.aiSummary,
      estimatedCost: args.estimatedCost,
      totalDistance: args.totalDistance,
      totalTime: args.totalTime,
      profiles: args.profiles,
      shareId,
      createdAt: Date.now(),
    });

    for (let i = 0; i < args.stops.length; i++) {
      const stop = args.stops[i];
      await ctx.db.insert("planSpots", {
        planId,
        spotId: stop.spotId,
        emoji: stop.emoji,
        name: stop.name,
        cost: stop.cost,
        order: i,
        suggestedTime: stop.suggestedTime,
        notes: stop.notes,
      });
    }

    return { planId, shareId };
  },
});

export const createWithStopsInternal = internalMutation({
  args: {
    userId: v.optional(v.string()),
    title: v.string(),
    aiSummary: v.string(),
    estimatedCost: v.optional(v.string()),
    totalDistance: v.optional(v.string()),
    totalTime: v.optional(v.string()),
    profiles: v.optional(v.array(v.string())),
    stops: v.array(
      v.object({
        emoji: v.optional(v.string()),
        name: v.optional(v.string()),
        cost: v.optional(v.string()),
        suggestedTime: v.optional(v.string()),
        notes: v.optional(v.string()),
      })
    ),
  },
  handler: async (ctx, args) => {
    const shareId = crypto.randomUUID().slice(0, 8);
    const planId = await ctx.db.insert("plans", {
      userId: args.userId,
      title: args.title,
      aiSummary: args.aiSummary,
      estimatedCost: args.estimatedCost,
      totalDistance: args.totalDistance,
      totalTime: args.totalTime,
      profiles: args.profiles,
      shareId,
      createdAt: Date.now(),
    });

    for (let i = 0; i < args.stops.length; i++) {
      const stop = args.stops[i];
      await ctx.db.insert("planSpots", {
        planId,
        emoji: stop.emoji,
        name: stop.name,
        cost: stop.cost,
        order: i,
        suggestedTime: stop.suggestedTime,
        notes: stop.notes,
      });
    }

    return { planId, shareId };
  },
});

export const getWithStops = query({
  args: { planId: v.id("plans") },
  handler: async (ctx, args) => {
    const plan = await ctx.db.get(args.planId);
    if (!plan) return null;

    const planSpots = await ctx.db
      .query("planSpots")
      .withIndex("by_plan", (q) => q.eq("planId", args.planId))
      .collect();

    const stops = await Promise.all(
      planSpots
        .sort((a, b) => a.order - b.order)
        .map(async (ps) => {
          const spot = ps.spotId ? await ctx.db.get(ps.spotId) : null;
          return {
            ...ps,
            spot,
          };
        })
    );

    return { ...plan, stops };
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

    const stops = await Promise.all(
      planSpots
        .sort((a, b) => a.order - b.order)
        .map(async (ps) => {
          const spot = ps.spotId ? await ctx.db.get(ps.spotId) : null;
          return {
            ...ps,
            spot,
          };
        })
    );

    return { ...plan, stops };
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
