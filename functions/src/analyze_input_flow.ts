// functions/src/analyze_input_flow.ts
import { GoogleGenerativeAI } from "@google/generative-ai";
import { compareTwoStrings } from "string-similarity";
import { getDistanceFromLatLonInKm } from "./utils";
import { defineString } from "firebase-functions/params";

// Get API keys from Firebase parameters (v2 functions)
const geminiApiKey = defineString("GEMINI_API_KEY");
const googlePlacesApiKey = defineString("GOOGLE_PLACES_API_KEY");
const foursquareApiKey = defineString("FOURSQUARE_API_KEY");
const tripAdvisorApiKey = defineString("TRIPADVISOR_API_KEY");
const zomatoApiKey = defineString("ZOMATO_API_KEY");

// Initialize Gemini
let genAI: GoogleGenerativeAI;

function getGenAI() {
  if (!genAI) {
    const apiKey = geminiApiKey.value();
    if (!apiKey) {
      throw new Error("Gemini API key not configured");
    }
    genAI = new GoogleGenerativeAI(apiKey);
  }
  return genAI;
}

// Type definitions
export interface PlaceDetails {
  placeId?: string;
  dataSource?: string;
  name: string;
  description: string;
  latitude: number;
  longitude: number;
  type: string;
  imageUrls?: string[];
  rating?: number;
  priceLevel?: string;
  reviewTexts?: string[];
  tags?: string[];
  websiteUrl?: string;
  phoneNumber?: string;
  menuUrl?: string;
  socialLinks?: Array<{
    platform: string;
    url: string;
  }>;
  distance?: number; // Add distance for sorting
}

export interface AnalyzeInputAndSuggestLocationsInput {
  textInput?: string;
  imageInputUri?: string;
  inputType: "text" | "image";
  latitude: number;
  longitude: number;
  searchRadius?: number;
}

export interface AnalyzeInputAndSuggestLocationsOutput {
  locations: PlaceDetails[];
}

interface LLMSuggestion {
  placeName: string;
  searchQuery: string;
}

interface LLMSuggestionsOutput {
  suggestions: LLMSuggestion[];
}

// Helper function to get LLM suggestions for text - IMPROVED
async function getTextSuggestions(
  textInput: string,
  latitude: number,
  longitude: number
): Promise<LLMSuggestionsOutput> {
  const model = getGenAI().getGenerativeModel({ model: "gemini-1.5-flash" });

  console.log(`[LLM] Getting suggestions for text: "${textInput}" at location: ${latitude}, ${longitude}`);

  // Improved prompt with better location awareness
  const prompt = `
You are an AI assistant that suggests diverse and relevant search queries for finding local places based on user input.

User's text input: "${textInput}"
User's location: Latitude ${latitude}, Longitude ${longitude} (likely Dubai/UAE area)

Based on this, provide 3-5 diverse search queries for finding local places NEAR THE USER'S LOCATION.
Include location-specific terms in your queries to ensure local results.
Focus on places that would actually exist near these coordinates.

Return ONLY a valid JSON object with suggestions array, each containing placeName and searchQuery.

Example format:
{
  "suggestions": [
    {"placeName": "Cozy Coffee Shop", "searchQuery": "${textInput} near ${latitude},${longitude}"},
    {"placeName": "Pet-Friendly Restaurant", "searchQuery": "${textInput} in Dubai"},
    {"placeName": "Local Favorite", "searchQuery": "best ${textInput} near me ${latitude},${longitude}"}
  ]
}

Return only the JSON, no additional text.`;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    // Extract JSON from the response
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]) as LLMSuggestionsOutput;
    }

    throw new Error("Invalid response format from LLM");
  } catch (error) {
    console.error("[LLM] Error getting text suggestions:", error);
    // Better fallback suggestions with location
    return {
      suggestions: [
        { placeName: "Nearby Places", searchQuery: `${textInput} near ${latitude},${longitude}` },
        { placeName: "Local Spots", searchQuery: `${textInput} in Dubai` },
        { placeName: "Top Rated", searchQuery: `best ${textInput} near ${latitude},${longitude}` }
      ]
    };
  }
}

