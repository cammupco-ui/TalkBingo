-- Function to migrate game history from an old User ID (Anonymous) to a new User ID (Authenticated)
-- Usage: Run this in the Supabase Dashboard -> SQL Editor

create or replace function migrate_user_history(old_id uuid, new_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  -- 1. Update Host ID (mp_id) in game_sessions
  -- (In case they were a host anonymously, though typically hosts start auth'd)
  update game_sessions
  set mp_id = new_id
  where mp_id = old_id;

  -- 2. Update Guest ID (cp_id) in game_sessions
  -- (This is the main case: claiming guest history)
  update game_sessions
  set cp_id = new_id
  where cp_id = old_id;
  
  -- Note: We do not merge 'profiles' rows here. 
  -- The app logic should handle creating the new profile entry if it doesn't exist.
end;
$$;

-- Function to securely charge VP (Victory Points)
-- Usage: Called by the app after successful payment verification
create or replace function charge_vp(amount int)
returns int
language plpgsql
security definer
as $$
declare
  new_total int;
begin
  -- Increment VP for the authenticated user
  update profiles
  set vp = coalesce(vp, 0) + amount
  where id = auth.uid()
  returning vp into new_total;
  
  return new_total;
end;
$$;
