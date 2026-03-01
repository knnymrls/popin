import { v } from "convex/values";
import { mutation, query, internalQuery, action } from "./_generated/server";
import { internal } from "./_generated/api";

// ── Queries ──────────────────────────────────────────────────────────

/** Get all accepted friends with their profile data */
export const getFriends = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    // Find friendships where this user is on either side, status = accepted
    const asRequester = await ctx.db
      .query("friendships")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.userId))
      .collect();

    const asAddressee = await ctx.db
      .query("friendships")
      .withIndex("by_addressee", (q) => q.eq("addresseeId", args.userId))
      .collect();

    const accepted = [
      ...asRequester.filter((f) => f.status === "accepted"),
      ...asAddressee.filter((f) => f.status === "accepted"),
    ];

    // For each friendship, load the OTHER user's profile
    const friends = await Promise.all(
      accepted.map(async (f) => {
        const friendUserId =
          f.requesterId === args.userId ? f.addresseeId : f.requesterId;
        const profile = await ctx.db
          .query("profiles")
          .withIndex("by_user", (q) => q.eq("userId", friendUserId))
          .first();

        if (!profile) return null;

        return {
          _id: profile._id,
          friendshipId: f._id,
          userId: profile.userId,
          name: profile.name,
          avatarEmoji: profile.avatarEmoji ?? null,
          profileImageUrl: profile.profileImageUrl ?? null,
          budget: profile.budget ?? null,
          vibes: profile.vibes,
          foodLoves: profile.foodLoves,
          foodAvoids: profile.foodAvoids,
          activities: profile.activities,
          dealbreakers: profile.dealbreakers,
          notes: profile.notes ?? null,
        };
      })
    );

    return friends.filter(Boolean);
  },
});

/** Get incoming pending friend requests */
export const getPendingRequests = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    const incoming = await ctx.db
      .query("friendships")
      .withIndex("by_addressee", (q) => q.eq("addresseeId", args.userId))
      .collect();

    const pending = incoming.filter((f) => f.status === "pending");

    const requests = await Promise.all(
      pending.map(async (f) => {
        const profile = await ctx.db
          .query("profiles")
          .withIndex("by_user", (q) => q.eq("userId", f.requesterId))
          .first();

        return {
          _id: f._id,
          requesterId: f.requesterId,
          addresseeId: f.addresseeId,
          status: f.status,
          createdAt: f.createdAt,
          requesterName: profile?.name ?? "Unknown",
          requesterEmoji: profile?.avatarEmoji ?? null,
          requesterImageUrl: profile?.profileImageUrl ?? null,
        };
      })
    );

    return requests;
  },
});

/** Get outgoing pending friend requests */
export const getOutgoingRequests = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    const outgoing = await ctx.db
      .query("friendships")
      .withIndex("by_requester", (q) => q.eq("requesterId", args.userId))
      .collect();

    const pending = outgoing.filter((f) => f.status === "pending");

    const requests = await Promise.all(
      pending.map(async (f) => {
        const profile = await ctx.db
          .query("profiles")
          .withIndex("by_user", (q) => q.eq("userId", f.addresseeId))
          .first();

        return {
          _id: f._id,
          requesterId: f.requesterId,
          addresseeId: f.addresseeId,
          status: f.status,
          createdAt: f.createdAt,
          addresseeName: profile?.name ?? "Unknown",
          addresseeEmoji: profile?.avatarEmoji ?? null,
          addresseeImageUrl: profile?.profileImageUrl ?? null,
        };
      })
    );

    return requests;
  },
});

/** Get plans shared with this user */
export const getSharedPlans = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    const shared = await ctx.db
      .query("sharedPlans")
      .withIndex("by_recipient", (q) => q.eq("recipientId", args.userId))
      .collect();

    const items = await Promise.all(
      shared.map(async (sp) => {
        const plan = await ctx.db.get(sp.planId);
        const senderProfile = await ctx.db
          .query("profiles")
          .withIndex("by_user", (q) => q.eq("userId", sp.senderId))
          .first();

        return {
          _id: sp._id,
          planId: sp.planId,
          senderId: sp.senderId,
          recipientId: sp.recipientId,
          shareType: sp.shareType,
          message: sp.message ?? null,
          rsvp: sp.rsvp,
          createdAt: sp.createdAt,
          senderName: senderProfile?.name ?? "Unknown",
          senderEmoji: senderProfile?.avatarEmoji ?? null,
          senderImageUrl: senderProfile?.profileImageUrl ?? null,
          planTitle: plan?.title ?? "Untitled",
          planSummary: plan?.aiSummary ?? "",
        };
      })
    );

    // Most recent first
    return items.sort((a, b) => b.createdAt - a.createdAt);
  },
});

