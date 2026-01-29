import os
import csv
import json
from supabase import create_client, Client

# Configuration
# Read from environment variables
SUPABASE_URL = os.environ.get("NEXT_PUBLIC_SUPABASE_URL") or os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") # Prefer Service Role for admin tasks

if not SUPABASE_URL or not SUPABASE_KEY:
    print("Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in environment.")
    exit(1) 

class SupabaseImporter:
    def __init__(self, url, key):
        self.supabase: Client = create_client(url, key)

    def import_csv(self, file_path, quiz_type):
        if not os.path.exists(file_path):
            print(f"File not found: {file_path}")
            return

        with open(file_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            rows_to_insert = []
            
            for row in reader:
                data = self._prepare_row_data(row, quiz_type)
                if data:
                    rows_to_insert.append(data)
            
            if rows_to_insert:
                # Batch insert/upsert
                try:
                    # Using upsert with generic ID generation or mapping 'q_id' to legacy_id if needed
                    # Assuming table 'questions' exists with columns: 
                    # type, content, details (jsonb), code_names (text[]), legacy_q_id
                    
                    response = self.supabase.table('questions').upsert(rows_to_insert, on_conflict='q_id').execute()
                    print(f"Imported {len(response.data)} rows from {file_path}")
                except Exception as e:
                    print(f"Error inserting batch: {e}")

    def _prepare_row_data(self, row, quiz_type):
        q_id = row.get('q_id', '').strip()
        content = row.get('content', '').strip()
        content_en = row.get('content_en', '').strip()
        order = row.get('Order', '').strip()
        
        # Parse CodeNames
        raw_codes = row.get('CodeName', '').split(',')
        code_names = [c.strip() for c in raw_codes if c.strip()]
        
        details = {}
        details_en = {}
        
        if quiz_type == 'Truth':
            details['answers'] = row.get('answers', '')
            details_en['answers'] = row.get('answers_en', '')
        elif quiz_type == 'Balance':
            details['choice_a'] = row.get('choice_a', '')
            details['choice_b'] = row.get('choice_b', '')
            details_en['choice_a'] = row.get('choice_a_en', '')
            details_en['choice_b'] = row.get('choice_b_en', '')
        
        details['order'] = order 
        if q_id:
             details['legacy_q_id'] = q_id

        # Parse Gender Variants (Korean)
        gender_variants = {}
        for key in ['var_m_f', 'var_f_m', 'var_m_m', 'var_f_f']:
            val = row.get(key, '').strip()
            if val: gender_variants[key] = val

        # Parse Gender Variants (English)
        gender_variants_en = {}
        for key in ['var_m_f_en', 'var_f_m_en', 'var_m_m_en', 'var_f_f_en']:
            # Store with simplified keys (e.g., 'var_m_f') inside the EN object, or keep detailed keys?
            # Decision: Keep consistent logic. If app expects { "var_m_f": ... }, then details_en should mimic structure?
            # BUT GameSession.dart parses `gender_variants` column. It doesn't look for `gender_variants_en` column yet!
            # Wait, I proposed adding `gender_variants_en` column to DB.
            # So I should populate it here.
            # And keys inside should be `var_m_f` etc (without _en suffix) so the logic can be reused?
            # "key.replace('_en', '')" -> 'var_m_f'
            val = row.get(key, '').strip()
            if val: 
                clean_key = key.replace('_en', '')
                gender_variants_en[clean_key] = val

        return {
            'q_id': q_id, 
            'type': quiz_type.lower(),
            'content': content,
            'content_en': content_en,
            'details': details, 
            'details_en': details_en,
            'code_names': code_names,
            'gender_variants': gender_variants,
            'gender_variants_en': gender_variants_en
        }

if __name__ == "__main__":
    try:
        import supabase
    except ImportError:
        print("Supabase client not found. Please install it using: pip install supabase")
        exit(1)

    importer = SupabaseImporter(SUPABASE_URL, SUPABASE_KEY)

    # Import Truth Quiz
    importer.import_csv('doc/TruthQuizData_v2.csv', 'Truth')
    
    # Import Balance Quiz
    importer.import_csv('doc/BalanceQuizData_v2.csv', 'Balance')

