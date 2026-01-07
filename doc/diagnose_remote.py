import os
import asyncio
from supabase import create_client, Client

# Manual .env loader since python-dotenv might not be installed
def load_env():
    env_path = os.path.join(os.path.dirname(__file__), '../app/.env')
    if not os.path.exists(env_path):
        print(f"❌ .env file not found at: {env_path}")
        return {}
    
    env = {}
    with open(env_path, 'r') as f:
        for line in f:
            if line.strip() and not line.startswith('#'):
                parts = line.strip().split('=', 1)
                if len(parts) == 2:
                    env[parts[0].strip()] = parts[1].strip()
    return env

async def main():
    env = load_env()
    url = env.get('SUPABASE_URL')
    anon_key = env.get('SUPABASE_ANON_KEY')
    service_key = env.get('SUPABASE_SERVICE_ROLE_KEY')

    if not url or not anon_key:
        print("❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env")
        return

    print(f"🔍 Checking Supabase project: {url}")

    # 1. Check with Anon Key (what the app sees)
    print("\n--- [1] Checking with ANON_KEY (User View) ---")
    try:
        anon_client: Client = create_client(url, anon_key)
        # Try to count rows
        response = anon_client.table('questions').select('*', count='exact').execute()
        print(f"✅ Data Count: {len(response.data)} rows visible via Anon Key")
    except Exception as e:
        print(f"❌ Anon Key Error: {e}")

    # 2. Check with Service Role Key (Admin View)
    print("\n--- [2] Checking with SERVICE_ROLE_KEY (Admin View) ---")
    if not service_key:
        print("⚠️  SKIPPING: SUPABASE_SERVICE_ROLE_KEY not found in .env")
        print("   -> Please add it to check for hidden data.")
    else:
        try:
            # Service role bypasses RLS
            admin_client: Client = create_client(url, service_key)
            response = admin_client.table('questions').select('*', count='exact').execute()
            count = len(response.data)
            print(f"✅ Data Count: {count} rows visible via Service Role Key")
            
            if count > 0:
                print(f"🎉 FOUND {count} QUESTIONS! They are hidden from the app due to RLS policies.")
            else:
                print("❌ Count is 0 even with Admin Key. Data might be permanently deleted.")
                
        except Exception as e:
            print(f"❌ Service Key Error: {e}")

if __name__ == '__main__':
    # Check if asyncio run is needed or standard sync
    # supabase-py recent versions are sync by default but support async. 
    # Let's use standard sync for simplicity if library allows, but import implies sync usage usually.
    # Re-writing for standard sync usage based on typical python usage
    
    env = load_env()
    url = env.get('SUPABASE_URL')
    anon_key = env.get('SUPABASE_ANON_KEY')
    service_key = env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    if not url:
        print("Error: URL not found")
        exit(1)

    print(f"Target: {url}")
    
    # Anon
    try:
        client = create_client(url, anon_key)
        
        # FETCH SAMPLE DATA WITH CODE NAMES
        print("\n--- CHECKING CODE NAMES (First 5 Rows) ---")
        data_res = client.table('questions').select('q_id, code_names').limit(5).execute()
        
        if not data_res.data:
            print("No data found.")
        
        for row in data_res.data:
            print(f"ID: {row.get('q_id')} | CodeNames: {row.get('code_names')}")

    except Exception as e:
        print(f"Error: {e}")

    except Exception as e:
        print(f"Anon Error: {e}")

    # Admin
    if service_key:
        try:
            admin = create_client(url, service_key)
            res = admin.table('questions').select('id', count='exact', head=True).execute()
            print(f"\nAdmin (Real) View Count: {res.count}")
        except Exception as e:
            print(f"Admin Error: {e}")
    else:
        print("\n>>> Need Service Key to check hidden data.")
        # Debug env
        print(f"Loaded Env Keys: {list(env.keys())}")
