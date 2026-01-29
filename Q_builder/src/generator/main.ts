import { SmartPipeline } from "./SmartPipeline";
import fs from "fs";
import path from "path";

async function main() {
    const args = process.argv.slice(2);
    const topic = args[0] || "캠핑"; // Default to camping if no arg

    console.log(`\n🤖 Integrated Smart Factory Started for topic: "${topic}"\n`);

    const pipeline = new SmartPipeline();

    try {
        // 1. Plan
        const blueprints = await pipeline.plan(topic);
        console.log(`✅ [Plan] Cleaned Blueprint: ${blueprints.length} items planned.`);
        // console.log(JSON.stringify(blueprints, null, 2));

        // 2. Create
        const rawContent = await pipeline.create(topic, blueprints);
        console.log(`✅ [Create] Raw Content Generated: ${rawContent.questions.length} items created.`);

        // 3. Assemble
        const finalProducts = pipeline.assemble(topic, blueprints, rawContent);
        console.log(`✅ [Assemble] Composer Finished!`);

        // 4. Display & Save
        console.log("\n====== 🎁 FINAL OUTPUT SAMPLE (First 2 Items) ======\n");
        console.log(JSON.stringify(finalProducts.slice(0, 2), null, 2));

        const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
        const filename = `result_${topic}_${timestamp}.json`;
        const savePath = path.join(process.cwd(), "src", "data", filename);

        // Ensure dir
        if (!fs.existsSync(path.dirname(savePath))) {
            fs.mkdirSync(path.dirname(savePath), { recursive: true });
        }

        fs.writeFileSync(savePath, JSON.stringify(finalProducts, null, 2));
        console.log(`\n💾 Saved full result to: ${savePath}`);

    } catch (e) {
        console.error("\n❌ Pipeline Error:", e);
    }
}

main();
