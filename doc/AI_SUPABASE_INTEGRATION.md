# ⭐ Important - TalkBingo - AI 에이전트 & Supabase 통합

## 🤖 AI 에이전트 + Supabase 통합 아키텍처

TalkBingo의 AI 에이전트가 Supabase(PostgreSQL)를 활용하여 사용자 관계 파악, 질문 생성, 데이터 요약을 수행하는 통합 시스템을 설계합니다.

---

---

## 🔒 보안 및 개인정보 보호 (Security & Privacy Guardrails)

**[중요]** 본 문서의 모든 AI 기능은 `doc/Security_Plan.md`의 **"4. 서비스 데이터 및 AI 활용 정책"**을 엄격히 준수해야 합니다.

1.  **PII 마스킹 필수**: AI 모델에 데이터를 전송하기 전, 이메일/전화번호/실명 등 식별 가능한 정보는 반드시 **[MASKED]** 처리하거나 해시값으로 변환해야 합니다.
2.  **가명 처리 (Pseudonymization)**: `user_id` 대신 일회성 `session_id` 또는 `alias_id`를 사용하여 AI가 특정 유저를 식별하지 못하도록 합니다.
3.  **데이터 격리**: AI 학습용 데이터와 서비스 운영 데이터는 물리적으로 분리됩니다.

---

## 🧠 AI 에이전트 핵심 기능

### 1. 사용자 관계 파악 (Relationship Analysis)

#### 관계 유형 자동 분류 및 CodeName 생성
```python
# AI 에이전트 - 관계 분석 및 CodeName 도출 함수
def analyze_user_relationship(user1_id, user2_id, supabase):
    """
    두 사용자 간의 관계를 분석하여 CodeName 구성 요소(MP, CP, IR, SubRel, Intimacy)를 도출
    """
    # Supabase Join Query (via View or RPC recommended)
    response = supabase.table('friend_relations').select(
        '*, p1:profiles!mp_id(gender), p2:profiles!cp_id(gender), relation_types(code), intimacy_levels(code)'
    ).eq('mp_id', user1_id).eq('cp_id', user2_id).single().execute()
    
    data = response.data
    mp_gender = data['p1']['gender']
    cp_gender = data['p2']['gender']
    ir_code = data['relation_types']['code'] # e.g., 'B'
    sub_rel_code = 'Ar' # Derived from relation data or sub-relation table
    intimacy = data['intimacy_levels']['code'] # e.g., 'L1'
    
    # CodeName 조합: [MP]-[CP]-[IR]-[SubRel]-[Intimacy]
    code_name = f"{mp_gender}-{cp_gender}-{ir_code}-{sub_rel_code}-{intimacy}"
    
    return {
        "code_name": code_name,
        "details": data
    }


#### 맞춤형 입장 메시지 생성 (Entrance Greeting)
```python
def generate_entrance_message(host_profile, guest_profile, relation_context):
    """
    호스트와 게스트의 입장을 알리는 표준 메시지 생성.
    (UI 모달에 표시될 텍스트)
    """
    
    # AI Prompting (Standardized)
    prompt = f"""
    Create a standard entrance notification message.
    Host: {host_profile['nickname']}, Guest: {guest_profile['nickname']}
    Language: Korean / English
    Output format: JSON {{"host_view": "...", "guest_view": "..."}}
    """
    
    # response = ai.generate(prompt)
    # Example Output:
    # Host View: "[Guest] has entered." / "[Guest]님이 입장하셨습니다."
    # Guest View: "Host has entered." / "초대자가 입장하셨습니다."
    return ai_response
```
```

#### 관계 기반 질문 추천 (Relationship-based Tagging)
```python
def recommend_questions_by_codename(code_name_components, supabase):
    """
    CodeName 구성 요소(성별, 관계, 친밀도)를 기반으로 질문 추천 (5:5 비율)
    """
    # code_name = f"{mp}-{cp}-{ir}-{sub}-{intimacy}"
    # supabase.rpc calling a stored procedure for complex random sampling per type
    
    params = {
        'p_intimacy': code_name_components['intimacy'],
        'p_rel_code': code_name_components['ir'],
        'p_mp_gender': code_name_components['mp'],
        'p_cp_gender': code_name_components['cp']
    }
    
    response = supabase.rpc('recommend_questions', params).execute()
    return response.data
    
    # SQL (Inside RPC):
    # SELECT * FROM questions q
    # JOIN question_intimacy qi ON q.id = qi.question_id
    # JOIN intimacy_levels il ON qi.intimacy_level_id = il.id
    # WHERE il.code = p_intimacy ...
    # ORDER BY random() LIMIT 25
```

