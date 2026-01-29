"use client";

import { useState, useCallback, useMemo, useEffect } from "react";
import { repairAndParseJson } from "@/lib/json-fixer";

// Types matching the Validator output
interface ValidItem {
  topic: string;
  category: string;
  order_code_prefix: string;
  gender_policy: string;
  questions?: any[];
  situations?: any[];
  [key: string]: any;
}

export default function Home() {
  const [dragActive, setDragActive] = useState(false);
  const [jsonInput, setJsonInput] = useState("");
  const [validationResult, setValidationResult] = useState<{
    status: "idle" | "valid" | "invalid";
    message: string;
    items: ValidItem[];
    stats: { topics: number; totalQuestions: number };
  }>({ status: "idle", message: "", items: [], stats: { topics: 0, totalQuestions: 0 } });

  const [validationLogs, setValidationLogs] = useState<string[]>([]);
  const [saveStatus, setSaveStatus] = useState<"idle" | "saving" | "success" | "error">("idle");
  const [savedPath, setSavedPath] = useState("");

  // Directory Selection State
  const [availableFolders, setAvailableFolders] = useState<string[]>([]);
  const [selectedFolder, setSelectedFolder] = useState<string>("Generated_Q_sources");

  // Fetch directories on mount

  useEffect(() => {
    fetch("/api/list-dirs")
      .then(res => res.json())
      .then(data => {
        if (data.directories && Array.isArray(data.directories)) {
          setAvailableFolders(data.directories);
          // Default to Generated_Q_sources if exists, otherwise first one
          if (data.directories.includes("Generated_Q_sources")) {
            setSelectedFolder("Generated_Q_sources");
          } else if (data.directories.length > 0) {
            setSelectedFolder(data.directories[0]);
          }
        }
      })
      .catch(err => console.error("Failed to fetch directories:", err));
  }, []);

  // Analyze the items to get stats
  const analyzeItems = (items: ValidItem[]) => {
    const topics = new Set(items.map(i => i.topic));
    const totalQuestions = items.reduce((acc, item) => acc + (item.questions ? item.questions.length : (item.situations ? item.situations.length : 0)), 0);
    return { topics: topics.size, totalQuestions };
  };

  // Main Validation Logic
  const handleValidate = (input: string) => {
    setSaveStatus("idle");
    setSavedPath("");
    setValidationLogs([]);
    setIsEditing(false);

    if (!input.trim()) {
      setValidationResult({ status: "idle", message: "", items: [], stats: { topics: 0, totalQuestions: 0 } });
      return;
    }

    try {
      const fixedResult = repairAndParseJson(input);
      setValidationLogs(fixedResult.logs);

      const fixedItems = fixedResult.items;

      if (fixedItems.length > 0) {
        const stats = analyzeItems(fixedItems);
        setValidationResult({
          status: "valid",
          message: "JSON Structure is Valid",
          items: fixedItems,
          stats
        });
      } else {
        setValidationResult({
          status: "invalid",
          message: "No valid TalkBingo items found in input.",
          items: [],
          stats: { topics: 0, totalQuestions: 0 }
        });
      }
    } catch (e: any) {
      setValidationResult({
        status: "invalid",
        message: "Parsing Error: " + e.message,
        items: [],
        stats: { topics: 0, totalQuestions: 0 }
      });
      setValidationLogs(prev => [...prev, `Critical Error: ${e.message}`]);
    }
  };

  // Handlers
  const onDrag = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === "dragenter" || e.type === "dragover") {
      setDragActive(true);
    } else if (e.type === "dragleave") {
      setDragActive(false);
    }
  }, []);

  const onDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);

    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      const file = e.dataTransfer.files[0];
      const reader = new FileReader();
      reader.onload = (ev) => {
        const text = ev.target?.result as string;
        setJsonInput(text);
        handleValidate(text);
      };
      reader.readAsText(file);
    }
  }, []);

  // Server Save Logic
  const handleServerSave = async () => {
    if (validationResult.items.length === 0) return;
    setSaveStatus("saving");

    try {
      const res = await fetch("/api/save-source", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          items: validationResult.items,
          subfolder: selectedFolder
        }),
      });
      const data = await res.json();

      if (data.success) {
        setSaveStatus("success");
        setSavedPath(data.fileName); // Show just filename for brevity
      } else {
        setSaveStatus("error");
        alert("Save Failed: " + data.error);
      }
    } catch (e: any) {
      setSaveStatus("error");
      alert("Network Error");
    }
  };

  // Edit Mode Logic
  const [isEditing, setIsEditing] = useState(false);
  const [editedJson, setEditedJson] = useState("");

  const handleEditClick = () => {
    setEditedJson(JSON.stringify(validationResult.items, null, 2));
    setIsEditing(true);
  };

  const handleApplyEdit = () => {
    try {
      const parsed = JSON.parse(editedJson);
      if (!Array.isArray(parsed)) throw new Error("Edited JSON must be an array of items.");

      // Simple re-validation of structure could go here, but let's assume if it parses it's "valid enough" to save
      // or re-run analyzeItems
      const stats = analyzeItems(parsed);
      setValidationResult(prev => ({
        ...prev,
        items: parsed,
        stats
      }));
      setIsEditing(false);
    } catch (e: any) {
      alert("Invalid JSON: " + e.message);
    }
  };

  return (
    <main className="min-h-screen bg-gray-50 flex flex-col p-8 font-sans text-gray-800">
      {/* Header */}
      <header className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-gray-900">
            TalkBingo <span className="text-indigo-600">JSON Validator</span>
          </h1>
          <p className="text-gray-500 mt-2">
            Check the suitability of source JSON files before ingestion.
          </p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => handleValidate(jsonInput)}
            className="px-6 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded shadow transition"
          >
            Manual Validate
          </button>
        </div>
      </header>

      <div className="flex flex-1 gap-8 h-[calc(100vh-200px)]">

        {/* LEFT: Input Area */}
        <div className="flex-1 flex flex-col">
          <label className="text-sm font-bold text-gray-700 mb-2 uppercase tracking-wide">
            Source JSON Input
          </label>
          <div
            className={`flex-1 relative rounded-xl border-2 transition-all overflow-hidden ${dragActive ? "border-indigo-500 bg-indigo-50" : "border-gray-300 bg-white"
              } ${validationResult.status === 'invalid' ? "border-red-300 bg-red-50" : ""
              }`}
            onDragEnter={onDrag}
            onDragLeave={onDrag}
            onDragOver={onDrag}
            onDrop={onDrop}
          >
            <textarea
              className="w-full h-full p-6 bg-transparent resize-none focus:outline-none font-mono text-sm leading-relaxed"
              placeholder="Paste JSON here or drag & drop a file..."
              value={jsonInput}
              onChange={(e) => {
                setJsonInput(e.target.value);
                // Optional: Auto-validate on change with debounce, but let's stick to manual or drop for now
              }}
            />

            {/* Overlay for Drag State */}
            {dragActive && (
              <div className="absolute inset-0 flex items-center justify-center bg-indigo-50/90 pointer-events-none">
                <p className="text-xl font-bold text-indigo-600">Drop JSON file here</p>
              </div>
            )}
          </div>
        </div>

        {/* RIGHT: Validation Report */}
        <div className="w-1/3 flex flex-col">
          <label className="text-sm font-bold text-gray-700 mb-2 uppercase tracking-wide">
            Validation Report
          </label>

          <div className="bg-white rounded-xl shadow-sm border border-gray-200 flex-1 flex flex-col overflow-hidden">
            {validationResult.status === "idle" && (
              <div className="flex-1 flex flex-col items-center justify-center text-gray-400 p-8 text-center">
                <p>No data analyzed.</p>
                <p className="text-xs mt-2">Paste data or drop a file to check suitability.</p>
              </div>
            )}

            {validationResult.status === "invalid" && (
              <div className="flex-1 p-8 flex flex-col items-center justify-center bg-red-50/50">
                <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-4 text-3xl">
                  ❌
                </div>
                <h3 className="text-xl font-bold text-red-700 mb-2">Invalid Format</h3>
                <p className="text-red-600 text-center mb-4">{validationResult.message}</p>

                {/* Error Log Display */}
                {validationLogs.length > 0 && (
                  <div className="w-full max-h-60 overflow-y-auto bg-red-100 rounded p-3 text-[10px] font-mono whitespace-pre-wrap text-left border border-red-200">
                    <div className="font-bold mb-1 border-b border-red-200 pb-1">Detailed Logs:</div>
                    {validationLogs.map((log, i) => (
                      <div key={i} className="mb-1 opacity-80 border-b border-red-200/50 last:border-0 pb-0.5">{log}</div>
                    ))}
                  </div>
                )}
              </div>
            )}

            {validationResult.status === "valid" && (
              <div className="flex flex-col h-full">
                {isEditing ? (
                  // EDIT MODE
                  <div className="flex-1 flex flex-col h-full">
                    <div className="p-4 bg-indigo-50 border-b border-indigo-100 flex justify-between items-center">
                      <h3 className="font-bold text-indigo-800">Edit JSON Result</h3>
                      <button onClick={() => setIsEditing(false)} className="text-xs text-gray-500 hover:text-gray-800">Cancel</button>
                    </div>
                    <textarea
                      className="flex-1 p-4 font-mono text-xs resize-none focus:outline-none bg-white"
                      value={editedJson}
                      onChange={(e) => setEditedJson(e.target.value)}
                    />
                    <div className="p-4 border-t bg-gray-50 flex gap-2">
                      <button onClick={handleApplyEdit} className="flex-1 bg-indigo-600 text-white py-2 rounded font-bold hover:bg-indigo-700 transition">Apply & Re-Validate</button>
                    </div>
                  </div>
                ) : (
                  // PREVIEW MODE
                  <>
                    {/* Summary Header */}
                    <div className="p-6 bg-green-50 border-b border-green-100">
                      <div className="flex items-center justify-between mb-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 bg-green-200 rounded-full flex items-center justify-center text-lg">
                            ✅
                          </div>
                          <div>
                            <h3 className="text-lg font-bold text-green-800">Valid Source Data</h3>
                            <p className="text-xs text-green-700">Ready for pipeline</p>
                          </div>
                        </div>
                        <button
                          onClick={handleEditClick}
                          className="text-xs bg-white border border-green-200 text-green-700 px-3 py-1 rounded hover:bg-green-100 transition"
                        >
                          Edit JSON
                        </button>
                      </div>

                      <div className="grid grid-cols-2 gap-4">
                        <div className="bg-white p-3 rounded border border-green-100 text-center">
                          <div className="text-2xl font-bold text-gray-800">{validationResult.stats.topics}</div>
                          <div className="text-[10px] text-gray-500 uppercase">Topics</div>
                        </div>
                        <div className="bg-white p-3 rounded border border-green-100 text-center">
                          <div className="text-2xl font-bold text-gray-800">{validationResult.stats.totalQuestions}</div>
                          <div className="text-[10px] text-gray-500 uppercase">Contexts</div>
                        </div>
                      </div>
                    </div>

                    {/* Validated Items List (Preview) */}
                    <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-gray-50">
                      {validationResult.items.map((item, idx) => (
                        <div key={idx} className="bg-white border rounded p-3 text-sm hover:shadow-sm transition">
                          <div className="flex justify-between mb-2">
                            <span className="font-bold text-indigo-700 truncate pr-2" title={item.topic}>{item.topic}</span>
                            <span className="text-[10px] bg-gray-100 px-2 py-0.5 rounded text-gray-500 whitespace-nowrap">{item.category}</span>
                          </div>

                          {/* Q&A Style Content */}
                          {item.questions && item.questions.length > 0 && (
                            <div className="space-y-1">
                              {item.questions.map((q: any, qIdx: number) => (
                                <div key={qIdx} className="text-xs text-gray-600 pl-2 border-l-2 border-gray-200">
                                  {q.context_variant}
                                </div>
                              ))}
                            </div>
                          )}

                          {/* Situation Style Content */}
                          {item.situations && item.situations.length > 0 && (
                            <div className="space-y-1">
                              {item.situations.map((s: any, sIdx: number) => (
                                <div key={sIdx} className="text-xs text-gray-600 pl-2 border-l-2 border-blue-200">
                                  <span className="font-bold text-blue-600">{s.emotion}</span>: {s.persona_state}
                                </div>
                              ))}
                            </div>
                          )}

                          {/* Fallback for empty content */}
                          {(!item.questions?.length && !item.situations?.length) && (
                            <div className="text-xs text-gray-400 italic">No detailed content found.</div>
                          )}
                        </div>
                      ))}
                    </div>

                    {/* Footer Actions */}
                    <div className="p-4 bg-white border-t space-y-3">
                      {/* Folder Selection */}
                      <div className="space-y-1">
                        <label className="text-xs font-bold text-gray-500 uppercase">Target Folder</label>
                        <select
                          value={selectedFolder}
                          onChange={(e) => setSelectedFolder(e.target.value)}
                          className="w-full p-2 text-sm border border-gray-300 rounded focus:ring-2 focus:ring-indigo-500 focus:outline-none bg-white"
                          disabled={saveStatus === 'success' || saveStatus === 'saving'}
                        >
                          {availableFolders.map(folder => (
                            <option key={folder} value={folder}>{folder}</option>
                          ))}
                        </select>
                      </div>

                      {saveStatus === 'success' ? (
                        <div className="text-center pt-2">
                          <div className="text-green-600 font-bold mb-1">Saved Successfully!</div>
                          <div className="text-xs text-gray-500 bg-gray-100 p-2 rounded break-all">{savedPath}</div>
                        </div>
                      ) : (
                        <button
                          onClick={handleServerSave}
                          disabled={saveStatus === 'saving'}
                          className={`w-full py-3 text-white text-sm font-bold rounded flex items-center justify-center gap-2 transition ${saveStatus === 'saving' ? 'bg-gray-400 cursor-not-allowed' : 'bg-gray-900 hover:bg-gray-800'
                            }`}
                        >
                          {saveStatus === 'saving' ? 'Saving...' : 'Save to Server'}
                        </button>
                      )}
                    </div>
                  </>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