// Helper function to get LLM suggestions for image - IMPROVED
async function getImageSuggestions(
  imageUri: string,
  latitude: number,
  longitude: number
): Promise<LLMSuggestionsOutput> {
  const model = getGenAI().getGenerativeModel({ model: "gemini-1.5-flash-latest" });

  try {
    // Fetch image data
    const imageResponse = await fetch(imageUri);
    const imageArrayBuffer = await imageResponse.arrayBuffer();
    const imageBase64 = Buffer.from(imageArrayBuffer).toString('base64');

    const prompt = `
Analyze this image and suggest relevant local places to visit.
User's location: Latitude ${latitude}, Longitude ${longitude} (likely Dubai/UAE area)

Provide 3-5 diverse search queries based on what you see in the image.
Focus on finding similar places near the user's location.
Include location terms in your search queries.

Return ONLY a valid JSON object with suggestions array.

Example format:
{
  "suggestions": [
    {"placeName": "Similar Restaurant", "searchQuery": "restaurants like this near ${latitude},${longitude}"},
    {"placeName": "Related Activity", "searchQuery": "similar places in Dubai"}
  ]
}

Return only the JSON, no additional text.`;

    const result = await model.generateContent([
      prompt,
      {
        inlineData: {
          mimeType: "image/jpeg",
          data: imageBase64
        }
      }
    ]);

    const response = await result.response;
    const text = response.text();

    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]) as LLMSuggestionsOutput;
    }

    throw new Error("Invalid response format from LLM");
  } catch (error) {
    console.error("[LLM] Error getting image suggestions:", error);
    // Fallback suggestions
    return {
      suggestions: [
        { placeName: "Similar Places", searchQuery: `similar places near ${latitude},${longitude}` },
        { placeName: "Nearby Options", searchQuery: "popular places in Dubai" },
        { placeName: "Local Favorites", searchQuery: `trending spots near ${latitude},${longitude}` }
      ]
    };
  }
}

// Fetch place details from Google Places - IMPROVED but keeping your working approach
async function fetchPlaceDetailsFromGoogle(
  searchQuery: string,
  latitude: number,
  longitude: number,
  searchRadius?: number
): Promise<PlaceDetails | null> {
  const apiKey = googlePlacesApiKey.value();

  if (!apiKey) {
    console.error("[Google Tool] API key not configured");
    return null;
  }

  try {
    // Use the radius from input or default to 25km
    const radiusMeters = searchRadius || 25000;
    
    console.log(`[Google Tool] Searching for "${searchQuery}" near ${latitude},${longitude} within ${radiusMeters}m`);

    // Keep your working Text Search approach but with better parameters
    const searchUrl = new URL("https://maps.googleapis.com/maps/api/place/textsearch/json");
    searchUrl.searchParams.append("query", searchQuery);
    searchUrl.searchParams.append("location", `${latitude},${longitude}`);
    searchUrl.searchParams.append("radius", radiusMeters.toString());
    // Add stronger location bias
    searchUrl.searchParams.append("locationbias", `circle:${radiusMeters}@${latitude},${longitude}`);
    searchUrl.searchParams.append("key", apiKey);

    const searchResponse = await fetch(searchUrl.toString());
    if (!searchResponse.ok) {
      console.error(`[Google Tool] Search failed: ${searchResponse.status}`);
      return null;
    }

    const searchData = await searchResponse.json();
    if (!searchData.results || searchData.results.length === 0) {
      console.log(`[Google Tool] No results found for "${searchQuery}"`);
      return null;
    }

    // Sort results by distance and take the closest one
    const sortedResults = searchData.results.sort((a: any, b: any) => {
      const distA = getDistanceFromLatLonInKm(
        latitude, longitude,
        a.geometry.location.lat, a.geometry.location.lng
      );
      const distB = getDistanceFromLatLonInKm(
        latitude, longitude,
        b.geometry.location.lat, b.geometry.location.lng
      );
      return distA - distB;
    });

    const foundPlace = sortedResults[0];
    const placeId = foundPlace.place_id;
    
    // Calculate distance for logging
    const distance = getDistanceFromLatLonInKm(
      latitude, longitude,
      foundPlace.geometry.location.lat, foundPlace.geometry.location.lng
    );

    console.log(`[Google Tool] Found place: ${foundPlace.name} (${distance.toFixed(2)}km away)`);

    // Get details
    const detailsUrl = new URL("https://maps.googleapis.com/maps/api/place/details/json");
    detailsUrl.searchParams.append("place_id", placeId);
    detailsUrl.searchParams.append("fields", "name,place_id,geometry,types,editorial_summary,website,formatted_phone_number,rating,price_level,reviews,photos");
    detailsUrl.searchParams.append("key", apiKey);

    const detailsResponse = await fetch(detailsUrl.toString());
    if (!detailsResponse.ok) return null;

    const detailsData = await detailsResponse.json();
    const details = detailsData.result;

    const imageUrls: string[] = [];
    if (details.photos && details.photos.length > 0) {
      details.photos.slice(0, 5).forEach((photo: any) => {
        if (photo.photo_reference) {
          imageUrls.push(`https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${photo.photo_reference}&key=${apiKey}`);
        }
      });
    }

    return {
      placeId: details.place_id,
      dataSource: "Google",
      name: details.name || searchQuery,
      description: details.editorial_summary?.overview || foundPlace.formatted_address || "A notable place",
      latitude: details.geometry.location.lat,
      longitude: details.geometry.location.lng,
      type: details.types?.[0]?.replace(/_/g, " ") || "Place",
      imageUrls: imageUrls.length > 0 ? imageUrls : undefined,
      rating: details.rating,
      priceLevel: details.price_level !== undefined ? "$".repeat(details.price_level + 1) : undefined,
      reviewTexts: details.reviews?.map((r: any) => r.text.substring(0, 150)).slice(0, 3),
      tags: details.types?.map((t: string) => t.replace(/_/g, " ")).slice(0, 4),
      websiteUrl: details.website,
      phoneNumber: details.formatted_phone_number,
      distance: distance, // Add distance for client-side sorting
    };
  } catch (error) {
    console.error("[Google Tool] Error:", error);
    return null;
  }
}

