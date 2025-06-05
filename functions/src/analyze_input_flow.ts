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

// Helper function to get LLM suggestions for text
async function getTextSuggestions(
  textInput: string,
  latitude: number,
  longitude: number
): Promise<LLMSuggestionsOutput> {
  const model = getGenAI().getGenerativeModel({ model: "gemini-1.5-flash" });
  
  const prompt = `
You are an AI assistant that suggests diverse and relevant search queries for finding local places based on user input.

User's text input: "${textInput}"
User's location: Latitude ${latitude}, Longitude ${longitude}

Based on this, provide 3-5 diverse search queries for finding local places.
Return ONLY a valid JSON object with suggestions array, each containing placeName and searchQuery.

Example format:
{
  "suggestions": [
    {"placeName": "Cozy Coffee Shop", "searchQuery": "artisan coffee shops near me"},
    {"placeName": "Pet-Friendly Restaurant", "searchQuery": "dog friendly restaurants"}
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
    // Fallback suggestions
    return {
      suggestions: [
        { placeName: "Nearby Places", searchQuery: `${textInput} near me` },
        { placeName: "Popular Spots", searchQuery: `best ${textInput}` },
        { placeName: "Local Favorites", searchQuery: `top rated ${textInput}` }
      ]
    };
  }
}

// Helper function to get LLM suggestions for image
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
User's location: Latitude ${latitude}, Longitude ${longitude}

Provide 3-5 diverse search queries based on what you see in the image.
Return ONLY a valid JSON object with suggestions array.

Example format:
{
  "suggestions": [
    {"placeName": "Similar Restaurant", "searchQuery": "restaurants with outdoor seating"},
    {"placeName": "Related Activity", "searchQuery": "parks for picnic"}
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
        { placeName: "Similar Places", searchQuery: "popular places near me" },
        { placeName: "Nearby Attractions", searchQuery: "things to do nearby" },
        { placeName: "Local Spots", searchQuery: "local favorites" }
      ]
    };
  }
}

// Fetch place details from Google Places
async function fetchPlaceDetailsFromGoogle(
  searchQuery: string,
  latitude: number,
  longitude: number
): Promise<PlaceDetails | null> {
  const apiKey = googlePlacesApiKey.value();
  
  if (!apiKey) {
    console.error("[Google Tool] API key not configured");
    return null;
  }

  try {
    // Text search
    const searchUrl = new URL("https://maps.googleapis.com/maps/api/place/textsearch/json");
    searchUrl.searchParams.append("query", searchQuery);
    searchUrl.searchParams.append("location", `${latitude},${longitude}`);
    searchUrl.searchParams.append("radius", "20000");
    searchUrl.searchParams.append("key", apiKey);

    const searchResponse = await fetch(searchUrl.toString());
    if (!searchResponse.ok) return null;
    
    const searchData = await searchResponse.json();
    if (!searchData.results || searchData.results.length === 0) return null;
    
    const foundPlace = searchData.results[0];
    const placeId = foundPlace.place_id;

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
    };
  } catch (error) {
    console.error("[Google Tool] Error:", error);
    return null;
  }
}

// Fetch place details from Foursquare
async function fetchPlaceDetailsFromFoursquare(
  searchQuery: string,
  latitude: number,
  longitude: number
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
    const searchParams = new URLSearchParams({
      query: searchQuery,
      ll: `${latitude},${longitude}`,
      radius: "20000",
      limit: "1",
    });
    
    const searchUrl = `https://api.foursquare.com/v3/places/search?${searchParams.toString()}`;
    const searchResponse = await fetch(searchUrl, { headers });
    
    if (!searchResponse.ok) return null;
    
    const searchData = await searchResponse.json();
    if (!searchData.results || searchData.results.length === 0) return null;
    
    const fsqPlace = searchData.results[0];

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

// Main function
export async function analyzeInputAndSuggestLocations(
  input: AnalyzeInputAndSuggestLocationsInput
): Promise<AnalyzeInputAndSuggestLocationsOutput> {
  try {
    console.log("[Flow] Starting with input type:", input.inputType);

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
          input.longitude
        ));
      }

      if (foursquareApiKey.value()) {
        promises.push(fetchPlaceDetailsFromFoursquare(
          suggestion.searchQuery,
          input.latitude,
          input.longitude
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

    console.log(`[Flow] Returning ${deduplicatedLocations.length} unique locations`);
    return { locations: deduplicatedLocations };
  } catch (error) {
    console.error("[analyzeInputAndSuggestLocations] Error:", error);
    throw error;
  }
}