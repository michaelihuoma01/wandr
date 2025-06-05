// functions/src/analyze_input_flow.ts

// Adjusted import path for the Genkit 'ai' instance
import { ai } from './genkit_config'; 
import { z } from '@genkit-ai/core';

// Adjusted import path for utility functions
import { getDistanceFromLatLonInKm } from './utils'; 
import { compareTwoStrings } from 'string-similarity';

const placeholderImage = "https://placehold.co/600x400.png";

// Schema for individual place details, used by tools and final output
export const PlaceDetailsSchema = z.object({
  placeId: z.string().optional().describe("The unique identifier for the place from its source API (e.g., Google Place ID, Foursquare FSQ ID). If unavailable or the source does not provide a stable ID, this field MUST BE OMITTED."),
  dataSource: z.string().optional().describe("The source of this place data (e.g., 'Google', 'Foursquare'). This indicates the origin of the place information. If unavailable, this field MUST BE OMITTED."),
  name: z.string().describe("The official name of the location. This field is required."),
  description: z.string().describe("A brief, engaging description of the location. This field is required."),
  latitude: z.number().describe("The precise latitude of the location. This field is required."),
  longitude: z.number().describe("The precise longitude of the location. This field is required."),
  type: z.string().describe("The primary type or category of the location (e.g., 'Restaurant', 'Coffee Shop', 'Museum'). This field is required."),
  imageUrls: z.array(z.string().url())
    .optional()
    .describe("An array of direct, publicly accessible URLs to high-quality images from the respective API. The tool constructs these URLs. THE LLM MUST USE THIS ARRAY AND ITS CONTENTS EXACTLY AS PROVIDED by the tool. If no images are available from the tool, this field MUST BE OMITTED."),
  rating: z.number().min(0).max(5).optional().describe("The location's rating, typically on a 1-5 scale. If unavailable, this field MUST BE OMITTED."),
  priceLevel: z.string().optional().describe("A string representing the price level (e.g., '\$', '\$\$', '\$\$\$'). If unavailable, this field MUST BE OMITTED."),
  reviewTexts: z.array(z.string()).optional().describe("An array of up to 3 concise user review snippets. If unavailable or empty, this field MUST BE OMITTED."),
  tags: z.array(z.string()).optional().describe("An array of relevant tags or keywords associated with the place. If unavailable or empty, this field MUST BE OMITTED."),
  websiteUrl: z.string().url().optional().describe("The official website URL. If unavailable, this field MUST BE OMITTED by the LLM from the output JSON."),
  phoneNumber: z.string().optional().describe("The primary phone number. If unavailable, this field MUST BE OMITTED by the LLM from the output JSON."),
  menuUrl: z.string().url().optional().describe("A direct URL to the location's menu. If unavailable, this field MUST BE OMITTED by the LLM from the output JSON."),
  socialLinks: z.array(z.object({
    platform: z.string().describe("Name of the social media platform (e.g., 'Facebook', 'Instagram')."),
    url: z.string().url().describe("Full URL to the social media profile."),
  })).optional().describe("An array of social media links. If unavailable or empty, this field MUST BE OMITTED."),
});
export type PlaceDetails = z.infer<typeof PlaceDetailsSchema>;


// Input schema for the main flow
export const AnalyzeInputAndSuggestLocationsInputSchema = z.object({
  textInput: z.string().optional(),
  imageInputUri: z.string().url().optional(),
  inputType: z.enum(['text', 'image']),
  latitude: z.number(),
  longitude: z.number(),
  searchRadius: z.number().optional().default(20000), // Default radius in meters (20km)
});
export type AnalyzeInputAndSuggestLocationsInput = z.infer<typeof AnalyzeInputAndSuggestLocationsInputSchema>;

// Output schema for the main flow
export const AnalyzeInputAndSuggestLocationsOutputSchema = z.object({
  locations: z.array(PlaceDetailsSchema).describe("An array of suggested locations, deduplicated and sorted by relevance/distance."),
});
export type AnalyzeInputAndSuggestLocationsOutput = z.infer<typeof AnalyzeInputAndSuggestLocationsOutputSchema>;


// Schema for LLM's initial place suggestions (queries or names)
export const LLMSuggestionSchema = z.object({
  placeName: z.string().describe('The conceptual name of a place or a type of place the user might be interested in (e.g., "Eiffel Tower", "quiet coffee shop").'),
  searchQuery: z.string().describe('A concise and effective search query string (e.g., "Eiffel Tower Paris", "quiet coffee shops near me") that can be used with Google Places API or Foursquare API to find specific establishments related to the placeName.'),
});

export const LLMSuggestionsOutputSchema = z.object({
  suggestions: z.array(LLMSuggestionSchema).min(3).max(5).describe('Array of 3-5 place suggestions, each with a conceptual name and a practical search query.'),
});