### 2. 질문 및 퀴즈 생성 (Question Generation)

#### AI 기반 맞춤형 질문 생성
```python
def generate_personalized_questions(user1_id, user2_id, question_type, graph_db):
    """
    사용자 관계와 이력을 바탕으로 맞춤형 질문 생성.
    *Note*: 호스트가 게임을 설정하는 시점에(게스트 입장 전) 호스트가 제공한 게스트 정보(성별, 관계 등)를 바탕으로 선행 생성됩니다.
    """
    # 1. 사용자 관계 정보 수집 (호스트 입력 정보 활용)
    relationship_info = get_relationship_context(user1_id, user2_id, graph_db)
    
    # 2. 사용자 선호도 분석
    preferences = analyze_user_preferences(user1_id, user2_id, graph_db)
    
    # 3. AI 모델에 컨텍스트 전달
    context = {
        'relationship_type': relationship_info['type'],
        'intimacy_level': relationship_info['intimacy_level'],
        'user_preferences': preferences,
        'question_type': question_type
    }
    
    # 4. AI 모델로 질문 생성
    generated_questions = ai_model.generate_questions(context)
    
    # 5. 생성된 질문을 Supabase에 저장
    save_generated_questions(generated_questions, graph_db)
    
    return generated_questions
```

#### 밸런스 퀴즈 생성
```python
def generate_balance_quiz(user1_id, user2_id, graph_db):
    """
    밸런스 퀴즈 생성 (A vs B 형태)
    """
    # 사용자 성향 분석
    user1_preferences = get_user_preferences(user1_id, graph_db)
    user2_preferences = get_user_preferences(user2_id, graph_db)
    
    # 공통 관심사 찾기
    common_interests = find_common_interests(user1_preferences, user2_preferences)
    
    # AI 모델로 밸런스 퀴즈 생성
    balance_quiz = ai_model.generate_balance_quiz({
        'user1_preferences': user1_preferences,
        'user2_preferences': user2_preferences,
        'common_interests': common_interests
    })
    
    return balance_quiz
```

### 3. 데이터 요약 및 분석 (Data Summarization)

#### 게임 세션 요약 및 신뢰도 평가
```python
def summarize_game_session(game_id, supabase):
    """
    게임 세션 요약 및 TS(신뢰도 점수), VP/AP/EP 포인트 집계
    """
    # 1. Fetch Game & User Data
    game = supabase.table('game_sessions').select('*').eq('id', game_id).single().execute()
    mp = supabase.table('profiles').select('nickname').eq('id', game.data['mp_id']).single().execute()
    cp = supabase.table('profiles').select('nickname').eq('id', game.data['cp_id']).single().execute()
    
    # 2. Fetch Used Questions (from logs or joined table if design permits)
    logs = supabase.table('logs').select('detail').eq('game_id', game_id).execute()
    questions = [log['detail']['question_text'] for log in logs.data if 'question_text' in log['detail']]
    
    # 3. Aggregate Scores (from rewards table)
    scores = supabase.table('rewards').select('vp, ap, ep, ts').eq('game_id', game_id).execute()
    
    # Note: If user migrated account during session, ensure 'user_id' in logs matches the new authenticated ID.
    
    # AI summary generation
    summary = ai_model.summarize_game({
        'questions': questions,
        'players': [mp.data['nickname'], cp.data['nickname']],
        'scores': scores.data
    })
    
    return summary
    
    
    def analyze_sudden_exit_state(game_id, supabase):
    """
    강제 종료(Sudden Exit)된 게임의 상태를 분석하여 정산 로직 검증.
    AI는 로그와 상태 불일치를 감지하여 재접속 시 올바른 리워드 표기를 보장하는 감시자 역할을 수행함.
    """
    # 1. Fetch Game State
    game = supabase.table('game_sessions').select('game_status, game_state').eq('id', game_id).single().execute()
    
    # 2. Verify Score Integrity
    # 로그 상 'Bingo Completed' 이벤트가 존재하는데, 리워드가 0인 경우 등을 탐지
    logs = supabase.table('logs').select('*').eq('game_id', game_id).eq('event', 'BINGO_WIN').execute()
    
    # 3. Report Discrepancy
    if logs.data and game.data['game_status'] != 'finished':
       return {"alert": "Mismatch detected", "suggested_action": "force_settle", "score_snapshot": logs.data[-1]}
    
    return {"status": "integrity_verified"}
```

