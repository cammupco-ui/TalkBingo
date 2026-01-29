import { OpalPipelineReplica } from "../generator/OpalPipelineReplica";
import { EnrichmentSchema } from "../schemas/enrichment.schema";

async function main() {
    const pipeline = new OpalPipelineReplica();

    console.log("🚀 Starting Pipeline...");

    // 실행: 주제 "게임", 코드 "GmGlL1"
    const result = await pipeline.execute("게임", "GmGlL1");

    console.log("✨ Pipeline Completed! Result:");
    console.log(JSON.stringify(result, null, 2));

    // 검증
    try {
        EnrichmentSchema.parse(result);
        console.log("✅ Final JSON is valid according to schema.");
    } catch (e) {
        console.error("❌ Schema Validation Failed:", e);
    }
}

main();
