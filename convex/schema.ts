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

  // User taste profiles
  profiles: defineTable({
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
  })
    .index("by_user", ["userId"])
    .index("by_phone", ["phoneNumber"]),

  // Saved spots (favorites)
  favorites: defineTable({
    userId: v.string(),
    name: v.string(),
    address: v.string(),
    priceLevel: v.optional(v.number()),
    rating: v.optional(v.number()),
    types: v.array(v.string()),
    description: v.optional(v.string()),
  })
    .index("by_user", ["userId"])
    .index("by_user_name", ["userId", "name"]),

  // User-created plans (itineraries)
  plans: defineTable({
    userId: v.optional(v.string()),
    title: v.string(),
    aiSummary: v.string(),
    estimatedCost: v.optional(v.string()),
    totalDistance: v.optional(v.string()),
    totalTime: v.optional(v.string()),
    profiles: v.optional(v.array(v.string())),
    shareId: v.optional(v.string()),
    createdAt: v.number(),
  })
    .index("by_user", ["userId"])
    .index("by_share_id", ["shareId"]),

  // Spots within a plan, ordered
  planSpots: defineTable({
    planId: v.id("plans"),
    spotId: v.optional(v.id("spots")),
    emoji: v.optional(v.string()),
    name: v.optional(v.string()),
    cost: v.optional(v.string()),
    order: v.number(),
    suggestedTime: v.optional(v.string()),
    notes: v.optional(v.string()),
  }).index("by_plan", ["planId"]),

  // Friendships between users
  friendships: defineTable({
    requesterId: v.string(),
    addresseeId: v.string(),
    status: v.string(), // "pending" | "accepted" | "declined"
    createdAt: v.number(),
    acceptedAt: v.optional(v.number()),
  })
    .index("by_requester", ["requesterId"])
    .index("by_addressee", ["addresseeId"])
    .index("by_pair", ["requesterId", "addresseeId"]),

  // Shared plans between friends
  sharedPlans: defineTable({
    planId: v.id("plans"),
    senderId: v.string(),
    recipientId: v.string(),
    shareType: v.string(), // "hangout" | "recommendation"
    message: v.optional(v.string()),
    rsvp: v.string(), // "pending" | "accepted" | "declined"
    createdAt: v.number(),
  })
    .index("by_recipient", ["recipientId"])
    .index("by_sender", ["senderId"])
    .index("by_plan", ["planId"]),

  // SMS invites with deep link codes
  invites: defineTable({
    inviterId: v.string(),
    inviteCode: v.string(),
    inviteePhone: v.optional(v.string()),
    claimedByUserId: v.optional(v.string()),
    status: v.string(), // "sent" | "claimed"
    createdAt: v.number(),
  })
    .index("by_code", ["inviteCode"])
    .index("by_inviter", ["inviterId"]),
});
