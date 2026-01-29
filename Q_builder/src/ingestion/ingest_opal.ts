import fs from "fs";
import path from "path";
import { BalanceQuestionComposer } from "../composer/BalanceQuestionComposer";
import { TruthQuestionComposer } from "../composer/TruthQuestionComposer";
import { BalanceQuestion } from "../schemas/balance-question.schema";
import { TruthQuestion } from "../schemas/truth-question.schema";

// ---------------------------------------------------------
// 1. Type Definitions for Opal Input
// ---------------------------------------------------------
// Opal seems to output data where the enrichment materials are nested.
// We should be flexible to handle slightly varying structures if Opal changes.
interface OpalItem {
    topic: string;
    category?: string; // Optional in input, derived from code if missing
    order_code_prefix: string;
    gender_policy: "neutral" | "directional" | "mixed";
    questions: {
        context_variant: string;
        base_content: string;
        enrichment_materials: {
            enrichment_psychological_tensions: string;
            enrichment_conversation_friendly_terms: string;
            enrichment_community_contexts?: string;
            enrichment_trending_keywords?: string;
        }
    }[];
}

interface FinalOutputItem {
    meta: {
        raw_topic: string;
        derived_category: "Friend" | "Family" | "Lover";
        order_code: string;
        origin_file: string;
    };
    balance_game: BalanceQuestion;
    truth_game: TruthQuestion;
}

// ---------------------------------------------------------
// 2. Logic: The Intelligent Importer
// ---------------------------------------------------------

async function ingestOpalData() {
    const rawDir = path.join(process.cwd(), "src", "data", "raw_opal");
    const outputDir = path.join(process.cwd(), "src", "data", "processed");

    // Ensure output dir
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    console.log(`\n📦 [Opal Ingest] Scanning directory: ${rawDir}`);

    if (!fs.existsSync(rawDir)) {
        console.error(`❌ Error: Directory not found: ${rawDir}`);
        console.log(`Please create it and put your JSON files there.`);
        return;
    }

    const files = fs.readdirSync(rawDir).filter(f => f.endsWith(".json"));

    if (files.length === 0) {
        console.log(`⚠️  No JSON files found in ${rawDir}`);
        return;
    }

    console.log(`Found ${files.length} files: ${files.join(", ")}\n`);

    const balanceComposer = new BalanceQuestionComposer();
    const truthComposer = new TruthQuestionComposer();
    const allProcessedItems: FinalOutputItem[] = [];

    // Process each file
    for (const file of files) {
        console.log(`Processing ${file}...`);
        const filePath = path.join(rawDir, file);

        try {
            const rawContent = fs.readFileSync(filePath, "utf-8");
            let data: OpalItem[] | OpalItem;

            try {
                data = JSON.parse(rawContent);
            } catch (e) {
                console.error(`❌ Failed to parse JSON in ${file}. Skipping.`);
                continue;
            }

            // Normalize to array
            const items = Array.isArray(data) ? data : [data];

            for (const item of items) {
                // 🕵️‍♂️ DNA Analysis (Code Prefix Inspection)
                const code = item.order_code_prefix;
                let category: "Friend" | "Family" | "Lover";

                if (code.startsWith("Fa-")) category = "Family";
                else if (code.startsWith("Lo-")) category = "Lover";
                else if (code.startsWith("B-")) category = "Friend";
                else {
                    console.warn(`⚠️  Unknown code prefix "${code}" in ${file}. defaulting to Friend.`);
                    category = "Friend";
                }

                // Prepare Input for Composers
                // Note: The composer expects a specific structure. 
                // We map the Opal item to that structure.
                const enrichmentInput = {
                    topic: item.topic,
                    category: category,
                    order_code_prefix: item.order_code_prefix,
                    gender_policy: item.gender_policy,
                    questions: item.questions // Assumes Opal output matches this inner structure exactly
                };

                // Run Composers
                try {
                    const balanceResult = balanceComposer.compose(enrichmentInput);
                    const truthResult = truthComposer.compose(enrichmentInput);

                    // Combine results (One Input Item -> Multiple Questions potentially, but usually mapped 1:1 or 1:N)
                    // Here we assume 1 Opal Item (Task) produces N questions.

                    for (let i = 0; i < balanceResult.length; i++) {
                        allProcessedItems.push({
                            meta: {
                                raw_topic: item.topic,
                                derived_category: category,
                                order_code: item.order_code_prefix,
                                origin_file: file
                            },
                            balance_game: balanceResult[i],
                            truth_game: truthResult[i] // Assumes strict index alignment
                        });
                    }

                } catch (composeError) {
                    console.error(`❌ Composer failed for item ${item.order_code_prefix}:`, composeError);
                }
            }

        } catch (e) {
            console.error(`❌ Error reading file ${file}:`, e);
        }
    }

    // ---------------------------------------------------------
    // 3. Save Results
    // ---------------------------------------------------------

    if (allProcessedItems.length > 0) {
        // Save as one big consolidated file
        const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
        const outName = `ingested_batch_${timestamp}.json`;
        const outPath = path.join(outputDir, outName);

        fs.writeFileSync(outPath, JSON.stringify(allProcessedItems, null, 2));
        console.log(`\n🎉 Success! Processed ${allProcessedItems.length} items.`);
        console.log(`💾 Saved to: ${outPath}`);

        // Option: Split by Category for easier inspection?
        // For now, keep consolidated.
    } else {
        console.log("\nNo items were successfully processed.");
    }
}

ingestOpalData();
