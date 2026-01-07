# TalkBingo Supabase Schema Design: Efficient Question Targeting

## 1. 문제 정의 (Problem Definition)
기존 설계(`q_id = CodeName`)에서는 하나의 질문이 여러 대상(예: 모든 L1 유저)에게 적용될 때, 해당 질문 데이터를 모든 타겟 CodeName별로 복제해야 하는 **데이터 중복(Data Duplication)** 문제가 발생합니다. 이는 저장 공간 낭비뿐만 아니라, 질문 수정 시 모든 복제본을 업데이트해야 하는 **유지보수 문제**를 야기합니다.

## 2. 해결 방안: 관계형 태깅 (Relational Tagging)
질문(Question) 테이블에는 질문 데이터가 **하나만 존재**하게 하고, 해당 질문이 어떤 속성(친밀도, 관계 등)을 타겟팅하는지를 **매핑 테이블(Mapping Tables)**을 통해 N:M 관계로 연결합니다.

### 2.1 테이블 구조 (Table Structure)

#### `questions` Table
- **Columns**: `id` (UUID, PK), `content` (TEXT), `type` (TEXT: 'Balance' / 'Truth'), `details` (JSONB: answers, choice_a, choice_b), `created_at` (TIMESTAMPTZ)
- **설명**: 질문의 본문 내용을 담은 메인 테이블입니다.

#### `intimacy_levels` Table
- **Columns**: `id` (INT, PK), `code` (TEXT: 'L1'~'L5'), `description` (TEXT)
- **설명**: 친밀도 레벨을 정의하는 기준 테이블입니다.

#### `relation_types` Table
- **Columns**: `id` (INT, PK), `code` (TEXT: 'Friend', 'Family', 'Lover'), `sub_code` (TEXT: 'Ar', 'Or'...)
- **설명**: 관계 유형을 정의하는 기준 테이블입니다.

#### `gender_targets` Table (New)
- **Columns**: `id` (INT, PK), `host_gender` (TEXT: 'M'/'F'), `guest_gender` (TEXT: 'M'/'F')
- **설명**: 호스트와 게스트의 성별 조합을 타겟팅합니다.

---

### 2.2 태깅 매핑 테이블 (Tagging Mapping Tables)
질문이 특정 조건에 **적합함**을 나타내기 위해 교차 테이블(Junction Table)을 사용합니다.

#### `question_intimacy` Table
- **Columns**: `question_id` (UUID, FK), `intimacy_level_id` (INT, FK)
- **설명**: 질문이 특정 친밀도에 적합함을 매핑합니다.

#### `question_relations` Table
- **Columns**: `question_id` (UUID, FK), `relation_type_id` (INT, FK)
- **설명**: 질문이 특정 관계 유형에 적합함을 매핑합니다.

#### `question_genders` Table
- **Columns**: `question_id` (UUID, FK), `gender_target_id` (INT, FK)
- **설명**: 질문이 특정 성별 조합에 적합함을 매핑합니다.

**규칙:**
1. **특정 조건 타겟팅**: 질문이 특정 친밀도(L1)에만 적합하다면, `question_intimacy`에 해당 매핑을 추가합니다.
2. **범용(Wildcard) 처리**:
   - 질문이 **모든 관계**에 적합하다면, `question_relations` 테이블에 매핑을 **생성하지 않습니다**. (No Entry = All Allowed)
   - 쿼리 시 `LEFT JOIN` 후 `NULL` 체크로 처리합니다.

---

### 2.3 데이터 소스 및 CSV 구조 (Data Sources & CSV Structure)

#### 1. Truth Quiz Data (`doc/TruthQuizData.csv`)
- **Columns**: `CodeName, Order, q_id, content, answers`
- **Example**: `M-F-B-Ar-L2, T25-00001, M-F-B-Ar-L2-1, "질문 내용", "답변 예시"`

#### 2. Balance Game Data (`doc/questions-2025-11-20T00-14-46.csv`)
- **Columns**: `CodeName, Order, q_id, content, choice_a, choice_b`
- **Example**: `F-F-B-Ar-L1, B25-00001, , "질문 내용", "선택A", "선택B"`

#### 3. CodeName Definition
`[MP]-[CP]-[IR]-[SubRel]-[Intimacy]`
- **MP (Main Player)**: Host Gender (M/F)
- **CP (Companion Player)**: Guest Gender (M/F)
- **IR (Intimate Relationship)**: Relation Type (B: Friend, Fa: Family, Lo: Lover)
- **SubRel**: Sub Relation (Ar, Or, etc.)
- **Intimacy**: Level (L1~L5)

