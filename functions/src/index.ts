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

// Vibe list generation endpoint
export const generateVibeList = onRequest(
  {
    timeoutSeconds: 60,
    memory: "1GiB",
    cors: true,
    invoker: "public",
  },
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({ error: "Method not allowed. Use POST." });
      return;
    }

    try {
      const { preferences, latitude, longitude, userId } = request.body;

      // Validate input
      if (!preferences || !latitude || !longitude || !userId) {
        response.status(400).json({
          error: "Missing required fields: preferences, latitude, longitude, userId"
        });
        return;
      }

      console.log("[GenerateVibeList] Processing vibe list request:", {
        userId,
        latitude,
        longitude,
        preferences: {
          preferredVibes: preferences.preferredVibes,
          spotType: preferences.spotType,
          specialOccasion: preferences.specialOccasion,
          groupType: preferences.groupType
        }
      });

      // Build search query based on preferences
      let searchQuery = "";
      const placeTypes = preferences.preferredPlaceTypes || [];
      const vibes = preferences.preferredVibes || [];
      
      // Create search query based on preferences
      if (preferences.specialOccasion && preferences.specialOccasion !== 'none') {
        switch (preferences.specialOccasion) {
          case 'birthday':
            searchQuery = "birthday celebration venues restaurants bars fun places";
            break;
          case 'date_night':
            searchQuery = "romantic restaurants intimate lounges date night spots";
            break;
          case 'first_date':
            searchQuery = "casual restaurants cafes comfortable first date places";
            break;
          case 'anniversary':
            searchQuery = "romantic upscale restaurants special occasion venues";
            break;
          case 'team_dinner':
            searchQuery = "group friendly restaurants team dining venues";
            break;
          default:
            searchQuery = placeTypes.join(' ') + ' ' + vibes.join(' ');
        }
      } else {
        searchQuery = placeTypes.join(' ') + ' ' + vibes.join(' ');
      }

      // Add location context
      searchQuery += " popular local recommended";

      console.log("[GenerateVibeList] Search query:", searchQuery);

      // Use the existing analyzeInputAndSuggestLocations function
      const searchInput: AnalyzeInputAndSuggestLocationsInput = {
        inputType: "text",
        textInput: searchQuery,
        latitude,
        longitude,
        searchRadius: preferences.maxDistance || 25
      };

      const searchResults = await analyzeInputAndSuggestLocations(searchInput);
      
      if (!searchResults.locations || searchResults.locations.length === 0) {
        response.status(404).json({
          error: "No suitable places found for your preferences"
        });
        return;
      }

      // Limit results to 2-3 places for better swiping experience
      const isMultiStop = preferences.spotType === 'multiple';
      const limitedPlaces = isMultiStop 
        ? searchResults.locations.slice(0, Math.min(3, preferences.multiSpotCategories?.length || 3))
        : searchResults.locations.slice(0, 2);

      // Create enhanced categories for multi-stop experiences
      let itineraryStops = null;
      let enhancedCategories = null;
      
      if (isMultiStop) {
        const creativeCategories = generateCreativeCategories(preferences);
        
        // Get 3-5 places per category (expand the search results)
        const expandedSearchResults = await getExpandedPlacesForCategories(
          searchInput, creativeCategories, 4 // 4 places per category on average
        );
        
        enhancedCategories = creativeCategories.map((categoryInfo, index) => ({
          categoryTitle: categoryInfo.title,
          categoryDescription: categoryInfo.description,
          timeSlot: categoryInfo.timeSlot,
          places: expandedSearchResults[index] || [],
          order: index + 1
        }));
        
        // Keep backward compatibility
        itineraryStops = null;
      }

      // Generate enhanced title and description
      const title = generateTitle(preferences);
      const description = generateDescription(preferences, limitedPlaces.length);

      // Calculate duration based on limited places
      const estimatedDuration = isMultiStop 
        ? (limitedPlaces.length * 90) + ((limitedPlaces.length - 1) * 30)
        : limitedPlaces.length * 60;

      // Create vibe list response
      const vibeList = {
        id: `vibe_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
        title,
        description,
        places: limitedPlaces,
        tags: [...(preferences.preferredVibes || []), ...(preferences.preferredPlaceTypes || [])],
        vibeType: preferences.preferredVibes?.[0] || 'social',
        estimatedDuration,
        createdAt: new Date().toISOString(),
        createdBy: userId,
        isShared: false,
        isMultiStop,
        itineraryStops,
        enhancedCategories,
        groupType: preferences.groupType,
        specialOccasion: preferences.specialOccasion
      };

      console.log(`[GenerateVibeList] Successfully generated vibe list with ${searchResults.locations.length} places`);
      response.status(200).json(vibeList);

    } catch (error: any) {
      console.error("[GenerateVibeList] Error:", error);
      response.status(500).json({
        error: "Failed to generate vibe list",
        details: error.message || "An unknown error occurred"
      });
    }
  }
);

function generateTitle(preferences: any): string {
  const groupType = preferences.groupType;
  const specialOccasion = preferences.specialOccasion;
  const isMultiStop = preferences.spotType === 'multiple';
  
  // Special occasion titles
  if (specialOccasion && specialOccasion !== 'none') {
    switch (specialOccasion) {
      case 'birthday':
        return isMultiStop ? 'Birthday Celebration Itinerary' : 'Perfect Birthday Spot';
      case 'date_night':
        return isMultiStop ? 'Romantic Date Night Journey' : 'Perfect Date Spot';
      case 'first_date':
        return isMultiStop ? 'First Date Adventure' : 'Great First Date Spot';
      case 'anniversary':
        return isMultiStop ? 'Anniversary Celebration' : 'Special Anniversary Spot';
      case 'team_dinner':
        return isMultiStop ? 'Team Event Itinerary' : 'Perfect Team Gathering';
      case 'celebration':
        return isMultiStop ? 'Celebration Itinerary' : 'Celebration Venue';
    }
  }
  
  // Group-based titles
  let groupPrefix = '';
  switch (groupType) {
    case 'solo':
      groupPrefix = 'Solo';
      break;
    case 'couple':
      groupPrefix = 'Couple\'s';
      break;
    case 'small_group':
      groupPrefix = 'Friends';
      break;
    case 'large_group':
      groupPrefix = 'Group';
      break;
  }
  
  return isMultiStop ? `${groupPrefix} Adventure` : `${groupPrefix} Perfect Spot`;
}

function generateDescription(preferences: any, placeCount: number): string {
  const isMultiStop = preferences.spotType === 'multiple';
  const specialOccasion = preferences.specialOccasion;
  
  if (specialOccasion && specialOccasion !== 'none') {
    switch (specialOccasion) {
      case 'birthday':
        return isMultiStop 
          ? `A perfect birthday celebration with ${placeCount} memorable stops to make the day special.`
          : 'The perfect spot to celebrate your special day in style.';
      case 'date_night':
        return isMultiStop 
          ? `A romantic evening journey with ${placeCount} intimate spots for the perfect date night.`
          : 'An intimate and romantic spot perfect for date night.';
      case 'first_date':
        return isMultiStop 
          ? `A carefully planned first date with ${placeCount} spots to create great first impressions.`
          : 'A welcoming spot perfect for getting to know each other.';
    }
  }
  
  return isMultiStop 
    ? `A curated journey with ${placeCount} amazing places for your perfect experience.`
    : 'An amazing destination carefully selected for you.';
}

function generateCreativeCategories(preferences: any): Array<{title: string, description: string, timeSlot: string, searchTerms: string}> {
  const specialOccasion = preferences.specialOccasion;
  const groupType = preferences.groupType;
  
  // Define creative categories based on vibe and occasion
  if (specialOccasion === 'date_night' || specialOccasion === 'anniversary') {
    return [
      {
        title: "With a View",
        description: "Sunset rooftop bars and scenic spots to set the mood",
        timeSlot: "sunset",
        searchTerms: "rooftop bars sunset views romantic scenic restaurants"
      },
      {
        title: "Fine Dining",
        description: "Exquisite restaurants for an unforgettable dinner",
        timeSlot: "dinner",
        searchTerms: "fine dining romantic restaurants upscale cuisine intimate dining"
      },
      {
        title: "Party All Night",
        description: "Vibrant nightlife spots to dance the night away",
        timeSlot: "night",
        searchTerms: "nightclub dance music lounge late night entertainment"
      }
    ];
  }
  
  if (specialOccasion === 'birthday') {
    return [
      {
        title: "Sweet Beginnings",
        description: "Delightful brunch spots to start the celebration",
        timeSlot: "brunch",
        searchTerms: "brunch birthday celebration breakfast cake bakery"
      },
      {
        title: "Adventure Time", 
        description: "Fun activities to make memories",
        timeSlot: "activity",
        searchTerms: "birthday activities fun entertainment adventure experiences"
      },
      {
        title: "Toast & Celebrate",
        description: "Perfect spots for birthday drinks and toasts",
        timeSlot: "evening",
        searchTerms: "birthday bars celebration drinks cocktails party venues"
      }
    ];
  }
  
  if (groupType === 'small_group' || groupType === 'large_group') {
    return [
      {
        title: "Fuel Up",
        description: "Great spots to grab food and catch up",
        timeSlot: "meal",
        searchTerms: "group dining casual restaurants family friendly food sharing"
      },
      {
        title: "Let's Play",
        description: "Interactive activities perfect for groups",
        timeSlot: "activity", 
        searchTerms: "group activities games entertainment bowling arcade karaoke"
      },
      {
        title: "Cheers Together", 
        description: "Social spaces for drinks and conversation",
        timeSlot: "drinks",
        searchTerms: "group bars social drinks pubs breweries cocktail lounges"
      }
    ];
  }
  
  if (groupType === 'solo') {
    return [
      {
        title: "Me Time",
        description: "Peaceful spots perfect for solo exploration",
        timeSlot: "solo",
        searchTerms: "quiet cafes solo dining peaceful spots meditation libraries"
      },
      {
        title: "Discovery Mode",
        description: "Interesting places to explore and learn",
        timeSlot: "explore",
        searchTerms: "museums galleries bookstores markets art spaces cultural sites"
      },
      {
        title: "Unwind & Relax",
        description: "Relaxing environments to recharge", 
        timeSlot: "relax",
        searchTerms: "spa wellness cafes parks nature spots quiet bars"
      }
    ];
  }
  
  // Default adventure categories
  return [
    {
      title: "Start Strong",
      description: "Great places to begin your adventure",
      timeSlot: "start",
      searchTerms: "cafes breakfast starting points meetup spots"
    },
    {
      title: "Main Event",
      description: "The highlight destination of your journey", 
      timeSlot: "main",
      searchTerms: "attractions main activities popular destinations highlights"
    },
    {
      title: "Grand Finale",
      description: "Perfect spots to end on a high note",
      timeSlot: "finale", 
      searchTerms: "dinner bars nightlife dessert end spots finale venues"
    }
  ];
}

async function getExpandedPlacesForCategories(
  baseSearchInput: AnalyzeInputAndSuggestLocationsInput,
  categories: Array<{title: string, description: string, timeSlot: string, searchTerms: string}>,
  placesPerCategory: number
): Promise<Array<any[]>> {
  const results: Array<any[]> = [];
  
  for (const category of categories) {
    try {
      // Create specific search for this category
      const categorySearchInput: AnalyzeInputAndSuggestLocationsInput = {
        ...baseSearchInput,
        textInput: category.searchTerms + " popular local recommended"
      };
      
      const searchResults = await analyzeInputAndSuggestLocations(categorySearchInput);
      
      // Take 3-5 places for this category
      const categoryPlaces = searchResults.locations.slice(0, Math.min(placesPerCategory, 5));
      results.push(categoryPlaces);
      
      console.log(`[ExpandedPlaces] Found ${categoryPlaces.length} places for category: ${category.title}`);
      
    } catch (error) {
      console.error(`[ExpandedPlaces] Error searching for category ${category.title}:`, error);
      results.push([]); // Empty array if search fails
    }
  }
  
  return results;
}


// Re-export the photo proxy functions from photo_proxy.ts
export { proxyPlacePhoto, getResolvedPhotoUrl } from "./photo_proxy";