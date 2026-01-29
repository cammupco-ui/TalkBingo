import os
import csv
import json
from supabase import create_client, Client

# --- Configuration ---
ENV_FILE_PATH = os.path.join(os.path.dirname(__file__), '../app/assets/env_config')

def load_env():
    """Manually load environment variables from app/assets/env_config"""
    env = {}
    if os.path.exists(ENV_FILE_PATH):
        with open(ENV_FILE_PATH, 'r') as f:
            for line in f:
                if line.strip() and not line.startswith('#'):
                    parts = line.strip().split('=', 1)
                    if len(parts) == 2:
                        env[parts[0].strip()] = parts[1].strip()
    return env

def expand_code_name(code_str):
    """
    Takes a single code like 'F-F-B-Ar-L2' and returns a list of codes
    with L1 to L5: ['F-F-B-Ar-L1', 'F-F-B-Ar-L2', ...]
    It also keeps existing comma-separated codes if they don't look like they need expansion.
    """
    if not code_str:
        return []
    
    initial_codes = [c.strip() for c in code_str.split(',') if c.strip()]
    final_codes = []

    for code in initial_codes:
        parts = code.split('-')
        # Check format similar to MP-CP-Rel-Sub-Lvl (e.g., 5 parts)
        # And specifically if the last part is 'L' followed by a digit.
        # But wait, the standard is usually MP-CP-Rel-Topic-Lvl (5 parts).
        # Let's be safe: if it ends with 'L[digit]', we assume it *might* be expandable,
        # BUT the logic in `fix_and_import.py` was unconditionally expanding for some reason?
        # Actually, the user requirement for `fix_and_import.py` (previous context) was to fix missing L1-L5.
        # Here, the CSV seems to have explicit codes.
        # Let's look at the CSV content provided in step 8.
        # Line 2: *-*-*-*-*,*-*-*-00001
        # Line 256: *-*-B-Ar-L3,B-Ar-L3-00255
        # It seems some rows have specific levels.
        # If I look at the previous `fix_and_import.py`, it was likely doing something specific for a repair task.
        # For THIS task, I should probably trust the CSV content mostly, OR double check if expansion is desired.
        # The user request is "replace with these data".
        # The CSV `doc/BalanceQuizData_20280128.csv` col 1 is `CodeName`.
        # Example line 254: `*-*-B-Ar-L3,B-Ar-L3-00253` -> This row has multiple codes.
        # So I should just split by comma and strip. No auto-expansion unless explicitly requested previously.
        # The previous conversation context mentions "expanding L1-L5" for some reason, but let's stick to the data provided.
        # Wait, line 254 `*-*-B-Ar-L3` looks like a wild card? No, '*-*-B-Ar-L3' is just a code.
        # Let's just parse the comma separated list.
        final_codes.append(code)

    return final_codes

