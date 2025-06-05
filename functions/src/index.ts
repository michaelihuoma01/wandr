// functions/src/index.ts
import { onRequest } from "firebase-functions/v2/https";
import { defineString } from "firebase-functions/params";
import * as admin from "firebase-admin";
// import cors from "cors"

import { 
  analyzeInputAndSuggestLocations, 
  AnalyzeInputAndSuggestLocationsInput,
  // AnalyzeInputAndSuggestLocationsOutput 
} from "./analyze_input_flow";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Define parameters for API keys
export const googlePlacesApiKey = defineString("GOOGLE_PLACES_API_KEY");
export const foursquareApiKey = defineString("FOURSQUARE_API_KEY");
export const geminiApiKey = defineString("GEMINI_API_KEY");
export const tripAdvisorApiKey = defineString("TRIPADVISOR_API_KEY");
export const zomatoApiKey = defineString("ZOMATO_API_KEY");

// Initialize CORS
// const corsHandler = cors({ origin: true });

// Main search endpoint
export const searchPlaces = onRequest(
  {
    timeoutSeconds: 60,
    memory: "1GiB",
    cors: true,
  },
  async (request, response) => {
    // Only allow POST requests
    if (request.method !== "POST") {
      response.status(405).json({ error: "Method not allowed. Use POST." });
      return;
    }

    try {
      // Parse request body
      const input = request.body as AnalyzeInputAndSuggestLocationsInput;

      // Validate input
      if (!input || typeof input.latitude !== "number" || typeof input.longitude !== "number" || !input.inputType) {
        response.status(400).json({
          error: "Invalid input format",
          details: "Required fields: inputType, latitude, longitude, and textInput or imageInputUri"
        });
        return;
      }

      if (input.inputType === "text" && !input.textInput) {
        response.status(400).json({
          error: "textInput is required for text inputType"
        });
        return;
      }

      if (input.inputType === "image" && !input.imageInputUri) {
        response.status(400).json({
          error: "imageInputUri is required for image inputType"
        });
        return;
      }

      console.log("[Index] Processing search request:", {
        inputType: input.inputType,
        latitude: input.latitude,
        longitude: input.longitude,
        textInput: input.textInput?.substring(0, 50)
      });

      // Call the main flow
      const results = await analyzeInputAndSuggestLocations(input);

      console.log(`[Index] Successfully processed request. Found ${results.locations.length} locations`);
      response.status(200).json(results);

    } catch (error: any) {
      console.error("[Index] Error processing request:", error);
      
      // Send a more informative error response
      response.status(500).json({
        error: "Failed to process search request",
        details: error.message || "An unknown error occurred"
      });
    }
  }
);

// Health check endpoint
export const healthCheck = onRequest(
  { cors: true },
  async (request, response) => {
    const apiKeysStatus = {
      googlePlaces: !!googlePlacesApiKey.value(),
      foursquare: !!foursquareApiKey.value(),
      gemini: !!geminiApiKey.value(),
      tripAdvisor: !!tripAdvisorApiKey.value(),
      zomato: !!zomatoApiKey.value(),
    };

    response.status(200).json({
      status: "healthy",
      timestamp: new Date().toISOString(),
      apiKeys: apiKeysStatus,
      version: "1.0.0"
    });
  }
);

// Re-export the photo proxy functions from photo_proxy.ts
export { proxyPlacePhoto, getResolvedPhotoUrl } from "./photo_proxy";