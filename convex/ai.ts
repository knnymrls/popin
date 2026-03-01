import { v } from "convex/values";
import { action } from "./_generated/server";
import { internal } from "./_generated/api";
import Anthropic from "@anthropic-ai/sdk";

// ── Types ─────────────────────────────────────────────────────────────

interface PlaceResult {
  place_id: string;
  name: string;
  geometry: { location: { lat: number; lng: number } };
  vicinity: string;
  photos?: Array<{ photo_reference: string }>;
  rating?: number;
  price_level?: number;
}

interface SpotData {
  placeId: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  photoUrl?: string;
  rating?: number;
  priceLevel?: number;
}

interface PlanStopData {
  order: number;
  emoji: string;
  name: string;
  time: string;
  cost: string;
  note: string;
}

interface PlanData {
  title: string;
  summary: string;
  stops: PlanStopData[];
  totalCost: string;
  totalTime: string;
  shareId?: string;
}

interface SpotDetail {
  placeId: string;
  name: string;
  address: string;
  phone?: string;
  website?: string;
  hours?: string[];
  isOpenNow?: boolean;
  rating?: number;
  priceLevel?: number;
  reviewCount?: number;
  reviews?: Array<{ rating: number; text: string; time: string }>;
  editorialSummary?: string;
  photoUrls: string[];
  perplexitySummary?: string;
}

// ── Tool definitions ──────────────────────────────────────────────────

const SEARCH_PLACES_TOOL: Anthropic.Tool = {
  name: "search_places",
  description:
    "Search for nearby places. Use this IMMEDIATELY when the user mentions any type of place, food, activity, or vibe. " +
    "Don't ask what they want first — just search based on what you know about them and what they said. " +
    "If you know their profile (food preferences, budget, vibes), use that to pick the right search query.",
  input_schema: {
    type: "object" as const,
    properties: {
      query: {
        type: "string",
        description:
          "Search query — be specific. Use the user's known preferences to refine. " +
          "e.g. if they love ramen and say 'hungry', search 'ramen'. " +
          "If they say 'date night' and you know they're on a budget, search 'cheap date night restaurant'.",
      },
      priceMax: {
        type: "number",
        description:
          "Max price level 1-4. Set this based on the user's profile budget " +
          "(cheap=1-2, moderate=2-3, splurge=3-4) even if they don't mention it.",
      },
      openNow: {
        type: "boolean",
        description: "Only open places. Default true unless they mention a future time.",
      },
    },
    required: ["query"],
  },
};

const CREATE_PLAN_TOOL: Anthropic.Tool = {
  name: "create_plan",
  description:
    "Create a plan/itinerary. Use this AUTOMATICALLY when the user's message implies multi-stop activity: " +
    "'date night', 'plan my evening', 'what should we do tonight', 'take me out', 'weekend plans', " +
    "'plan a ___', 'night out', etc. Don't ask if they want a plan — just make one. " +
    "Search for places FIRST, then create the plan using those results.",
  input_schema: {
    type: "object" as const,
    properties: {
      title: {
        type: "string",
        description: "Short catchy title — 'Cheap Date Night', 'Sunday Brunch Run', 'Late Night Eats'",
      },
      summary: {
        type: "string",
        description: "One-line route — 'Coffee → park → tacos. Walkable, under $25.'",
      },
      stops: {
        type: "array",
        items: {
          type: "object",
          properties: {
            order: { type: "number", description: "Stop number (1, 2, 3...)" },
            emoji: { type: "string", description: "Single emoji for this stop" },
            name: { type: "string", description: "Place name — use a REAL place from your search results" },
            time: { type: "string", description: "Suggested time — e.g. '6:00pm'" },
            cost: { type: "string", description: "Estimated cost — e.g. '$4', '$12'" },
            note: { type: "string", description: "Brief tip — what to order, what to do here" },
          },
          required: ["order", "emoji", "name", "time", "cost", "note"],
        },
        description: "Ordered list of stops. 2-4 stops, use REAL places from search results.",
      },
      totalCost: { type: "string", description: "Total estimated cost — e.g. '~$25'" },
      totalTime: { type: "string", description: "Total duration — e.g. '3 hrs'" },
    },
    required: ["title", "summary", "stops", "totalCost", "totalTime"],
  },
};