def prepare_row_data(row, quiz_type):
    # Map CSV fields to DB schema
    
    # 1. q_id
    q_id = row.get('q_id', '').strip()
    if not q_id:
        # Fallback or skip? Ideally every row needs a q_id.
        return None

    # 2. Content
    content = row.get('content', '').strip()
    content_en = row.get('content_en', '').strip()
    
    # 3. Details (JSONB)
    details = {}
    details_en = {} # We'll put English details here if needed, or structured differently?
    # Schema check: usually 'details' contains answers/choices.
    # We can put english choices in 'details_en' key inside 'details' column? 
    # OR the table has a separate column? `import_supabase.py` suggests `questions` table has jsonb `details`.
    # And it puts `details_en` as a separate payload key... does the table have `details_en` column?
    # Looking at `import_supabase.py`: 
    # payload = { 'details': details, 'details_en': details_en, ... }
    # So likely yes, `details` and `details_en` are separate columns or structure mappings.
    # Let's follow `import_supabase.py` structure.
    
    if quiz_type == 'Truth':
        details['answers'] = row.get('answers', '')
        details_en['answers'] = row.get('answers_en', '')
    elif quiz_type == 'Balance':
        details['choice_a'] = row.get('choice_a', '')
        details['choice_b'] = row.get('choice_b', '')
        details_en['choice_a'] = row.get('choice_a_en', '')
        details_en['choice_b'] = row.get('choice_b_en', '')
    
    # Add Order to details
    details['order'] = row.get('Order', '').strip()

    # 4. Code Names (Text Array)
    raw_codes = row.get('CodeName', '').split(',')
    # Clean up codes
    code_names = [c.strip() for c in raw_codes if c.strip()]
    
    
    # 5. Type (Legacy/Simple 'B' or 'T')
    q_type = 'B' if quiz_type == 'Balance' else 'T'

    return {
        'q_id': q_id,
        'type': q_type,
        'content': content,
        'content_en': content_en,
        'details': details,
        'details_en': details_en,
        'code_names': code_names,
        # 'gender_variants': ... # If CSV has them, add them.
        # checking CSV header: 
        # Balance: CodeName,Order,q_id,content,choice_a,choice_b,content_en,choice_a_en,choice_b_en
        # Truth: CodeName,Order,q_id,content,answers,content_en,answers_en
        # No gender variants in these visible headers.
    }

def process_file(file_path, quiz_type, supabase):
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    print(f"Reading {file_path}...")
    rows_to_insert = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            data = prepare_row_data(row, quiz_type)
            if data:
                rows_to_insert.append(data)
    
    if not rows_to_insert:
        print("No data found to insert.")
        return

    print(f"Found {len(rows_to_insert)} rows to insert.")

    # Batch insert
    batch_size = 100
    total_inserted = 0
    
    for i in range(0, len(rows_to_insert), batch_size):
        batch = rows_to_insert[i:i+batch_size]
        try:
            # We assume q_id is the unique key. 
            # Since we cleared the data beforehand, simple insert might work, 
            # but upsert is safer if there are dupes in CSV (though there shouldn't be).
            response = supabase.table('questions').upsert(batch, on_conflict='q_id').execute()
            # Note: supbase-py v2 returns an object with .data, .count etc.
            # Depending on version `execute()` might return `APIResponse`.
            total_inserted += len(response.data) if response.data else 0
        except Exception as e:
            print(f"Error inserting batch {i}: {e}")

    print(f"Imported {total_inserted} {quiz_type} questions.")


def main():
    # 1. Load Config
    env = load_env()
    url = env.get('SUPABASE_URL')
    key = env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    if not url or not key:
        print("Error: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in app/assets/env_config")
        return

    # 2. Connect
    supabase: Client = create_client(url, key)
    print("Connected to Supabase.")

    # 3. Delete existing B and T data
    print("Deleting existing Balance (B) and Truth (T) questions...")
    try:
        # Delete type = 'B'
        res_b = supabase.table('questions').delete().eq('type', 'B').execute()
        count_b = len(res_b.data) if res_b.data else 0
        print(f"Deleted {count_b} Balance questions.")

        # Delete type = 'T'
        res_t = supabase.table('questions').delete().eq('type', 'T').execute()
        count_t = len(res_t.data) if res_t.data else 0
        print(f"Deleted {count_t} Truth questions.")
        
    except Exception as e:
        print(f"Error deleting existing data: {e}")
        # Proceed or stop? If delete fails, insert might duplicate if we rely on upsert?
        # But user wants "Empty and Fill".
        # If delete fails, we should probably stop to avoid mixed data state if possible.
        # But upsert on q_id will replace.
        # However, old IDs that are NOT in new CSV will remain if delete fails.
        # Let's warn and continue? Or exit?
        # Safer to exit.
        print("Aborting migration due to delete failure.")
        return

    # 4. Import New Data
    # Balance
    process_file('doc/BalanceQuizData_20280128.csv', 'Balance', supabase)
    
    # Truth
    process_file('doc/TruthQuizData_20260128.csv', 'Truth', supabase)

    print("\nMigration completed successfully.")

if __name__ == "__main__":
    main()
