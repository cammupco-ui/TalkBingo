import os
import csv
import json
from supabase import create_client, Client

# Manual .env loader
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

def expand_code_name(code_str):
    """
    Takes a single code like 'F-F-B-Ar-L2' and returns a list of codes
    with L1 to L5: ['F-F-B-Ar-L1', 'F-F-B-Ar-L2', ...]
    """
    if not code_str:
        return []
    
    # Handle if already multiple
    codes = [c.strip() for c in code_str.split(',') if c.strip()]
    if not codes:
        return []

    base_code = codes[0] # Assume the first one is the template like ...-L2
    parts = base_code.split('-')
    
    # Check format MP-CP-Rel-Sub-Lvl
    if len(parts) < 5:
        # unexpected format, just return original
        return codes
    
    # Reconstruct base without Level (last part)
    # Actually identifying the level part might be tricky if content varies, 
    # but based on rules it is the last part.
    
    # Explicitly check if last part is L something
    if not parts[-1].startswith('L'):
        return codes

    prefix = "-".join(parts[:-1]) # 'F-F-B-Ar'
    
    expanded = []
    for i in range(1, 6):
        expanded.append(f"{prefix}-L{i}")
        
    return expanded

def process_file(csv_path, quiz_type, supabase):
    if not os.path.exists(csv_path):
        print(f"Skipping {csv_path} (Not found)")
        return

    print(f"Processing {csv_path}...")
    
    rows_to_upload = []
    updated_csv_rows = []
    fieldnames = []

    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        
        for row in reader:
            # 1. Expand CodeName
            original_code = row.get('CodeName', '')
            expanded_codes = expand_code_name(original_code)
            
            # Update row for CSV backup
            row['CodeName'] = ",".join(expanded_codes)
            updated_csv_rows.append(row)

            # 2. Prepare payload for Supabase
            q_id = row.get('q_id', '').strip()
            # If q_id is missing, use Order? Or skip? The restored data has q_id.
            
            content = row.get('content', '').strip()
            
            details = {}
            if quiz_type == 'Truth':
                details['answers'] = row.get('answers', '')
            elif quiz_type == 'Balance':
                details['choice_a'] = row.get('choice_a', '')
                details['choice_b'] = row.get('choice_b', '')
            
            # Add other details if present in CSV?
            # Start interaction logic uses 'game_code' sometimes? 
            # For now standard details.
            
            # Order
            order = row.get('Order', '').strip()
            details['order'] = order

            payload = {
                'q_id': q_id,
                'type': 'T' if quiz_type == 'Truth' else 'B',
                'content': content,
                'details': details,
                'code_names': expanded_codes,
                # 'ui_config': {} # Optional
            }
            
            rows_to_upload.append(payload)

    # 3. Upload to Supabase
    print(f"  > Uploading {len(rows_to_upload)} rows to Supabase...")
    
    count_updated = 0
    count_inserted = 0
    
    # Batch process to avoid massive payload
    batch_size = 50
    for i in range(0, len(rows_to_upload), batch_size):
        batch = rows_to_upload[i:i+batch_size]
        
        try:
             # UPSERT on 'q_id'
             response = supabase.table('questions').upsert(
                 batch, 
                 on_conflict='q_id'
             ).execute()
             count_updated += len(response.data)
        except Exception as e:
            print(f"  ! Error batch {i}: {e}")
            print("  ! Falling back to individual update...")
            for item in batch:
                lid = item['q_id']
                try:
                    # Find ID
                    chk = supabase.table('questions').select('id').eq('q_id', lid).execute()
                    if chk.data:
                        uid = chk.data[0]['id']
                        supabase.table('questions').update(item).eq('id', uid).execute()
                        count_updated += 1
                    else:
                        # Insert
                        supabase.table('questions').insert(item).execute()
                        count_inserted += 1
                except Exception as inner_e:
                    print(f"    x Failed item {lid}: {inner_e}")

    print(f"  > Done. Updated/Inserted: {count_updated + count_inserted}")

    # 4. Save Backup CSV
    print(f"  > Saving backup to {csv_path}...")
    with open(csv_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(updated_csv_rows)


def main():
    env = load_env()
    url = env.get('SUPABASE_URL')
    key = env.get('SUPABASE_SERVICE_ROLE_KEY') or env.get('SUPABASE_ANON_KEY')

    if not url or not key:
        print("❌ Missing Supabase credentials")
        return

    supabase: Client = create_client(url, key)

    # Process Balance
    process_file('doc/Restored_BalanceQuizData.csv', 'Balance', supabase)
    
    # Process Truth
    process_file('doc/Restored_TruthQuizData.csv', 'Truth', supabase)
    
    print("\n✅ All operations completed.")

if __name__ == "__main__":
    main()
