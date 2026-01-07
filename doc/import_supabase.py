import os
import csv
import json
from supabase import create_client, Client

# Configuration
# TODO: Enter your Supabase URL and Service Role Key (for writing data)
# Use Service Role Key to bypass RLS policies if needed, or ensuring your user has write access.
SUPABASE_URL = "https://your-project-id.supabase.co"
SUPABASE_KEY = "your-service-role-key" 

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
                    
                    response = self.supabase.table('questions').upsert(rows_to_insert).execute()
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

        return {
            'legacy_q_id': q_id,
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
    importer.import_csv('TruthQuizData.csv', 'Truth')
    
    # Import Balance Quiz
    importer.import_csv('BalanceQuizData.csv', 'Balance') # Check filename availability

