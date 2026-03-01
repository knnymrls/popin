import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // AI search queries and cached results
  searches: defineTable({
    userId: v.optional(v.string()),
    query: v.string(),
    latitude: v.number(),
    longitude: v.number(),
    aiBlurb: v.string(),
    searchTerms: v.array(v.string()),
    vibeTags: v.array(v.string()),
    createdAt: v.number(),
  }).index("by_user", ["userId"]),

  // Places returned from search results
  spots: defineTable({
    searchId: v.id("searches"),
    placeId: v.string(), // Google Places ID
    name: v.string(),
    latitude: v.number(),
    longitude: v.number(),
    address: v.string(),
    photoUrl: v.optional(v.string()),
    rating: v.optional(v.number()),
    priceLevel: v.optional(v.number()),
    oneLiner: v.string(),
    vibeTags: v.array(v.string()),
    // Perplexity deep detail (fetched on tap)
    deepDetail: v.optional(v.string()),
  }).index("by_search", ["searchId"]),

  // User-created plans (itineraries)
  plans: defineTable({
    userId: v.optional(v.string()),
    title: v.string(),
    aiSummary: v.string(),
    estimatedCost: v.optional(v.string()),
    shareId: v.optional(v.string()), // unique ID for sharing
    createdAt: v.number(),
  })
    .index("by_user", ["userId"])
    .index("by_share_id", ["shareId"]),

  // Spots within a plan, ordered
  planSpots: defineTable({
    planId: v.id("plans"),
    spotId: v.id("spots"),
    order: v.number(),
    suggestedTime: v.optional(v.string()),
    notes: v.optional(v.string()),
  }).index("by_plan", ["planId"]),
});
