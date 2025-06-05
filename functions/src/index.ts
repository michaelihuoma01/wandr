// functions/src/index.ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { analyzeInputAndSuggestLocations, AnalyzeInputAndSuggestLocationsInput } from "./search_logic"; // Import your core logic
import { defineString } from "firebase-functions/params";

// Initialize Firebase Admin SDK (if you use other Firebase services like Firestore, Storage, etc., in this function)
// If not, for a simple HTTP function like this, it might not be strictly necessary unless other Firebase services are used.
admin.initializeApp();

// Define API key parameters. These names MUST match what you set in Firebase environment configuration.
const googlePlacesApiKey = defineString("GOOGLE_PLACES_API_KEY");
const foursquareApiKey = defineString("FOURSQUARE_API_KEY");
const geminiApiKey = defineString("GEMINI_API_KEY"); // Define if you plan to use Gemini directly in search_logic

export const searchPlaces = functions.https.onRequest(async (request, response) => {
  // Set CORS headers to allow requests from your app (or any origin with '*')
  response.set('Access-Control-Allow-Origin', '*'); // Be more specific in production if needed
  response.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization'); // Allow Authorization if you plan to use it
  response.set('Access-Control-Max-Age', '3600');

  // Handle preflight OPTIONS request for CORS
  if (request.method === 'OPTIONS') {
    response.status(204).send('');
    return;
  }

  // Only allow POST requests for this function
  if (request.method !== 'POST') {
    response.status(405).send('Method Not Allowed. Please use POST.');
    return;
  }

  try {
    // The request body should contain the input data for your search logic
    const input = request.body as AnalyzeInputAndSuggestLocationsInput;

    // Basic validation (you might want to use a library like Zod here too if not done in search_logic.ts)
    if (!input || typeof input.latitude !== 'number' || typeof input.longitude !== 'number' || !input.inputType) {
         response.status(400).send('Invalid input format. Required fields: inputType, latitude, longitude, and textInput or imageInputUri.');
         return;
    }
    if (input.inputType === 'text' && !input.textInput) {
        response.status(400).send('Invalid input: textInput is required for text inputType.');
        return;
    }
    if (input.inputType === 'image' && !input.imageInputUri) {
        response.status(400).send('Invalid input: imageInputUri is required for image inputType.');
        return;
    }

    // Retrieve API keys from environment variables
    const apiKeysToPass = {
      googleApiKey: googlePlacesApiKey.value(),
      foursquareApiKey: foursquareApiKey.value(),
      geminiApiKey: geminiApiKey.value(), // Pass Gemini key if needed by search_logic
    };

    console.log("[Index] Calling analyzeInputAndSuggestLocations with input:", JSON.stringify(input).substring(0,300));
    // Pass the API keys to your core logic
    const results = await analyzeInputAndSuggestLocations(input, apiKeysToPass);

    console.log("[Index] Sending results:", JSON.stringify(results).substring(0,300));
    response.status(200).json(results);

  } catch (error: any) {
    console.error("[Index] Error processing search request:", error.message, error.stack);
    // It's good to log the error but be careful about sending detailed internal errors to the client.
    response.status(500).send("An internal error occurred while processing your request.");
  }
});