/** Get a single friend's full profile (only if connected) */
export const getFriendProfile = query({
  args: { userId: v.string(), friendUserId: v.string() },
  handler: async (ctx, args) => {
    // Verify they are friends
    const f1 = await ctx.db
      .query("friendships")
      .withIndex("by_pair", (q) =>
        q.eq("requesterId", args.userId).eq("addresseeId", args.friendUserId)
      )
      .first();

    const f2 = await ctx.db
      .query("friendships")
      .withIndex("by_pair", (q) =>
        q.eq("requesterId", args.friendUserId).eq("addresseeId", args.userId)
      )
      .first();

    const friendship = f1 ?? f2;
    if (!friendship || friendship.status !== "accepted") return null;

    const profile = await ctx.db
      .query("profiles")
      .withIndex("by_user", (q) => q.eq("userId", args.friendUserId))
      .first();

    if (!profile) return null;

    // Also get shared plans between these two users
    const sharedAsRecipient = await ctx.db
      .query("sharedPlans")
      .withIndex("by_recipient", (q) => q.eq("recipientId", args.userId))
      .collect();

    const sharedAsSender = await ctx.db
      .query("sharedPlans")
      .withIndex("by_sender", (q) => q.eq("senderId", args.userId))
      .collect();

    const mutualPlans = [
      ...sharedAsRecipient.filter((sp) => sp.senderId === args.friendUserId),
      ...sharedAsSender.filter((sp) => sp.recipientId === args.friendUserId),
    ];

    // Load plan details for mutual plans
    const plansWithDetails = await Promise.all(
      mutualPlans.map(async (sp) => {
        const plan = await ctx.db.get(sp.planId);
        return {
          _id: sp._id,
          shareType: sp.shareType,
          rsvp: sp.rsvp,
          planTitle: plan?.title ?? "Untitled",
          planSummary: plan?.aiSummary ?? "",
          createdAt: sp.createdAt,
        };
      })
    );

    return {
      ...profile,
      friendshipId: friendship._id,
      mutualPlans: plansWithDetails.sort((a, b) => b.createdAt - a.createdAt),
    };
  },
});

/** Internal query: get friend profiles with full taste data (for AI) */
export const getFriendsWithProfilesInternal = internalQuery({
  args: { userId: v.string(), friendIds: v.array(v.string()) },
  handler: async (ctx, args) => {
    const profiles = await Promise.all(
      args.friendIds.map(async (friendId) => {
        // Verify friendship exists
        const f1 = await ctx.db
          .query("friendships")
          .withIndex("by_pair", (q) =>
            q.eq("requesterId", args.userId).eq("addresseeId", friendId)
          )
          .first();

        const f2 = await ctx.db
          .query("friendships")
          .withIndex("by_pair", (q) =>
            q.eq("requesterId", friendId).eq("addresseeId", args.userId)
          )
          .first();

        const friendship = f1 ?? f2;
        if (!friendship || friendship.status !== "accepted") return null;

        return await ctx.db
          .query("profiles")
          .withIndex("by_user", (q) => q.eq("userId", friendId))
          .first();
      })
    );

    return profiles.filter(Boolean);
  },
});

// ── Mutations ────────────────────────────────────────────────────────

