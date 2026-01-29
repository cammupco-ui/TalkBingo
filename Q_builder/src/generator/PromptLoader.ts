import fs from "fs";
import path from "path";

export class PromptLoader {
    private docPath: string;

    constructor() {
        this.docPath = path.join(process.cwd(), "src", "doc");
    }

    /**
     * 마크다운 프롬프트 템플릿 로드
     */
    public loadTemplate(filename: string): string {
        const filePath = path.join(this.docPath, filename);
        if (!fs.existsSync(filePath)) {
            throw new Error(`Template not found: ${filename}`);
        }
        return fs.readFileSync(filePath, "utf-8");
    }

    /**
     * JSON 참조 파일 로드 (문자열로 반환하여 프롬프트에 주입)
     */
    public loadReferenceJson(filename: string): string {
        const filePath = path.join(this.docPath, filename);
        if (!fs.existsSync(filePath)) {
            throw new Error(`Reference JSON not found: ${filename}`);
        }
        return fs.readFileSync(filePath, "utf-8");
    }

    /**
     * 템플릿 변수 치환
     * 예: {{Base_Content.topic}} -> "여행"
     */
    public fillTemplate(template: string, data: Record<string, any>): string {
        let filled = template;

        // Flatten data for dot notation access if needed, 
        // but for now simple replacement logic:
        for (const [key, value] of Object.entries(data)) {
            // value가 객체면 이쁘게 JSON stringify
            const strVal = typeof value === 'object'
                ? JSON.stringify(value, null, 2)
                : String(value);

            // {{key}} 패턴 치환
            const regex = new RegExp(`{{${key}}}`, "g");
            filled = filled.replace(regex, strVal);
        }

        // 혹시 객체 내부 접근(dot notation)이 필요한 경우 정규식으로 처리
        // 예: {{Base_Content.topic}}
        filled = filled.replace(/{{([^}]+)}}/g, (match, keyPath) => {
            const val = this.getValueByPath(data, keyPath.trim());
            if (val === undefined) return match; // 값이 없으면 그대로 둠 (디버깅 용이)
            return typeof val === 'object' ? JSON.stringify(val, null, 2) : String(val);
        });

        return filled;
    }

    private getValueByPath(obj: any, path: string): any {
        return path.split('.').reduce((acc, part) => acc && acc[part], obj);
    }
}
