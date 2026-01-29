import { z } from "zod";

export const BalanceQuestionSchema = z.object({
  type: z.literal("balance"),

  topic: z.string(),
  category: z.string(),

  context_variant: z.string(),

  question: z.string(),

  options: z.tuple([
    z.string(),
    z.string()
  ]),

  intimacy_level: z.number().min(1).max(5),

  source_order_code: z.string(),
});

export type BalanceQuestion = z.infer<typeof BalanceQuestionSchema>;