// Fetch place details from Foursquare - IMPROVED
async function fetchPlaceDetailsFromFoursquare(
  searchQuery: string,
  latitude: number,
  longitude: number,
  searchRadius?: number
): Promise<PlaceDetails | null> {
  const apiKey = foursquareApiKey.value();

  if (!apiKey) {
    console.error("[Foursquare Tool] API key not configured");
    return null;
  }

  const headers = {
    "Authorization": apiKey,
    "Accept": "application/json"
  };

  try {
    const radiusMeters = searchRadius || 25000;
    
    const searchParams = new URLSearchParams({
      query: searchQuery,
      ll: `${latitude},${longitude}`,
      radius: radiusMeters.toString(),
      limit: "5", // Get more results to find the best one
      sort: "DISTANCE", // Sort by distance
    });

    const searchUrl = `https://api.foursquare.com/v3/places/search?${searchParams.toString()}`;
    const searchResponse = await fetch(searchUrl, { headers });

    if (!searchResponse.ok) return null;

    const searchData = await searchResponse.json();
    if (!searchData.results || searchData.results.length === 0) return null;

    // Take the closest result
    const fsqPlace = searchData.results[0];
    
    const distance = getDistanceFromLatLonInKm(
      latitude, longitude,
      fsqPlace.geocodes.main.latitude, fsqPlace.geocodes.main.longitude
    );

    // Get photos
    const photosUrl = `https://api.foursquare.com/v3/places/${fsqPlace.fsq_id}/photos?limit=5`;
    const photosResponse = await fetch(photosUrl, { headers });
    let imageUrls: string[] = [];
    if (photosResponse.ok) {
      const photos = await photosResponse.json();
      imageUrls = photos.map((p: any) => `${p.prefix}original${p.suffix}`);
    }

    // Get tips
    const tipsUrl = `https://api.foursquare.com/v3/places/${fsqPlace.fsq_id}/tips?limit=3`;
    const tipsResponse = await fetch(tipsUrl, { headers });
    let reviewTexts: string[] = [];
    if (tipsResponse.ok) {
      const tips = await tipsResponse.json();
      reviewTexts = tips.map((t: any) => t.text.substring(0, 150));
    }

    return {
      placeId: fsqPlace.fsq_id,
      dataSource: "Foursquare",
      name: fsqPlace.name,
      description: fsqPlace.categories?.map((c: any) => c.name).join(", ") || "Popular venue",
      latitude: fsqPlace.geocodes.main.latitude,
      longitude: fsqPlace.geocodes.main.longitude,
      type: fsqPlace.categories?.[0]?.name || "Place",
      imageUrls: imageUrls.length > 0 ? imageUrls : undefined,
      rating: fsqPlace.rating ? fsqPlace.rating / 2 : undefined,
      reviewTexts: reviewTexts.length > 0 ? reviewTexts : undefined,
      tags: fsqPlace.categories?.map((c: any) => c.name).slice(0, 4),
      distance: distance,
    };
  } catch (error) {
    console.error("[Foursquare Tool] Error:", error);
    return null;
  }
}

// Placeholder for TripAdvisor integration
async function fetchPlaceDetailsFromTripAdvisor(
  searchQuery: string,
  latitude: number,
  longitude: number
): Promise<PlaceDetails | null> {
  const apiKey = tripAdvisorApiKey.value();

  if (!apiKey) {
    return null;
  }

  try {
    // TODO: Implement TripAdvisor API integration
    console.log("[TripAdvisor Tool] Would search for:", searchQuery);
    return null;
  } catch (error) {
    console.error("[TripAdvisor Tool] Error:", error);
    return null;
  }
}

