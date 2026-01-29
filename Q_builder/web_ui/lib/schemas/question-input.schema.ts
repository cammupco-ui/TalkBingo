// src/schemas/question-input.schema.ts

export interface QuestionInput {
  topic: string;
  category: string;
  order_code_prefix: string;
  gender_policy: string;
  context_variant: string;
  base_content: string;
  enrichment_text: string; // materials 합쳐서 1줄
}
