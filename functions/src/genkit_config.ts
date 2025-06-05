// functions/src/genkit_config.ts
import { genkit } from '@genkit-ai/core';
import { googleAI } from '@genkit-ai/google-ai';
import { firebase } from '@genkit-ai/firebase'; // Recommended for Firebase environment for logging/tracing

// The googleAI plugin, when initialized with no specific apiKey, 
// will look for GEMINI_API_KEY or GOOGLE_API_KEY in process.env.
// Ensure this is set in your Firebase Functions environment configuration.

export const ai = genkit({
  plugins: [
    googleAI(), // Initializes Google AI with API key from environment variables
    firebase(), // Integrates Firebase for better logging, tracing, flow state in Firebase environment
  ],
  // Set a default model for this Genkit instance.
  // Prompts/flows can override this if they specify a different model.
  // Your original code had 'googleai/gemini-2.0-flash'. 
  // Standard Genkit model names are usually simpler, e.g., 'gemini-1.5-flash-latest' or 'gemini-pro'.
  // We will use 'gemini-1.5-flash-latest' here. Adjust if you have a specific reason for the other format.
  defaultModel: 'gemini-1.5-flash-latest',
  
  // Optional: Explicitly configure stores to use Firebase in this environment if not defaulted by the firebase plugin.
  flowStateStore: 'firebase', 
  traceStore: 'firebase',
  
  // Configure logging level for Genkit.
  logLevel: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  // Metrics and tracing are useful, especially during development.
  enableTracingAndMetrics: true,
});

// Corrected console log to refer to the 'ai' instance itself or a general message.
console.log('[Genkit Config] Genkit 'ai' instance has been configured.');
