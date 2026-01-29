import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from "dotenv";

dotenv.config();

export class GeminiClient {
    private genAI: GoogleGenerativeAI;
    private model: any;

    constructor() {
        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey) {
            throw new Error("GEMINI_API_KEY is missing in .env file");
        }
        this.genAI = new GoogleGenerativeAI(apiKey);

        // 모델명 변경: gemini-2.0-flash (Available in list)
        this.model = this.genAI.getGenerativeModel({
            model: "gemini-2.0-flash"
        });
    }

    public async generate(prompt: string, modelName: string = "gemini-2.0-flash", maxRetries: number = 5): Promise<any> {
        const specificModel = this.genAI.getGenerativeModel({ model: modelName });
        let attempt = 0;

        while (attempt < maxRetries) {
            try {
                if (attempt > 0) {
                    console.log(`⏳ Retry attempt ${attempt}/${maxRetries} for ${modelName}...`);
                }

                // 요청 전 기본 딜레이 (안정성 확보)
                await this.sleep(1000 * (attempt + 1));

                const result = await specificModel.generateContent(prompt);
                const response = await result.response;
                let text = response.text();

                // Markdown Code Block 제거
                text = text.replace(/```json/g, "").replace(/```/g, "").trim();

                return JSON.parse(text);

            } catch (error: any) {
                attempt++;

                // 에러 분석
                const isRateLimit = error.message?.includes("429") || error.status === 429;
                const isServerOverload = error.message?.includes("503") || error.status === 503;

                if (attempt >= maxRetries) {
                    console.error(`❌ Final Failure after ${maxRetries} attempts.`);
                    throw error;
                }

                if (isRateLimit || isServerOverload) {
                    // Exponential Backoff: 2초, 4초, 8초, 16초... 대기
                    const waitTime = Math.pow(2, attempt) * 2000;
                    console.warn(`⚠️ API Rate/Server Limit (${error.status}). Waiting ${waitTime / 1000}s...`);
                    await this.sleep(waitTime);
                    continue;
                }

                // 그 외 에러(JSON 파싱 등)는 재시도 없이 즉시 throw 할지, 재시도 할지 결정
                // JSON 파싱 에러도 가끔 모델이 이상한 텍스트 뱉을 때 있으므로 재시도 가치 있음
                console.warn(`⚠️ Unexpected Error: ${error.message}. Retrying...`);
                await this.sleep(2000);
            }
        }
    }

    private sleep(ms: number) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}
