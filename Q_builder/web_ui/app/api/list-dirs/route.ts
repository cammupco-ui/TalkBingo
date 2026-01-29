
import { NextResponse } from "next/server";
import fs from "fs";
import path from "path";

export async function GET() {
    try {
        // Resolve Directory Robustly
        const candidates = [
            path.resolve(process.cwd(), "../src/data/Q_build"),
            path.resolve(process.cwd(), "src/data/Q_build"),
            path.resolve(process.cwd(), "data/Q_build"),
        ];

        let TARGET_DIR = candidates.find(p => fs.existsSync(p));

        if (!TARGET_DIR) {
            return NextResponse.json({ directories: [] });
        }

        const entries = fs.readdirSync(TARGET_DIR, { withFileTypes: true });
        const directories = entries
            .filter(entry => entry.isDirectory())
            .map(entry => entry.name)
            .filter(name => !name.startsWith(".")); // exclude hidden dirs

        return NextResponse.json({ directories });

    } catch (e: any) {
        return NextResponse.json({ error: e.message }, { status: 500 });
    }
}
