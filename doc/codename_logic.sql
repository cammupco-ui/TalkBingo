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