// Tool: Fetch place details from Google Places API
export const fetchPlaceDetailsFromGoogle = ai.defineTool(
  {
    name: 'fetchPlaceDetailsFromGoogle',
    description: 'Fetches detailed information about a specific place from Google Places API using a search query and location context. Returns details for the most relevant match.',
    inputSchema: z.object({
      searchQuery: z.string().describe("The search query string (e.g., 'Eiffel Tower Paris', 'best pizza nearby')."),
      latitude: z.number().describe("User's current latitude."),
      longitude: z.number().describe("User's current longitude."),
    }),
    outputSchema: PlaceDetailsSchema.nullable().describe("Detailed information for one matching place, or null if no relevant place is found or an error occurs."),
  },
  async ({ searchQuery, latitude, longitude }) => {
    const apiKey = process.env.GOOGLE_PLACES_API_KEY;
    console.log("[Google Tool] GOOGLE_PLACES_API_KEY availability:", { configured: !!apiKey, valueFirstChars: apiKey ? apiKey.substring(0, 5) + "..." : "Not Set/Undefined" });

    if (!apiKey) {
      console.error("[Google Tool] CRITICAL ERROR: GOOGLE_PLACES_API_KEY (environment variable) is not configured on the server. Cannot fetch Google Place details.");
      return {
        name: searchQuery,
        description: "Could not fetch details: Google API key not configured on server. Please check server environment variables.",
        latitude: 0, longitude: 0, type: "Configuration Error",
        imageUrls: [placeholderImage],
        dataSource: 'Google',
      } as PlaceDetails;
    }

    try {
      const searchUrl = new URL("https://maps.googleapis.com/maps/api/place/textsearch/json");
      searchUrl.searchParams.append("query", searchQuery);
      searchUrl.searchParams.append("location", `${latitude},${longitude}`);
      searchUrl.searchParams.append("radius", "20000");
      searchUrl.searchParams.append("key", apiKey);

      console.log(`[Google Tool] TextSearch URL: ${searchUrl.toString().replace(apiKey, "GOOGLE_API_KEY_HIDDEN")}`);
      const searchResponse = await fetch(searchUrl.toString());
      if (!searchResponse.ok) {
        const errorText = await searchResponse.text();
        console.error(`[Google Tool] TextSearch API error: ${searchResponse.status} ${errorText}`);
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

      console.log(`[Google Tool] PlaceDetails URL: ${detailsUrl.toString().replace(apiKey, "GOOGLE_API_KEY_HIDDEN")}`);
      const detailsResponse = await fetch(detailsUrl.toString());
      if (!detailsResponse.ok) {
         const errorText = await detailsResponse.text();
        console.error(`[Google Tool] PlaceDetails API error: ${detailsResponse.status} ${errorText}`);
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
      console.log(`[Google Tool] Constructed image URLs for ${details.name}: ${actualImageUrls.length}`);

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
        priceLevel: details.price_level !== undefined ? '$'.repeat(details.price_level + 1) : undefined,
        reviewTexts: details.reviews?.map((r: any) => r.text.substring(0, 150) + (r.text.length > 150 ? "..." : "")).slice(0, 3) || undefined,
        tags: details.types?.map((t: string) => t.replace(/_/g, ' ')).filter((t: string) => ![^'point_of_interest', 'establishment'].includes(t.toLowerCase())).slice(0, 4) || undefined,
        websiteUrl: details.website || undefined,
        phoneNumber: details.formatted_phone_number || undefined,
        menuUrl: undefined,
        socialLinks: undefined,
      };
      for (const key in output) {
        if (output[key as keyof PlaceDetails] === undefined) {
          delete output[key as keyof PlaceDetails];
        }
      }
      console.log(`[Google Tool] Successfully fetched details for: ${output.name}`);
      return output;

    } catch (error: any) {
      console.error(`[Google Tool] Error fetching place details for query "${searchQuery}":`, error.message, error.stack);
      return null;
    }
  }
);

// Tool: Fetch place details from Foursquare API
export const fetchPlaceDetailsFromFoursquare = ai.defineTool(
  {
    name: 'fetchPlaceDetailsFromFoursquare',
    description: 'Fetches detailed information about a place from Foursquare API based on a search query and location. Returns details for the most relevant match.',
    inputSchema: z.object({
      searchQuery: z.string().describe("The search query string (e.g., 'Eiffel Tower Paris', 'best pizza nearby')."),
      latitude: z.number().describe("User's current latitude."),
      longitude: z.number().describe("User's current longitude."),
    }),
    outputSchema: PlaceDetailsSchema.nullable().describe("Detailed information for one matching place, or null if no relevant place is found or an error occurs."),
  },
  async ({ searchQuery, latitude, longitude }) => {
    const apiKey = process.env.FOURSQUARE_API_KEY;
    console.log("[Foursquare Tool] FOURSQUARE_API_KEY availability:", { configured: !!apiKey });

    if (!apiKey) {
      console.error("[Foursquare Tool] CRITICAL ERROR: FOURSQUARE_API_KEY (environment variable) is not configured on the server. Cannot fetch Foursquare details.");
       return {
        name: searchQuery,
        description: "Could not fetch details: Foursquare API key not configured on server. Please check server environment variables.",
        latitude: 0, longitude: 0, type: "Configuration Error",
        imageUrls: [placeholderImage],
        dataSource: 'Foursquare',
      } as PlaceDetails;
    }

    const headers = { 'Authorization': apiKey, 'Accept': 'application/json', 'Foursquare-Version': '20230314' };

    try {
      const searchParams = new URLSearchParams({
        query: searchQuery,
        ll: `${latitude},${longitude}`,
        radius: '20000',
        limit: '1',
        fields: 'fsq_id,name,geocodes,location,categories,website,social_media,tel,email,rating,price,description,menu',
      });
      const searchUrl = `https://api.foursquare.com/v3/places/search?${searchParams.toString()}`;
      console.log(`[Foursquare Tool] Search URL: ${searchUrl}`);

      const searchResponse = await fetch(searchUrl, { headers });
      if (!searchResponse.ok) {
        const errorText = await searchResponse.text();
        console.error(`[Foursquare Tool] Search API error: ${searchResponse.status} ${errorText}`);
        return null;
      }
      const searchData = await searchResponse.json();
      if (!searchData.results || searchData.results.length === 0) {
        console.log(`[Foursquare Tool] Search: No results for query "${searchQuery}"`);
        return null;
      }
      const fsqPlace = searchData.results[0];

      const photosUrl = `https://api.foursquare.com/v3/places/${fsqPlace.fsq_id}/photos?limit=5&sort=POPULAR`;
      const photosResponse = await fetch(photosUrl, { headers });
      let actualImageUrls: string[] = [];
      if (photosResponse.ok) {
        const fsqPhotos = await photosResponse.json();
        actualImageUrls = fsqPhotos.map((p: any) => `${p.prefix}original${p.suffix}`);
      }
      console.log(`[Foursquare Tool] Constructed image URLs for ${fsqPlace.name}: ${actualImageUrls.length}`);

      const tipsUrl = `https://api.foursquare.com/v3/places/${fsqPlace.fsq_id}/tips?limit=3&sort=POPULAR`;
      const tipsResponse = await fetch(tipsUrl, { headers });
      let reviewTexts: string[] = [];
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
        rating: fsqPlace.rating ? parseFloat((fsqPlace.rating / 2).toFixed(1)) : undefined,
        priceLevel: fsqPlace.price ? '$'.repeat(fsqPlace.price) : undefined,
        reviewTexts: reviewTexts.length > 0 ? reviewTexts : undefined,
        tags: fsqPlace.categories?.map((c: any) => c.name).slice(0, 4) || undefined,
        websiteUrl: fsqPlace.website || undefined,
        phoneNumber: fsqPlace.tel || undefined,
        menuUrl: fsqPlace.menu || undefined,
        socialLinks: socialLinks.length > 0 ? socialLinks : undefined,
      };
       for (const key in output) {
        if (output[key as keyof PlaceDetails] === undefined) {
          delete output[key as keyof PlaceDetails];
        }
      }
      console.log(`[Foursquare Tool] Successfully fetched details for: ${output.name}`);
      return output;

    } catch (error: any) {
      console.error(`[Foursquare Tool] Error fetching place details for query "${searchQuery}":`, error.message, error.stack);
      return null;
    }
  }
);