#### 사용자 관계 발전 추이 분석
```python
def analyze_relationship_progress(user1_id, user2_id, graph_db):
    """
    사용자 간 관계 발전 추이 분석
    """
    query = """
    MATCH (u1:User {id: $user1_id})-[r:FRIEND_WITH]->(u2:User {id: $user2_id})
    MATCH (u1)-[:PLAYED_IN]->(g:GameSession)<-[:PLAYED_IN]-(u2)
    WHERE g.created_at > datetime() - duration('P30D')
    RETURN g.created_at, g.status, r.intimacy_level, r.trust_score
    ORDER BY g.created_at
    """
    
    result = graph_db.run(query, user1_id=user1_id, user2_id=user2_id)
    progress_data = result.data()
    
    # AI 모델로 관계 발전 분석
    analysis = ai_model.analyze_relationship_progress(progress_data)
    
    return analysis
```

---

## 🔄 실시간 데이터 처리

### 1. 스트리밍 데이터 처리
```python
class RealTimeDataProcessor:
    def __init__(self, graph_db, ai_model):
        self.graph_db = graph_db
        self.ai_model = ai_model
    
    def process_chat_message(self, user_id, game_id, message_content):
        """
        실시간 채팅 메시지 처리
        """
        # 1. 채팅 메시지를 Supabase에 저장
        self.save_chat_message(user_id, game_id, message_content)
        
        # 2. 대화 맥락 분석 (PII Masking 적용)
        safe_context = self.mask_pii(message_content) 
        context = self.analyze_conversation_context(game_id, safe_context)
        
        # 3. AI 모델로 응답 생성
        ai_response = self.ai_model.generate_response(context)
        
        return ai_response
    
    def process_game_action(self, user_id, game_id, action_type, action_data):
        """
        게임 액션 처리
        """
        # 1. 게임 액션을 Supabase에 저장
        self.save_game_action(user_id, game_id, action_type, action_data)
        
        # 2. 사용자 행동 패턴 업데이트
        self.update_user_behavior_pattern(user_id, action_type, action_data)
        
        # 3. 관계 데이터 업데이트
        self.update_relationship_data(user_id, game_id, action_data)
```

### 2. 배치 데이터 처리
```python
class BatchDataProcessor:
    def __init__(self, graph_db, ai_model):
        self.graph_db = graph_db
        self.ai_model = ai_model
    
    def daily_relationship_analysis(self):
        """
        일일 관계 분석 및 업데이트
        """
        # 1. 모든 활성 사용자 관계 분석
        active_relationships = self.get_active_relationships()
        
        # 2. AI 모델로 관계 발전 예측
        predictions = self.ai_model.predict_relationship_development(active_relationships)
        
        # 3. Supabase 업데이트
        self.update_relationship_predictions(predictions)
    
    def weekly_content_optimization(self):
        """
        주간 콘텐츠 최적화
        """
        # 1. 사용자 피드백 수집
        user_feedback = self.collect_user_feedback()
        
        # 2. AI 모델로 콘텐츠 개선
        improvements = self.ai_model.optimize_content(user_feedback)
        
        # 3. 질문 데이터베이스 업데이트
        self.update_question_database(improvements)
```

---

## 🎯 AI 에이전트 학습 시스템

### 1. 지속적 학습 (Continuous Learning)
```python
class AILearningSystem:
    def __init__(self, graph_db, ai_model):
        self.graph_db = graph_db
        self.ai_model = ai_model
    
    def learn_from_user_interactions(self):
        """
        사용자 상호작용으로부터 학습
        """
        # 1. 사용자 행동 데이터 수집
        interaction_data = self.collect_interaction_data()
        
        # 2. AI 모델 학습
        self.ai_model.train(interaction_data)
        
        # 3. 학습 결과를 Supabase에 저장
        self.save_learning_results()
    
    def learn_from_relationship_development(self):
        """
        관계 발전으로부터 학습
        """
        # 1. 관계 발전 데이터 수집
        relationship_data = self.collect_relationship_data()
        
        # 2. AI 모델로 관계 패턴 학습
        patterns = self.ai_model.learn_relationship_patterns(relationship_data)
        
        # 3. 학습된 패턴을 Supabase에 저장
        self.save_relationship_patterns(patterns)
```

