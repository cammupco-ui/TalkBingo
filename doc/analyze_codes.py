import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv(dotenv_path='app/.env')

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_ANON_KEY")

supabase: Client = create_client(url, key)

print("Fetching all CodeNames...")
res = supabase.table('questions').select('code_names').execute()

unique_parts = set()
for row in res.data:
    codes = row.get('code_names', [])
    if codes:
        for c in codes:
            parts = c.split('-')
            if len(parts) >= 3:
                unique_parts.add(parts[2]) # The Relationship Code (B, Fa, Lo?)

print(f"Unique Relationship Codes found in DB: {unique_parts}")

# Also check Gender parts
genders = set()
for row in res.data:
    codes = row.get('code_names', [])
    if codes:
        for c in codes:
            parts = c.split('-')
            if len(parts) >= 2:
                genders.add(f"{parts[0]}-{parts[1]}") # e.g. M-F

print(f"Unique Gender Pairs found in DB: {genders}")