// ── Time context ──────────────────────────────────────────────────────

function getTimeContext(): string {
  const now = new Date();
  const days = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
  ];
  const day = days[now.getDay()];
  const hour = now.getHours();
  const minutes = now.getMinutes();
  const ampm = hour >= 12 ? "pm" : "am";
  const h12 = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
  const timeStr = `${h12}:${minutes.toString().padStart(2, "0")}${ampm}`;

  let timeOfDay: string;
  if (hour < 6) timeOfDay = "late night";
  else if (hour < 11) timeOfDay = "morning";
  else if (hour < 14) timeOfDay = "lunchtime";
  else if (hour < 17) timeOfDay = "afternoon";
  else if (hour < 21) timeOfDay = "evening";
  else timeOfDay = "night";

  const isWeekend =
    now.getDay() === 0 || now.getDay() === 6 || now.getDay() === 5;

  return `Current time: ${day}, ${timeStr} (${timeOfDay}). ${isWeekend ? "It's the weekend." : "It's a weekday."}`;
}

// ── System prompt ─────────────────────────────────────────────────────

type ProfileData = {
  name: string;
  budget?: string;
  vibes: string[];
  foodLoves: string[];
  foodAvoids: string[];
  activities: string[];
  dealbreakers: string[];
  notes?: string;
};

