// functions/src/photo_proxy.ts
import * as functions from "firebase-functions";
import { defineString } from "firebase-functions/params";
import cors from "cors"
import { onRequest } from "firebase-functions/https";

// Get Google Places API key
const googlePlacesApiKey = defineString("GOOGLE_PLACES_API_KEY");

// Initialize CORS
const corsHandler = cors({ origin: true });

interface PhotoProxyQuery {
  photoReference?: string;
  maxWidth?: string;
  maxHeight?: string;
}

/**
 * Proxy function for Google Places photos to handle CORS
 */
export const proxyPlacePhoto = onRequest(
  {
    timeoutSeconds: 60,
    memory: "1GiB",
    cors: true,
  },
  async(req, res) => {
    return corsHandler(req, res, async () => {
      if (req.method !== "GET") {
        res.status(405).json({ error: "Method not allowed. Use GET." });
        return;
      }

      const { photoReference, maxWidth, maxHeight } = req.query as PhotoProxyQuery;
      const apiKey = googlePlacesApiKey.value();

      if (!photoReference) {
        res.status(400).json({ error: "Missing photoReference parameter" });
        return;
      }

      if (!apiKey) {
        res.status(500).json({ error: "Server configuration error" });
        return;
      }

      const width = maxWidth ? parseInt(maxWidth, 10) : 800;
      const height = maxHeight ? parseInt(maxHeight, 10) : 600;

      try {
        const photoUrl = 
          `https://maps.googleapis.com/maps/api/place/photo?` +
          `maxwidth=${width}&maxheight=${height}&` +
          `photoreference=${encodeURIComponent(photoReference)}&key=${apiKey}`;

        const response = await fetch(photoUrl, {
          method: "GET",
          redirect: "follow",
        });

        if (!response.ok) {
          res.status(response.status).json({ 
            error: "Failed to fetch photo",
            status: response.status 
          });
          return;
        }

        const contentType = response.headers.get("content-type") || "image/jpeg";
        const buffer = await response.arrayBuffer();

        res.set({
          "Content-Type": contentType,
          "Cache-Control": "public, max-age=86400",
        });

        res.send(Buffer.from(buffer));
      } catch (error: any) {
        console.error("Photo proxy error:", error);
        res.status(500).json({ 
          error: "Failed to proxy photo",
          details: error.message 
        });
      }
    });
  });

/**
 * Get resolved photo URL (returns the direct Google URL)
 */
export const getResolvedPhotoUrl = functions.https.onRequest((req, res) => {
  return corsHandler(req, res, async () => {
    if (req.method !== "GET") {
      res.status(405).json({ error: "Method not allowed. Use GET." });
      return;
    }

    const { photoReference, maxWidth } = req.query as PhotoProxyQuery;
    const apiKey = googlePlacesApiKey.value();

    if (!photoReference || !apiKey) {
      res.status(400).json({ error: "Missing required parameters" });
      return;
    }

    const width = maxWidth ? parseInt(maxWidth, 10) : 800;
    const photoUrl = 
      `https://maps.googleapis.com/maps/api/place/photo?` +
      `maxwidth=${width}&photoreference=${encodeURIComponent(photoReference)}&key=${apiKey}`;

    try {
      const response = await fetch(photoUrl, {
        method: "HEAD",
        redirect: "follow",
      });

      res.json({
        status: "success",
        originalUrl: photoUrl.replace(apiKey, "***"),
        resolvedUrl: response.url,
        isDirectGoogleUrl: response.url.includes("googleusercontent.com"),
      });
    } catch (error: any) {
      res.status(500).json({ 
        error: "Failed to resolve URL",
        details: error.message 
      });
    }
  });
});