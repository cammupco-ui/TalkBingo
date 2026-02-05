import os
from supabase import create_client
import json

# Configuration
url = "https://jmihbovtywtwqdjrmuey.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImptaWhib3Z0eXd0d3FkanJtdWV5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDIwMjYyMywiZXhwIjoyMDc5Nzc4NjIzfQ.muHLsU7qFBvv_gpzlh00AM7e8nJgki7CZYzOzG9Zg2A"

supabase = create_client(url, key)

# Define updates based on approved plan
# Each item: {'id': 'q_id', 'updates': { 'column': 'value', 'details_update': {'key': 'val'} }}
# Note: For details, we need to fetch, merge, and update, OR use JSONB update if supported cleanly.
# Safest is to fetch, update dict, and push back.

updates_list = [
    # 1. English Questions
    {'id': 'T26-00362', 'content_en': "Found a passage resonating with your life while transcribing?"},
    {'id': 'B26-00116', 'content_en': "Is it true that persistence always pays off in romance?"},
    {'id': 'T26-00361', 'content_en': "Most embarrassing attempt to look 'intellectual' with books?"},
    {'id': 'B26-00125', 'content_en': "Reaction to finding your past self's cringe moment in 10 years?"},
    {'id': 'B26-00119', 'content_en': "How do you handle a friend you don't vibe with?"},
    {'id': 'B26-00421', 'content_en': "Is it okay for my partner to drink alone with my friend?"},
    {'id': 'T26-00393', 'content_en': "Best dessert/drink to clear the grease after a holiday meal?"},
    {'id': 'T26-00360', 'content_en': "Good promise to make for a long-distance relationship?"},

    # 2. Balance Choices (Korean) - Updating 'details' column
    {'id': 'B26-00337', 'choice_update': {'choice_a': "길에서 본 SNS 친구"}},
    {'id': 'B26-00343', 'choice_update': {'choice_a': "조별 과제로 첫 대화"}},
    {'id': 'B26-00344', 'choice_update': {'choice_a': "거실에서 다함께 과일"}},
    {'id': 'B26-00346', 'choice_update': {'choice_a': "자녀 안부 묻는 어른들"}},
    {'id': 'B26-00351', 'choice_update': {'choice_a': "장례식장에서의 안부"}},
    {'id': 'B26-00358', 'choice_update': {'choice_a': "밤샘 카톡 중 끊김"}},
    {'id': 'B26-00335', 'choice_update': {'choice_a': "동창회의 어색한 재회"}},
    {'id': 'B26-00348', 'choice_update': {'choice_a': "어른 몰래 우리끼리"}},
    {'id': 'B26-00336', 'choice_update': {'choice_a': "결혼식장에서의 조우"}},
    {'id': 'B26-00350', 'choice_update': {'choice_a': "결혼식장 친지 만남"}},
    {'id': 'B26-00357', 'choice_update': {'choice_a': "공통 관심사 찾기"}},
    {'id': 'B26-00364', 'choice_update': {'choice_a': "퇴근 시간 맞춤 카톡"}},
    {'id': 'B26-00333', 'choice_update': {'choice_a': "목소리로 걱정하는 애인"}},
    {'id': 'B26-00341', 'choice_update': {'choice_a': "새 학기 어색한 소개"}},
    {'id': 'B26-00345', 'choice_update': {'choice_a': "명절 음식 준비 중"}},
    {'id': 'B26-00347', 'choice_update': {'choice_a': "SNS 사촌과의 만남"}},
    {'id': 'B26-00349', 'choice_update': {'choice_a': "달라진 서로의 모습"}},
    {'id': 'B26-00355', 'choice_update': {'choice_a': "첫인상 얘기한 뒤"}},
    {'id': 'B26-00359', 'choice_update': {'choice_a': "스토리 보고 연락"}},
    {'id': 'B26-00363', 'choice_update': {'choice_a': "번호 교환 다음 날"}},
]

def apply_updates():
    print(f"Applying {len(updates_list)} updates...")
    
    for item in updates_list:
        q_id = item['id']
        
        try:
            # 1. Fetch current data to preserve other fields in 'details'
            res = supabase.table('questions').select('*').eq('q_id', q_id).execute()
            if not res.data:
                print(f"❌ ID not found: {q_id}")
                continue
            
            current_row = res.data[0]
            update_payload = {}
            
            # Handle Content En update
            if 'content_en' in item:
                update_payload['content_en'] = item['content_en']
                
            # Handle Choice update (details JSONB)
            if 'choice_update' in item:
                current_details = current_row.get('details') or {}
                # Update specific keys
                for k, v in item['choice_update'].items():
                    current_details[k] = v
                update_payload['details'] = current_details
            
            if update_payload:
                update_res = supabase.table('questions').update(update_payload).eq('q_id', q_id).execute()
                print(f"✅ Updated {q_id}: {list(update_payload.keys())}")
            else:
                print(f"⚠️ No changes for {q_id}")
                
        except Exception as e:
            print(f"❌ Error updating {q_id}: {e}")

if __name__ == "__main__":
    apply_updates()
