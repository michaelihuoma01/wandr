// functions/src/search_logic.ts

// Assuming you will use Genkit or a similar library for schema and AI flow
// If using Genkit, you'd import from '@genkit-ai/core' or similar
// For now, we'll define basic types. Replace with your actual Genkit/schema setup.
import { z } from 'genkit'; // Placeholder, replace with actual import if you use genkit or zod
import { compareTwoStrings } from 'string-similarity';
import { getDistanceFromLatLonInKm } from './utils';

// --- Replace with your actual schema definitions --- START
// These are based on the TypeScript code you provided earlier.
// Ensure these match your Genkit or Zod schemas if you use them.
const placeholderImage = "https://placehold.co/600x400.png";

export const PlaceDetailsSchema = z.object({
  placeId: z.string().optional(),
  dataSource: z.string().optional(),
  name: z.string(),
  description: z.string(),
  latitude: z.number(),
  longitude: z.number(),
  type: z.string(),
  imageUrls: z.array(z.string().url()).optional(),
  rating: z.number().min(0).max(5).optional(),
  priceLevel: z.string().optional(),
  reviewTexts: z.array(z.string()).optional(),
  tags: z.array(z.string()).optional(),
  websiteUrl: z.string().url().optional(),
  phoneNumber: z.string().optional(),
  menuUrl: z.string().url().optional(),
  socialLinks: z.array(z.object({
    platform: z.string(),
    url: z.string().url(),
  })).optional(),
});
export type PlaceDetails = z.infer<typeof PlaceDetailsSchema>;

export const AnalyzeInputAndSuggestLocationsInputSchema = z.object({
  textInput: z.string().optional(),
  imageInputUri: z.string().url().optional(),
  inputType: z.enum(['text', 'image']),
  latitude: z.number(),
  longitude: z.number(),
  searchRadius: z.number().optional().default(20000),
});
export type AnalyzeInputAndSuggestLocationsInput = z.infer<typeof AnalyzeInputAndSuggestLocationsInputSchema>;

export const AnalyzeInputAndSuggestLocationsOutputSchema = z.object({
  locations: z.array(PlaceDetailsSchema),
});
export type AnalyzeInputAndSuggestLocationsOutput = z.infer<typeof AnalyzeInputAndSuggestLocationsOutputSchema>;

export const LLMSuggestionSchema = z.object({
  placeName: z.string(),
  searchQuery: z.string(),
});

export const LLMSuggestionsOutputSchema = z.object({
  suggestions: z.array(LLMSuggestionSchema).min(3).max(5),
});
// --- Replace with your actual schema definitions --- END


interface ApiKeys {
  googleApiKey: string;
  foursquareApiKey: string;
  geminiApiKey?: string; // Optional, if you pass it for direct use here
}

