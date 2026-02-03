-- ===========================================
-- TalkBingo Board & Report System Schema
-- ===========================================

-- 1. Inquiries Table (게시판/문의)
-- -------------------------------------------
create table if not exists public.inquiries (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete set null, -- Guest: null or anonymous id? For now nullable.
  category text not null, -- 'General', 'Bug', 'Feature', 'Payment', 'Account', 'Etc'
  title text not null,
  content text not null,
  is_private boolean default true,
  status text default 'submitted', -- 'submitted', 'in_progress', 'resolved'
  app_version text,
  device_info jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Enable RLS
alter table public.inquiries enable row level security;

-- Policies for Inquiries
-- Users can see their own inquiries
create policy "Users can view own inquiries"
  on public.inquiries for select
  using ( auth.uid() = user_id );

-- Users can insert their own inquiries
create policy "Users can insert own inquiries"
  on public.inquiries for insert
  with check ( auth.uid() = user_id );
  
-- (Optional) If we want public posts visible to everyone
-- create policy "Public inquiries are viewable by everyone"
--   on public.inquiries for select
--   using ( is_private = false );


-- 2. Inquiry Replies Table (관리자 답변/대댓글)
-- -------------------------------------------
create table if not exists public.inquiry_replies (
  id uuid default gen_random_uuid() primary key,
  inquiry_id uuid references public.inquiries(id) on delete cascade not null,
  admin_id uuid references auth.users(id), -- Nullable if system message
  content text not null,
  created_at timestamptz default now()
);

-- Enable RLS
alter table public.inquiry_replies enable row level security;

-- Policies for Replies
-- Users can view replies to THEIR OWN inquiries (Complex join policy)
create policy "Users can view replies to their inquiries"
  on public.inquiry_replies for select
  using (
    exists (
      select 1 from public.inquiries
      where inquiries.id = inquiry_replies.inquiry_id
      and inquiries.user_id = auth.uid()
    )
  );


-- 3. Reports Table (질문 신고 - Missing Table Fix)
-- -------------------------------------------
create table if not exists public.reports (
  id uuid default gen_random_uuid() primary key,
  q_id text not null, -- Question String ID (e.g., 'T-Fa-Md-L3-001')
  reporter_id uuid references auth.users(id) on delete set null,
  reason text not null, -- 'Typo', 'Weird', 'Other'
  details text,
  created_at timestamptz default now()
);

-- Enable RLS
alter table public.reports enable row level security;

-- Policies for Reports
-- Users can insert reports
create policy "Users can insert reports"
  on public.reports for insert
  with check ( auth.uid() = reporter_id );

-- Users usually don't need to see logic reports, but maybe their own?
create policy "Users can view own reports"
  on public.reports for select
  using ( auth.uid() = reporter_id );


-- ===========================================
-- Permissions (Grant access to authenticated users)
-- ===========================================
grant select, insert, update on public.inquiries to authenticated;
grant select on public.inquiry_replies to authenticated;
grant select, insert on public.reports to authenticated;

-- Grant to service_role (Admin) usually handled by Supabase default, 
-- but ensuring it for good measure is redundant in Supabase context.
