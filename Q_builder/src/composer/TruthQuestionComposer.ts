import { TruthQuestion } from "../schemas/truth-question.schema";
import { EnrichmentInput } from "../schemas/enrichment.schema";
import { extractIntimacyLevel } from "../utils/composer-helper";

/**
 * Truth Question Composer
 * - Enrichment 데이터를 기반으로
 * - 진실게임 질문 + 예상답변 생성
 * - 모바일 화면 기준: 짧고, 구체적, 말 걸기 톤
 */
export class TruthQuestionComposer {
    compose(enrichment: EnrichmentInput): TruthQuestion[] {
        // 공통 헬퍼 활용
        const intimacyLevel = extractIntimacyLevel(enrichment.order_code_prefix);

        return enrichment.questions.map((q, index) => {
            const question = this.buildQuestion(q.base_content);
            const expectedAnswers = this.buildExpectedAnswers(q);

            return {
                id: `T-${enrichment.order_code_prefix}-${index + 1}`,
                intimacyLevel,
                question,
                expectedAnswers,
            };
        });
    }

    // -------------------------
    // 🔧 Helpers
    // -------------------------

    /**
     * 질문 생성 (모바일 기준 압축)
     * - 의미 기반 압축 및 길이 제한
     */
    private buildQuestion(base: string): string {
        return this.compressQuestion(base);
    }

    /**
     * 예상 답변 생성
     * - 심리 텐션 + 말 걸기 표현 활용
     * - 의미 압축 적용
     */
    private buildExpectedAnswers(question: any): string[] {
        const tensions =
            question.enrichment_materials.enrichment_psychological_tensions
                ?.split("|")
                .map((v: string) => v.trim()) ?? [];

        const friendly =
            question.enrichment_materials.enrichment_conversation_friendly_terms
                ?.split("|")
                .map((v: string) => v.trim()) ?? [];

        const answers: string[] = [];

        // 1. Tensions 처리: "A vs B" 형태라면 쪼개서 각각 답변으로 제시
        if (tensions.length > 0) {
            tensions.forEach((t: string) => {
                if (t.includes("vs")) {
                    const [a, b] = t.split("vs").map(s => s.trim());
                    if (a) answers.push(this.compressAnswer(a));
                    if (b) answers.push(this.compressAnswer(b));
                } else {
                    answers.push(this.compressAnswer(t));
                }
            });
        }

        // 2. Friendly Terms 추가
        friendly.forEach((term: string) => {
            answers.push(this.compressAnswer(term));
        });

        // 3. 중복 제거 및 최대 개수 제한
        const uniqueAnswers = Array.from(new Set(answers)).filter(Boolean);
        return uniqueAnswers.slice(0, 4);
    }

    // -------------------------
    // ✂️ Compression Logic
    // -------------------------

    private compressQuestion(text: string): string {
        // 1. 문맥적 치환 (Truth 전용)
        let compressed = text
            .replace(/아이들과/g, "아이와")
            .replace(/가족들이랑/g, "가족과")
            .replace(/친구들이랑/g, "친구와")
            .replace(/함께 해본 적 있어\?/g, "해봤어?")
            .replace(/어떻게 생각해\?/g, "어때?")
            .replace(/어떤 시간 보내\?/g, "뭐 해?")
            .replace(/시간을 보내다/g, "놀기")
            .replace(/이야기 나누기/g, "대화")
            .replace(/생각해본 적 있어\?/g, "생각해봐")
            .replace(/알고 있어\?/g, "알아?")
            .replace(/기억에 남는/g, "기억남는")
            .replace(/가장 좋아하는/g, "최애")
            .replace(/무엇인가요\?/g, "뭐야?")
            .replace(/무엇인가\?/g, "뭐야?");

        // 2. 조사 생략
        compressed = compressed
            .replace(/을 /g, " ")
            .replace(/를 /g, " ")
            .replace(/이 /g, " ")
            .replace(/가 /g, " ")
            .replace(/의 /g, " ");

        // 3. 공백 정리
        compressed = compressed.replace(/\s+/g, " ").trim();

        // 4. 질문 강화
        if (!compressed.endsWith("?") && !compressed.endsWith("!")) {
            compressed += "?";
        }

        // 5. 길이 제한 완화 (32자 -> 50자) 및 말줄임표 처리 보완
        // 어법이 끊기지 않도록 너무 짧게 자르지 않음
        if (compressed.length > 50) {
            return compressed.slice(0, 49) + "…";
        }
        return compressed;
    }

    private compressAnswer(text: string): string {
        let compressed = text;

        // 1. 답변용 치환 규칙
        const rules: Record<string, string> = {
            "쪽인 것 같아": "",
            "기억이 더 남아": "기억",
            "생각이 들어": "생각함",
            "느낌이야": "느낌",
            "쪽이야": "",
            "기억놔": "기억나",
            "놀아줘야 한다는": "의무적인", // "놀아주는"보다 "의무적인"이 '부담감'과 잘 붙음
            "아이보다 그림 못 그릴 때의": "실력 부족",
            "칭찬과 솔직함 사이의": "칭찬과 솔직",
            "피곤하지만 억지로": "억지로",
        };

        for (const [long, short] of Object.entries(rules)) {
            compressed = compressed.replace(long, short);
        }

        // 2. 불필요한 조사/어미 처리
        compressed = compressed
            .replace(/한다는 /g, "하는 ") // 무작정 삭제 대신 연결형으로
            .replace(/하는 /g, " ")      // '하는'은 상황에 따라 생략 가능하지만 주의 필요 (일단 유지하거나 공백으로) -> 여기서는 '하는' 뒤 명사가 오면 생략해도 말이 되는 경우가 많음 (생각하는 힘 -> 생각 힘). 하지만 '놀아줘야 하는 부담감' -> '놀아줘야 부담감'은 이상함.
            // 앞 단계 규칙에서 '놀아줘야 한다는'을 처리했으므로 여기선 보조적 역할.
            .replace(/에 대한/g, "")
            .replace(/을 위한/g, "")
            .replace(/때의 /g, "때 ")

        // 3. 공백 정리
        compressed = compressed.replace(/\s+/g, " ").trim();

        // 4. 길이 제한 완화 (12자 -> 20자)
        if (compressed.length > 20) {
            return compressed.slice(0, 20);
        }
        return compressed;
    }
}