### 2. A/B 테스트 시스템
```python
class ABTestingSystem:
    def __init__(self, graph_db, ai_model):
        self.graph_db = graph_db
        self.ai_model = ai_model
    
    def test_question_variants(self, user1_id, user2_id):
        """
        질문 변형 A/B 테스트
        """
        # 1. 사용자를 A/B 그룹으로 분할
        group = self.assign_user_group(user1_id)
        
        # 2. 그룹별 다른 질문 생성
        if group == 'A':
            questions = self.generate_questions_variant_a(user1_id, user2_id)
        else:
            questions = self.generate_questions_variant_b(user1_id, user2_id)
        
        # 3. 결과 추적
        self.track_ab_test_results(user1_id, user2_id, group, questions)
    
    def test_ai_model_versions(self):
        """
        AI 모델 버전 A/B 테스트
        """
        # 1. 모델 버전별 성능 비교
        model_a_performance = self.test_model_performance('model_a')
        model_b_performance = self.test_model_performance('model_b')
        
        # 2. 더 나은 모델 선택
        best_model = self.select_best_model(model_a_performance, model_b_performance)
        
        # 3. 프로덕션 모델 업데이트
        self.update_production_model(best_model)
```

---

## 📊 성능 모니터링 및 최적화

### 1. AI 모델 성능 모니터링
```python
class AIModelMonitor:
    def __init__(self, graph_db):
        self.graph_db = graph_db
    
    def monitor_question_generation_performance(self):
        """
        질문 생성 성능 모니터링
        """
        query = """
        MATCH (q:Question)
        WHERE q.created_at > datetime() - duration('P1D')
        RETURN q.type, 
               COUNT(q) as question_count,
               AVG(q.quality_score) as avg_quality,
               AVG(q.user_satisfaction) as avg_satisfaction
        """
        
        result = self.graph_db.run(query)
        performance_data = result.data()
        
        return performance_data
    
    def monitor_relationship_analysis_accuracy(self):
        """
        관계 분석 정확도 모니터링
        """
        query = """
        MATCH (u1:User)-[r:FRIEND_WITH]->(u2:User)
        WHERE r.trust_score > 4.0
        RETURN COUNT(r) as high_trust_relationships,
               AVG(r.intimacy_level) as avg_intimacy
        """
        
        result = self.graph_db.run(query)
        accuracy_data = result.data()
        
        return accuracy_data
```

### 2. Supabase 성능 최적화
```python
class SupabaseOptimizer:
    def __init__(self, graph_db):
        self.graph_db = graph_db
    
    def optimize_queries(self):
        """
        쿼리 성능 최적화
        """
        # 1. 느린 쿼리 식별
        slow_queries = self.identify_slow_queries()
        
        # 2. 인덱스 최적화
        self.optimize_indexes(slow_queries)
        
        # 3. 쿼리 최적화
        self.optimize_query_plans(slow_queries)
    
    def optimize_data_model(self):
        """
        데이터 모델 최적화
        """
        # 1. 노드 분할 최적화
        self.optimize_node_partitioning()
        
        # 2. 관계 최적화
        self.optimize_relationships()
        
        # 3. 데이터 압축
        self.compress_historical_data()
```

---

## 🚀 배포 및 운영

### 1. 마이크로서비스 아키텍처
```yaml
# docker-compose.yml
version: '3.8'
services:
  supabase:
    image: supabase/postgres:latest
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_PASSWORD=password
  
  ai-agent:
    build: ./ai-agent
    environment:
      - SUPABASE_URL=http://supabase:5432
      - SUPABASE_KEY=service-role-key
    depends_on:
      - supabase
  
  api-server:
    build: ./api-server
    environment:
      - SUPABASE_URL=http://supabase:5432
      - AI_AGENT_URL=http://ai-agent:8000
    depends_on:
      - supabase
      - ai-agent
```

### 2. 모니터링 및 알림
```python
class SystemMonitor:
    def __init__(self, graph_db, ai_model):
        self.graph_db = graph_db
        self.ai_model = ai_model
    
    def monitor_system_health(self):
        """
        시스템 상태 모니터링
        """
        # 1. Supabase 연결 상태 확인
        db_status = self.check_database_connection()
        
        # 2. AI 모델 성능 확인
        ai_status = self.check_ai_model_performance()
        
        # 3. 알림 발송
        if db_status != 'healthy' or ai_status != 'healthy':
            self.send_alert(db_status, ai_status)
    
    def monitor_user_satisfaction(self):
        """
        사용자 만족도 모니터링
        """
        query = """
        MATCH (u:User)-[:RATED]->(q:Question)
        WHERE q.created_at > datetime() - duration('P1D')
        RETURN AVG(q.user_rating) as avg_rating,
               COUNT(q) as rating_count
        """
        
        result = self.graph_db.run(query)
        satisfaction_data = result.data()
        
        if satisfaction_data[0]['avg_rating'] < 3.0:
            self.send_satisfaction_alert(satisfaction_data)
```

---

*TalkBingo - AI 에이전트와 Supabase의 완벽한 통합으로 지능적인 대화 경험 제공*




