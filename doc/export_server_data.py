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

def main():
    env = load_env()
    url = env.get('SUPABASE_URL')
    # Use Service Role Key to ensure we get ALL data including any hidden rows
    key = env.get('SUPABASE_SERVICE_ROLE_KEY') or env.get('SUPABASE_ANON_KEY')

    if not url or not key:
        print("❌ Missing Supabase credentials in .env")
        return

    print(f"CONNECTING TO: {url}")
    supabase: Client = create_client(url, key)

    # Fetch all questions (limit 1000 for safety, though we know there are 582)
    response = supabase.table('questions').select('*').limit(1000).execute()
    data = response.data
    
    print(f"✅ FETCHED {len(data)} rows.")

    truth_rows = []
    balance_rows = []

    for row in data:
        q_type = row.get('type')
        content = row.get('content', '')
        q_id = row.get('legacy_q_id', '')
        
        # Details is JSON dict usually, but supabase-py might return it as dict directly
        details = row.get('details') or {}
        if isinstance(details, str):
            try:
                details = json.loads(details)
            except:
                details = {}
        
        # CodeNames
        code_names = row.get('code_names') or []
        code_name_str = ",".join(code_names) if isinstance(code_names, list) else str(code_names)

        # Order - seemingly wasn't stored in top level, maybe in details?
        # In import script: details['order'] = order
        order = details.get('order', '')

        if q_type == 'T':
            # Truth Structure: CodeName, Order, q_id, content, answers
            answers = details.get('answers', '')
            truth_rows.append({
                'CodeName': code_name_str,
                'Order': order,
                'q_id': q_id,
                'content': content,
                'answers': answers
            })
        elif q_type == 'B':
            # Balance Structure: CodeName, Order, q_id, content, choice_a, choice_b
            choice_a = details.get('choice_a', '')
            choice_b = details.get('choice_b', '')
            balance_rows.append({
                'CodeName': code_name_str,
                'Order': order,
                'q_id': q_id,
                'content': content,
                'choice_a': choice_a,
                'choice_b': choice_b
            })

    # Write Truth CSV
    if truth_rows:
        with open('doc/Restored_TruthQuizData.csv', 'w', newline='', encoding='utf-8') as f:
            fieldnames = ['CodeName', 'Order', 'q_id', 'content', 'answers']
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(truth_rows)
        print(f"🎉 Exported {len(truth_rows)} Truth questions to doc/Restored_TruthQuizData.csv")

    # Write Balance CSV
    if balance_rows:
        with open('doc/Restored_BalanceQuizData.csv', 'w', newline='', encoding='utf-8') as f:
            fieldnames = ['CodeName', 'Order', 'q_id', 'content', 'choice_a', 'choice_b']
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(balance_rows)
        print(f"🎉 Exported {len(balance_rows)} Balance questions to doc/Restored_BalanceQuizData.csv")

if __name__ == "__main__":
    main()
