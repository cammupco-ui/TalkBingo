import os
from supabase import create_client
import json

url = "https://jmihbovtywtwqdjrmuey.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImptaWhib3Z0eXd0d3FkanJtdWV5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDIwMjYyMywiZXhwIjoyMDc5Nzc4NjIzfQ.muHLsU7qFBvv_gpzlh00AM7e8nJgki7CZYzOzG9Zg2A"

supabase = create_client(url, key)

res = supabase.table('questions').select('*').eq('q_id', 'B26-00378').execute()
if res.data:
    print(json.dumps(res.data[0], indent=2, ensure_ascii=False))
