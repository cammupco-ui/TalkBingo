-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. ENUMS
CREATE TYPE user_role AS ENUM ('admin', 'user', 'guest');
CREATE TYPE gender_type AS ENUM ('M', 'F', 'O');
CREATE TYPE question_type AS ENUM ('Truth', 'Balance', 'Mini');
CREATE TYPE game_status AS ENUM ('waiting', 'playing', 'paused', 'finished');

-- 2. TABLES

-- Profiles (extends auth.users)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    nickname TEXT,
    -- age INT, -- Removed (Simplication)
    gender gender_type,
    -- hometown TEXT, -- Removed (Simplication)
    -- location TEXT, -- Removed (Simplication)
    role user_role DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Static Data Tables (Metadata)
CREATE TABLE public.relation_types (
    id SERIAL PRIMARY KEY,
    code TEXT UNIQUE NOT NULL, -- 'B', 'Fa', 'Lo'
    label TEXT NOT NULL,
    description TEXT
);

CREATE TABLE public.intimacy_levels (
    id SERIAL PRIMARY KEY,
    code TEXT UNIQUE NOT NULL, -- 'L1'...'L5'
    label TEXT NOT NULL,
    description TEXT
);

-- Questions Table
CREATE TABLE public.questions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    legacy_q_id TEXT, -- Original ID from CSV (e.g., T25-00001)
    type question_type NOT NULL,
    content TEXT NOT NULL, -- Korean (Default)
    content_en TEXT, -- English Translation
    details JSONB, -- Stores 'answers' (Truth) or 'choice_a'/'choice_b' (Balance) (Korean)
    details_en JSONB, -- English Options (e.g. choice_a_en)
    code_names TEXT[], -- Denormalized array of code strings for quick filtering
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Game Sessions
CREATE TABLE public.game_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    mp_id UUID REFERENCES public.profiles(id), -- Host
    cp_id UUID REFERENCES public.profiles(id), -- Guest
    status game_status DEFAULT 'waiting',
    invite_code TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Relationships (Friend/Family/Lover)
CREATE TABLE public.friend_relations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    mp_id UUID REFERENCES public.profiles(id) NOT NULL,
    cp_id UUID REFERENCES public.profiles(id) NOT NULL,
    relation_type_id INT REFERENCES public.relation_types(id),
    intimacy_level_id INT REFERENCES public.intimacy_levels(id),
    sub_relation_code TEXT, -- 'Ar', 'Sc', etc.
    trust_score FLOAT DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(mp_id, cp_id)
);

-- Logs (Game Activity)
CREATE TABLE public.logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    game_id UUID REFERENCES public.game_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id),
    action TEXT NOT NULL, -- 'select_question', 'answer', 'bingo'
    detail JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rewards/Results
CREATE TABLE public.rewards (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    game_id UUID REFERENCES public.game_sessions(id) ON DELETE CASCADE,
    vp INT DEFAULT 0, -- Victory Points
    ap INT DEFAULT 0, -- Activity Points
    ep INT DEFAULT 0, -- Experience Points
    ts FLOAT DEFAULT 0.0, -- Trust Score
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- MAPPING TABLES (For Normalized Querying)

-- Question <-> Intimacy
CREATE TABLE public.question_intimacy (
    question_id UUID REFERENCES public.questions(id) ON DELETE CASCADE,
    intimacy_level_id INT REFERENCES public.intimacy_levels(id) ON DELETE CASCADE,
    PRIMARY KEY (question_id, intimacy_level_id)
);

-- Question <-> RelationType
CREATE TABLE public.question_relations (
    question_id UUID REFERENCES public.questions(id) ON DELETE CASCADE,
    relation_type_id INT REFERENCES public.relation_types(id) ON DELETE CASCADE,
    PRIMARY KEY (question_id, relation_type_id)
);

-- Question <-> Gender Target
CREATE TABLE public.question_genders (
    question_id UUID REFERENCES public.questions(id) ON DELETE CASCADE,
    mp_gender gender_type,
    cp_gender gender_type,
    PRIMARY KEY (question_id, mp_gender, cp_gender)
);


-- 3. RLS POLICIES (Row Level Security)

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friend_relations ENABLE ROW LEVEL SECURITY;

-- Profiles: Public read, Self update
CREATE POLICY "Public profiles are viewable by everyone" 
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" 
ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Questions: Public read (authenticated), Admin write
CREATE POLICY "Authenticated users can view questions" 
ON public.questions FOR SELECT TO authenticated USING (true);

-- Game Sessions: Participants can view/update
CREATE POLICY "Participants can view their games" 
ON public.game_sessions FOR SELECT 
USING (auth.uid() = mp_id OR auth.uid() = cp_id);

CREATE POLICY "Host can create games" 
ON public.game_sessions FOR INSERT 
WITH CHECK (auth.uid() = mp_id);

CREATE POLICY "Participants can update games" 
ON public.game_sessions FOR UPDATE 
USING (auth.uid() = mp_id OR auth.uid() = cp_id);

-- 4. INDEXES
CREATE INDEX idx_questions_type ON public.questions(type);
CREATE INDEX idx_questions_codenames ON public.questions USING GIN (code_names);
CREATE INDEX idx_game_sessions_invite ON public.game_sessions(invite_code);
-- Function to generate CodeName based on User IDs
-- Usage: SELECT generate_codename('mp_uuid', 'cp_uuid');

CREATE OR REPLACE FUNCTION generate_codename(mp_uuid UUID, cp_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    mp_gender gender_type;
    cp_gender gender_type;
    rel_code TEXT;
    sub_rel TEXT;
    intimacy TEXT;
    codename TEXT;
BEGIN
    -- 1. Get Genders
    SELECT gender INTO mp_gender FROM profiles WHERE id = mp_uuid;
    SELECT gender INTO cp_gender FROM profiles WHERE id = cp_uuid;

    -- 2. Get Relationship Data
    SELECT 
        rt.code, 
        fr.sub_relation_code, 
        il.code
    INTO 
        rel_code, 
        sub_rel, 
        intimacy
    FROM 
        friend_relations fr
    JOIN 
        relation_types rt ON fr.relation_type_id = rt.id
    JOIN 
        intimacy_levels il ON fr.intimacy_level_id = il.id
    WHERE 
        fr.mp_id = mp_uuid AND fr.cp_id = cp_uuid;

    -- 3. Handle Missing Data (Fallback)
    IF mp_gender IS NULL OR cp_gender IS NULL OR rel_code IS NULL THEN
        RETURN NULL; -- Or default like 'M-F-B-*-L1'
    END IF;

    -- 4. Construct CodeName
    -- Format: [MP_Gender]-[CP_Gender]-[Relation]-[SubRel]-[Intimacy]
    codename := mp_gender || '-' || cp_gender || '-' || rel_code || '-' || COALESCE(sub_rel, '*') || '-' || intimacy;

    RETURN codename;
END;
$$ LANGUAGE plpgsql;