function buildSystemPrompt(
  profile: ProfileData | null,
  friendProfiles?: ProfileData[]
): string {
  let prompt = `You are Popin — the friend who always knows where to go. Not a search engine. Not an assistant. You're the homie with opinions.

${getTimeContext()}

YOUR JOB: Recommend places and make plans. That's it. Don't overthink it.

HOW YOU TALK:
- Like you're texting a friend. Casual, direct, zero fluff.
- Lead with your pick and say WHY in one sentence. "go to [place] — the [thing] is insane" or "[place], trust me. [reason]."
- 1-3 sentences max. You're not writing an essay.
- Reference the time/day naturally. "it's friday night bro" or "perfect lunch spot rn"

WHAT YOU DO:
- Someone mentions food, drinks, activities, vibes, going out → IMMEDIATELY call search_places. Don't ask what they want. Just search.
- Someone says anything that sounds like multiple stops — "date night", "plan my evening", "what should we do", "take me out", "night out", "plan a ___", "this weekend" → search for places THEN call create_plan. Don't ask if they want a plan. Just make it.
- "I'm hungry" → you already know what they like (see profile below). Search for that. Don't ask "what kind of food?"
- "I'm bored" → search for things to do right now based on the time and their interests. Don't ask what they're in the mood for.
- Vague message? Pick the best option based on what you know and the time of day. Commit. You can always adjust if they push back.

NEVER DO THIS:
- Never ask "what kind of food are you in the mood for?" — you either know from their profile or you just pick based on the vibe
- Never ask "would you like me to make a plan?" — if the message implies it, just do it
- Never ask "what's your budget?" — you know it from the profile, or default to moderate
- Never ask more than one question total in a conversation. If you absolutely must clarify something, ask ONE thing then immediately follow with a recommendation regardless of their answer
- Never say "I found these options", "here are some suggestions", "I'd recommend", "you might enjoy", "let me know if" — just say what's good and why
- Never list places without picking a favorite. You always have an opinion.

PLAN RULES:
- DO MULTIPLE SEARCHES before creating a plan. A date night plan needs at least 2 searches: "dinner restaurant" + "dessert" or "bar" or "activity". A day out needs 3+. Each stop category should be a separate search.
- Times start at least 30 min from right now
- 2-4 stops max. Don't over-plan.
- ONLY use places that appeared in your search results. Never make up place names.
- Costs based on price level ($ = ~$5-10, $$ = ~$10-20, $$$ = ~$20-40)
- Keep it walkable when possible
- Each stop needs a specific insider tip — what to order, what to do, where to sit. Not generic "enjoy the food."
- The summary should read like a route: "Tacos at [place] → walk to [place] for drinks → end at [place]. Under $40."

PLANNING FLOW (follow this exactly):
1. User says something plan-like ("date night", "plan my evening", etc.)
2. Search for the FIRST category (e.g. "dinner restaurants")
3. Search for the SECOND category (e.g. "dessert spots" or "cocktail bars")
4. Optionally search for a THIRD category (e.g. "late night activity")
5. Pick the BEST place from each search result
6. Call create_plan with those real places, realistic times, and specific tips
7. Write one hype sentence about the plan`;

  if (profile) {
    const lines = [];
    lines.push(`Name: ${profile.name}`);
    if (profile.budget)
      lines.push(
        `Budget: ${profile.budget} — ${profile.budget === "cheap" ? "always go cheap, $-$$ spots" : profile.budget === "moderate" ? "mid-range is fine, $$" : "they'll splurge, $$-$$$"}`
      );
    if (profile.vibes.length)
      lines.push(`Their vibe: ${profile.vibes.join(", ")}`);
    if (profile.foodLoves.length)
      lines.push(
        `LOVES eating: ${profile.foodLoves.join(", ")} — when they say "hungry" or "food", default to these`
      );
    if (profile.foodAvoids.length)
      lines.push(
        `AVOIDS: ${profile.foodAvoids.join(", ")} — never recommend these`
      );
    if (profile.activities.length)
      lines.push(
        `Into: ${profile.activities.join(", ")} — use these for "bored" or "what should I do" questions`
      );
    if (profile.dealbreakers.length)
      lines.push(
        `Dealbreakers: ${profile.dealbreakers.join(", ")} — hard no on these, always filter out`
      );
    if (profile.notes) lines.push(`Notes: ${profile.notes}`);

    prompt += `

YOU KNOW THIS PERSON:
${lines.join("\n")}

This is your friend. You know what they like. Act like it.
- "I'm hungry" + they love tacos + cheap budget → search "cheap tacos" immediately. Don't ask.
- "date night" + they like cozy vibes → search "cozy date night restaurant" then make a plan. Don't ask.
- "bored" + they're into live music → search "live music tonight". Don't ask.
Use their preferences to pick your search queries. If their profile says "cheap" budget, set priceMax to 2. If they avoid sushi, never include sushi spots. This should feel like talking to a friend who actually remembers what you like.`;
  } else {
    prompt += `

NO PROFILE LOADED — you don't know this person's preferences yet. That's fine.
- Default to mid-range budget ($-$$)
- Pick based on time of day and what's popular
- Still don't ask a bunch of questions. Just recommend something good.`;
  }

  // Inject friend context for group planning
  if (friendProfiles && friendProfiles.length > 0) {
    prompt += `

GROUP PLANNING MODE — This person is planning with friends. You need to find spots that work for EVERYONE.

FRIENDS IN THE GROUP:`;
    for (const friend of friendProfiles) {
      const lines = [];
      lines.push(`  Name: ${friend.name}`);
      if (friend.budget) lines.push(`  Budget: ${friend.budget}`);
      if (friend.vibes.length)
        lines.push(`  Vibes: ${friend.vibes.join(", ")}`);
      if (friend.foodLoves.length)
        lines.push(`  Loves: ${friend.foodLoves.join(", ")}`);
      if (friend.foodAvoids.length)
        lines.push(`  Avoids: ${friend.foodAvoids.join(", ")}`);
      if (friend.activities.length)
        lines.push(`  Into: ${friend.activities.join(", ")}`);
      if (friend.dealbreakers.length)
        lines.push(`  Dealbreakers: ${friend.dealbreakers.join(", ")}`);
      prompt += `\n${lines.join("\n")}`;
    }

    prompt += `

GROUP RULES:
- Find spots everyone can enjoy. Look for OVERLAP in vibes and food loves.
- NEVER recommend anything on ANYONE's avoids list or dealbreakers.
- Use the LOWEST budget in the group as your ceiling (cheap beats moderate beats splurge).
- When making plans, mention why it works for the group: "this works for you and Maya because..."
- If preferences conflict (one loves sushi, another avoids it), pick something else entirely. Don't compromise — find common ground.`;
  }

  return prompt;
}

