import os
from supabase import create_client
import json

url = "https://jmihbovtywtwqdjrmuey.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImptaWhib3Z0eXd0d3FkanJtdWV5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDIwMjYyMywiZXhwIjoyMDc5Nzc4NjIzfQ.muHLsU7qFBvv_gpzlh00AM7e8nJgki7CZYzOzG9Zg2A"

supabase = create_client(url, key)

q_id = 'B26-00378'
new_choice_a = "날씨 탓하며 수다"

try:
    res = supabase.table('questions').select('*').eq('q_id', q_id).execute()
    if res.data:
        current_details = res.data[0].get('details') or {}
        current_details['choice_a'] = new_choice_a
        
        supabase.table('questions').update({'details': current_details}).eq('q_id', q_id).execute()
        print(f"✅ Updated {q_id} choice_a to: {new_choice_a}")
    else:
        print("ID not found")
except Exception as e:
    print(f"Error: {e}")
