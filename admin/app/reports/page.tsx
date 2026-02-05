"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabaseClient";

export default function ReportsPage() {
    const [reports, setReports] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [editingId, setEditingId] = useState<string | null>(null);

    // Edit State
    const [editForm, setEditForm] = useState<any>({});

    // Filters
    const [filterType, setFilterType] = useState<string>('All');
    const [filterReason, setFilterReason] = useState<string>('All');

    useEffect(() => {
        fetchReports();
    }, []);

    const fetchReports = async () => {
        setLoading(true);
        // ... (existing fetch logic remains same) ...

        // 1. Get Reports
        const { data: reportsData, error: reportsError } = await supabase
            .from("reports")
            .select("*")
            .order("created_at", { ascending: false })
            .limit(50);

        if (reportsError) {
            console.error("Error fetching reports", reportsError);
            setLoading(false);
            return;
        }

        // 2. Get Related Questions
        const qIds = reportsData.map((r: any) => r.q_id).filter(Boolean);
        if (qIds.length > 0) {
            const { data: questionsByCode } = await supabase.from("questions").select("*").in("q_id", qIds);
            const { data: questionsByContent } = await supabase.from("questions").select("*").in("content", qIds);

            const qMap = new Map();
            if (questionsByCode) questionsByCode.forEach((q: any) => qMap.set(q.q_id, q));
            if (questionsByContent) questionsByContent.forEach((q: any) => qMap.set(q.content, q));

            const merged = reportsData.map((r: any) => {
                const q = qMap.get(r.q_id);
                return { ...r, question: q };
            });
            setReports(merged);
        } else {
            setReports(reportsData);
        }
        setLoading(false);
    };

    // Derived state for filtering
    const filteredReports = reports.filter(r => {
        // 1. Filter by Reason
        if (filterReason !== 'All' && r.reason !== filterReason) return false;

        // 2. Filter by Type
        if (filterType !== 'All') {
            const q = r.question;
            if (!q) return false; // Hide if no question data and type filter is active? Or show? Let's hide.

            const qType = q.type || q.options?.type || (q.details?.type);
            // Normalize type check
            // DB types: 'B', 'T', 'balance', 'truth'
            const isBalance = (qType === 'B' || qType === 'balance');
            const isTruth = (qType === 'T' || qType === 'truth');

            if (filterType === 'Balance' && !isBalance) return false;
            if (filterType === 'Truth' && !isTruth) return false;
        }
        return true;
    });

    // Unique Reasons for Dropdown
    const distinctReasons = Array.from(new Set(reports.map(r => r.reason))).filter(Boolean);

    const handleEdit = (item: any) => {
        if (!item.question) return;
        const q = item.question;
        const details = q.details || {};

        setEditingId(item.id);
        setEditForm({
            q_id: q.q_id,
            content: q.content,
            content_en: q.content_en,
            choice_a: q.choice_a || details.choice_a || details.A || "",
            choice_b: q.choice_b || details.choice_b || details.B || "",
            answers: q.answers || details.answers || "",
            choice_a_en: q.choice_a_en || "",
            choice_b_en: q.choice_b_en || "",
            answers_en: q.answers_en || "",
            type: q.type
        });
    };

    // ... existing handleSave ...

    return (
        <div className="p-8 font-sans max-w-6xl mx-auto">
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-3xl font-bold">Reported Questions Management</h1>
                <button
                    onClick={fetchReports}
                    className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                    Refresh List
                </button>
            </div>

            <div className="bg-gray-100 p-4 rounded mb-6 flex gap-4 items-center flex-wrap">
                <span className="font-bold text-gray-700">Filters:</span>

                <div className="flex items-center gap-2">
                    <label className="text-sm font-semibold">Type:</label>
                    <select
                        className="p-2 border rounded"
                        value={filterType}
                        onChange={(e) => setFilterType(e.target.value)}
                    >
                        <option value="All">All Types</option>
                        <option value="Balance">Balance Game</option>
                        <option value="Truth">Truth Game</option>
                    </select>
                </div>

                <div className="flex items-center gap-2">
                    <label className="text-sm font-semibold">Reason:</label>
                    <select
                        className="p-2 border rounded"
                        value={filterReason}
                        onChange={(e) => setFilterReason(e.target.value)}
                    >
                        <option value="All">All Reasons</option>
                        {distinctReasons.map(reason => (
                            <option key={reason as string} value={reason as string}>{reason as string}</option>
                        ))}
                    </select>
                </div>

                <div className="ml-auto text-sm text-gray-500">
                    Showing {filteredReports.length} / {reports.length} items
                </div>
            </div>

            {loading ? <p>Loading...</p> : (
                <div className="overflow-x-auto">
                    <table className="min-w-full bg-white border border-gray-200 shadow-sm rounded-lg">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="py-3 px-4 text-left border-b">Report ID</th>
                                <th className="py-3 px-4 text-left border-b w-1/6">Report Reason</th>
                                <th className="py-3 px-4 text-left border-b w-1/3">Question Content</th>
                                <th className="py-3 px-4 text-left border-b">Details (Editable)</th>
                                <th className="py-3 px-4 text-left border-b">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredReports.map((r) => {
                                const isEditing = editingId === r.id;
                                const q = r.question;

                                if (!q) return (
                                    <tr key={r.id} className="border-b text-gray-400">
                                        <td className="py-3 px-4">{r.id.slice(0, 8)}...</td>
                                        <td className="py-3 px-4">{r.reason}</td>
                                        <td colSpan={3} className="py-3 px-4">Question data not found (ID: {r.q_id})</td>
                                    </tr>
                                );

                                return (
                                    <tr key={r.id} className={`border-b ${isEditing ? 'bg-blue-50' : 'hover:bg-gray-50'}`}>
                                        <td className="py-3 px-4 text-sm font-mono text-gray-500">
                                            {r.created_at.slice(0, 10)}<br />
                                            {r.q_id}
                                        </td>
                                        <td className="py-3 px-4">
                                            <span className="font-bold text-red-600">{r.reason}</span>
                                            <p className="text-xs text-gray-500">{r.details}</p>
                                        </td>

                                        <td className="py-3 px-4">
                                            {isEditing ? (
                                                <div className="flex flex-col gap-2">
                                                    <label className="text-xs font-bold text-gray-700">Korean (Content)</label>
                                                    <textarea
                                                        className="border p-1 rounded w-full"
                                                        value={editForm.content}
                                                        onChange={e => setEditForm({ ...editForm, content: e.target.value })}
                                                    />
                                                    <label className="text-xs font-bold text-gray-700">English (Content En)</label>
                                                    <textarea
                                                        className="border p-1 rounded w-full"
                                                        value={editForm.content_en}
                                                        onChange={e => setEditForm({ ...editForm, content_en: e.target.value })}
                                                    />
                                                </div>
                                            ) : (
                                                <div>
                                                    <p className="font-bold text-gray-900">{q.content}</p>
                                                    <p className="text-gray-500 text-sm mt-1">{q.content_en}</p>
                                                </div>
                                            )}
                                        </td>

                                        <td className="py-3 px-4">
                                            {isEditing ? (
                                                <div className="flex flex-col gap-2">
                                                    {editForm.type === 'B' || editForm.type === 'balance' ? (
                                                        <>
                                                            <div className="grid grid-cols-2 gap-2">
                                                                <div>
                                                                    <label className="text-xs font-bold text-pink-600">Choice A</label>
                                                                    <input
                                                                        className="border p-1 rounded w-full"
                                                                        value={editForm.choice_a}
                                                                        onChange={e => setEditForm({ ...editForm, choice_a: e.target.value })}
                                                                    />
                                                                </div>
                                                                <div>
                                                                    <label className="text-xs font-bold text-blue-600">Choice B</label>
                                                                    <input
                                                                        className="border p-1 rounded w-full"
                                                                        value={editForm.choice_b}
                                                                        onChange={e => setEditForm({ ...editForm, choice_b: e.target.value })}
                                                                    />
                                                                </div>
                                                            </div>
                                                        </>
                                                    ) : (
                                                        <div>
                                                            <label className="text-xs font-bold text-green-600">Answers (Comma separated)</label>
                                                            <input
                                                                className="border p-1 rounded w-full"
                                                                value={editForm.answers}
                                                                onChange={e => setEditForm({ ...editForm, answers: e.target.value })}
                                                            />
                                                        </div>
                                                    )}
                                                </div>
                                            ) : (
                                                <div className="text-sm">
                                                    {(q.type === 'B' || q.type === 'balance') ? (
                                                        <ul className="list-disc list-inside">
                                                            <li><span className="text-pink-600 font-bold">A:</span> {q.details?.choice_a || q.details?.A}</li>
                                                            <li><span className="text-blue-600 font-bold">B:</span> {q.details?.choice_b || q.details?.B}</li>
                                                        </ul>
                                                    ) : (
                                                        <p><span className="text-green-600 font-bold">Ans:</span> {q.details?.answers}</p>
                                                    )}
                                                </div>
                                            )}
                                        </td>

                                        <td className="py-3 px-4">
                                            {isEditing ? (
                                                <div className="flex flex-col gap-2">
                                                    <button
                                                        onClick={handleSave}
                                                        className="bg-green-600 text-white px-3 py-1 rounded text-sm hover:bg-green-700"
                                                    >
                                                        Save
                                                    </button>
                                                    <button
                                                        onClick={() => setEditingId(null)}
                                                        className="bg-gray-400 text-white px-3 py-1 rounded text-sm hover:bg-gray-500"
                                                    >
                                                        Cancel
                                                    </button>
                                                </div>
                                            ) : (
                                                <button
                                                    onClick={() => handleEdit(r)}
                                                    className="bg-indigo-100 text-indigo-700 px-3 py-1 rounded text-sm hover:bg-indigo-200"
                                                >
                                                    Edit
                                                </button>
                                            )}
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
}
