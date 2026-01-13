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
        order = row.get('Order', '').strip()
        
        # Parse CodeNames
        # Input: "M-F-B-Ar-L2, M-F-Fa-*-L1"
        raw_codes = row.get('CodeName', '').split(',')
        code_names = [c.strip() for c in raw_codes if c.strip()]
        
        details = {}
        if quiz_type == 'Truth':
            details['answers'] = row.get('answers', '')
        elif quiz_type == 'Balance':
            details['choice_a'] = row.get('choice_a', '')
            details['choice_b'] = row.get('choice_b', '')
        
        details['order'] = order # Keep order in details if useful
        if q_id:
             details['legacy_q_id'] = q_id

        return {
            'q_id': q_id, 
            'type': quiz_type,
            'content': content,
            'details': details, # JSONB automatically handled by client usually, or dict
            'code_names': code_names
        }

if __name__ == "__main__":
    try:
        import supabase
    except ImportError:
        print("Supabase client not found. Please install it using: pip install supabase")
        exit(1)

    importer = SupabaseImporter(SUPABASE_URL, SUPABASE_KEY)

    # Import Truth Quiz
    importer.import_csv('doc/TruthQuizData.csv', 'Truth')
    
    # Import Balance Quiz
    importer.import_csv('doc/BalanceQuizData.csv', 'Balance') # Check filename availability

