/**
 * Composer 공통 헬퍼 함수들
 */

/**
 * Order Code에서 친밀도 레벨 추출
 * 포맷 예시: FaFsL2 -> Level 2
 * @param orderCode 
 * @returns 1~5 사이의 정수 (기본값 1)
 */
export function extractIntimacyLevel(orderCode: string): number {
    const match = orderCode.match(/L(\d+)/);
    if (match && match[1]) {
        const level = parseInt(match[1], 10);
        if (level >= 1 && level <= 5) return level;
    }
    return 1;
}

/**
 * 정규식 기반 텍스트 치환 헬퍼
 * @param text 원본 텍스트
 * @param rules 치환 규칙 맵
 * @returns 치환된 텍스트
 */
export function applyReplacementRules(text: string, rules: Record<string, string>): string {
    let result = text;
    for (const [pattern, replacement] of Object.entries(rules)) {
        // 단순 문자열 치환이 아닌, 정규식으로 처리하고 싶다면 별도 로직 필요하지만
        // 현재는 키워드 치환 위주이므로 replaceAll 사용 (ES2021) 
        // 혹은 정규식 이스케이프 후 Global Flag 적용
        const regex = new RegExp(escapeRegExp(pattern), "g");
        result = result.replace(regex, replacement);
    }
    return result;
}

function escapeRegExp(string: string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
