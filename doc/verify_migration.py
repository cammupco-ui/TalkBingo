import os
from supabase import create_client, Client

# --- Configuration ---
ENV_FILE_PATH = os.path.join(os.path.dirname(__file__), '../app/assets/env_config')

def load_env():
    env = {}
    if os.path.exists(ENV_FILE_PATH):
        with open(ENV_FILE_PATH, 'r') as f:
            for line in f:
                if line.strip() and not line.startswith('#'):
                    parts = line.strip().split('=', 1)
                    if len(parts) == 2:
                        env[parts[0].strip()] = parts[1].strip()
    return env

def main():
    env = load_env()
    url = env.get('SUPABASE_URL')
    key = env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    if not url or not key:
        print("Error: Config missing")
        return

    supabase: Client = create_client(url, key)
    
    # Count Balance
    res_b = supabase.table('questions').select('*', count='exact').eq('type', 'B').execute()
    print(f"Balance Questions (type='B'): {res_b.count}")

    # Count Truth
    res_t = supabase.table('questions').select('*', count='exact').eq('type', 'T').execute()
    print(f"Truth Questions (type='T'): {res_t.count}")

if __name__ == "__main__":
    main()
