import { NextRequest, NextResponse } from "next/server";
import { BalanceQuestionComposer } from "@/lib/composer/BalanceQuestionComposer";
import { TruthQuestionComposer } from "@/lib/composer/TruthQuestionComposer";

// Init Composers
const balanceComposer = new BalanceQuestionComposer();
const truthComposer = new TruthQuestionComposer();

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { type, sourceItem, selectedText } = body;

        // Construct a temporary EnrichmentInput focused on the selected text
        // We trick the composer by providing the selected text as the ONLY material
        // This forces the composer to use it for option/answer generation.
        const mockInput = {
            topic: sourceItem.topic,
            category: sourceItem.category,
            order_code_prefix: sourceItem.source_order_code || sourceItem.order_code_prefix,
            gender_policy: sourceItem.gender_policy,
            questions: [{
                context_variant: sourceItem.context_variant,
                base_content: sourceItem.base_content || sourceItem.question,
                enrichment_materials: {
                    // Force the selected text into fields used by composers
                    enrichment_psychological_tensions: selectedText,
                    enrichment_conversation_friendly_terms: selectedText,
                    enrichment_trending_keywords: selectedText,
                    enrichment_community_contexts: selectedText
                }
            }]
        };

        let resultItem;
        if (type === 'balance') {
            const results = balanceComposer.compose(mockInput as any);
            if (results.length > 0) {
                resultItem = {
                    ...results[0],
                    type: 'balance',
                    // Restore original metadata correctly
                    topic: sourceItem.topic,
                    category: sourceItem.category,
                    context_variant: sourceItem.context_variant,
                    source_order_code: sourceItem.source_order_code,
                    base_content: sourceItem.base_content,
                    gender_policy: sourceItem.gender_policy,
                    enrichment_materials: sourceItem.enrichment_materials // Keep original reference
                };
            }
        } else {
            const results = truthComposer.compose(mockInput as any);
            if (results.length > 0) {
                resultItem = {
                    ...results[0],
                    type: 'truth',
                    topic: sourceItem.topic,
                    category: sourceItem.category,
                    context_variant: sourceItem.context_variant,
                    source_order_code: sourceItem.source_order_code,
                    base_content: sourceItem.base_content,
                    gender_policy: sourceItem.gender_policy,
                    enrichment_materials: sourceItem.enrichment_materials,
                    expected_answers: results[0].expectedAnswers
                };
            }
        }

        if (resultItem) {
            return NextResponse.json({ success: true, item: resultItem });
        } else {
            return NextResponse.json({ success: false, error: "Composition failed" });
        }

    } catch (e: any) {
        console.error(e);
        return NextResponse.json({ success: false, error: e.message }, { status: 500 });
    }
}
