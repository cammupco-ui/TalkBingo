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
        // 1. 의미 전달에 불필요한 서술어구 치환
        let compressed = text
            .replace(/쪽인 것 같아/g, "")
            .replace(/기억이 더 남아/g, "기억")
            .replace(/생각이 들어/g, "생각")
            .replace(/하는 것/g, "")
            .replace(/하기/g, "")
            .replace(/함/g, "")
            .replace(/느낌이야/g, "느낌")
            .replace(/쪽이야/g, "")
            .replace(/기억놔/g, "기억나")
            .replace(/놀아줘야 한다는/g, "의무적인")
            .replace(/아이보다 그림 못 그릴 때의/g, "실력 부족")
            .replace(/칭찬과 솔직함 사이의/g, "칭찬 vs 솔직")
            .replace(/피곤하지만 억지로/g, "억지로")
            .replace(/있다/g, "")
            .replace(/하다/g, "")
            .replace(/되다/g, "");

        // 2. 조사 및 불필요한 단어 제거 (Aggressive)
        compressed = compressed
            .replace(/에 대한/g, "")
            .replace(/을 위한/g, "")
            .replace(/에 관한/g, "")
            .replace(/으로 인한/g, "")
            .replace(/때문에/g, "")
            .replace(/때의/g, "때")
            .replace(/의 /g, " ")
            .replace(/을 /g, " ")
            .replace(/를 /g, " ")
            .replace(/이 /g, " ")
            .replace(/가 /g, " ")
            .replace(/은 /g, " ")
            .replace(/는 /g, " ")
            .replace(/와 /g, " ")
            .replace(/과 /g, " ")
            .replace(/로 /g, " ");

        // 3. 공백 축소
        compressed = compressed.replace(/\s+/g, " ").trim();

        // 4. 길이 제한 (15자) - 모바일 최적화
        if (compressed.length > 15) {
            return compressed.slice(0, 15);
        }
        return compressed;
    }
}
