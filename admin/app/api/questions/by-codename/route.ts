import { NextResponse } from 'next/server';
import neo4j from 'neo4j-driver';

const NEO4J_URI = process.env.NEO4J_URI || 'bolt://localhost:7687';
const NEO4J_USER = process.env.NEO4J_USER || 'neo4j';
const NEO4J_PASSWORD = process.env.NEO4J_PASSWORD || 'password';

const driver = neo4j.driver(NEO4J_URI, neo4j.auth.basic(NEO4J_USER, NEO4J_PASSWORD));

export async function GET(request: Request) {
    const { searchParams } = new URL(request.url);
    const codename = searchParams.get('codename');
    const limit = parseInt(searchParams.get('limit') || '50');

    if (!codename) {
        return NextResponse.json({ success: false, error: 'Codename is required' }, { status: 400 });
    }

    // Extract Intimacy Level from CodeName (e.g., "M-F-Fr-L3")
    // Format: MP-CP-Relation-SubRel-Intimacy
    const parts = codename.split('-');
    // Find the part that looks like 'L1' to 'L5'
    const targetIntimacy = parts.find(p => /^L[1-5]$/.test(p)) || 'L3';

    const session = driver.session();

    try {
        console.log(`Fetching questions for CodeName: ${codename} (Intimacy: ${targetIntimacy})`);

        const limitInt = parseInt(limit.toString());
        const balanceLimit = Math.ceil(limitInt / 2);
        const truthLimit = Math.floor(limitInt / 2);

        console.log(`Fetching ${balanceLimit} Balance and ${truthLimit} Truth questions for ${codename} (Intimacy: ${targetIntimacy})`);

        // 1. Fetch Balance Questions
        const balanceResult = await session.run(
            `
            MATCH (q:Question)-[:TARGET_INTIMACY]->(i:IntimacyLevel {code: $intimacy})
            WHERE toLower(q.type) CONTAINS 'balance'
            RETURN q
            ORDER BY rand()
            LIMIT $limit
            `,
            { intimacy: targetIntimacy, limit: neo4j.int(balanceLimit) }
        );

        // 2. Fetch Truth Questions
        const truthResult = await session.run(
            `
            MATCH (q:Question)-[:TARGET_INTIMACY]->(i:IntimacyLevel {code: $intimacy})
            WHERE toLower(q.type) CONTAINS 'truth' OR toLower(q.type) CONTAINS 'deep'
            RETURN q
            ORDER BY rand()
            LIMIT $limit
            `,
            { intimacy: targetIntimacy, limit: neo4j.int(truthLimit) }
        );

        const balanceQuestions = balanceResult.records.map(record => {
            const node = record.get('q').properties;
            return {
                q_id: node.q_id,
                content: node.content,
                type: 'balance',
                answers: node.answers || '',
                choice_a: node.choice_a || '',
                choice_b: node.choice_b || '',
                intimacy_level: targetIntimacy
            };
        });

        const truthQuestions = truthResult.records.map(record => {
            const node = record.get('q').properties;
            return {
                q_id: node.q_id,
                content: node.content,
                type: 'truth',
                answers: node.answers || '',
                choice_a: '', // Truth doesn't usually have choices, but safe to empty
                choice_b: '',
                intimacy_level: targetIntimacy
            };
        });

        // Combine and Shuffle
        const allQuestions = [...balanceQuestions, ...truthQuestions];

        // Fisher-Yates Shuffle
        for (let i = allQuestions.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [allQuestions[i], allQuestions[j]] = [allQuestions[j], allQuestions[i]];
        }

        console.log(`Found ${balanceQuestions.length} Balance + ${truthQuestions.length} Truth = ${allQuestions.length} Total.`);

        return NextResponse.json({
            success: true,
            codename: codename,
            data: {
                questions: allQuestions
            }
        }, {
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            }
        });
    } catch (error) {
        console.error('Neo4j Query Error:', error);
        return NextResponse.json(
            { success: false, error: 'Database query failed' },
            { status: 500, headers: { 'Access-Control-Allow-Origin': '*' } }
        );
    } finally {
        await session.close();
    }
}

export async function OPTIONS() {
    return NextResponse.json({}, {
        headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        }
    });
}
