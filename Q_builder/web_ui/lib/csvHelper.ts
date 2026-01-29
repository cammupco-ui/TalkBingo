// Helper to escape CSV fields
export function escapeCSV(field: any): string {
    if (field === null || field === undefined) return "";
    const str = String(field);
    if (str.includes(",") || str.includes('"') || str.includes("\n")) {
        return `"${str.replace(/"/g, '""')}"`;
    }
    return str;
}

// Columns: type,topic,order_code,context_variant,question,options
export function toBalanceCSVRow(item: any): string {
    // Options separated by pipe | to distinguish from CSV comma
    // Or stick to JSON format for arrays to be safe? 
    // User asked for "options" column. Let's use pipe "|" because comma is CSV delimiter.
    const optionsStr = item.options ? item.options.join("|") : "";

    return [
        escapeCSV("balance"),
        escapeCSV(item.topic || ""),
        escapeCSV(item.source_order_code || item.order_code_prefix || ""),
        escapeCSV(item.context_variant || ""),
        escapeCSV(item.question || ""),
        escapeCSV(optionsStr)
    ].join(",");
}

// Columns: type,topic,order_code,context_variant,question,expectedAnswer
export function toTruthCSVRow(item: any): string {
    // Answers separated by pipe |
    const answersStr = Array.isArray(item.expected_answers)
        ? item.expected_answers.join("|")
        : (item.expected_answers || "");

    return [
        escapeCSV("truth"),
        escapeCSV(item.topic || ""),
        escapeCSV(item.source_order_code || item.order_code_prefix || ""),
        escapeCSV(item.context_variant || ""),
        escapeCSV(item.question || ""),
        escapeCSV(answersStr)
    ].join(",");
}

// Re-using the logic for daily backup if needed, but the main goal is the V2 files now.
export function toDailyBackupRow(item: any): string {
    // Just reuse the specific format depending on type
    if (item.type === 'balance') return toBalanceCSVRow(item);
    return toTruthCSVRow(item);
}
