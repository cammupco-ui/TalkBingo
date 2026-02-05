import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabaseClient';

export async function PUT(request: Request) {
    try {
        const body = await request.json();
        const { q_id, updatePayload } = body;

        if (!q_id || !updatePayload) {
            return NextResponse.json({ error: 'Missing q_id or payload' }, { status: 400 });
        }

        // Use Service Role Key client (server-side) to bypass RLS
        const { error } = await supabase
            .from("questions")
            .update(updatePayload)
            .eq("q_id", q_id);

        if (error) {
            return NextResponse.json({ error: error.message }, { status: 500 });
        }

        return NextResponse.json({ success: true });
    } catch (e) {
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
