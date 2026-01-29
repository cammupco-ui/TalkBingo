// src/utils/validate_enrichment.ts
import fs from "fs";
import path from "path";
import { EnrichmentSchema } from "../schemas/enrichment.schema.ts";

const filePath = path.join(
    process.cwd(),
    'src',
    'data',
    'sample_enrichment.json'
);

try {
    const raw = fs.readFileSync(filePath, "utf-8");
    const json = JSON.parse(raw);

    const result = EnrichmentSchema.parse(json);

    console.log("✅ Enrichment JSON is valid");
    console.log(
        `- topic: ${result.topic}`
    );
    console.log(
        `- questions count: ${result.questions.length}`
    );
} catch (err: any) {
    console.error("❌ Enrichment JSON validation failed");
    console.error(err.errors ?? err.message);
}