// Placeholder for Zomato integration
async function fetchPlaceDetailsFromZomato(
  searchQuery: string,
  latitude: number,
  longitude: number
): Promise<PlaceDetails | null> {
  const apiKey = zomatoApiKey.value();

  if (!apiKey) {
    return null;
  }

  try {
    // TODO: Implement Zomato API integration
    console.log("[Zomato Tool] Would search for:", searchQuery);
    return null;
  } catch (error) {
    console.error("[Zomato Tool] Error:", error);
    return null;
  }
}

// Deduplication function
function deduplicateLocations(locations: PlaceDetails[]): PlaceDetails[] {
  const uniqueLocations: PlaceDetails[] = [];
  const seenPlaceIds = new Set<string>();

  for (const location of locations) {
    // Check if we've seen this place ID
    if (location.placeId && seenPlaceIds.has(location.placeId)) {
      continue;
    }

    // Check for similar locations by name and proximity
    let isDuplicate = false;
    for (const existing of uniqueLocations) {
      const nameSimilarity = compareTwoStrings(
        location.name.toLowerCase(),
        existing.name.toLowerCase()
      );
      const distance = getDistanceFromLatLonInKm(
        location.latitude,
        location.longitude,
        existing.latitude,
        existing.longitude
      );

      if (nameSimilarity > 0.85 && distance < 0.15) {
        isDuplicate = true;
        break;
      }
    }

    if (!isDuplicate) {
      uniqueLocations.push(location);
      if (location.placeId) {
        seenPlaceIds.add(location.placeId);
      }
    }
  }

  return uniqueLocations;
}

// Main function - IMPROVED
export async function analyzeInputAndSuggestLocations(
  input: AnalyzeInputAndSuggestLocationsInput
): Promise<AnalyzeInputAndSuggestLocationsOutput> {
  try {
    console.log("[Flow] Starting with input:", {
      type: input.inputType,
      latitude: input.latitude,
      longitude: input.longitude,
      searchRadius: input.searchRadius,
      query: input.textInput?.substring(0, 50)
    });

    // Step 1: Get suggestions from LLM
    let llmSuggestions: LLMSuggestionsOutput;

    if (input.inputType === "text" && input.textInput) {
      llmSuggestions = await getTextSuggestions(
        input.textInput,
        input.latitude,
        input.longitude
      );
    } else if (input.inputType === "image" && input.imageInputUri) {
      llmSuggestions = await getImageSuggestions(
        input.imageInputUri,
        input.latitude,
        input.longitude
      );
    } else {
      return { locations: [] };
    }

    if (!llmSuggestions?.suggestions?.length) {
      console.log("[Flow] No suggestions from LLM");
      return { locations: [] };
    }

    console.log(`[Flow] Got ${llmSuggestions.suggestions.length} suggestions from LLM`);

    // Step 2: Fetch details from all sources
    const allResults: PlaceDetails[] = [];

    for (const suggestion of llmSuggestions.suggestions) {
      console.log(`[Flow] Processing suggestion: ${suggestion.searchQuery}`);

      // Fetch from all available sources in parallel
      const promises: Promise<PlaceDetails | null>[] = [];

      if (googlePlacesApiKey.value()) {
        promises.push(fetchPlaceDetailsFromGoogle(
          suggestion.searchQuery,
          input.latitude,
          input.longitude,
          input.searchRadius
        ));
      }

      if (foursquareApiKey.value()) {
        promises.push(fetchPlaceDetailsFromFoursquare(
          suggestion.searchQuery,
          input.latitude,
          input.longitude,
          input.searchRadius
        ));
      }

      if (tripAdvisorApiKey.value()) {
        promises.push(fetchPlaceDetailsFromTripAdvisor(
          suggestion.searchQuery,
          input.latitude,
          input.longitude
        ));
      }

      if (zomatoApiKey.value() && suggestion.searchQuery.toLowerCase().includes("restaurant")) {
        promises.push(fetchPlaceDetailsFromZomato(
          suggestion.searchQuery,
          input.latitude,
          input.longitude
        ));
      }

      const results = await Promise.all(promises);
      const validResults = results.filter((r): r is PlaceDetails => r !== null);
      allResults.push(...validResults);
    }

    // Step 3: Deduplicate results
    const deduplicatedLocations = deduplicateLocations(allResults);
    
    // Step 4: Sort by distance (client can re-sort as needed)
    const sortedLocations = deduplicatedLocations.sort((a, b) => {
      const distA = a.distance || getDistanceFromLatLonInKm(
        input.latitude, input.longitude,
        a.latitude, a.longitude
      );
      const distB = b.distance || getDistanceFromLatLonInKm(
        input.latitude, input.longitude,
        b.latitude, b.longitude
      );
      return distA - distB;
    });

    console.log(`[Flow] Returning ${sortedLocations.length} unique locations`);
    return { locations: sortedLocations };
  } catch (error) {
    console.error("[analyzeInputAndSuggestLocations] Error:", error);
    throw error;
  }
}