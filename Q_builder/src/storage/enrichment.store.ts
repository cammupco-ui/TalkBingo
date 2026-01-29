// src/storage/enrichment.store.ts
import { EnrichmentExport } from '../schemas/enrichment.schema';

export function saveEnrichment(payload: EnrichmentExport) {
    // 지금은 파일 저장
    // 나중에 DB로 바꿔도 이 파일만 고치면 됨
}
