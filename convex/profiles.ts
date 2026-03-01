import { v } from "convex/values";
import { mutation, query, internalQuery } from "./_generated/server";

export const upsert = mutation({
  args: {
    userId: v.string(),
    name: v.string(),
    phoneNumber: v.optional(v.string()),
    avatarEmoji: v.optional(v.string()),
    profileImageUrl: v.optional(v.string()),
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
        profileImageUrl: args.profileImageUrl,
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

/** Seed a profile for the current user with preset data */
export const seedProfile = mutation({
  args: {
    userId: v.string(),
    name: v.string(),
    preset: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("profiles")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .first();

    if (existing) {
      return { seeded: false, message: "Profile already exists" };
    }

    const presets: Record<
      string,
      {
        avatarEmoji: string;
        profileImageUrl: string;
        budget: string;
        vibes: string[];
        foodLoves: string[];
        foodAvoids: string[];
        activities: string[];
        dealbreakers: string[];
        notes: string;
      }
    > = {
      kenny: {
        avatarEmoji: "🔥",
        profileImageUrl: "https://i.pravatar.cc/200?u=kenny_morales",
        budget: "moderate",
        vibes: ["chill", "lowkey", "adventurous", "casual"],
        foodLoves: ["tacos", "ramen", "coffee", "pizza", "bbq", "wings"],
        foodAvoids: [],
        activities: [
          "coffee shops",
          "bars",
          "live music",
          "outdoor dining",
          "breweries",
        ],
        dealbreakers: ["too crowded", "slow service"],
        notes: "Down for anything spontaneous. Lincoln local.",
      },
      alyn: {
        avatarEmoji: "💜",
        profileImageUrl: "https://i.pravatar.cc/200?u=alyn_popin",
        budget: "moderate",
        vibes: ["cozy", "trendy", "romantic", "chill"],
        foodLoves: [
          "sushi",
          "brunch",
          "coffee",
          "dessert",
          "mediterranean",
          "thai",
        ],
        foodAvoids: ["spicy"],
        activities: [
          "coffee shops",
          "shopping",
          "movies",
          "wine tasting",
          "thrifting",
          "concerts",
        ],
        dealbreakers: ["too loud", "long wait"],
        notes: "Loves a good vibe. Always finding the cutest spots.",
      },
    };

    const data = presets[args.preset ?? "kenny"] ?? presets["kenny"];

    await ctx.db.insert("profiles", {
      userId: args.userId,
      name: args.name,
      ...data,
    });

    return { seeded: true, message: "Profile created" };
  },
});

/** One-off: backfill profileImageUrl on all profiles that don't have one */
export const backfillProfileImages = mutation({
  args: {},
  handler: async (ctx) => {
    const all = await ctx.db.query("profiles").collect();
    let updated = 0;

    for (const profile of all) {
      if (profile.profileImageUrl) continue;

      const slug = profile.name.toLowerCase().replace(/\s+/g, "_");
      await ctx.db.patch(profile._id, {
        profileImageUrl: `https://i.pravatar.cc/200?u=${slug}`,
      });
      updated++;
    }

    return { updated, total: all.length };
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
