import { z } from "zod";
import { EnrichmentSchema, EnrichmentInput } from "../schemas/enrichment.schema";

/**
 * 🏭 Mock AI Client (나중에 실제 OpenAI/Gemini로 교체)
 */
async function callAIModel(prompt: string): Promise<string> {
    console.log(`\n🤖 [AI Calling] Prompt: ${prompt.slice(0, 50)}...`);
    // 여기서는 테스트를 위해 더미 데이터를 반환하지만, 
    // 실제로는 fetch('https://api.openai.com/v1/chat/completions', ...) 등을 사용
    await new Promise(r => setTimeout(r, 1000)); // 1초 대기 흉내
    return ""; // 실제 구현부에서 오버라이드 예정
}

export class OpalPipelineReplica {

    // ----------------------------------------------------------------
    // 📍 Node 1: 기본 설정 (Topic & Metadata definition)
    // ----------------------------------------------------------------
    async defineMetadata(topic: string, codePrefix: string): Promise<Partial<EnrichmentInput>> {
        console.log("📍 Node 1: 메타데이터 정의 중...");
        return {
            topic: topic,
            category: "General", // AI에게 맡기거나 고정
            order_code_prefix: codePrefix,
            gender_policy: "neutral",
        };
    }

    // ----------------------------------------------------------------
    // 📍 Node 2: 질문 아이디에이션 (Ideation)
    // ----------------------------------------------------------------
    async generateBaseQuestions(topic: string, count: number = 3): Promise<string[]> {
        console.log(`📍 Node 2: '${topic}'에 대한 질문 ${count}개 아이디에이션 중...`);

        const prompt = `
            주제 '${topic}'에 대해 친한 사람들끼리 할 수 있는 
            흥미로운 대화 질문 ${count}기를 한국어 구어체로 만들어줘.
            JSON Array format string only: ["질문1", "질문2", "질문3"]
        `;

        // Mock Response (실제로는 AI 호출 결과 파싱)
        // const response = await callAIModel(prompt);
        return [
            `${topic} 할 때 가장 킹받는 순간은?`,
            `${topic} 고수라고 생각하는 기준이 뭐야?`,
            `다같이 ${topic} 하러 간다면 어디로 가고 싶어?`
        ];
    }

    // ----------------------------------------------------------------
    // 📍 Node 3: 데이터 풍부화 (Enrichment - Context & Tensions)
    // ----------------------------------------------------------------
    async enrichOneQuestion(baseQuestion: string): Promise<any> {
        console.log(`📍 Node 3: 질문("${baseQuestion}") 풍부화(Enriching) 중...`);

        const prompt = `
            질문: "${baseQuestion}"
            이 질문에 대한 다음 정보를 JSON으로 생성해:
            1. context_variant: 대화 상황 (예: 술자리, 여행)
            2. enrichment_materials: 
               - trending_keywords (유행어)
               - psychological_tensions (심리적 갈등/밸런스 요소)
               - conversation_friendly_terms (대화하기 좋은 단어)
        `;

        // Mock Response
        return {
            context_variant: "가벼운 수다",
            base_content: baseQuestion,
            enrichment_materials: {
                enrichment_community_contexts: "친구들과 카페 | 술자리 안주거리",
                enrichment_trending_keywords: "킹받네 | 찐텐 | 억까",
                enrichment_psychological_tensions: "실력 vs 장비 | 즐겜 vs 빡겜",
                enrichment_conversation_friendly_terms: "솔직히 인정 | 그건 인정이지"
            }
        };
    }

    // ----------------------------------------------------------------
    // 🔗 Pipeline Execution (노드 연결 및 최종 조립)
    // ----------------------------------------------------------------
    async execute(topic: string, codePrefix: string) {
        // Step 1
        const metadata = await this.defineMetadata(topic, codePrefix);

        // Step 2
        const rawQuestions = await this.generateBaseQuestions(topic);

        // Step 3 (Parallel Execution)
        const enrichedQuestions = await Promise.all(
            rawQuestions.map(q => this.enrichOneQuestion(q))
        );

        // Final Assembly
        const finalData = {
            ...metadata,
            questions: enrichedQuestions
        };

        return finalData;
    }
}
