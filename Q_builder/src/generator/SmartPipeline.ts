import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from "dotenv";
import fs from "fs";
import path from "path";
import { BalanceQuestionComposer } from "../composer/BalanceQuestionComposer";
import { TruthQuestionComposer } from "../composer/TruthQuestionComposer";

dotenv.config();

// Types
interface BlueprintItem {
    category: "Friend" | "Family" | "Lover";
    code_prefix: string;
    context_variant: string;
    gender_policy: "neutral" | "directional";
}

interface EnrichedItemRaw {
    context_variant: string;
    base_content: string;
    enrichment_materials: {
        enrichment_psychological_tensions: string;
        enrichment_conversation_friendly_terms: string;
    };
}

export class SmartPipeline {
    private genAI: GoogleGenerativeAI;
    private modelName = "gemini-2.0-flash"; // Speed & Quality balance

    constructor() {
        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey) throw new Error("GEMINI_API_KEY is missing");
        this.genAI = new GoogleGenerativeAI(apiKey);
    }

    private loadPrompt(filename: string): string {
        return fs.readFileSync(path.join(process.cwd(), "src", "doc", filename), "utf-8");
    }

    // Stage 1: The Planner
    async plan(topic: string): Promise<BlueprintItem[]> {
        const promptTemplate = this.loadPrompt("Smart_Planner.md");
        const fullPrompt = `
            ${promptTemplate}
            
            [Target Topic]: "${topic}"
        `;

        console.log("🏭 Stage 1: Planning...");
        const result = await this.callGemini(fullPrompt, true);
        return result as BlueprintItem[];
    }

    // Stage 2: The Creator
    async create(topic: string, blueprints: BlueprintItem[]) {
        const promptTemplate = this.loadPrompt("Smart_Creator.md");
        const fullPrompt = `
            ${promptTemplate}

            [Topic]: "${topic}"
            [Blueprint List]:
            ${JSON.stringify(blueprints, null, 2)}
        `;

        console.log("🏭 Stage 2: Creating & Enriching...");
        const result = await this.callGemini(fullPrompt, true);
        return result as { questions: EnrichedItemRaw[] };
    }

    // Stage 3: The Assembly (Composer)
    assemble(topic: string, blueprints: BlueprintItem[], rawData: { questions: EnrichedItemRaw[] }) {
        console.log("🏭 Stage 3: Assembling (Composer Engine)...");

        const balanceComposer = new BalanceQuestionComposer();
        const truthComposer = new TruthQuestionComposer();

        const finalOutput: any[] = [];

        // Map raw items back to blueprints to get metadata
        rawData.questions.forEach((q, idx) => {
            // Assume strict order mapping or try to match context_variant
            // Ideally, we pass IDs, but for now we map by index or look up blueprint
            const blueprint = blueprints.find(b => b.context_variant === q.context_variant) || blueprints[idx];

            if (!blueprint) return;

            // Prepare Composer Input
            const enrichmentInput = {
                topic: topic,
                category: blueprint.category,
                order_code_prefix: blueprint.code_prefix,
                gender_policy: blueprint.gender_policy,
                questions: [{
                    context_variant: q.context_variant,
                    base_content: q.base_content,
                    enrichment_materials: q.enrichment_materials
                }]
            };

            // Run Composers
            // 1. Balance Game
            const balanceResult = balanceComposer.compose(enrichmentInput);
            // 2. Truth Game
            const truthResult = truthComposer.compose(enrichmentInput);

            finalOutput.push({
                meta: {
                    category: blueprint.category,
                    code: blueprint.code_prefix,
                    gender: blueprint.gender_policy
                },
                balance_game: balanceResult[0], // Composer returns array
                truth_game: truthResult[0]
            });
        });

        return finalOutput;
    }

    // Helper: Call Gemini
    private async callGemini(prompt: string, jsonMode: boolean = false): Promise<any> {
        const model = this.genAI.getGenerativeModel({
            model: this.modelName,
            generationConfig: {
                responseMimeType: jsonMode ? "application/json" : "text/plain"
            }
        });

        try {
            const result = await model.generateContent(prompt);
            const text = result.response.text();
            return jsonMode ? JSON.parse(text) : text;
        } catch (e) {
            console.error("Gemini API Error:", e);
            throw e;
        }
    }
}