// ── Google Places search ──────────────────────────────────────────────

async function searchGooglePlaces(
  query: string,
  latitude: number,
  longitude: number,
  googleApiKey: string,
  priceMax?: number
): Promise<SpotData[]> {
  const url = new URL(
    "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
  );
  url.searchParams.set("location", `${latitude},${longitude}`);
  url.searchParams.set("radius", "3000");
  url.searchParams.set("keyword", query);
  url.searchParams.set("key", googleApiKey);
  if (priceMax) {
    url.searchParams.set("maxprice", String(priceMax));
  }

  const res = await fetch(url.toString());
  const data = (await res.json()) as { results: PlaceResult[] };
  const places = data.results.slice(0, 5);

  const seenIds = new Set<string>();
  const spots: SpotData[] = [];

  for (const place of places) {
    if (seenIds.has(place.place_id)) continue;
    seenIds.add(place.place_id);

    const photoRef = place.photos?.[0]?.photo_reference;
    const photoUrl = photoRef
      ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${photoRef}&key=${googleApiKey}`
      : undefined;

    spots.push({
      placeId: place.place_id,
      name: place.name,
      address: place.vicinity,
      latitude: place.geometry.location.lat,
      longitude: place.geometry.location.lng,
      photoUrl,
      rating: place.rating,
      priceLevel: place.price_level,
    });
  }

  return spots;
}

// ── Google Places Details ─────────────────────────────────────────────

async function getGooglePlaceDetails(
  placeId: string,
  googleApiKey: string
): Promise<{
  name: string;
  address: string;
  phone?: string;
  website?: string;
  hours?: string[];
  isOpenNow?: boolean;
  rating?: number;
  priceLevel?: number;
  reviewCount?: number;
  reviews: Array<{ rating: number; text: string; time: string }>;
  editorialSummary?: string;
  photoUrls: string[];
}> {
  const url = new URL(
    "https://maps.googleapis.com/maps/api/place/details/json"
  );
  url.searchParams.set("place_id", placeId);
  url.searchParams.set(
    "fields",
    "name,formatted_address,formatted_phone_number,website,opening_hours,rating,price_level,user_ratings_total,reviews,editorial_summary,photos"
  );
  url.searchParams.set("key", googleApiKey);

  const res = await fetch(url.toString());
  const data = (await res.json()) as {
    result: {
      name: string;
      formatted_address: string;
      formatted_phone_number?: string;
      website?: string;
      opening_hours?: {
        weekday_text?: string[];
        open_now?: boolean;
      };
      rating?: number;
      price_level?: number;
      user_ratings_total?: number;
      reviews?: Array<{
        rating: number;
        text: string;
        relative_time_description: string;
      }>;
      editorial_summary?: { overview: string };
      photos?: Array<{ photo_reference: string }>;
    };
  };

  const r = data.result;
  return {
    name: r.name,
    address: r.formatted_address,
    phone: r.formatted_phone_number,
    website: r.website,
    hours: r.opening_hours?.weekday_text,
    isOpenNow: r.opening_hours?.open_now,
    rating: r.rating,
    priceLevel: r.price_level,
    reviewCount: r.user_ratings_total,
    reviews: (r.reviews ?? []).slice(0, 3).map((rev) => ({
      rating: rev.rating,
      text: rev.text,
      time: rev.relative_time_description,
    })),
    editorialSummary: r.editorial_summary?.overview,
    photoUrls: (r.photos ?? []).slice(0, 5).map(
      (p) =>
        `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${p.photo_reference}&key=${googleApiKey}`
    ),
  };
}

// ── Perplexity enrichment ─────────────────────────────────────────────

async function getPerplexitySummary(
  name: string,
  address: string
): Promise<string | undefined> {
  const apiKey = process.env.PERPLEXITY_API_KEY;
  if (!apiKey) return undefined;

  try {
    const res = await fetch("https://api.perplexity.ai/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "sonar",
        messages: [
          {
            role: "system",
            content:
              "You write ultra-concise place summaries for a local recommendations app. 2-3 sentences max. Include: what it's known for, the vibe, and one insider tip (best dish, best time to go, what to skip). Write like a friend texting, not a review site. No fluff.",
          },
          {
            role: "user",
            content: `Tell me about "${name}" at ${address}. What's it known for? What should I order/do? What's the vibe?`,
          },
        ],
        max_tokens: 200,
      }),
    });

    const data = (await res.json()) as {
      choices: Array<{ message: { content: string } }>;
    };
    return data.choices?.[0]?.message?.content;
  } catch {
    return undefined;
  }
}

// ── Chat action ───────────────────────────────────────────────────────

export const chat = action({
  args: {
    messages: v.array(
      v.object({
        role: v.union(v.literal("user"), v.literal("assistant")),
        content: v.string(),
      })
    ),
    userId: v.optional(v.string()),
    latitude: v.number(),
    longitude: v.number(),
    friendIds: v.optional(v.array(v.string())),
  },
  handler: async (
    ctx,
    args
  ): Promise<{
    text: string;
    spots?: SpotData[];
    plan?: PlanData;
  }> => {
    const anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
    const googleApiKey = process.env.GOOGLE_PLACES_API_KEY;
    if (!googleApiKey) throw new Error("GOOGLE_PLACES_API_KEY not set");

    // Load user profile if available
    let profile: ProfileData | null = null;
    if (args.userId) {
      profile = await ctx.runQuery(internal.profiles.getInternal, {
        userId: args.userId,
      });
    }

    // Load friend profiles for group planning
    let friendProfiles: ProfileData[] | undefined;
    if (args.userId && args.friendIds && args.friendIds.length > 0) {
      const friends = await ctx.runQuery(
        internal.friends.getFriendsWithProfilesInternal,
        { userId: args.userId, friendIds: args.friendIds }
      );
      if (friends && friends.length > 0) {
        friendProfiles = friends as ProfileData[];
      }
    }

    const systemPrompt = buildSystemPrompt(profile, friendProfiles);

    // Convert messages to Anthropic format
    const claudeMessages: Anthropic.MessageParam[] = args.messages.map((m) => ({
      role: m.role,
      content: m.content,
    }));

    // Collect results across tool calls
    let resultSpots: SpotData[] = [];
    let resultPlan: PlanData | undefined;

    // Agentic loop — keep going until Claude stops calling tools
    while (true) {
      const response = await anthropic.messages.create({
        model: "claude-sonnet-4-6",
        max_tokens: 2048,
        system: systemPrompt,
        tools: [SEARCH_PLACES_TOOL, CREATE_PLAN_TOOL],
        messages: claudeMessages,
      });

      // If Claude is done, extract text and return
      if (response.stop_reason === "end_turn") {
        claudeMessages.push({ role: "assistant", content: response.content });
        const text = response.content
          .filter((b): b is Anthropic.TextBlock => b.type === "text")
          .map((b) => b.text)
          .join("");

        return {
          text,
          spots: resultSpots.length > 0 ? resultSpots : undefined,
          plan: resultPlan,
        };
      }

      // Extract tool use blocks
      const toolUseBlocks = response.content.filter(
        (b): b is Anthropic.ToolUseBlock => b.type === "tool_use"
      );

      if (toolUseBlocks.length === 0) {
        claudeMessages.push({ role: "assistant", content: response.content });
        const text = response.content
          .filter((b): b is Anthropic.TextBlock => b.type === "text")
          .map((b) => b.text)
          .join("");
        return { text };
      }

      // Append assistant's response (includes tool_use blocks)
      claudeMessages.push({ role: "assistant", content: response.content });

      // Execute each tool and collect results
      const toolResults: Anthropic.ToolResultBlockParam[] = [];

      for (const tool of toolUseBlocks) {
        if (tool.name === "search_places") {
          const input = tool.input as {
            query: string;
            priceMax?: number;
            openNow?: boolean;
          };

          const spots = await searchGooglePlaces(
            input.query,
            args.latitude,
            args.longitude,
            googleApiKey,
            input.priceMax
          );
          resultSpots.push(...spots);

          // Give Claude rich info to pick from
          const priceLabel = (p?: number) =>
            p ? ["", "$", "$$", "$$$", "$$$$"][p] || "" : "?";
          toolResults.push({
            type: "tool_result",
            tool_use_id: tool.id,
            content: JSON.stringify(
              spots.map((s, i) => ({
                pick: i + 1,
                name: s.name,
                address: s.address,
                rating: s.rating ? `${s.rating}★` : "no rating",
                price: priceLabel(s.priceLevel),
              }))
            ),
          });
        } else if (tool.name === "create_plan") {
          const input = tool.input as {
            title: string;
            summary: string;
            stops: PlanStopData[];
            totalCost: string;
            totalTime: string;
          };

          // Save plan to Convex
          const { shareId } = await ctx.runMutation(
            internal.plans.createWithStopsInternal,
            {
              userId: args.userId,
              title: input.title,
              aiSummary: input.summary,
              estimatedCost: input.totalCost,
              totalTime: input.totalTime,
              stops: input.stops.map((s) => ({
                emoji: s.emoji,
                name: s.name,
                cost: s.cost,
                suggestedTime: s.time,
                notes: s.note,
              })),
            }
          );

          resultPlan = {
            title: input.title,
            summary: input.summary,
            stops: input.stops,
            totalCost: input.totalCost,
            totalTime: input.totalTime,
            shareId,
          };

          toolResults.push({
            type: "tool_result",
            tool_use_id: tool.id,
            content: JSON.stringify({
              success: true,
              message: "Plan created and saved.",
            }),
          });
        } else {
          toolResults.push({
            type: "tool_result",
            tool_use_id: tool.id,
            content: "Unknown tool",
            is_error: true,
          });
        }
      }

      // Send tool results back to Claude
      claudeMessages.push({ role: "user", content: toolResults });
    }
  },
});

// ── Nearby spots action ──────────────────────────────────────────────

export const getNearbySpots = action({
  args: {
    latitude: v.number(),
    longitude: v.number(),
  },
  handler: async (_, args): Promise<SpotData[]> => {
    const googleApiKey = process.env.GOOGLE_PLACES_API_KEY;
    if (!googleApiKey) throw new Error("GOOGLE_PLACES_API_KEY not set");

    // Fetch a few categories in parallel for a rich map
    const [restaurants, cafes, bars] = await Promise.all([
      searchGooglePlaces("popular restaurants", args.latitude, args.longitude, googleApiKey),
      searchGooglePlaces("coffee shops cafes", args.latitude, args.longitude, googleApiKey),
      searchGooglePlaces("bars nightlife", args.latitude, args.longitude, googleApiKey),
    ]);

    // Deduplicate by placeId, mix results
    const seen = new Set<string>();
    const spots: SpotData[] = [];
    for (const spot of [...restaurants, ...cafes, ...bars]) {
      if (seen.has(spot.placeId)) continue;
      seen.add(spot.placeId);
      spots.push(spot);
    }

    return spots;
  },
});

// ── Spot Detail action ────────────────────────────────────────────────

export const getSpotDetail = action({
  args: {
    placeId: v.string(),
  },
  handler: async (_, args): Promise<SpotDetail> => {
    const googleApiKey = process.env.GOOGLE_PLACES_API_KEY;
    if (!googleApiKey) throw new Error("GOOGLE_PLACES_API_KEY not set");

    // Google Places Details + Perplexity in parallel
    const details = await getGooglePlaceDetails(args.placeId, googleApiKey);

    // Kick off Perplexity after we have the name/address
    const perplexitySummary = await getPerplexitySummary(
      details.name,
      details.address
    );

    return {
      placeId: args.placeId,
      ...details,
      perplexitySummary,
    };
  },
});