/** Send a friend request */
export const sendFriendRequest = mutation({
  args: { requesterId: v.string(), addresseeId: v.string() },
  handler: async (ctx, args) => {
    if (args.requesterId === args.addresseeId) {
      throw new Error("Cannot send friend request to yourself");
    }

    // Check for existing friendship in either direction
    const existing1 = await ctx.db
      .query("friendships")
      .withIndex("by_pair", (q) =>
        q
          .eq("requesterId", args.requesterId)
          .eq("addresseeId", args.addresseeId)
      )
      .first();

    const existing2 = await ctx.db
      .query("friendships")
      .withIndex("by_pair", (q) =>
        q
          .eq("requesterId", args.addresseeId)
          .eq("addresseeId", args.requesterId)
      )
      .first();

    if (existing1 || existing2) {
      throw new Error("Friendship already exists");
    }

    return await ctx.db.insert("friendships", {
      requesterId: args.requesterId,
      addresseeId: args.addresseeId,
      status: "pending",
      createdAt: Date.now(),
    });
  },
});

/** Accept a friend request */
export const acceptFriendRequest = mutation({
  args: { friendshipId: v.id("friendships"), userId: v.string() },
  handler: async (ctx, args) => {
    const friendship = await ctx.db.get(args.friendshipId);
    if (!friendship) throw new Error("Friendship not found");
    if (friendship.addresseeId !== args.userId) {
      throw new Error("Only the recipient can accept a request");
    }
    if (friendship.status !== "pending") {
      throw new Error("Request is not pending");
    }

    await ctx.db.patch(args.friendshipId, {
      status: "accepted",
      acceptedAt: Date.now(),
    });
  },
});

/** Decline a friend request */
export const declineFriendRequest = mutation({
  args: { friendshipId: v.id("friendships"), userId: v.string() },
  handler: async (ctx, args) => {
    const friendship = await ctx.db.get(args.friendshipId);
    if (!friendship) throw new Error("Friendship not found");
    if (friendship.addresseeId !== args.userId) {
      throw new Error("Only the recipient can decline a request");
    }

    await ctx.db.patch(args.friendshipId, { status: "declined" });
  },
});

/** Remove a friend (either side can do it) */
export const removeFriend = mutation({
  args: { friendshipId: v.id("friendships"), userId: v.string() },
  handler: async (ctx, args) => {
    const friendship = await ctx.db.get(args.friendshipId);
    if (!friendship) throw new Error("Friendship not found");
    if (
      friendship.requesterId !== args.userId &&
      friendship.addresseeId !== args.userId
    ) {
      throw new Error("Not part of this friendship");
    }

    await ctx.db.delete(args.friendshipId);
  },
});

/** Share a plan with a friend */
export const sharePlan = mutation({
  args: {
    planId: v.id("plans"),
    senderId: v.string(),
    recipientId: v.string(),
    shareType: v.string(),
    message: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const plan = await ctx.db.get(args.planId);
    if (!plan) throw new Error("Plan not found");

    return await ctx.db.insert("sharedPlans", {
      planId: args.planId,
      senderId: args.senderId,
      recipientId: args.recipientId,
      shareType: args.shareType,
      message: args.message,
      rsvp: args.shareType === "recommendation" ? "accepted" : "pending",
      createdAt: Date.now(),
    });
  },
});

/** Respond to a shared plan (hangout invite) */
export const respondToSharedPlan = mutation({
  args: {
    sharedPlanId: v.id("sharedPlans"),
    userId: v.string(),
    accept: v.boolean(),
  },
  handler: async (ctx, args) => {
    const shared = await ctx.db.get(args.sharedPlanId);
    if (!shared) throw new Error("Shared plan not found");
    if (shared.recipientId !== args.userId) {
      throw new Error("Not the recipient");
    }

    await ctx.db.patch(args.sharedPlanId, {
      rsvp: args.accept ? "accepted" : "declined",
    });

    // If accepted hangout, add recipient to the plan's profiles array
    if (args.accept && shared.shareType === "hangout") {
      const plan = await ctx.db.get(shared.planId);
      if (plan) {
        const currentProfiles = plan.profiles ?? [];
        if (!currentProfiles.includes(args.userId)) {
          await ctx.db.patch(shared.planId, {
            profiles: [...currentProfiles, args.userId],
          });
        }
      }
    }
  },
});

