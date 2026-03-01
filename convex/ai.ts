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
  types?: string[];
  opening_hours?: { open_now?: boolean };
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
  types?: string[];
  isOpenNow?: boolean;
}

interface PlanStopData {
  order: number;
  emoji: string;
  name: string;
  time: string;
  cost: string;
  note: string;
  photoUrl?: string;
  placeId?: string;
}

interface PlanData {
  title: string;
  summary: string;
  stops: PlanStopData[];
  totalCost: string;
  totalTime: string;
  planId?: string;
  shareId?: string;
}

interface SpotDetail {
  placeId: string;
  name: string;
  address: string;
  phone?: string;
  website?: string;
  googleMapsUrl?: string;
  hours?: string[];
  isOpenNow?: boolean;
  rating?: number;
  priceLevel?: number;
  reviewCount?: number;
  reviews?: Array<{ rating: number; text: string; time: string }>;
  editorialSummary?: string;
  photoUrls: string[];
  types?: string[];
  dineIn?: boolean;
  delivery?: boolean;
  takeout?: boolean;
  reservable?: boolean;
  servesBeer?: boolean;
  servesWine?: boolean;
  servesVegetarianFood?: boolean;
  servesBreakfast?: boolean;
  servesLunch?: boolean;
  servesDinner?: boolean;
  wheelchairAccessible?: boolean;
  perplexitySummary?: string;
  knownFor?: string;
  mustTry?: string[];
  proTip?: string;
  vibe?: string;
}

// ── Tool definitions ──────────────────────────────────────────────────