// Tool: Fetch place details from Google Places API
const fetchPlaceDetailsFromGoogle = async (
    { searchQuery, latitude, longitude }: { searchQuery: string; latitude: number; longitude: number },
    googleApiKey: string
  ): Promise<PlaceDetails | null> => {
  const apiKey = googleApiKey;
  console.log("[Google Tool] GOOGLE_PLACES_API_KEY availability:", { configured: !!apiKey });

  if (!apiKey) {
    console.error("[Google Tool] CRITICAL ERROR: GOOGLE_PLACES_API_KEY is not configured.");
    return {
      name: searchQuery,
      description: "Could not fetch details: Google API key not configured on server.",
      latitude: 0, longitude: 0, type: "Configuration Error",
      imageUrls: [placeholderImage],
      dataSource: 'Google',
    } as PlaceDetails; // Cast to satisfy type, ensure all required fields are present for PlaceDetails
  }

  try {
    const searchUrl = new URL("https://maps.googleapis.com/maps/api/place/textsearch/json");
    searchUrl.searchParams.append("query", searchQuery);
    searchUrl.searchParams.append("location", `${latitude},${longitude}`);
    searchUrl.searchParams.append("radius", "20000");
    searchUrl.searchParams.append("key", apiKey);

    const searchResponse = await fetch(searchUrl.toString());
    if (!searchResponse.ok) {
      console.error(`[Google Tool] TextSearch API error: ${searchResponse.status} ${await searchResponse.text()}`);
      return null;
    }
    const searchData = await searchResponse.json();
    if (!searchData.results || searchData.results.length === 0) {
      console.log(`[Google Tool] TextSearch: No results for query "${searchQuery}"`);
      return null;
    }
    const foundPlace = searchData.results[0];
    const placeId = foundPlace.place_id;

    if (!placeId) {
      console.log(`[Google Tool] TextSearch: No place_id found for "${searchQuery}"'s top result.`);
      return null;
    }

    const detailsUrl = new URL("https://maps.googleapis.com/maps/api/place/details/json");
    detailsUrl.searchParams.append("place_id", placeId);
    detailsUrl.searchParams.append("fields", "name,place_id,geometry,types,editorial_summary,website,formatted_phone_number,rating,price_level,reviews,photos");
    detailsUrl.searchParams.append("key", apiKey);

    const detailsResponse = await fetch(detailsUrl.toString());
    if (!detailsResponse.ok) {
      console.error(`[Google Tool] PlaceDetails API error: ${detailsResponse.status} ${await detailsResponse.text()}`);
      return null;
    }
    const detailsData = await detailsResponse.json();
    const details = detailsData.result;

    if (!details) {
      console.log(`[Google Tool] PlaceDetails: No details found for place_id "${placeId}"`);
      return null;
    }

    const actualImageUrls: string[] = [];
    if (details.photos && details.photos.length > 0) {
      details.photos.slice(0, 5).forEach((photo: any) => {
        if (photo.photo_reference && apiKey) {
          actualImageUrls.push(`https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${photo.photo_reference}&key=${apiKey}`);
        }
      });
    }

    const output: PlaceDetails = {
      placeId: details.place_id || undefined,
      dataSource: 'Google',
      name: details.name || searchQuery,
      description: details.editorial_summary?.overview || foundPlace.formatted_address || `A notable place: ${details.name || searchQuery}`,
      latitude: details.geometry.location.lat,
      longitude: details.geometry.location.lng,
      type: details.types?.[0]?.replace(/_/g, ' ') || 'Place',
      imageUrls: actualImageUrls.length > 0 ? actualImageUrls : undefined,
      rating: details.rating ? parseFloat(details.rating.toFixed(1)) : undefined,
      priceLevel: details.price_level !== undefined ? '.repeat(details.price_level + 1) : undefined,
      reviewTexts: details.reviews?.map((r: any) => r.text.substring(0, 150) + (r.text.length > 150 ? "..." : "")).slice(0, 3) || undefined,
      tags: details.types?.map((t: string) => t.replace(/_/g, ' ')).filter((t: string) => !['point_of_interest', 'establishment'].includes(t.toLowerCase())).slice(0, 4) || undefined,
      websiteUrl: details.website || undefined,
      phoneNumber: details.formatted_phone_number || undefined,
      // menuUrl: undefined, // Google Places API doesn't directly provide a menu URL
      // socialLinks: undefined, // Google Places API doesn't directly provide social links
    };
    console.log(`[Google Tool] Successfully fetched details for: ${output.name}`);
    return output;
  } catch (error: any) {
    console.error(`[Google Tool] Error fetching place details for query "${searchQuery}":`, error.message, error.stack);
    return null;
  }
};

