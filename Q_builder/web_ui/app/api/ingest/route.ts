import { NextRequest, NextResponse } from "next/server";
import fs from "node:fs";
import path from "node:path";
import { BalanceQuestionComposer } from "@/lib/composer/BalanceQuestionComposer";
import { TruthQuestionComposer } from "@/lib/composer/TruthQuestionComposer";
import { toDailyBackupRow } from "@/lib/csvHelper";

// 1. Init Composers
const balanceComposer = new BalanceQuestionComposer();
const truthComposer = new TruthQuestionComposer();

// Paths
const PROCESSED_DIR = path.resolve(process.cwd(), "../src/data/processed");
const DOC_DIR = path.resolve(process.cwd(), "../src/doc");

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const opalData = Array.isArray(body) ? body : [body];

        const allItems: any[] = [];
        const dailyBackupRows: string[] = [];

        // 2. Process Items
        for (const item of opalData) {
            // DNA Analysis (Category Detection)
            const code = item.order_code_prefix || "";
            let category = "Friend";
            if (code.startsWith("Fa") || code.startsWith("Fa-")) category = "Family";
            else if (code.startsWith("Lo") || code.startsWith("Lo-")) category = "Lover";
            else if (code.startsWith("B") || code.startsWith("B-")) category = "Friend";

            // Prepare Input
            const enrichmentInput = {
                topic: item.topic,
                category: category as any,
                order_code_prefix: item.order_code_prefix,
                gender_policy: item.gender_policy,
                questions: item.questions
            };

            // Run Composers
            const balanceResults = balanceComposer.compose(enrichmentInput);
            const truthResults = truthComposer.compose(enrichmentInput);

            // Collect Balance Results (Already contains metadata)
            balanceResults.forEach(q => {
                const fullItem = {
                    ...q,
                    type: 'balance', // Explicit type
                    base_content: item.questions.find((oq: any) => oq.context_variant === q.context_variant)?.base_content || "",
                    gender_policy: item.gender_policy,
                    enrichment_materials: item.questions.find((oq: any) => oq.context_variant === q.context_variant)?.enrichment_materials,
                    source_order_code: item.order_code_prefix // Ensure source code is present
                };
                allItems.push(fullItem);
                dailyBackupRows.push(toDailyBackupRow({ ...fullItem, type: 'balance' }));
            });

            // Collect Truth Results (Missing metadata, need to map by index)
            truthResults.forEach((q, idx) => {
                // Determine original question by index (assuming synchronous order)
                // Use enrichmentInput.questions[idx] 
                const originalQ = enrichmentInput.questions[idx];

                const fullItem = {
                    ...q,
                    type: 'truth', // Explicit type
                    topic: item.topic,
                    category: category,
                    context_variant: originalQ ? originalQ.context_variant : "Unknown",
                    source_order_code: item.order_code_prefix,
                    base_content: originalQ ? originalQ.base_content : "",
                    gender_policy: item.gender_policy,
                    enrichment_materials: originalQ ? originalQ.enrichment_materials : {},
                    // Map camelCase from Composer to snake_case for UI/CSV
                    expected_answers: q.expectedAnswers
                };

                allItems.push(fullItem);
                dailyBackupRows.push(toDailyBackupRow({ ...fullItem, type: 'truth' }));
            });
        }

        // 3. Save Ingested JSON (Timestamped)
        const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
        if (!fs.existsSync(PROCESSED_DIR)) fs.mkdirSync(PROCESSED_DIR, { recursive: true });

        const jsonPath = path.join(PROCESSED_DIR, `ingested_batch_${timestamp}.json`);
        fs.writeFileSync(jsonPath, JSON.stringify(allItems, null, 2), "utf-8");

        // 4. Save Daily Backup CSV (Append)
        const dateStr = new Date().toISOString().split("T")[0];
        const csvPath = path.join(DOC_DIR, `new_data_${dateStr}.csv`);

        let csvContent = "";
        if (!fs.existsSync(csvPath)) {
            csvContent = "Type,SourceCode,Topic,Context,Question,Choices/Answers\n";
        }
        csvContent += dailyBackupRows.join("\n") + "\n";

        if (!fs.existsSync(DOC_DIR)) fs.mkdirSync(DOC_DIR, { recursive: true });
        fs.appendFileSync(csvPath, csvContent, "utf-8");

        return NextResponse.json({ success: true, count: allItems.length, items: allItems });

    } catch (e: any) {
        console.error(e);
        return NextResponse.json({ success: false, error: e.message }, { status: 500 });
    }
}
