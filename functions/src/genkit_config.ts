// functions/src/genkit_config.ts
import { genkit, configureGenkit } from '@genkit-ai/core';
import { googleAI } from '@genkit-ai/googleai';
import { firebase } from '@genkit-ai/firebase'; // Recommended for Firebase environment

// The googleAI plugin typically checks for GOOGLE_API_KEY or GEMINI_API_KEY in process.env.
// Ensure this key is set in your Firebase Functions environment variables.
const apiKey = process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY;

const genkitPlugins = [
  firebase(), // For logging, flow state management, and auth context if needed
];

if (apiKey) {
  genkitPlugins.push(googleAI({ apiKey: apiKey })); 
  console.log("[Genkit Config] Google AI plugin configured WITH an explicit API key.");
} else {
  genkitPlugins.push(googleAI());
  console.warn("[Genkit Config] GEMINI_API_KEY or GOOGLE_API_KEY not found in environment. Initializing Google AI plugin without explicit API key.");
}

configureGenkit({
  plugins: genkitPlugins,
  flowStateStore: 'firebase', 
  traceStore: 'firebase',     
  defaultModel: 'gemini-1.5-flash-latest', // Corrected default model name for Genkit Google AI plugin
  logLevel: process.env.NODE_ENV === 'production' ? 'warn' : 'debug',
  enableTracingAndMetrics: true, 
});

export { genkit as ai };
