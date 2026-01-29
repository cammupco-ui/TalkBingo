import fs from "fs";
import path from "path";
import { EnrichmentSchema } from "../schemas/enrichment.schema";
import { TruthQuestion } from "../schemas/truth-question.schema"; // Import only type if valid, otherwise we won't runtime validate output structure with Zod here unless we create a Zod schema for TruthQuestion. The user didn't ask for output schema validation, just functionality validation.
import { TruthQuestionComposer } from "../composer/TruthQuestionComposer";

const DATA_FILE_PATH = path.join(process.cwd(), 'src', 'data', 'sample_enrichment.json');

async function validateTruthComposer() {
    console.log(`🔍 Reading input from: ${DATA_FILE_PATH}`);

    try {
        const raw = fs.readFileSync(DATA_FILE_PATH, "utf-8");
        const json = JSON.parse(raw);

        // 1. Validate Input
        const enrichmentData = EnrichmentSchema.parse(json);
        console.log("✅ Input Enrichment Data is valid.");

        // 2. Run Composer
        const composer = new TruthQuestionComposer();
        const truthQuestions = composer.compose(enrichmentData);
        console.log(`ℹ️  Composer generated ${truthQuestions.length} questions.`);

        // 3. Output results
        console.log("---------------------------------------------------");
        truthQuestions.forEach((q, idx) => {
            console.log(`[${idx + 1}] ${q.id} (Level ${q.intimacyLevel})`);
            console.log(`    Q: ${q.question} (${q.question.length} chars)`);
            console.log(`    Answers: [${q.expectedAnswers.join(", ")}]`);
        });
        console.log("---------------------------------------------------");

    } catch (err: any) {
        console.error("❌ Unexpected Error:");
        console.error(err instanceof Error ? err.message : err);
        if (err.errors) console.error(err.errors);
        process.exit(1);
    }
}

validateTruthComposer();
