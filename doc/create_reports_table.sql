-- Create Reports Table
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    q_id TEXT NOT NULL,
    reporter_id UUID REFERENCES auth.users(id),
    reason TEXT NOT NULL,
    details TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS Policy (Enable Insert for Authenticated/Anon Users)
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable insert for all users" ON public.reports
    FOR INSERT 
    WITH CHECK (true);

CREATE POLICY "Enable read for service role only" ON public.reports
    FOR SELECT
    USING (auth.role() = 'service_role');
