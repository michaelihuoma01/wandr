// functions/src/config/genkit.ts
import { genkit, configureGenkit } from '@genkit-ai/core';
import { googleAI } from '@genkit-ai/google-ai';

// This will initialize Genkit with the Google AI plugin.
// The Google AI plugin will look for GEMINI_API_KEY in the environment variables.
configureGenkit({
  plugins: [
    googleAI(), // Ensure GEMINI_API_KEY is set in Firebase Func env vars
  ],
  // You can set other Genkit configurations here if needed:
  // logLevel: 'debug',
  // enableTracingAndMetrics: true,
});

// Export the default genkit instance as 'ai' to match your existing code's import.
// 'genkit()' call was in your original code, which is for defining a flow with specific model.
// For a global ai instance to use with defineTool, definePrompt, it's better to export the configured genkit module directly
// or a customized instance. Your original code: export const ai = genkit({...})
// This implies genkit() function can also be used for configuration.
// Let's stick to your original way of creating the 'ai' instance.

export const ai = genkit({
  plugins: [googleAI()],
  // model: 'googleai/gemini-2.0-flash', // This sets a default model for flows if not specified elsewhere
                                    // Your prompts will likely specify their own models or use a default
                                    // from the googleAI plugin if this line is omitted.
                                    // For clarity, prompts should ideally specify models or use what googleAI defaults to.
});
