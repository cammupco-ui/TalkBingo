import os
from supabase import create_client

# Use the credentials we found
url = "https://jmihbovtywtwqdjrmuey.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImptaWhib3Z0eXd0d3FkanJtdWV5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDIwMjYyMywiZXhwIjoyMDc5Nzc4NjIzfQ.muHLsU7qFBvv_gpzlh00AM7e8nJgki7CZYzOzG9Zg2A"

supabase = create_client(url, key)

def get_length(text):
    if not text: return 0
    return len(text)

def analyze():
    print("Fetching all questions...")
    # Fetch all - might need pagination if > 1000, supabase limit is usually 1000
    all_questions = []
    
    # Simple pagination
    batch_size = 1000
    start = 0
    while True:
        response = supabase.table('questions').select("*").range(start, start + batch_size - 1).execute()
        batch = response.data
        if not batch:
            break
        all_questions.extend(batch)
        if len(batch) < batch_size:
            break
        start += batch_size
        
    print(f"Total questions fetched: {len(all_questions)}")
    
    long_korean = []
    long_english = []
    long_choices = [] # For Balance type
    
    # Thresholds (Assumed, can be adjusted)
    LIMIT_KO = 45 # Korean usually denser, 45 chars is ~2 lines on mobile
    LIMIT_EN = 80 # English ~ 80 chars
    LIMIT_CHOICE = 15 # Choices should be short
    
    for q in all_questions:
        q_id = q.get('q_id', 'UNKNOWN')
        content = q.get('content', '')
        content_en = q.get('content_en', '')
        q_type = q.get('type')
        details = q.get('details') or {}
        details_en = q.get('details_en') or {}
        
        if get_length(content) > LIMIT_KO:
            long_korean.append((len(content), q_id, content))
            
        if get_length(content_en) > LIMIT_EN:
            long_english.append((len(content_en), q_id, content_en))
            
        if q_type == 'B' or q_type == 'b':
            # Check choices
            ca = details.get('choice_a', '')
            cb = details.get('choice_b', '')
            if get_length(ca) > LIMIT_CHOICE:
                long_choices.append((len(ca), q_id, f"Choice A: {ca}"))
            if get_length(cb) > LIMIT_CHOICE:
                long_choices.append((len(cb), q_id, f"Choice B: {cb}"))
                
    # Sort by length desc
    long_korean.sort(key=lambda x: x[0], reverse=True)
    long_english.sort(key=lambda x: x[0], reverse=True)
    long_choices.sort(key=lambda x: x[0], reverse=True)
    
    print(f"\n[Long Korean Questions > {LIMIT_KO} chars] - {len(long_korean)} found")
    for l, qid, txt in long_korean[:20]:
        print(f"[{qid}] ({l}c): {txt}")
        
    print(f"\n[Long English Questions > {LIMIT_EN} chars] - {len(long_english)} found")
    for l, qid, txt in long_english[:20]:
        print(f"[{qid}] ({l}c): {txt}")

    print(f"\n[Long Choices > {LIMIT_CHOICE} chars] - {len(long_choices)} found")
    for l, qid, txt in long_choices[:20]:
        print(f"[{qid}] ({l}c): {txt}")

if __name__ == "__main__":
    analyze()