/** Create an SMS invite with a unique code */
export const createInvite = mutation({
  args: {
    inviterId: v.string(),
    inviteePhone: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const inviteCode = crypto.randomUUID().slice(0, 8);

    await ctx.db.insert("invites", {
      inviterId: args.inviterId,
      inviteCode,
      inviteePhone: args.inviteePhone,
      status: "sent",
      createdAt: Date.now(),
    });

    return { inviteCode };
  },
});

/** Claim an invite (called when new user opens deep link) */
export const claimInvite = mutation({
  args: {
    inviteCode: v.string(),
    claimedByUserId: v.string(),
  },
  handler: async (ctx, args) => {
    const invite = await ctx.db
      .query("invites")
      .withIndex("by_code", (q) => q.eq("inviteCode", args.inviteCode))
      .first();

    if (!invite) throw new Error("Invalid invite code");
    if (invite.status === "claimed") throw new Error("Invite already claimed");
    if (invite.inviterId === args.claimedByUserId) {
      throw new Error("Cannot claim your own invite");
    }

    // Mark invite as claimed
    await ctx.db.patch(invite._id, {
      claimedByUserId: args.claimedByUserId,
      status: "claimed",
    });

    // Auto-create accepted friendship
    const existing1 = await ctx.db
      .query("friendships")
      .withIndex("by_pair", (q) =>
        q
          .eq("requesterId", invite.inviterId)
          .eq("addresseeId", args.claimedByUserId)
      )
      .first();

    const existing2 = await ctx.db
      .query("friendships")
      .withIndex("by_pair", (q) =>
        q
          .eq("requesterId", args.claimedByUserId)
          .eq("addresseeId", invite.inviterId)
      )
      .first();

    if (!existing1 && !existing2) {
      await ctx.db.insert("friendships", {
        requesterId: invite.inviterId,
        addresseeId: args.claimedByUserId,
        status: "accepted",
        createdAt: Date.now(),
        acceptedAt: Date.now(),
      });
    }

    return { inviterId: invite.inviterId };
  },
});

/** Match phone contacts against existing users */
export const matchContacts = mutation({
  args: {
    userId: v.string(),
    phoneNumbers: v.array(v.string()),
  },
  handler: async (ctx, args) => {
    const matched: Array<{
      userId: string;
      name: string;
      phoneNumber: string;
      avatarEmoji: string | null;
      profileImageUrl: string | null;
    }> = [];
    const unmatched: string[] = [];

    for (const phone of args.phoneNumbers) {
      const profile = await ctx.db
        .query("profiles")
        .withIndex("by_phone", (q) => q.eq("phoneNumber", phone))
        .first();

      if (profile && profile.userId !== args.userId) {
        matched.push({
          userId: profile.userId,
          name: profile.name,
          phoneNumber: phone,
          avatarEmoji: profile.avatarEmoji ?? null,
          profileImageUrl: profile.profileImageUrl ?? null,
        });
      } else if (!profile) {
        unmatched.push(phone);
      }
    }

    return { matched, unmatched };
  },
});