// Common system instruction for the LLM
const commonPromptSystemInstruction = `
You are an expert local guide AI. Your goal is to suggest specific, real places based on user input (text or image) and their location.
You will be provided with a list of search queries or place names.
For each item in that list, you MUST use the 'fetchPlaceDetailsFromGoogle' tool AND the 'fetchPlaceDetailsFromFoursquare' tool to get detailed information.
Ensure you accurately map the data from the tools to the JSON output schema.

CRITICALLY IMPORTANT FOR ALL FIELDS:
1.  The tools provide various fields. You MUST use the data from these tools EXACTLY AS PROVIDED to populate the corresponding fields in your final JSON output (defined by 'PlaceDetailsSchema').
2.  For optional fields in the 'PlaceDetailsSchema' (like rating, priceLevel, reviewTexts, tags, websiteUrl, phoneNumber, menuUrl, socialLinks, imageUrls, placeId, dataSource):
    *   If a tool provides a value for an optional field, you MUST include that field and its value in your output.
    *   If a tool DOES NOT provide a value for an optional field (i.e., the field is 'undefined' or missing in the tool's output), YOU MUST OMIT THE FIELD ENTIRELY for that location in your JSON output. DO NOT use 'null', an empty string "", or an empty array [] for these missing optional fields unless the schema specifically allows it for that field (e.g. imageUrls could be an empty array if the tool returns it as such, but it's better to omit if truly no images). If a field like 'websiteUrl' is missing from the tool output, it should NOT appear in your JSON for that location.
3.  The 'imageUrls' field: If the tool provides an array of image URLs, use it as is. The tool is responsible for constructing correct, full URLs (including API keys if needed for direct display). If the tool provides an empty array or no 'imageUrls' field, OMIT the 'imageUrls' field from your output for that location. Do NOT substitute a placeholder UNLESS the tool explicitly provides a placeholder URL in the array.
4.  Pay close attention to data types. Numbers must be numbers, strings must be strings, arrays must be arrays.

Your final response MUST be a JSON object conforming to 'AnalyzeInputAndSuggestLocationsOutputSchema', containing a 'locations' array.
Each object in the 'locations' array MUST conform to 'PlaceDetailsSchema'.
Do not add any commentary or conversational text outside the JSON structure.
Prioritize accuracy and directly use the tool-provided data.
`;

