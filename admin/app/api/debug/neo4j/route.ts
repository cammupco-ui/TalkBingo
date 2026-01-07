import { NextResponse } from 'next/server';
import neo4j from 'neo4j-driver';

const NEO4J_URI = process.env.NEO4J_URI || 'bolt://localhost:7687';
const NEO4J_USER = process.env.NEO4J_USER || 'neo4j';
const NEO4J_PASSWORD = process.env.NEO4J_PASSWORD || 'password';

const driver = neo4j.driver(NEO4J_URI, neo4j.auth.basic(NEO4J_USER, NEO4J_PASSWORD));

export async function GET() {
    const session = driver.session();
    try {
        // Check Intimacy Levels
        const intimacyResult = await session.run(`MATCH (i:IntimacyLevel) RETURN i.code, count(i) as c`);
        const intimacyLevels = intimacyResult.records.map(r => r.get('i.code'));

        // Check Questions by Type
        const typeResult = await session.run(`
            MATCH (q:Question) 
            RETURN q.type as type, count(q) as count
        `);
        const types = typeResult.records.map(r => ({
            type: r.get('type'),
            count: r.get('count').toInt()
        }));

        // Check Relations for L3
        const l3Result = await session.run(`
            MATCH (q:Question)-[:TARGET_INTIMACY]->(i:IntimacyLevel {code: 'L3'})
            RETURN q.type as type, count(q) as count
        `);
        const l3Data = l3Result.records.map(r => ({
            type: r.get('type'),
            count: r.get('count').toInt()
        }));

        return NextResponse.json({
            intimacyLevels,
            overallKeyStats: types,
            l3Stats: l3Data
        });
    } catch (e: any) {
        return NextResponse.json({ error: e.message });
    } finally {
        await session.close();
    }
}
