
import { NextRequest, NextResponse } from "next/server";
import fs from "fs";
import path from "path";

export async function POST(req: NextRequest) {
    try {
        const { items, subfolder } = await req.json();

        if (!items || !Array.isArray(items) || items.length === 0) {
            return NextResponse.json({ success: false, error: "No items to save." }, { status: 400 });
        }

        // Base Directory Resolution
        const candidates = [
            path.resolve(process.cwd(), "../src/data/Q_build"), // If running from web_ui
            path.resolve(process.cwd(), "src/data/Q_build"),    // If running from Q_builder root
            path.resolve(process.cwd(), "data/Q_build"),         // Fallback
        ];

        let BASE_DIR = candidates.find(p => fs.existsSync(p));

        if (!BASE_DIR) {
            console.error("Could not find Q_build directory. Checked:", candidates);
            return NextResponse.json({ success: false, error: "Configuration Error: structured data directory not found." }, { status: 500 });
        }

        console.log(`[SaveSource] Resolving paths. CWD: ${process.cwd()}, Selected BASE_DIR: ${BASE_DIR}`);

        // Determine Target Directory
        const targetFolder = subfolder || "Generated_Q_sources"; // Default if not specified
        const TARGET_DIR = path.join(BASE_DIR, targetFolder);

        // Ensure directory exists
        if (!fs.existsSync(TARGET_DIR)) {
            console.log(`[SaveSource] Creating directory: ${TARGET_DIR}`);
            fs.mkdirSync(TARGET_DIR, { recursive: true });
        }

        // Current Date
        const now = new Date();
        const yyyy = now.getFullYear();
        const mm = String(now.getMonth() + 1).padStart(2, '0');
        const dd = String(now.getDate()).padStart(2, '0');
        const dateStr = `${yyyy}${mm}${dd}`;

        // Prefix based on folder name
        // User requested "folder name + next sequence"
        // Let's use format: {FolderName}_{YYYYMMDD}-{N}.json
        // e.g. QSituations_20260121-1.json
        // Prefix based on folder name
        // Use "Q_sources" for "Generated_Q_sources" to match convention
        const prefix = targetFolder === "Generated_Q_sources"
            ? `Q_sources_${dateStr}`
            : `${targetFolder}_${dateStr}`;

        const files = fs.readdirSync(TARGET_DIR);

        // Calculate Next Sequence using strict pattern match
        let maxNum = 0;
        // Escape regex special chars in prefix just in case usually not needed for folder names but good practice
        // or just use simple string based check
        const pattern = new RegExp(`^${prefix}-(\\d+)\\.json$`);

        files.forEach(file => {
            const match = file.match(pattern);
            if (match) {
                const num = parseInt(match[1], 10);
                if (num > maxNum) maxNum = num;
            }
        });

        const nextNum = maxNum + 1;
        const fileName = `${prefix}-${nextNum}.json`;
        const filePath = path.join(TARGET_DIR, fileName);

        // Write File
        fs.writeFileSync(filePath, JSON.stringify(items, null, 2), "utf-8");

        return NextResponse.json({
            success: true,
            savedPath: filePath,
            fileName: fileName,
            folder: targetFolder
        });

    } catch (e: any) {
        console.error("Save Source Error:", e);
        return NextResponse.json({ success: false, error: e.message }, { status: 500 });
    }
}