/** Seed mock users and friendships for the current user */
export const seedMockFriends = mutation({
  args: { currentUserId: v.string() },
  handler: async (ctx, args) => {
    const mockUsers = [
      {
        userId: "mock_maya_chen",
        name: "Maya Chen",
        phoneNumber: "+15551000001",
        avatarEmoji: "🎨",
        profileImageUrl: "https://i.pravatar.cc/200?u=maya_chen",
        budget: "moderate",
        vibes: ["chill", "cozy", "hipster"],
        foodLoves: ["ramen", "coffee", "brunch"],
        foodAvoids: ["spicy"],
        activities: ["coffee shops", "museums", "thrifting"],
        dealbreakers: ["too loud", "too crowded"],
        notes: "Prefers quiet spots with good vibes",
      },
      {
        userId: "mock_jordan_reeves",
        name: "Jordan Reeves",
        phoneNumber: "+15551000002",
        avatarEmoji: "🏀",
        profileImageUrl: "https://i.pravatar.cc/200?u=jordan_reeves",
        budget: "cheap",
        vibes: ["adventurous", "lively", "casual"],
        foodLoves: ["tacos", "bbq", "wings"],
        foodAvoids: ["sushi"],
        activities: ["bars", "sports", "bowling"],
        dealbreakers: ["expensive", "far away"],
        notes: "Always chasing the best taco truck",
      },
      {
        userId: "mock_priya_patel",
        name: "Priya Patel",
        phoneNumber: "+15551000003",
        avatarEmoji: "✨",
        profileImageUrl: "https://i.pravatar.cc/200?u=priya_patel",
        budget: "splurge",
        vibes: ["trendy", "bougie", "romantic"],
        foodLoves: ["sushi", "mediterranean", "brunch"],
        foodAvoids: ["spicy", "fast food"],
        activities: ["wine tasting", "concerts", "shopping"],
        dealbreakers: ["cash only", "no parking"],
        notes: "Loves discovering new spots before they blow up",
      },
      {
        userId: "mock_alex_thompson",
        name: "Alex Thompson",
        phoneNumber: "+15551000004",
        avatarEmoji: "🎸",
        profileImageUrl: "https://i.pravatar.cc/200?u=alex_thompson",
        budget: "moderate",
        vibes: ["dive-y", "lowkey", "lively"],
        foodLoves: ["pizza", "thai", "korean"],
        foodAvoids: ["gluten"],
        activities: ["live music", "karaoke", "arcade"],
        dealbreakers: ["too crowded", "slow service"],
        notes: "Plays guitar, always knows about underground shows",
      },
      {
        userId: "mock_sofia_rodriguez",
        name: "Sofia Rodriguez",
        phoneNumber: "+15551000005",
        avatarEmoji: "🌻",
        profileImageUrl: "https://i.pravatar.cc/200?u=sofia_rodriguez",
        budget: "cheap",
        vibes: ["casual", "chill", "adventurous"],
        foodLoves: ["mexican", "dessert", "coffee"],
        foodAvoids: ["seafood"],
        activities: ["hiking", "outdoor dining", "breweries"],
        dealbreakers: ["no outdoor seating", "long wait"],
        notes: "Weekend warrior, loves a good patio",
      },
      {
        userId: "mock_david_kim",
        name: "David Kim",
        phoneNumber: "+15551000006",
        avatarEmoji: "🍷",
        profileImageUrl: "https://i.pravatar.cc/200?u=david_kim",
        budget: "splurge",
        vibes: ["upscale", "romantic", "trendy"],
        foodLoves: ["italian", "steak", "seafood"],
        foodAvoids: ["fast food"],
        activities: ["wine tasting", "comedy shows", "concerts"],
        dealbreakers: ["too loud", "cash only"],
        notes: "Planning lots of date nights lately",
      },
    ];

    // Check if mock users already exist
    const existingCheck = await ctx.db
      .query("profiles")
      .withIndex("by_user", (q) => q.eq("userId", "mock_maya_chen"))
      .first();

    if (existingCheck) {
      return { seeded: false, message: "Mock users already exist" };
    }

    // Create mock profiles
    for (const user of mockUsers) {
      await ctx.db.insert("profiles", user);
    }

    // Create friendships between current user and all mock users
    for (const user of mockUsers) {
      await ctx.db.insert("friendships", {
        requesterId: user.userId,
        addresseeId: args.currentUserId,
        status: "accepted",
        createdAt: Date.now(),
        acceptedAt: Date.now(),
      });
    }

    // Also create a pending request from a "new" mock user
    await ctx.db.insert("profiles", {
      userId: "mock_kai_nakamura",
      name: "Kai Nakamura",
      phoneNumber: "+15551000007",
      avatarEmoji: "🎯",
      profileImageUrl: "https://i.pravatar.cc/200?u=kai_nakamura",
      budget: "moderate",
      vibes: ["adventurous", "trendy", "lively"],
      foodLoves: ["ramen", "sushi", "korean"],
      foodAvoids: ["dairy"],
      activities: ["arcade", "bowling", "karaoke"],
      dealbreakers: ["far away"],
      notes: "New in town, looking for cool spots",
    });

    await ctx.db.insert("friendships", {
      requesterId: "mock_kai_nakamura",
      addresseeId: args.currentUserId,
      status: "pending",
      createdAt: Date.now(),
    });

    return { seeded: true, message: "Created 7 mock friends (6 accepted, 1 pending)" };
  },
});
