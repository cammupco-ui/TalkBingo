/**
 * Smart JSON Fixer for TalkBingo Ingestion
 * 
 * Capability:
 * - Extracts valid JSON objects from mixed text files (logs, copy-pastes)
 * - Ignores non-JSON text (headers, dates, comments)
 * - Normalizes various object structures into the standard TalkBingo Schema
 */

interface ValidItem {
    topic: string;
    category: string;
    order_code_prefix: string;
    gender_policy: string;
    questions?: any[];  // Made optional
    situations?: any[]; // For situation source files
    [key: string]: any; // Allow other fields like '일련번호'
}

interface RepairResult {
    items: ValidItem[];
    logs: string[];
}

export function repairAndParseJson(rawText: string): RepairResult {
    const validItems: ValidItem[] = [];
    const logs: string[] = [];

    const log = (msg: string) => {
        // console.log("[JsonFixer] " + msg); 
        logs.push(msg);
    };

    log(`Starting analysis of ${rawText.length} characters.`);

    // 1. Extract potential JSON blocks using regex
    // Looks for blocks starting with { and ending with }
    // This is a naive heuristic but works for concatenated JSONs
    let bracketCount = 0;
    let startIndex = -1;
    let inString = false;
    let escape = false;

    // Scan character by character to identify top-level objects 
    // (Resilient against nested objects)
    for (let i = 0; i < rawText.length; i++) {
        const char = rawText[i];

        if (inString) {
            if (escape) {
                escape = false;
            } else if (char === '\\') {
                escape = true;
            } else if (char === '"') {
                inString = false;
            }
            continue;
        }

        if (char === '"') {
            inString = true;
            continue;
        }

        if (char === '{') {
            if (bracketCount === 0) startIndex = i;
            bracketCount++;
        } else if (char === '}') {
            bracketCount--;
            if (bracketCount === 0 && startIndex !== -1) {
                // Found a candidate block
                const block = rawText.substring(startIndex, i + 1);
                log(`Found candidate JSON block of size ${block.length}`);
                try {
                    const parsed = JSON.parse(block);
                    const normalized = normalizeItem(parsed, log);
                    if (normalized) {
                        if (Array.isArray(normalized)) {
                            log(`Block yielded ${normalized.length} valid items.`);
                            validItems.push(...normalized);
                        } else {
                            log(`Block yielded 1 valid item.`);
                            validItems.push(normalized);
                        }
                    } else {
                        log(`Block parsed but contained no valid TalkBingo data.`);
                    }
                } catch (e: any) {
                    log(`JSON Parse Failed for block: ${e.message}`);
                }
                startIndex = -1;
            }
        }
    }

    // Fallback: If no objects found, try parsing the whole text wrapped in array
    if (validItems.length === 0) {
        log("No items found via block scanning. Attempting global parse.");
        try {
            // Try wrapping in brackets if not present
            const textToParse = rawText.trim();
            const wrappedText = textToParse.startsWith('[') ? textToParse : `[${textToParse}]`;

            const parsedArray = JSON.parse(wrappedText);
            if (Array.isArray(parsedArray)) {
                log(`Global parse successful, array of length ${parsedArray.length}.`);
                parsedArray.forEach((p, idx) => {
                    const normalized = normalizeItem(p, log);
                    if (normalized) {
                        if (Array.isArray(normalized)) {
                            validItems.push(...normalized);
                        } else {
                            validItems.push(normalized);
                        }
                    } else {
                        log(`Global item ${idx} invalid.`);
                    }
                });
            } else {
                // Maybe it was a single object?
                const normalized = normalizeItem(parsedArray, log);
                if (normalized) {
                    if (Array.isArray(normalized)) {
                        validItems.push(...normalized);
                    } else {
                        validItems.push(normalized);
                    }
                }
            }
        } catch (e: any) {
            log(`Global parse failed: ${e.message}`);
        }
    }

    log(`Total valid items found: ${validItems.length}`);
    return { items: validItems, logs };
}

