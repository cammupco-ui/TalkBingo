import os
import csv
from supabase import create_client, Client

def load_env():
    env_path = os.path.join(os.path.dirname(__file__), '../app/.env')
    env = {}
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            for line in f:
                if line.strip() and not line.startswith('#'):
                    parts = line.strip().split('=', 1)
                    if len(parts) == 2:
                        env[parts[0].strip()] = parts[1].strip()
    return env

def expand_code_name_str(code_str):
    """
    Ensure the code string in CSV is expanded.
    If it's already "..., L5", keeps it.
    If it's just "...-L2", expands it.
    """
    if 'L1' in code_str and 'L5' in code_str:
        return [c.strip() for c in code_str.split(',') if c.strip()]
    
    # Simple single expansion fallback (if CSV was NOT updated in previous run for some reason)
    # But we saw it WAS updated. So usually we just parse.
    codes = [c.strip() for c in code_str.split(',') if c.strip()]
    return codes

def cleanup_bad_rows(supabase):
    print("🧹 Cleaning up rows with empty q_id...")
    # Delete where q_id is empty string or null.
    # Note: Supabase/PostgREST syntax for 'is' null varies, but empty string is checkable.
    try:
        # Delete empty string q_id
        res = supabase.table('questions').delete().eq('q_id', '').execute()
        print(f"  -> Deleted {len(res.data)} rows with empty q_id.")
    except Exception as e:
        print(f"  ! Error cleaning empty strings: {e}")

    try:
        # Delete null q_id (if any)
        res = supabase.table('questions').delete().is_('q_id', 'null').execute()
        print(f"  -> Deleted {len(res.data)} rows with null q_id.")
    except Exception as e:
        print(f"  ! Error cleaning nulls: {e}")

def fix_file(csv_path, quiz_type, supabase):
    if not os.path.exists(csv_path):
        return

    print(f"\nProcessing {csv_path}...")
    updated_rows = []
    
    # Read entire file content first to fix header typo manually if needed
    with open(csv_path, 'r', encoding='utf-8') as f:
        content_txt = f.read()
    
    if '스CodeName' in content_txt:
        print("  ! Fixing header typo '스CodeName'...")
        content_txt = content_txt.replace('스CodeName', 'CodeName')
        
    # Re-parse as CSV
    from io import StringIO
    f = StringIO(content_txt)
    reader = csv.DictReader(f)
    fieldnames = reader.fieldnames
    
    if not fieldnames:
        print("  ! Empty file or invalid csv")
        return

    if 'CodeName' not in fieldnames and '스CodeName' in fieldnames:
         # Should have been fixed by string replace, but just in case
         fieldnames = ['CodeName' if x == '스CodeName' else x for x in fieldnames]

    if 'q_id' not in fieldnames:
        fieldnames.append('q_id')
        
    rows = list(reader)
    match_count = 0
    
    for row in rows:
        content = row.get('content', '').strip()
        
        # Find in Supabase by CONTENT
        try:
            # We select ID, Q_ID, and CODE_NAMES to be the SOURCE OF TRUTH
            res = supabase.table('questions').select('id, q_id, code_names').eq('content', content).eq('type', 'T' if quiz_type=='Truth' else 'B').execute()
            
            if res.data:
                # MATCH FOUND
                db_row = res.data[0]
                valid_qid = db_row.get('q_id')
                db_codes = db_row.get('code_names')
                
                # 1. Update CSV with Supabase Data (Source of Truth)
                row['q_id'] = valid_qid
                row['Order'] = valid_qid
                
                if db_codes and isinstance(db_codes, list):
                    # Join list back to string for CSV
                    row['CodeName'] = ",".join(db_codes)
                
                match_count += 1
            else:
                print(f"  [WARN] No match for content: {content[:20]}...")
                
        except Exception as e:
            print(f"  ! Error processing row: {e}")

        updated_rows.append(row)

    print(f"  -> Matched and synced {match_count} / {len(rows)} rows from Supabase.")
    
    # Save back
    with open(csv_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(updated_rows)

def main():
    env = load_env()
    url = env.get('SUPABASE_URL')
    key = env.get('SUPABASE_SERVICE_ROLE_KEY') or env.get('SUPABASE_ANON_KEY')
    
    if not url or not key:
        print("Missing Credentials")
        return
        
    supabase = create_client(url, key)
    
    cleanup_bad_rows(supabase)
    
    fix_file('doc/Restored_BalanceQuizData.csv', 'Balance', supabase)
    fix_file('doc/Restored_TruthQuizData.csv', 'Truth', supabase)
    
    print("\n✅ Integrity Fix Complete.")

if __name__ == "__main__":
    main()
