import { NextRequest, NextResponse } from "next/server";
import fs from "node:fs";
import path from "node:path";
import { toBalanceCSVRow, toTruthCSVRow } from "@/lib/csvHelper";

const DOC_DIR = path.resolve(process.cwd(), "../src/doc");
const BALANCE_CSV = path.join(DOC_DIR, "BalanceQuizData_v2.csv");
const TRUTH_CSV = path.join(DOC_DIR, "TruthQuizData_v2.csv");

export async function POST(req: NextRequest) {
    try {
        const { type, items } = await req.json(); // type: 'balance' | 'truth'

        if (!items || items.length === 0) {
            return NextResponse.json({ success: true, count: 0 });
        }

        const filePath = type === 'balance' ? BALANCE_CSV : TRUTH_CSV;
        const converter = type === 'balance' ? toBalanceCSVRow : toTruthCSVRow;

        const csvContent = items.map((item: any) => converter(item)).join("\n") + "\n";

        fs.appendFileSync(filePath, csvContent, "utf-8");

        return NextResponse.json({ success: true, savedCount: items.length });

    } catch (e: any) {
        console.error(e);
        return NextResponse.json({ success: false, error: e.message }, { status: 500 });
    }
}