// Tool: Fetch place details from Foursquare API
const fetchPlaceDetailsFromFoursquare = async (
    { searchQuery, latitude, longitude }: { searchQuery: string; latitude: number; longitude: number },
    foursquareApiKey: string
  ): Promise<PlaceDetails | null> => {
  const apiKey = foursquareApiKey;
  console.log("[Foursquare Tool] FOURSQUARE_API_KEY availability:", { configured: !!apiKey });

  if (!apiKey) {
    console.error("[Foursquare Tool] CRITICAL ERROR: FOURSQUARE_API_KEY is not configured.");
    return {
        name: searchQuery,
        description: "Could not fetch details: Foursquare API key not configured on server.",
        latitude: 0, longitude: 0, type: "Configuration Error",
        imageUrls: [placeholderImage],
        dataSource: 'Foursquare',
      } as PlaceDetails;
  }

  const headers = { 'Authorization': apiKey, 'Accept': 'application/json' }; // Foursquare-Version is often not needed for v3/places/search

  try {
    const searchParams = new URLSearchParams({
      query: searchQuery,
      ll: `${latitude},${longitude}`,
      radius: '20000',
      limit: '1',
      fields: 'fsq_id,name,geocodes,location,categories,website,social_media,tel,email,rating,price,description,menu',
    });
    const searchUrl = `https://api.foursquare.com/v3/places/search?${searchParams.toString()}`;

    const searchResponse = await fetch(searchUrl, { headers });
    if (!searchResponse.ok) {
      console.error(`[Foursquare Tool] Search API error: ${searchResponse.status} ${await searchResponse.text()}`);
      return null;
    }
    const searchData = await searchResponse.json();
    if (!searchData.results || searchData.results.length === 0) {
      console.log(`[Foursquare Tool] Search: No results for query "${searchQuery}"`);
      return null;
    }
    const fsqPlace = searchData.results[0];

    let actualImageUrls: string[] = [];
    const photosUrl = `https://api.foursquare.com/v3/places/${fsqPlace.fsq_id}/photos?limit=5&sort=POPULAR`;
    const photosResponse = await fetch(photosUrl, { headers });
    if (photosResponse.ok) {
      const fsqPhotos = await photosResponse.json();
      actualImageUrls = fsqPhotos.map((p: any) => `${p.prefix}original${p.suffix}`);
    }

    let reviewTexts: string[] = [];
    const tipsUrl = `https://api.foursquare.com/v3/places/${fsqPlace.fsq_id}/tips?limit=3&sort=POPULAR`;
    const tipsResponse = await fetch(tipsUrl, { headers });
    if (tipsResponse.ok) {
      const fsqTips = await tipsResponse.json();
      reviewTexts = fsqTips.map((t: any) => t.text.substring(0,150) + (t.text.length > 150 ? "..." : ""));
    }

    const socialLinks: { platform: string; url: string }[] = [];
    if (fsqPlace.social_media) {
      if (fsqPlace.social_media.facebook_id) socialLinks.push({ platform: 'Facebook', url: `https://www.facebook.com/${fsqPlace.social_media.facebook_id}` });
      if (fsqPlace.social_media.instagram) socialLinks.push({ platform: 'Instagram', url: `https://www.instagram.com/${fsqPlace.social_media.instagram}` });
      if (fsqPlace.social_media.twitter) socialLinks.push({ platform: 'Twitter', url: `https://twitter.com/${fsqPlace.social_media.twitter}` });
    }

    const output: PlaceDetails = {
      placeId: fsqPlace.fsq_id,
      dataSource: 'Foursquare',
      name: fsqPlace.name,
      description: fsqPlace.description || fsqPlace.categories?.map((c: any) => c.name).join(', ') || `Popular Foursquare venue: ${fsqPlace.name}`,
      latitude: fsqPlace.geocodes.main.latitude,
      longitude: fsqPlace.geocodes.main.longitude,
      type: fsqPlace.categories?.[0]?.name || 'Place',
      imageUrls: actualImageUrls.length > 0 ? actualImageUrls : undefined,
      rating: fsqPlace.rating ? parseFloat((fsqPlace.rating / 2).toFixed(1)) : undefined, // Normalize 0-10 to 0-5
      priceLevel: fsqPlace.price ? '.repeat(fsqPlace.price) : undefined,
      reviewTexts: reviewTexts.length > 0 ? reviewTexts : undefined,
      tags: fsqPlace.categories?.map((c: any) => c.name).slice(0, 4) || undefined,
      websiteUrl: fsqPlace.website || undefined,
      phoneNumber: fsqPlace.tel || undefined,
      menuUrl: fsqPlace.menu || undefined,
      socialLinks: socialLinks.length > 0 ? socialLinks : undefined,
    };
    console.log(`[Foursquare Tool] Successfully fetched details for: ${output.name}`);
    return output;
  } catch (error: any) {
    console.error(`[Foursquare Tool] Error fetching place details for query "${searchQuery}":`, error.message, error.stack);
    return null;
  }
};

