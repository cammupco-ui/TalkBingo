import { NextResponse } from 'next/server';
import neo4j from 'neo4j-driver';

const NEO4J_URI = process.env.NEO4J_URI || 'bolt://localhost:7687';
const NEO4J_USER = process.env.NEO4J_USER || 'neo4j';
const NEO4J_PASSWORD = process.env.NEO4J_PASSWORD || 'password';

const driver = neo4j.driver(NEO4J_URI, neo4j.auth.basic(NEO4J_USER, NEO4J_PASSWORD));

export async function GET() {
    const session = driver.session();
    try {
        // Move ALL Balance questions from L1 to L2
        // Assumption: Current L1 Balance questions are the ones we want to move.
        // Also ensure L2 node exists.

        await session.run(`MERGE (:IntimacyLevel {code: 'L2'})`);

        const result = await session.run(`
            MATCH (q:Question)-[r:TARGET_INTIMACY]->(old:IntimacyLevel {code: 'L1'})
            WHERE toLower(q.type) CONTAINS 'balance'
            MATCH (new:IntimacyLevel {code: 'L2'})
            DELETE r
            MERGE (q)-[:TARGET_INTIMACY]->(new)
            RETURN count(q) as moved_count
        `);

        const count = result.records[0].get('moved_count').toInt();

        return NextResponse.json({
            success: true,
            moved_count: count,
            message: `Moved ${count} Balance questions from L1 to L2`
        });
    } catch (e: any) {
        return NextResponse.json({ error: e.message });
    } finally {
        await session.close();
    }
}