function normalizeItem(obj: any, log: (m: string) => void): ValidItem | ValidItem[] | null {
    if (!obj || typeof obj !== 'object') {
        log("Item is not an object.");
        return null;
    }

    // Case 0: Handle "raw_input" wrapper logic
    // Users often paste data where the actual content is inside a "raw_input" key
    // This can be a stringified JSON or a direct object.
    if ('raw_input' in obj) {
        let innerContent = obj.raw_input;

        // If it's a string, try to parse it
        if (typeof innerContent === 'string') {
            try {
                innerContent = JSON.parse(innerContent);
                log("Successfully parsed raw_input string.");
            } catch (e: any) {
                // Parsing failed, try heuristic
                const originalError = e.message;
                let recovered = false;

                const trimmed = innerContent.trim();
                // Heuristic: If it looks like a Python dict string (common in AI logs), fix quotes
                // Apply this for both dicts {} and lists []
                if ((trimmed.startsWith('{') || trimmed.startsWith('[')) && innerContent.includes("'")) {
                    log("Standard parse failed. Attempting Python-style string repair...");
                    const repaired = innerContent.replace(/'/g, '"').replace(/None/g, 'null').replace(/True/g, 'true').replace(/False/g, 'false');
                    try {
                        innerContent = JSON.parse(repaired);
                        recovered = true;
                        log("Successfully parsed raw_input after repair.");
                    } catch (e2: any) {
                        log(`Repair attempt failed: ${e2.message}`);
                    }
                }

                if (!recovered) {
                    log(`Failed to parse raw_input string: ${originalError}`);
                    // Proceed, maybe it's not JSON but a regular object? (unlikely if string)
                }
            }
        }

        // Recursively try to normalize the inside content
        if (Array.isArray(innerContent)) {
            log(`Processing raw_input array of size ${innerContent.length}`);
            const extractedItems: ValidItem[] = [];
            innerContent.forEach((item: any, idx) => {
                const normalized = normalizeItem(item, log);
                if (normalized) {
                    if (Array.isArray(normalized)) {
                        extractedItems.push(...normalized);
                    } else {
                        extractedItems.push(normalized);
                    }
                } else {
                    log(`raw_input item ${idx} invalid.`);
                }
            });
            return extractedItems.length > 0 ? extractedItems : null;
        }

        return normalizeItem(innerContent, log);
    }

    // Case 1: Standard Opal output (has 'data' property)
    if (obj.data && obj.data.questions) {
        return {
            topic: obj.data.topic,
            category: obj.data.category,
            order_code_prefix: obj.data.order_code_prefix,
            gender_policy: obj.data.gender_policy || "neutral",
            questions: obj.data.questions
        };
    }

    // Case 2: Already valid structure with 'questions' array
    if (obj.questions && Array.isArray(obj.questions)) {
        return obj as ValidItem;
    }

    // Case 3: Flat structure (e.g. from copy-pasting single items)
    // Needs to be wrapped into questions array
    if (obj.topic && (obj.base_content || obj.question)) {
        return {
            topic: obj.topic,
            category: obj.category || "Friend",
            order_code_prefix: obj.order_code_prefix || "",
            gender_policy: obj.gender_policy || "neutral",
            questions: [
                {
                    context_variant: obj.context_variant || "Default",
                    base_content: obj.base_content || obj.question || "",
                    enrichment_materials: obj.enrichment_materials || {}
                }
            ]
        };
    }

    // Case 4: Situation Source Data (has 'situations' array)
    if (obj.situations && Array.isArray(obj.situations)) {
        // Create a minimal ValidItem wrapper. 
        // We use the ID or Summary as 'topic' for display purposes.
        return {
            topic: obj["이슈 요약"] || obj["일련번호"] || "Unknown Situation",
            category: "Situation",
            order_code_prefix: obj["일련번호"] || "",
            gender_policy: "neutral",
            situations: obj.situations,
            // Pass through other useful fields for saving
            ...obj
        } as ValidItem;
    }

    // Failure logging
    if (obj.topic) log("Object has topic but missing content or questions array.");
    else if (obj.situations) log("Object has situations but invalid structure.");
    else log("Object missing 'topic' or 'situations' field.");

    return null;
}