// Main exported function
export async function analyzeInputAndSuggestLocations(
  input: AnalyzeInputAndSuggestLocationsInput,
  apiKeys: ApiKeys
): Promise<AnalyzeInputAndSuggestLocationsOutput> {
  console.log('[SearchLogic] Starting analyzeInputAndSuggestLocations with input:', input);

  // Validate input - this is good practice
  try {
    AnalyzeInputAndSuggestLocationsInputSchema.parse(input);
  } catch (e) {
    console.error("[SearchLogic] Invalid input schema:", e);
    return { locations: [] };
  }

  let llmSuggestions: z.infer<typeof LLMSuggestionsOutputSchema>;

  // Step 1: Get initial search queries/place name ideas from LLM
  //  ========= IMPORTANT: REPLACE WITH YOUR ACTUAL LLM (GEMINI) INTEGRATION =========
  // This section is a placeholder. You need to integrate with your LLM (e.g., Gemini)
  // using the Google AI Node.js SDK or your preferred method.
  if (input.inputType === 'text' && input.textInput) {
    console.log(`[SearchLogic] Getting LLM suggestions for text input: "${input.textInput}" (Using Placeholder)`);
    // Example: const result = await callGeminiForText(input.textInput, input.latitude, input.longitude, apiKeys.geminiApiKey);
    // llmSuggestions = result.output; // Adapt based on your LLM call
    llmSuggestions = { // Placeholder Data
      suggestions: [
        { placeName: "Cozy Cafe", searchQuery: `cafe near ${input.latitude},${input.longitude}` },
        { placeName: "Local Park", searchQuery: `park near ${input.latitude},${input.longitude}` },
        { placeName: "Book Store", searchQuery: `book store near ${input.latitude},${input.longitude}` },
      ]
    };
  } else if (input.inputType === 'image' && input.imageInputUri) {
    console.log(`[SearchLogic] Getting LLM suggestions for image input (Using Placeholder)`);
    // Example: const result = await callGeminiForImage(input.imageInputUri, input.latitude, input.longitude, apiKeys.geminiApiKey);
    // llmSuggestions = result.output;
    llmSuggestions = { // Placeholder Data
      suggestions: [
        { placeName: "Modern Restaurant", searchQuery: `modern restaurant near ${input.latitude},${input.longitude}` },
        { placeName: "Art Gallery", searchQuery: `art gallery near ${input.latitude},${input.longitude}` },
      ]
    };
  } else {
    console.error("[SearchLogic] Invalid input: Neither text nor image provided.");
    return { locations: [] };
  }
  // ========= END OF LLM PLACEHOLDER SECTION =========

  if (!llmSuggestions || !llmSuggestions.suggestions || llmSuggestions.suggestions.length === 0) {
    console.log("[SearchLogic] LLM did not provide any initial suggestions.");
    return { locations: [] };
  }
  console.log(`[SearchLogic] LLM provided ${llmSuggestions.suggestions.length} initial suggestions/queries.`);

  // Step 2: Fetch details for each LLM suggestion
  const googleResultsList: PlaceDetails[] = [];
  const foursquareResultsList: PlaceDetails[] = [];

  for (const suggestion of llmSuggestions.suggestions) {
    console.log(`[SearchLogic] Processing LLM suggestion: Query="${suggestion.searchQuery}"`);

    if (apiKeys.googleApiKey) {
      const googleResult = await fetchPlaceDetailsFromGoogle(
        { searchQuery: suggestion.searchQuery, latitude: input.latitude, longitude: input.longitude },
        apiKeys.googleApiKey
      );
      if (googleResult) googleResultsList.push(googleResult);
    } else {
      console.warn("[SearchLogic] GOOGLE_PLACES_API_KEY not provided. Skipping Google Places API calls.");
    }

    if (apiKeys.foursquareApiKey) {
      const foursquareResult = await fetchPlaceDetailsFromFoursquare(
        { searchQuery: suggestion.searchQuery, latitude: input.latitude, longitude: input.longitude },
        apiKeys.foursquareApiKey
      );
      if (foursquareResult) foursquareResultsList.push(foursquareResult);
    } else {
      console.warn("[SearchLogic] FOURSQUARE_API_KEY not provided. Skipping Foursquare API calls.");
    }
  }

  console.log(`[SearchLogic] Total Google results fetched: ${googleResultsList.length}`);
  console.log(`[SearchLogic] Total Foursquare results fetched: ${foursquareResultsList.length}`);

  // Step 3: Deduplicate and Combine Results
  const combinedLocations: PlaceDetails[] = [];
  const addedGooglePlaceIds = new Set<string>();

  googleResultsList.forEach(gPlace => {
    if (gPlace.placeId && !addedGooglePlaceIds.has(gPlace.placeId)) {
      combinedLocations.push(gPlace);
      addedGooglePlaceIds.add(gPlace.placeId);
    } else if (!gPlace.placeId && !combinedLocations.some(l => l.name === gPlace.name && l.dataSource === 'Google')) {
      combinedLocations.push(gPlace);
    }
  });

  const addedFoursquarePlaceIds = new Set<string>();
  for (const fsqPlace of foursquareResultsList) {
    if (fsqPlace.placeId && addedFoursquarePlaceIds.has(fsqPlace.placeId)) continue;
    if (fsqPlace.placeId) addedFoursquarePlaceIds.add(fsqPlace.placeId);

    let isDuplicateOfGoogle = false;
    for (const gPlace of googleResultsList) {
      if (!gPlace.name || !fsqPlace.name) continue;

      const gName = gPlace.name.toLowerCase().trim();
      const fName = fsqPlace.name.toLowerCase().trim();
      const nameSimilarity = compareTwoStrings(gName, fName);
      let namesAreSimilar = nameSimilarity > 0.85;

      if (!namesAreSimilar && (gName.includes(fName) || fName.includes(gName))) {
        if (Math.min(gName.length, fName.length) > 5) namesAreSimilar = true;
      }

      if (namesAreSimilar) {
        const distance = getDistanceFromLatLonInKm(gPlace.latitude, gPlace.longitude, fsqPlace.latitude, fsqPlace.longitude);
        if (distance < 0.15) { // 150 meters threshold
          isDuplicateOfGoogle = true;
          console.log(`[SearchLogic] Deduplication: Foursquare place "${fsqPlace.name}" (FSQ ID: ${fsqPlace.placeId}) considered duplicate of Google place "${gPlace.name}" (Google ID: ${gPlace.placeId}). Skipping Foursquare entry.`);
          break;
        }
      }
    }

    if (!isDuplicateOfGoogle) {
      if (fsqPlace.placeId && combinedLocations.some(l => l.placeId === fsqPlace.placeId && l.dataSource === 'Foursquare')) {
         // Already added (e.g. if Google list was empty)
      } else {
          combinedLocations.push(fsqPlace);
      }
    }
  }
  console.log(`[SearchLogic] Total combined locations after deduplication: ${combinedLocations.length}`);

  if (combinedLocations.length === 0) {
    console.log("[SearchLogic] No locations found after fetching and deduplication.");
    return { locations: [] };
  }

  console.log(`[SearchLogic] Final locations to return: ${combinedLocations.length}`);
  return { locations: combinedLocations };
}

// You would also have your LLM interaction functions here, e.g.:
/*
import { GoogleGenerativeAI } from "@google/generative-ai";

async function callGeminiForText(textInput: string, latitude: number, longitude: number, geminiApiKey?: string) {
  if (!geminiApiKey) {
    console.error("[LLM] Gemini API Key not provided.");
    return { suggestions: [] }; // Or throw error
  }
  const genAI = new GoogleGenerativeAI(geminiApiKey);
  const model = genAI.getGenerativeModel({ model: "gemini-pro" }); // Choose appropriate model

  const prompt = `User input: "${textInput}" at lat/lon: ${latitude},${longitude}. Suggest 3-5 search queries for local places.
  Format as JSON: { "suggestions": [{"placeName": "Name", "searchQuery": "Query"}] }`;

  try {
    const result = await model.generateContent(prompt);
    const response = result.response;
    const llmOutputText = response.text();
    console.log("[LLM] Gemini Raw Output:", llmOutputText);
    return JSON.parse(llmOutputText); // Ensure this matches LLMSuggestionsOutputSchema
  } catch (error) {
    console.error("[LLM] Error calling Gemini or parsing response:", error);
    return { suggestions: [] }; // Fallback
  }
}
// Implement callGeminiForImage similarly if needed
*/
