import { NextResponse } from 'next/server';
import neo4j from 'neo4j-driver';

const NEO4J_URI = process.env.NEO4J_URI || 'bolt://localhost:7687';
const NEO4J_USER = process.env.NEO4J_USER || 'neo4j';
const NEO4J_PASSWORD = process.env.NEO4J_PASSWORD || 'password';

const driver = neo4j.driver(NEO4J_URI, neo4j.auth.basic(NEO4J_USER, NEO4J_PASSWORD));

export async function POST(request: Request) {
    const body = await request.json();
    const { email, nickname, age, gender, hometown, consent } = body;

    // Basic Validation
    if (!nickname || !age || !gender || !hometown) {
        return NextResponse.json(
            { success: false, error: 'Missing required fields' },
            { status: 400 }
        );
    }

    const session = driver.session();

    try {
        // Merge User (Create or Update based on Nickname/Email if provided)
        // Ideally use Email or UserID from Auth, but using Nickname for MVP Demo if no ID
        // Assuming Email is unique identifier
        const identifier = email || `anon_${Date.now()}`;

        const result = await session.run(
            `
            MERGE (u:User {email: $email})
            ON CREATE SET 
                u.created_at = datetime(),
                u.nickname = $nickname,
                u.age = $age,
                u.gender = $gender,
                u.hometown_province = $province,
                u.hometown_city = $city,
                u.consent = $consent,
                u.role = 'MP'
            ON MATCH SET
                u.updated_at = datetime(),
                u.nickname = $nickname,
                u.age = $age,
                u.gender = $gender,
                u.hometown_province = $province,
                u.hometown_city = $city,
                u.consent = $consent,
                u.role = 'MP'
            RETURN u
            `,
            {
                email: identifier,
                nickname: nickname,
                age: age,
                gender: gender,
                province: hometown.province,
                city: hometown.city,
                consent: consent
            }
        );

        const savedUser = result.records[0].get('u').properties;

        return NextResponse.json({
            success: true,
            message: 'Host Info Saved to Neo4j',
            data: {
                user: savedUser,
                userId: identifier
            }
        });

    } catch (error) {
        console.error('Neo4j Save Error:', error);
        return NextResponse.json(
            { success: false, error: 'Database Error' },
            { status: 500 }
        );
    } finally {
        await session.close();
    }
}

export async function OPTIONS() {
    return NextResponse.json({}, {
        headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        }
    });
}
