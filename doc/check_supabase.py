import os
from supabase import create_client

url = "https://jmihbovtywtwqdjrmuey.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImptaWhib3Z0eXd0d3FkanJtdWV5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDIwMjYyMywiZXhwIjoyMDc5Nzc4NjIzfQ.muHLsU7qFBvv_gpzlh00AM7e8nJgki7CZYzOzG9Zg2A"

try:
    print(f"Connecting to {url}...")
    supabase = create_client(url, key)
    
    # Try to fetch one row from 'questions' table to verify access
    response = supabase.table('questions').select("*").limit(1).execute()
    print("Connection successful!")
    print(f"Data sample: {response.data}")
    
    # Optional: Count total questions
    count_response = supabase.table('questions').select("*", count='exact').execute()
    print(f"Total questions in DB: {count_response.count}")

except Exception as e:
    print(f"Connection failed: {e}")