// LLM Prompts for generating initial search queries
export const textSuggestionPrompt = ai.definePrompt({
  name: 'textSuggestionPrompt',
  input: {
    schema: z.object({
      textInput: z.string(),
      latitude: z.number(),
      longitude: z.number(),
    }),
  },
  output: { schema: LLMSuggestionsOutputSchema },
  system: "You are an AI assistant that suggests 3-5 diverse and relevant search queries for finding local places based on a user's text input and location. Focus on variety and potential user intent.",
  prompt: `User's text input: "{{{textInput}}}"
User's current location: Latitude {{{latitude}}}, Longitude {{{longitude}}}

Based on this, provide 3-5 diverse search queries. For each, provide a conceptual 'placeName' and a 'searchQuery' suitable for APIs.
Return ONLY a JSON object matching the LLMSuggestionsOutputSchema.
Example:
{
  "suggestions": [
    {"placeName": "Fancy Dinner Spot", "searchQuery": "fine dining restaurants near me"},
    {"placeName": "Quick Coffee", "searchQuery": "best independent coffee shops"},
    {"placeName": "Park for a Walk", "searchQuery": "parks with walking trails"}
  ]
}`,
  tools: [], // No tools for this initial suggestion step
  model: 'gemini-pro' // Specify model if not globally set in genkit_config or if you want to override
});

export const imageSuggestionPrompt = ai.definePrompt({
  name: 'imageSuggestionPrompt',
  input: {
    schema: z.object({
      imageInputUri: z.string().url(),
      latitude: z.number(),
      longitude: z.number(),
    }),
  },
  output: { schema: LLMSuggestionsOutputSchema },
  system: "You are an AI assistant that analyzes an image and suggests 3-5 diverse and relevant search queries for finding local places related to the image content and user's location. Focus on variety and potential user intent.",
  prompt: `Image input: {{media url=imageInputUri}}
User's current location: Latitude {{{latitude}}}, Longitude {{{longitude}}}

Based on this, provide 3-5 diverse search queries. For each, provide a conceptual 'placeName' and a 'searchQuery' suitable for APIs.
Return ONLY a JSON object matching the LLMSuggestionsOutputSchema.
Example if image shows a fancy meal:
{
  "suggestions": [
    {"placeName": "Similar High-End Restaurant", "searchQuery": "gourmet restaurants with tasting menus"},
    {"placeName": "Place for Special Occasions", "searchQuery": "romantic restaurants for anniversaries"},
    {"placeName": "Cocktail Bar Nearby", "searchQuery": "upscale cocktail bars"}
  ]
}`,
  tools: [], // No tools for this initial suggestion step
  model: 'gemini-pro' // Or appropriate vision model like gemini-pro-vision, if needed for image input
});


// Main exported function
export async function analyzeInputAndSuggestLocations(
  input: AnalyzeInputAndSuggestLocationsInput
): Promise<AnalyzeInputAndSuggestLocationsOutput> {
  AnalyzeInputAndSuggestLocationsInputSchema.parse(input); // Validate input
  console.log('[Flow Entry] Starting analyzeInputAndSuggestLocations with input:', JSON.stringify(input, null, 2).substring(0, 500));
  // Directly call and return the result of the Genkit flow
  // The Genkit flow itself handles the core logic.
  return analyzeInputAndSuggestLocationsFlow.run(input, { 
    // You can pass additional context or options here if needed for the flow runner
    // For example, if you have specific tracing or auth context to inject.
  }); 
}

// The Genkit flow will be added in the next step.
