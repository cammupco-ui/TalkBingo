-- ============================================
-- Supabase RPC: get_random_questions (v2)
-- 최신 질문 우선 추출 + 적절한 랜덤성 유지
-- Supabase SQL Editor에서 실행하세요
-- ============================================

-- 기존 함수가 있으면 삭제
DROP FUNCTION IF EXISTS get_random_questions(text[], text, int);

CREATE OR REPLACE FUNCTION get_random_questions(
  p_codes text[],           -- code_names 매칭 배열
  p_type_prefix text,       -- 'B' (밸런스) 또는 'T' (진실)
  p_limit int DEFAULT 40    -- 가져올 최대 개수
)
RETURNS SETOF questions
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT *
  FROM questions
  WHERE is_published = true
    AND code_names && p_codes                    -- 관계 코드 매칭 (overlap)
    AND q_id LIKE (p_type_prefix || '%')         -- 타입 필터 (B% 또는 T%)
  ORDER BY updated_at DESC NULLS LAST,           -- 최신 업데이트 질문 우선!
           created_at DESC NULLS LAST             -- updated_at 같으면 생성일 기준
  LIMIT p_limit;
$$;

-- 와일드카드 전용 함수 (범용 질문)
DROP FUNCTION IF EXISTS get_random_wildcard_questions(text, int);

CREATE OR REPLACE FUNCTION get_random_wildcard_questions(
  p_type_prefix text,       -- 'B' 또는 'T'
  p_limit int DEFAULT 20
)
RETURNS SETOF questions
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT *
  FROM questions
  WHERE is_published = true
    AND code_names @> ARRAY['*-*-*-*-*']::text[] -- 와일드카드 질문만
    AND q_id LIKE (p_type_prefix || '%')
  ORDER BY updated_at DESC NULLS LAST,           -- 최신 업데이트 질문 우선!
           created_at DESC NULLS LAST
  LIMIT p_limit;
$$;
