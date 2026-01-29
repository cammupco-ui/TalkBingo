import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from "dotenv";

dotenv.config();

async function listModels() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
        console.error("❌ GEMINI_API_KEY not found in .env");
        return;
    }

    const genAI = new GoogleGenerativeAI(apiKey);

    try {
        console.log("🔍 Fetching available models...");
        // This is not directly exposed in the high-level SDK mostly, 
        // but for some versions we can just try a simple generation to check connectivity first
        // If 404 persists on simple generation, the key/project is the issue.
        // Actually the SDK doesn't have a simple listModels method exposed in the helper typically,
        // but we can try the direct API call if needed. 
        // However, let's try to 'get' the model and ask for info or just try a VERY simple prompt.

        // Alternative: Use a generic 'getGenerativeModel' and print it.
        // But better test: Try a few known model names.

        const candidates = ["gemini-1.5-flash", "gemini-1.5-pro", "gemini-pro", "gemini-1.0-pro"];

        for (const modelName of candidates) {
            console.log(`\nTesting model: ${modelName}`);
            try {
                const model = genAI.getGenerativeModel({ model: modelName });
                const result = await model.generateContent("Hello");
                const response = await result.response;
                console.log(`✅ SUCCESS with ${modelName}:`, response.text());
                return; // Found a working one
            } catch (e: any) {
                console.log(`❌ FAILED with ${modelName}: ${e.message}`);
                // unexpected 404 means model not found or api not enabled.
            }
        }

    } catch (error) {
        console.error("Fatal Error:", error);
    }
}

listModels();
