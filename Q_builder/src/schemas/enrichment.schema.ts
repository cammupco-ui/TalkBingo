// src/schemas/enrichment.schema.ts
import { z } from "zod";

export const EnrichmentMaterialSchema = z.object({
  enrichment_community_contexts: z.string(),
  enrichment_trending_keywords: z.string(),
  enrichment_psychological_tensions: z.string(),
  enrichment_conversation_friendly_terms: z.string(),
});

export const EnrichmentQuestionSchema = z.object({
  context_variant: z.string(),
  base_content: z.string(),
  enrichment_materials: EnrichmentMaterialSchema,
});

export const EnrichmentSchema = z.object({
  topic: z.string(),
  category: z.string(),
  order_code_prefix: z.string(),
  gender_policy: z.string(),
  questions: z.array(EnrichmentQuestionSchema),
});

export type EnrichmentInput = z.infer<typeof EnrichmentSchema>;
export type EnrichmentQuestion = z.infer<typeof EnrichmentQuestionSchema>;