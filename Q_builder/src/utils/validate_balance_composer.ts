import fs from "fs";
import path from "path";
import { EnrichmentSchema } from "../schemas/enrichment.schema";
import { BalanceQuestionSchema } from "../schemas/balance-question.schema";
import { BalanceQuestionComposer } from "../composer/BalanceQuestionComposer";
import { z } from "zod";

const DATA_FILE_PATH = path.join(process.cwd(), 'src', 'data', 'sample_enrichment.json');

async function validateComposerOutput() {
    console.log(`🔍 Reading input from: ${DATA_FILE_PATH}`);

    try {
        const raw = fs.readFileSync(DATA_FILE_PATH, "utf-8");
        const json = JSON.parse(raw);

        // 1. Validate Input
        const enrichmentData = EnrichmentSchema.parse(json);
        console.log("✅ Input Enrichment Data is valid.");

        // 2. Run Composer
        const composer = new BalanceQuestionComposer();
        const balanceQuestions = composer.compose(enrichmentData);
        console.log(`ℹ️  Composer generated ${balanceQuestions.length} questions.`);

        // 3. Validate Output
        const OutputSchema = z.array(BalanceQuestionSchema);
        const result = OutputSchema.safeParse(balanceQuestions);

        if (result.success) {
            console.log("✅ Composer Output Validation Successful!");
            console.log("---------------------------------------------------");
            result.data.forEach((q, idx) => {
                console.log(`[${idx + 1}] ${q.source_order_code} (Level ${q.intimacy_level})`);
                console.log(`    Q: ${q.question}`);
                console.log(`    Options: [${q.options.join(", ")}]`);
            });
            console.log("---------------------------------------------------");
        } else {
            console.error("❌ Composer Output Validation Failed:");
            result.error.errors.forEach((err) => {
                const path = err.path.join('.');
                console.error(`  - [${path}]: ${err.message}`);
            });
            process.exit(1);
        }

    } catch (err: any) {
        console.error("❌ Unexpected Error:");
        console.error(err instanceof Error ? err.message : err);
        if (err.errors) console.error(err.errors);
        process.exit(1);
    }
}

validateComposerOutput();
