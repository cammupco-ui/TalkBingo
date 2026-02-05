-- 1. Add new columns
ALTER TABLE public.questions 
ADD COLUMN IF NOT EXISTS choice_a text,
ADD COLUMN IF NOT EXISTS choice_b text,
ADD COLUMN IF NOT EXISTS answers text,
ADD COLUMN IF NOT EXISTS choice_a_en text,
ADD COLUMN IF NOT EXISTS choice_b_en text,
ADD COLUMN IF NOT EXISTS answers_en text;

-- 2. Migrate data from 'details' (Korean)
UPDATE public.questions
SET 
  choice_a = details->>'choice_a',
  choice_b = details->>'choice_b',
  answers = details->>'answers'
WHERE details IS NOT NULL;

-- 3. Migrate data from 'details_en' (English)
UPDATE public.questions
SET 
  choice_a_en = details_en->>'choice_a',
  choice_b_en = details_en->>'choice_b',
  answers_en = details_en->>'answers'
WHERE details_en IS NOT NULL;

-- 4. Handle legacy keys (A/B instead of choice_a/choice_b) if exist
UPDATE public.questions
SET choice_a = details->>'A'
WHERE choice_a IS NULL AND details->>'A' IS NOT NULL;

UPDATE public.questions
SET choice_b = details->>'B'
WHERE choice_b IS NULL AND details->>'B' IS NOT NULL;

-- 5. (Optional) Cleanup - We KEEP 'details' for now for backward compatibility or other metadata (like 'order')
-- But future updates should write to top-level columns.
