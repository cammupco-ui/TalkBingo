-- Enable RLS on tables
alter table profiles enable row level security;
alter table game_sessions enable row level security;
alter table questions enable row level security;

-- ==========================================
-- 1. PROFILES
-- ==========================================

-- View: Everyone can see profiles (needed for game partner info)
create policy "Public profiles are viewable by everyone"
on profiles for select
using ( true );

-- Insert: Users can insert their own profile
create policy "Users can insert their own profile"
on profiles for insert
with check ( auth.uid() = id );

-- Update: Users can update only their own profile
create policy "Users can update own profile"
on profiles for update
using ( auth.uid() = id );

-- ==========================================
-- 2. GAME SESSIONS
-- ==========================================

-- Select: Visible to Host (mp_id), Guest (cp_id), or ANYONE if slot is open (cp_id is null) for joining
create policy "Sessions viewable by participants or joiners"
on game_sessions for select
using ( 
  auth.uid() = mp_id 
  or auth.uid() = cp_id 
  or cp_id is null 
);

-- Insert: Authenticated users can create sessions (as Host)
create policy "Users can create sessions"
on game_sessions for insert
with check ( auth.uid() = mp_id );

-- Update (Host): Host can update their own session at any time
create policy "Host can update session"
on game_sessions for update
using ( auth.uid() = mp_id );

-- Update (Guest): Guest can 'Claim' an open slot (Join Game)
-- Only allow update if cp_id is currently NULL (open) and they are setting it to themselves
create policy "Guests can join open sessions"
on game_sessions for update
using ( cp_id is null ) 
with check ( cp_id = auth.uid() );

-- Update (Participant Guest): Guest can update session (e.g. game state) if they are already the guest
create policy "Guests can update active session"
on game_sessions for update
using ( auth.uid() = cp_id );

-- ==========================================
-- 3. QUESTIONS
-- ==========================================

-- Select: Everyone (Host/Guest) can read questions
create policy "Questions are viewable by everyone"
on questions for select
using ( true );

-- Insert/Update: Admin only (Service Role) - No public policies allowing modification
