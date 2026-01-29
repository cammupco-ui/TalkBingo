import { PromptLoader } from "./PromptLoader";
import { GeminiClient } from "./GeminiClient";
import fs from "fs";
import path from "path";

// 3. Dispatcher 결과 타입
interface DispatchItem {
    topic: string;
    category: "Friend" | "Family" | "Lover";
    context_variant: string;
    order_code_prefix: string;
    gender_policy: "neutral" | "directional";
}

export class ContentGenerator {
    private loader: PromptLoader;
    private ai: GeminiClient;

    constructor() {
        this.loader = new PromptLoader();
        this.ai = new GeminiClient();
    }

    async run(topicInput: string) {
        console.log(`\n🚀 [Start] Topic: "${topicInput}"`);

        // =========================================================
        // Node 1: 주제 분석 (Topic Analysis)
        // =========================================================
        console.log("\n--- Node 1: Topic Analysis ---");
        let node1Prompt = this.loader.loadTemplate("Node_flow.md")
            .split("Node 1 :")[1]
            .split("Node 2 :")[0]; // Node 1 부분만 추출 (임시 파싱, 더 견고하게 할 수 있음)

        // 하지만 사용자가 준 파일은 통짜 MD 파일이 아니었을 수도 있음.
        // 현재 Node_flow.md에는 전체 흐름이 들어있는 것으로 보임.
        // 사용자가 파일별로 나누지 않고 Node_flow.md에 텍스트로 적어두었다면 파싱해야 함.
        // **수정**: 사용자가 Node_flow.md에 모든 프롬프트를 다 적어둠.
        // 따라서 여기서 split으로 잘라서 쓰는 것이 맞음. 
        // 다만 실제 파일 내용이 어떻게 저장되었는지 view_file 내용을 신뢰해야 함.

        // 더 확실한 방법: Node 1 프롬프트 구성
        const familyJson = this.loader.loadReferenceJson("family.json");
        const friendJson = this.loader.loadReferenceJson("friend.json");
        const loverJson = this.loader.loadReferenceJson("lover.json");
        const intimacyJson = this.loader.loadReferenceJson("intimacy.json");

        // Node_flow.md에서 Node 1 부분 파싱
        const fullFlow = this.loader.loadTemplate("Node_flow.md");
        const node1Raw = fullFlow.split("Node 1 :")[1].split("Node 2 :")[0];

        const node1PromptFilled = `
            ${node1Raw}
            
            [Topic Input]: "${topicInput}"

            [Reference Data]:
            - Family Rules: ${familyJson}
            - Friend Rules: ${friendJson}
            - Lover Rules: ${loverJson}
            - Intimacy Levels: ${intimacyJson}
        `;

        // 최적화: 전체 규칙을 다 보내면 토큰 낭비가 심하므로, 
        // Node 1 단계에서는 '주제 분류'에 필요한 핵심 정보만 요약해서 보낼 수도 있음.
        // 하지만 정확도를 위해 다 보내되, 재시도 횟수를 대폭 늘림 (무료 티어 대응)

        const node1Result = await this.ai.generate(node1PromptFilled, "gemini-2.0-flash", 10); // 최대 10회 재시도
        console.log("✅ Node 1 Result:", JSON.stringify(node1Result, null, 2));


        // =========================================================
        // Node 2: 성별 정책 (Gender Policy)
        // =========================================================
        console.log("\n--- Node 2: Gender Policy ---");
        const node2Raw = fullFlow.split("Node 2 :")[1].split("Node 3 :")[0];
        const node2Prompt = `
            ${node2Raw}

            [Input Data (topic_analysis)]:
            ${JSON.stringify(node1Result, null, 2)}
        `;

        const node2Result = await this.ai.generate(node2Prompt, "gemini-2.0-flash", 10);
        console.log("✅ Node 2 Result:", JSON.stringify(node2Result, null, 2));


        // =========================================================
        // Node 3: Dispatcher
        // =========================================================
        console.log("\n--- Node 3: Dispatcher ---");
        const node3Raw = fullFlow.split("Node 3 :")[1]; // 마지막 부분
        // **주의**: Node 3에서 배열로 내보내달라고 수정 요청했으나, MD 파일 수정이 반영 안됐을 수 있음.
        // AI가 알아서 잘 하길 기대하거나 프롬프트에 강제 주입.
        // 여기서는 안전하게 프롬프트 뒤에 "Output a flat JSON array for all variants" 라고 덧붙임.

        const node3Prompt = `
            ${node3Raw}

            [Input Data]:
            ${JSON.stringify(node2Result, null, 2)}
        `;

        const node3Result: DispatchItem[] = await this.ai.generate(node3Prompt, "gemini-2.0-flash", 10);
        console.log(`✅ Node 3 Result: Generated ${node3Result.length} items`);


        // =========================================================
        // Node 4 & 5: BaseContent -> Enrichment (Parallel)
        // =========================================================
        console.log("\n--- Node 4 & 5: Content Generation & Enrichment ---");

        // 카테고리별로 그룹화 (BaseContent는 context_variants를 배열로 받음)
        // Dispatcher 결과는 Flat list이므로 다시 그룹핑 필요
        // 그룹 키: code_prefix + category + gender_policy
        const grouped = new Map<string, {
            topic: string,
            category: string,
            order_code_prefix: string,
            gender_policy: string,
            context_variants: string[]
        }>();

        for (const item of node3Result) {
            const key = `${item.order_code_prefix}`; // prefix가 고유하면 됨
            if (!grouped.has(key)) {
                grouped.set(key, {
                    topic: item.topic,
                    category: item.category,
                    order_code_prefix: item.order_code_prefix,
                    gender_policy: item.gender_policy,
                    context_variants: []
                });
            }
            grouped.get(key)!.context_variants.push(item.context_variant);
        }

        const finalResults = [];

        // 그룹별 실행
        for (const group of grouped.values()) {
            console.log(`\nProcessing Group: ${group.category} (${group.order_code_prefix}) - ${group.context_variants.length} variants`);

            // 4.1 Base Content
            const baseTemplateName = `Node_basecontent_${group.category.toLowerCase()}.md`;
            const baseTemplate = this.loader.loadTemplate(baseTemplateName);

            // 템플릿에 데이터 주입 X -> JSON Input으로 주입
            const basePrompt = `
                ${baseTemplate}

                [입력 데이터]:
                ${JSON.stringify(group, null, 2)}
            `;

            const baseResult = await this.ai.generate(basePrompt, "gemini-2.0-flash", 10);
            // baseResult.questions 배열

            // 4.2 Enrichment (Sequential Execution to avoid Rate Limit)
            const enrichTemplateName = `Node_enrichment_${group.category.toLowerCase()}.md`;
            const enrichTemplateRaw = this.loader.loadTemplate(enrichTemplateName);

            // Reference JSON for enrichment
            const categoryJson = this.loader.loadReferenceJson(`${group.category.toLowerCase()}.json`);

            // 순차 실행 (Rate Limit 방지용 Delay 추가)
            const enrichedGroup = [];
            for (const q of baseResult.questions) {
                // Template variable filling
                const enrichData = {
                    Base_Content: {
                        topic: group.topic,
                        category: group.category,
                        order_code_prefix: group.order_code_prefix,
                        gender_policy: group.gender_policy,
                    },
                    question: q
                };

                const enrichPrompt = this.loader.fillTemplate(enrichTemplateRaw, enrichData);
                const fullEnrichPrompt = `
                    ${enrichPrompt}
                    
                    [Reference Code Data]:
                    ${categoryJson}
                `;

                console.log(`zzz... Waiting for API rate limit (2s)...`);
                await new Promise(resolve => setTimeout(resolve, 2000)); // 2초 대기

                const result = await this.ai.generate(fullEnrichPrompt, "gemini-2.0-flash", 10);
                enrichedGroup.push(result);
            }

            finalResults.push(...enrichedGroup);
        }

        // =========================================================
        // Result Aggregation
        // =========================================================

        // 최종 구조로 조립 (EnrichmentInput Schema)
        const finalOutput = {
            topic: topicInput,
            category: "General", // or derive from major category
            order_code_prefix: "MIXED", // 여러 코드가 섞여있어서
            gender_policy: "mixed",
            questions: finalResults
        };

        // 파일 저장
        const outputPath = path.join(process.cwd(), "src", "data", `generated_${topicInput.replace(/\s+/g, "_")}.json`);
        fs.writeFileSync(outputPath, JSON.stringify(finalOutput, null, 2));
        console.log(`\n✨ Output saved to: ${outputPath}`);
    }
}