const SEARCH_PLACES_TOOL: Anthropic.Tool = {
  name: "search_places",
  description:
    "Search for nearby places. Be specific with your query — use what you know about the user. " +
    "One focused search is usually enough. Only do a second search if you need a different category. " +
    "Use the user's profile (food preferences, budget, vibes) to pick smarter queries.",
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
    "Create a plan/itinerary. ONLY use this when the user explicitly asks for a plan — " +
    "'make me a plan', 'plan it out', 'yeah plan it', 'bet', 'plan my ___'. " +
    "Do NOT auto-create plans. Recommend spots first, then offer to plan. " +
    "Always search for places FIRST, then create the plan using those results.",
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
  let prompt = `You are Popin — not a search engine, not an assistant. You're the friend in the group chat who always has the move. You know what's good, you have opinions, and you actually listen.

${getTimeContext()}

HOW YOU TALK:
- Like you're texting your friend. Casual, lowercase, direct
- GenZ energy but not forced. Use slang when it fits: "lowkey", "no cap", "fr", "hits different", "bussin", "bet", "ngl", "its giving", "say less"
- Keep it SHORT — 1-3 sentences per message. Nobody reads paragraphs in a chat
- Be specific. Not "this place is great" — say WHY. "their birria tacos are unreal and it's never crowded on weeknights"
- Max 1-2 emojis per message. Don't overdo it
- Reference time/day naturally: "it's a tuesday afternoon, perfect for a chill coffee spot"
- NEVER use markdown formatting. No **bold**, no *italics*, no bullet points, no headers. This is a chat app — plain text only. Just write place names normally, no special formatting
- NEVER sound corporate, formal, or like a Yelp review

YOUR VIBE — BE A REAL FRIEND:
- A real friend asks follow-ups. If someone says "i'm hungry" and you DON'T know their preferences, ask "what are you in the mood for? like tacos, sushi, comfort food?" — that's being helpful, not annoying
- A real friend narrows it down. Don't just dump 5 options. Ask ONE clarifying question if needed, then commit to a pick
- A real friend remembers. If you know their profile (below), USE IT. Don't ask questions you already know the answer to
- A real friend reads the room. "plan my night" = they want help. "where's good for coffee" = quick rec, don't overcomplicate it

SEARCH STRATEGY:
- Do 1-2 searches max. One focused search is usually enough. Add a second only if you need a different category (e.g. dinner + drinks)
- Be SPECIFIC in your search query. Use what you know: "cheap ramen" not "restaurants", "cozy coffee shop" not "cafe"
- The UI shows the top 5 results as tappable cards. Your job is to tell them which one to pick and WHY
- Pick your #1, give a specific reason, mention 1 runner-up if it's worth it. That's it

WHEN TO ASK vs WHEN TO JUST GO:
- You KNOW their profile → just search. "i'm hungry" + they love ramen → search ramen spots. Don't ask
- You DON'T know their profile → ask ONE question to narrow it. "what vibe — like chill sit-down or quick grab-and-go?" then search
- They're VAGUE ("find me something") → ask what they're feeling. "food? drinks? something to do? give me a direction and i got you"
- They're SPECIFIC ("best tacos nearby") → search immediately, no questions
- NEVER ask more than one question at a time. Ask, then act
- CRITICAL: Once they answer your question, SEARCH IMMEDIATELY. Do NOT ask a second question. ONE question max, then you MUST search. If they say "tacos" → search tacos. If they say "chill drinks" → search cocktail bars. Just GO
- You already have their GPS location. NEVER ask "what area" or "where are you"

HOW TO RESPOND AFTER SEARCHING:
- Lead with your #1 pick and a specific reason: "[place] — their [specific thing] is unreal"
- Briefly mention 1-2 alternatives: "also [place] if you want something more [vibe]"
- The spots will show as cards they can tap — your text should add context the cards don't have (insider tips, what to order, best time to go)
- If the ask could become a multi-stop thing, offer: "want me to plan out the whole thing?"

PLANS — ONLY WHEN ASKED:
- DON'T auto-create plans. Recommend spots first, let them react
- Offer to plan: "want me to map out the route?" or "i can plan the whole night if you want"
- ONLY call create_plan when user explicitly asks: "yeah plan it", "make me a plan", "bet", "do it", etc.
- When "make me a plan", "plan my ___", or "plan a ___" is said → you can ask ONE quick vibe question, then IMMEDIATELY search and create the plan. Don't keep asking — just make smart assumptions and go
- "plan my night" / "plan for tonight" without profile → ask ONE question about vibe (chill, wild, romantic?), then search and plan. Do NOT ask about food, budget, area, or anything else

PLAN RULES (when creating):
- Do MULTIPLE SEARCHES first — each stop type is a separate search
- 2-4 stops max. Keep it tight
- ONLY use places from your search results. Never make up names
- Each stop needs a specific tip — what to order, where to sit, what to skip. Not "enjoy the food"
- Summary reads like a route: "Tacos at [place] → walk to [place] for drinks → end at [place]. Under $40"
- Hype it: "ok this night is about to go crazy" not "here is your evening plan"

NEVER DO THIS:
- Never dump 5+ options with no opinion. Pick your favorite, explain why
- Never say "here are some options", "I'd recommend", "you might enjoy", "let me know" — customer service bot energy
- Never ask "what's your budget?" — check the profile or default to moderate
- Never write more than 3 sentences in a response. If you're writing a paragraph, you're doing it wrong
- Never sound like a travel blog`;

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

You KNOW this person. Use their profile to pick search queries — don't ask questions you already have answers to.
- "I'm hungry" + they love tacos + cheap budget → search "cheap tacos", "best taco spot", "street tacos". Don't ask what kind
- "date night" + cozy vibes → search "cozy dinner", "romantic restaurant", "intimate cocktail bar". Don't ask the vibe
- "bored" + into live music → search "live music tonight", "concerts nearby", "open mic". Don't ask what they want to do
- If budget is "cheap", always set priceMax to 2. If they avoid sushi, never include sushi spots
- Call them by name sometimes. It's personal`;
  } else {
    prompt += `

YOU DON'T KNOW THIS PERSON YET — no profile loaded.
- Ask a quick question to get oriented: "what are you feeling — food, drinks, something to do?"
- Or if they're specific, just search and go
- Default to mid-range budget ($-$$), popular spots
- After helping them, you'll learn what they like`;
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
- When making plans, mention why it works for the group: "this works for you and [friend] because..."
- If preferences conflict (one loves sushi, another avoids it), pick something else entirely. Don't compromise — find common ground.
- IMPORTANT: You have BOTH profiles. You can see the overlap. If they say "bored", "what should we do", "find us something" — just SEARCH based on overlapping activities/vibes and recommend. Don't ask what they want to do when you already know what they're both into. Act like a friend who knows the whole group.
- For group requests like "what should we do" — search their overlapping interests, give a strong recommendation, and offer to plan it out. ONE message, not a back-and-forth.`;
  }

  return prompt;
}

// ── Google Places search ──────────────────────────────────────────────

async function searchGooglePlaces(
  query: string,
  latitude: number,
  longitude: number,
  googleApiKey: string,
  options?: { priceMax?: number; limit?: number; radius?: number }
): Promise<SpotData[]> {
  const url = new URL(
    "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
  );
  url.searchParams.set("location", `${latitude},${longitude}`);
  url.searchParams.set("radius", String(options?.radius ?? 3000));
  url.searchParams.set("keyword", query);
  url.searchParams.set("key", googleApiKey);
  if (options?.priceMax) {
    url.searchParams.set("maxprice", String(options.priceMax));
  }

  const res = await fetch(url.toString());
  const data = (await res.json()) as { results: PlaceResult[] };
  const places = data.results.slice(0, options?.limit ?? 5);

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
      types: place.types,
      isOpenNow: place.opening_hours?.open_now,
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
  googleMapsUrl?: string;
  hours?: string[];
  isOpenNow?: boolean;
  rating?: number;
  priceLevel?: number;
  reviewCount?: number;
  reviews: Array<{ rating: number; text: string; time: string }>;
  editorialSummary?: string;
  photoUrls: string[];
  types?: string[];
  dineIn?: boolean;
  delivery?: boolean;
  takeout?: boolean;
  reservable?: boolean;
  servesBeer?: boolean;
  servesWine?: boolean;
  servesVegetarianFood?: boolean;
  servesBreakfast?: boolean;
  servesLunch?: boolean;
  servesDinner?: boolean;
  wheelchairAccessible?: boolean;
}> {
  const url = new URL(
    "https://maps.googleapis.com/maps/api/place/details/json"
  );
  url.searchParams.set("place_id", placeId);
  url.searchParams.set(
    "fields",
    "name,formatted_address,formatted_phone_number,website,url,opening_hours,rating,price_level,user_ratings_total,reviews,editorial_summary,photos,types,dine_in,delivery,takeout,reservable,serves_beer,serves_wine,serves_vegetarian_food,serves_breakfast,serves_lunch,serves_dinner,wheelchair_accessible_entrance"
  );
  url.searchParams.set("key", googleApiKey);

  const res = await fetch(url.toString());
  const data = (await res.json()) as {
    result: {
      name: string;
      formatted_address: string;
      formatted_phone_number?: string;
      website?: string;
      url?: string;
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
      types?: string[];
      dine_in?: boolean;
      delivery?: boolean;
      takeout?: boolean;
      reservable?: boolean;
      serves_beer?: boolean;
      serves_wine?: boolean;
      serves_vegetarian_food?: boolean;
      serves_breakfast?: boolean;
      serves_lunch?: boolean;
      serves_dinner?: boolean;
      wheelchair_accessible_entrance?: boolean;
    };
  };

  const r = data.result;

  // Clean up types — remove generic ones and format nicely
  const genericTypes = new Set([
    "point_of_interest",
    "establishment",
    "food",
    "store",
    "political",
    "locality",
  ]);
  const cleanTypes = (r.types ?? [])
    .filter((t) => !genericTypes.has(t))
    .map((t) =>
      t
        .split("_")
        .map((w) => w[0].toUpperCase() + w.slice(1))
        .join(" ")
    );

  return {
    name: r.name,
    address: r.formatted_address,
    phone: r.formatted_phone_number,
    website: r.website,
    googleMapsUrl: r.url,
    hours: r.opening_hours?.weekday_text,
    isOpenNow: r.opening_hours?.open_now,
    rating: r.rating,
    priceLevel: r.price_level,
    reviewCount: r.user_ratings_total,
    reviews: (r.reviews ?? []).slice(0, 5).map((rev) => ({
      rating: rev.rating,
      text: rev.text,
      time: rev.relative_time_description,
    })),
    editorialSummary: r.editorial_summary?.overview,
    photoUrls: (r.photos ?? []).slice(0, 8).map(
      (p) =>
        `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=${p.photo_reference}&key=${googleApiKey}`
    ),
    types: cleanTypes.length > 0 ? cleanTypes : undefined,
    dineIn: r.dine_in,
    delivery: r.delivery,
    takeout: r.takeout,
    reservable: r.reservable,
    servesBeer: r.serves_beer,
    servesWine: r.serves_wine,
    servesVegetarianFood: r.serves_vegetarian_food,
    servesBreakfast: r.serves_breakfast,
    servesLunch: r.serves_lunch,
    servesDinner: r.serves_dinner,
    wheelchairAccessible: r.wheelchair_accessible_entrance,
  };
}

// ── Perplexity enrichment ─────────────────────────────────────────────

interface PerplexityInsight {
  summary?: string;
  knownFor?: string;
  mustTry?: string[];
  proTip?: string;
  vibe?: string;
}

async function getPerplexityInsight(
  name: string,
  address: string
): Promise<PerplexityInsight | undefined> {
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
            content: `You are a local insider writing for a recommendations app. Return ONLY valid JSON (no markdown, no code fences) with these fields:
{
  "knownFor": "one sentence about what this place is famous for",
  "mustTry": ["specific item 1", "specific item 2", "specific item 3"],
  "proTip": "one insider tip — best time to go, where to sit, what to skip, parking situation, etc.",
  "vibe": "one sentence describing the atmosphere and who it's good for"
}
Write like a friend texting, not a review site. Be SPECIFIC — actual menu items or experiences, not generic "try the food". If it's not a food place, adapt mustTry to activities or experiences worth doing. Keep each field to 1-2 sentences max.`,
          },
          {
            role: "user",
            content: `Tell me about "${name}" at ${address}.`,
          },
        ],
        max_tokens: 400,
      }),
    });

    const data = (await res.json()) as {
      choices: Array<{ message: { content: string } }>;
    };
    const content = data.choices?.[0]?.message?.content;
    if (!content) return undefined;

    try {
      // Extract JSON from response (handles markdown code fences)
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (!jsonMatch) return { summary: content };

      const parsed = JSON.parse(jsonMatch[0]);
      return {
        knownFor: typeof parsed.knownFor === "string" ? parsed.knownFor : undefined,
        mustTry: Array.isArray(parsed.mustTry) ? parsed.mustTry.filter((x: unknown) => typeof x === "string") : undefined,
        proTip: typeof parsed.proTip === "string" ? parsed.proTip : undefined,
        vibe: typeof parsed.vibe === "string" ? parsed.vibe : undefined,
      };
    } catch {
      // JSON parsing failed — use raw text as summary
      return { summary: content };
    }
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

    // ── Demo edge case ───────────────────────────────────────────────
    const lastMsg = args.messages[args.messages.length - 1].content.toLowerCase();
    if (lastMsg.includes("alyn") && (lastMsg.includes("bored") || lastMsg.includes("what should we do"))) {
      // Search for the 3 demo locations in parallel to get real photos/placeIds
      const [bkfastResults, libResults, recResults] = await Promise.all([
        searchGooglePlaces("The Mill Coffee", args.latitude, args.longitude, googleApiKey, { limit: 1, radius: 8000 }),
        searchGooglePlaces("Love Library UNL", args.latitude, args.longitude, googleApiKey, { limit: 1, radius: 8000 }),
        searchGooglePlaces("Campus Recreation Center UNL", args.latitude, args.longitude, googleApiKey, { limit: 1, radius: 8000 }),
      ]);

      const breakfast: SpotData = bkfastResults[0] ?? {
        placeId: "demo_breakfast", name: "The Mill Coffee", address: "800 P St, Lincoln",
        latitude: 40.8145, longitude: -96.7067, rating: 4.7, priceLevel: 1,
      };
      const library: SpotData = libResults[0] ?? {
        placeId: "demo_library", name: "Love Library", address: "1248 R St, Lincoln",
        latitude: 40.8186, longitude: -96.7036,
      };
      const rec: SpotData = recResults[0] ?? {
        placeId: "demo_rec", name: "Campus Recreation Center", address: "1740 Vine St, Lincoln",
        latitude: 40.8241, longitude: -96.6987,
      };

      // Save plan to Convex
      const { planId, shareId } = await ctx.runMutation(
        internal.plans.createWithStopsInternal,
        {
          userId: args.userId,
          title: "Productive Sunday w/ Alyn",
          aiSummary: `${breakfast.name} → ${library.name} → ${rec.name}. fuel up, lock in, blow off steam.`,
          estimatedCost: "~$15",
          totalTime: "5-6 hrs",
          stops: [
            { emoji: "☕", name: breakfast.name, cost: "~$8", suggestedTime: "9:00am", notes: "fuel up before the grind" },
            { emoji: "📚", name: library.name, cost: "free", suggestedTime: "10:30am", notes: "lock in and get that homework done" },
            { emoji: "💪", name: rec.name, cost: "free", suggestedTime: "2:00pm", notes: "blow off steam after studying" },
          ],
        }
      );

      return {
        text: "you two need a productive sunday fr. breakfast to fuel up, library to lock in, then gym to blow off steam. the perfect reset day 💪",
        spots: [breakfast, library, rec],
        plan: {
          title: "Productive Sunday w/ Alyn",
          summary: `${breakfast.name} → ${library.name} → ${rec.name}. fuel up, lock in, blow off steam.`,
          stops: [
            { order: 1, emoji: "☕", name: breakfast.name, time: "9:00am", cost: "~$8", note: "get a cold brew and a pastry, you need the energy for this grind sesh", photoUrl: breakfast.photoUrl, placeId: breakfast.placeId },
            { order: 2, emoji: "📚", name: library.name, time: "10:30am", cost: "free", note: "3rd floor quiet zone is the move, nobody bothers you up there. lock in for a couple hours", photoUrl: library.photoUrl, placeId: library.placeId },
            { order: 3, emoji: "💪", name: rec.name, time: "2:00pm", cost: "free", note: "hit the courts or do a gym sesh. you earned it after all that studying", photoUrl: rec.photoUrl, placeId: rec.placeId },
          ],
          totalCost: "~$15",
          totalTime: "5-6 hrs",
          planId: planId as string,
          shareId,
        },
      };
    }

    // ── Demo edge case 2: swap gym for Raikes hackathon ──────────────
    const hasGymNegative = (lastMsg.includes("gym") || lastMsg.includes("rec")) &&
      (lastMsg.includes("not") || lastMsg.includes("skip") || lastMsg.includes("change") || lastMsg.includes("swap") || lastMsg.includes("instead") || lastMsg.includes("nah") || lastMsg.includes("maybe"));
    // Also trigger if they mention raikes/hackathon directly
    const hasRaikesMention = lastMsg.includes("raikes") || lastMsg.includes("hackathon");
    if (hasGymNegative || (hasRaikesMention && args.messages.length > 1)) {
      // Get the original breakfast + library from the previous plan context, and search for Raikes
      const [bkfastResults, libResults, raikesResults] = await Promise.all([
        searchGooglePlaces("The Mill Coffee", args.latitude, args.longitude, googleApiKey, { limit: 1, radius: 8000 }),
        searchGooglePlaces("Love Library UNL", args.latitude, args.longitude, googleApiKey, { limit: 1, radius: 8000 }),
        searchGooglePlaces("Raikes School UNL Hawks Hall", args.latitude, args.longitude, googleApiKey, { limit: 1, radius: 8000 }),
      ]);

      const breakfast: SpotData = bkfastResults[0] ?? {
        placeId: "demo_breakfast", name: "The Mill Coffee", address: "800 P St, Lincoln",
        latitude: 40.8145, longitude: -96.7067, rating: 4.7, priceLevel: 1,
      };
      const library: SpotData = libResults[0] ?? {
        placeId: "demo_library", name: "Love Library", address: "1248 R St, Lincoln",
        latitude: 40.8186, longitude: -96.7036,
      };
      const raikesRaw: SpotData | undefined = raikesResults[0];
      const raikes: SpotData = raikesRaw
        ? { ...raikesRaw, name: "Raikes School" }
        : {
            placeId: "demo_raikes", name: "Raikes School", address: "1244 R St, Lincoln",
            latitude: 40.8184, longitude: -96.7045,
          };

      const { planId, shareId } = await ctx.runMutation(
        internal.plans.createWithStopsInternal,
        {
          userId: args.userId,
          title: "Productive Sunday w/ Alyn (v2)",
          aiSummary: `${breakfast.name} → ${library.name} → Raikes School hackathon. fuel up, study, then build something.`,
          estimatedCost: "~$8",
          totalTime: "6-7 hrs",
          stops: [
            { emoji: "☕", name: breakfast.name, cost: "~$8", suggestedTime: "9:00am", notes: "fuel up before the grind" },
            { emoji: "📚", name: library.name, cost: "free", suggestedTime: "10:30am", notes: "lock in and get that homework done" },
            { emoji: "💻", name: raikes.name, cost: "free", suggestedTime: "2:00pm", notes: "hackathon time" },
          ],
        }
      );

      return {
        text: "say less, swapped the gym for the hackathon at Raikes. now its breakfast, study, then go build something cool. even better tbh 🔥",
        spots: [breakfast, library, raikes],
        plan: {
          title: "Productive Sunday w/ Alyn (v2)",
          summary: `${breakfast.name} → ${library.name} → ${raikes.name} hackathon. fuel up, study, then build something.`,
          stops: [
            { order: 1, emoji: "☕", name: breakfast.name, time: "9:00am", cost: "~$8", note: "get a cold brew and a pastry, you need the energy for this grind sesh", photoUrl: breakfast.photoUrl, placeId: breakfast.placeId },
            { order: 2, emoji: "📚", name: library.name, time: "10:30am", cost: "free", note: "3rd floor quiet zone is the move, nobody bothers you up there. lock in for a couple hours", photoUrl: library.photoUrl, placeId: library.placeId },
            { order: 3, emoji: "💻", name: raikes.name, time: "2:00pm", cost: "free", note: "hackathon time — bring the laptop, find a team, and build something sick with Alyn", photoUrl: raikes.photoUrl, placeId: raikes.placeId },
          ],
          totalCost: "~$8",
          totalTime: "6-7 hrs",
          planId: planId as string,
          shareId,
        },
      };
    }

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

        // Deduplicate by placeId and cap at 5 spots for the UI
        const seenIds = new Set<string>();
        const dedupedSpots: SpotData[] = [];
        for (const spot of resultSpots) {
          if (seenIds.has(spot.placeId)) continue;
          seenIds.add(spot.placeId);
          dedupedSpots.push(spot);
        }
        // Sort by rating (highest first) and take top 5
        dedupedSpots.sort((a, b) => (b.rating ?? 0) - (a.rating ?? 0));
        const topSpots = dedupedSpots.slice(0, 5);

        return {
          text,
          // Don't show spot cards if a plan was created — the plan already contains the spots
          spots: resultPlan ? undefined : (topSpots.length > 0 ? topSpots : undefined),
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
            { priceMax: input.priceMax }
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
          const { planId, shareId } = await ctx.runMutation(
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

          // Match plan stop names to searched spots to get photos
          const stopsWithPhotos = input.stops.map((s) => {
            const match = resultSpots.find(
              (spot) =>
                spot.name.toLowerCase() === s.name.toLowerCase() ||
                spot.name.toLowerCase().includes(s.name.toLowerCase()) ||
                s.name.toLowerCase().includes(spot.name.toLowerCase())
            );
            return {
              ...s,
              photoUrl: match?.photoUrl,
              placeId: match?.placeId,
            };
          });

          resultPlan = {
            title: input.title,
            summary: input.summary,
            stops: stopsWithPhotos,
            totalCost: input.totalCost,
            totalTime: input.totalTime,
            planId: planId as string,
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
    type: v.optional(v.string()),
  },
  handler: async (_, args): Promise<SpotData[]> => {
    const googleApiKey = process.env.GOOGLE_PLACES_API_KEY;
    if (!googleApiKey) throw new Error("GOOGLE_PLACES_API_KEY not set");

    const opts = { limit: 15, radius: 5000 };

    // If a specific type is requested, only search that category
    const typeQueries: Record<string, string> = {
      restaurant: "restaurants",
      cafe: "cafes",
      bar: "bars",
      coffee_shop: "coffee shops",
      bakery: "dessert ice cream bakery",
      shopping_mall: "shopping stores",
      park: "parks outdoors hiking",
      night_club: "nightlife clubs",
    };

    let allResults: SpotData[];

    if (args.type && typeQueries[args.type]) {
      allResults = await searchGooglePlaces(
        typeQueries[args.type],
        args.latitude,
        args.longitude,
        googleApiKey,
        { limit: 20, radius: 5000 }
      );
    } else {
      // Fetch several categories in parallel for a rich map
      const [restaurants, cafes, bars, entertainment, dessert, parks, shopping] = await Promise.all([
        searchGooglePlaces("restaurants", args.latitude, args.longitude, googleApiKey, opts),
        searchGooglePlaces("coffee shops cafes", args.latitude, args.longitude, googleApiKey, opts),
        searchGooglePlaces("bars nightlife", args.latitude, args.longitude, googleApiKey, opts),
        searchGooglePlaces("entertainment fun things to do", args.latitude, args.longitude, googleApiKey, opts),
        searchGooglePlaces("dessert ice cream bakery", args.latitude, args.longitude, googleApiKey, opts),
        searchGooglePlaces("parks nature trails outdoors", args.latitude, args.longitude, googleApiKey, opts),
        searchGooglePlaces("shopping boutiques retail stores", args.latitude, args.longitude, googleApiKey, opts),
      ]);
      allResults = [...restaurants, ...cafes, ...bars, ...entertainment, ...dessert, ...parks, ...shopping];
    }

    // Deduplicate by placeId
    const seen = new Set<string>();
    const spots: SpotData[] = [];
    for (const spot of allResults) {
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

    // Google Places Details first, then Perplexity (needs name/address)
    const details = await getGooglePlaceDetails(args.placeId, googleApiKey);
    const insight = await getPerplexityInsight(details.name, details.address);

    return {
      placeId: args.placeId,
      ...details,
      perplexitySummary: insight?.summary,
      knownFor: insight?.knownFor,
      mustTry: insight?.mustTry,
      proTip: insight?.proTip,
      vibe: insight?.vibe,
    };
  },
});
