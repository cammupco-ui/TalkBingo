import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv(dotenv_path='app/.env')

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_ANON_KEY")

if not url or not key:
    print("Error: Supabase URL or Key not found in app/.env")
    exit(1)

supabase: Client = create_client(url, key)

# Test Candidate Codes - Standard Pattern
candidates = [
    "F-F-B-Ar-L2",
    "F-F-B-*-L2",
    "F-F-B-Ar-*",
    "F-F-B-*-*"
]

print(f"Testing overlaps with candidates: {candidates}")

try:
    response = supabase.table('questions').select("*").overlaps('code_names', candidates).execute()
    
    print(f"Found {len(response.data)} matches.")
    
    if len(response.data) > 0:
        print("First match sample:")
        print(f"  ID: {response.data[0].get('q_id')}")
        print(f"  Content: {response.data[0].get('content')}")
        print(f"  CodeNames: {response.data[0].get('code_names')}")
    else:
        print("❌ No matches found! The DB might have empty code_names or format mismatch.")
        
    # Check what IS in the DB for a few rows
    print("\n--- DB Sample Check ---")
    sample = supabase.table('questions').select("code_names").limit(5).execute()
    for row in sample.data:
        print(f"  {row['code_names']}")

except Exception as e:
    print(f"Error querying Supabase: {e}")
