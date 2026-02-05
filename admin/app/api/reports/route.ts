import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabaseClient';

export async function GET() {
    try {
        // 1. Get Reports
        const { data: reportsData, error: reportsError } = await supabase
            .from("reports")
            .select("*")
            .order("created_at", { ascending: false })
            .limit(50);

        if (reportsError) {
            return NextResponse.json({ error: reportsError.message }, { status: 500 });
        }

        // 2. Get Related Questions
        const qIds = reportsData.map((r: any) => r.q_id).filter(Boolean);
        let merged = reportsData;

        if (qIds.length > 0) {
            // Fetch by ID and Content
            const { data: questionsByCode } = await supabase.from("questions").select("*").in("q_id", qIds);
            const { data: questionsByContent } = await supabase.from("questions").select("*").in("content", qIds);

            const qMap = new Map();
            if (questionsByCode) questionsByCode.forEach((q: any) => qMap.set(q.q_id, q));
            // Map content to q object for textual lookup
            if (questionsByContent) questionsByContent.forEach((q: any) => qMap.set(q.content, q));

            merged = reportsData.map((r: any) => {
                // Try exact ID match or Content match
                const q = qMap.get(r.q_id);
                return { ...r, question: q };
            });
        }

        return NextResponse.json(merged);
    } catch (e) {
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
