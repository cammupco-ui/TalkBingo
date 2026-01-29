import { BalanceQuestion } from "../schemas/balance-question.schema";
import { EnrichmentInput, EnrichmentQuestion } from "../schemas/enrichment.schema";
import { extractIntimacyLevel } from "../utils/composer-helper";

export class BalanceQuestionComposer {
    compose(enrichment: EnrichmentInput): BalanceQuestion[] {
        // 공통 헬퍼 사용하여 친밀도 추출
        const intimacyLevel = extractIntimacyLevel(enrichment.order_code_prefix);

        return enrichment.questions.map((q) => ({
            type: "balance",
            topic: enrichment.topic, // 상위 메타데이터 활용
            category: enrichment.category,
            context_variant: q.context_variant,
            question: this.buildQuestion(q),
            options: this.buildOptions(q, intimacyLevel),
            intimacy_level: intimacyLevel,
            source_order_code: enrichment.order_code_prefix,
        }));
    }

    private buildQuestion(q: EnrichmentQuestion): string {
        return this.compressQuestion(q.base_content);
    }

    private buildOptions(
        q: EnrichmentQuestion,
        intimacyLevel: number
    ): [string, string] {
        const mat = q.enrichment_materials;

        // 1. Tensions 활용 (기존 로직)
        const tensions = mat.enrichment_psychological_tensions
            ?.split("|")
            .map(t => t.trim())
            .filter(Boolean) ?? [];

        // 2. 추가 Material 활용 준비 
        // (필요 시 community_contexts나 conversation_friendly_terms를 옵션 생성의 fallback이나 수식어로 사용 가능)
        // const contexts = mat.enrichment_community_contexts?.split("|") ...
        // const keywords = mat.enrichment_trending_keywords?.split("|") ...

        let rawOptions: [string, string];

        if (tensions.length === 0) {
            rawOptions = ["조용히 보내기", "활동적으로 보내기"];
        } else {
            // 랜덤 픽
            const picked = tensions[Math.floor(Math.random() * tensions.length)];

            // 'vs' 또는 ',' 구분자 처리
            let parts: string[] = [];
            if (picked.includes("vs")) {
                parts = picked.split("vs");
            } else if (picked.includes(",")) {
                parts = picked.split(",");
            }

            if (parts.length >= 2) {
                const [a, b] = parts.map(s => s.trim());
                rawOptions = [
                    this.expandOption(a, q),
                    this.expandOption(b, q),
                ];
            } else {
                rawOptions = [
                    `${picked} 쪽을 선택`,
                    `${picked} 반대 선택`,
                ];
            }
        }

        return [
            this.compressOption(rawOptions[0]),
            this.compressOption(rawOptions[1]),
        ];
    }

    private compressOption(text: string): string {
        // 1. 의미 보존을 위한 치환 규칙 (Specific to General)
        const rules: Record<string, string> = {
            "하루 꽉 채운 액티비티 여행": "꽉찬 액티비티",
            "숙소 중심으로 쉬는 힐링 여행": "숙소 힐링",
            "미리 계획한 일정대로": "계획대로",
            "그날 기분대로 움직이기": "기분따라",
            "쪽을 선택": "", // "쪽을 선택" 제거하여 핵심만 남김
            "반대 선택": "아님", // "반대 선택"을 "아님"으로 축약
        };

        let compressed = text;
        for (const [long, short] of Object.entries(rules)) {
            compressed = compressed.replace(long, short);
        }

        // 2. 불필요한 관형형 어미 및 조사 제거 (Regex)
        compressed = compressed
            .replace(/한다는 /g, " ")
            .replace(/하는 /g, " ")
            .replace(/있는 /g, " ")
            .replace(/같은 /g, " ")
            .replace(/에 대한/g, "")
            .replace(/을 위한/g, "")
            .replace(/ 의 /g, " ")
            .replace(/와 /g, " ")
            .replace(/과 /g, " ");

        // 3. 공백 축소 및 트림
        compressed = compressed.replace(/\s+/g, " ").trim();

        // 4. 최후 안전장치: 길이 제한 완화 (14자 -> 25자)
        if (compressed.length > 25) {
            // 너무 길면 어쩔 수 없이 자름
            return compressed.slice(0, 25);
        }

        return compressed;
    }

    private compressQuestion(text: string): string {
        // 1. 문맥적 치환 (의미 압축)
        let compressed = text
            .replace(/아이들과/g, "아이와")
            .replace(/가족들이랑/g, "가족과")
            .replace(/함께 해본 적 있어\?/g, "해봤어?")
            .replace(/어떤 시간 보내\?/g, "뭐 해?")
            .replace(/시간을 보내다/g, "놀기")
            .replace(/그림 그리면서/g, "그림 그리며")
            .replace(/이야기 나누기/g, "대화")
            .replace(/생각해본 적 있어\?/g, "생각해봐")
            .replace(/어떠했어\?/g, "어땠어?")
            .replace(/기억에 남는/g, "기억남는");

        // 2. 조사 생략 (과도한 생략 지양 - 자연스러움 유지)
        // 은/는/이/가 정도만 상황 봐서 제거 (여기서는 보수적으로 유지하거나 최소화)
        compressed = compressed.replace(/\s+/g, " ").trim();

        // 3. 질문형 보장
        if (!compressed.endsWith("?") && !compressed.endsWith("!")) {
            compressed += "?";
        }

        // 4. 길이 체크 및 최후 절단 (24자 -> 50자)
        if (compressed.length <= 50) return compressed;
        return compressed.slice(0, 49) + "?"; // 잘리더라도 질문형 유지 노력
    }

    private expandOption(option: string, q: EnrichmentQuestion): string {
        // TODO: Implement more sophisticated option expansion logic using q.enrichment_materials
        return option;
    }
}