---

### 2.4 게임 로직 및 타겟팅 (Game Logic & Targeting)

#### 5:5 비율 배분 (5:5 Ratio Allocation)
빙고 보드 생성 시, **Balance Quiz**와 **Truth Quiz**를 정확히 **5:5 비율**로 배치해야 합니다.
- **Total Cells**: 25 (5x5 Bingo)
- **Allocation**:
    - **Balance Quiz**: 12~13개
    - **Truth Quiz**: 12~13개

#### CodeName Selection Process
1. 호스트 페이지에서 호스트 정보 입력 → Supabase `profiles` 혹은 Local Storage 저장.
2. **게임 생성 시**: 호스트가 입력한 게스트 정보를 기반으로 **즉시 질문 추출** (Supabase RPC or Queries).
3. 호스트는 질문이 로드된 게임 화면으로 **즉시 입장**.

#### 게스트 및 호스트 정보 기반 배치 (Guest & Host Info Based Placement)
질문은 현재 게임의 **Host(MP)**와 **Guest(CP)** 정보에 맞춰 필터링되어야 합니다.
1. **성별 매칭**: `gender_targets` 테이블과 매칭 (NULL이면 전체 허용).
2. **관계 매칭**: `relation_types` 테이블과 매칭 (NULL이면 전체 허용).
3. **친밀도 매칭**: `intimacy_levels` 테이블과 매칭 (NULL이면 전체 허용).

---

## 3. 쿼리 전략 (Query Strategy)

사용자(게스트)가 접속했을 때, 해당 사용자의 속성(예: `Friend`, `L1`, `M-F`)에 맞는 질문을 효율적으로 가져오는 SQL 쿼리입니다.

**사용자 정보:** `Relation: Friend`, `Intimacy: L1`, `HostGender: M`, `GuestGender: F`

```sql
WITH filtered_questions AS (
  SELECT q.*
  FROM questions q
  -- 1. 친밀도 필터 (매핑이 없거나, 해당 레벨과 매핑된 경우)
  LEFT JOIN question_intimacy qi ON q.id = qi.question_id
  LEFT JOIN intimacy_levels il ON qi.intimacy_level_id = il.id
  WHERE (il.code = 'L1' OR qi.question_id IS NULL)

  -- 2. 관계 필터
  AND EXISTS (
    SELECT 1 FROM question_relations qr
    LEFT JOIN relation_types rt ON qr.relation_type_id = rt.id
    WHERE qr.question_id = q.id AND (rt.code = 'Friend' OR qr.question_id IS NULL) -- Logic refined in implementation
  )
  -- Note: The logic "No Entry = All Allowed" requires careful SQL using LEFT JOINs and check for NULLs properly.
  -- Simplified Logic:
  AND (
      -- Case A: No specific relationship targeting (Universal)
      NOT EXISTS (SELECT 1 FROM question_relations WHERE question_id = q.id)
      OR
      -- Case B: Direct match
      EXISTS (
        SELECT 1 FROM question_relations qr
        JOIN relation_types rt ON qr.relation_type_id = rt.id
        WHERE qr.question_id = q.id AND rt.code = 'Friend'
      )
  )
  AND (
      -- Case A: No specific gender targeting
      NOT EXISTS (SELECT 1 FROM question_genders WHERE question_id = q.id)
      OR
      -- Case B: Direct match
      EXISTS (
        SELECT 1 FROM question_genders qg
        JOIN gender_targets gt ON qg.gender_target_id = gt.id
        WHERE qg.question_id = q.id AND gt.host_gender = 'M' AND gt.guest_gender = 'F'
      )
  )
)
-- 4. 타입별 분리 및 랜덤 추출 (Balance 13, Truth 12)
(
  SELECT * FROM filtered_questions 
  WHERE type = 'Balance' 
  ORDER BY random() 
  LIMIT 13
)
UNION ALL
(
  SELECT * FROM filtered_questions 
  WHERE type = 'Truth' 
  ORDER BY random() 
  LIMIT 12
);
```

## 4. 결론
**"질문 테이블은 하나, 타겟 조건은 매핑 테이블(N:M)로 연결"**하는 방식이 가장 효율적입니다. Supabase의 PostgreSQL 기능을 활용하여 효율적인 쿼리와 인덱싱이 가능합니다.

