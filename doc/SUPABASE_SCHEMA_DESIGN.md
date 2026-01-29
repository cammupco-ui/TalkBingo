# TalkBingo Supabase Schema Design: Dynamic Gender & Wildcard Targeting

## 1. 문제 정의 (Problem Definition)
기존 설계에서는 `HostGender - GuestGender` 조합별로 별도의 질문 데이터(Row)를 생성해야 했습니다. 이는 다음과 같은 문제를 야기합니다.
1.  **데이터 중복**: 같은 질문임에도 성별 조사(오빠/누나 등)만 다른 데이터가 4배로 증식.
2.  **유지보수 어려움**: 오타 수정 시 4개의 데이터를 모두 찾아 고쳐야 함.
3.  **유연성 부족**: 게임 도중 역할(질문자/응답자)이 바뀔 때 즉각적인 텍스트 대응이 불가능.

## 2. 해결 방안: 동적 변형 시스템 (Dynamic Variant System)
질문 데이터는 **하나의 Row**로 통합하고, 성별/역할에 따른 텍스트 변형은 **JSONB 컬럼(`gender_variants`)**에 담아 클라이언트가 렌더링 시점에 선택하도록 합니다.

### 2.1 테이블 구조 (Table Structure)

#### `questions` Table
질문의 핵심 데이터를 담는 테이블입니다.

| Column Name | Type |- **questions Table (`questions`)**
  - `id` (UUID, PK)
  - `q_id` (VARCHAR, Unique): 관리 ID (`B26-00001`)
  - `content` (TEXT): 질문 기본 텍스트 (한국어)
  - `content_en` (TEXT): 질문 기본 텍스트 (영어)
  - `type` (VARCHAR): 'balance', 'truth', 'mini'
  - `details` (JSONB): 선택지(A/B), 답변예시 등 (한국어)
  - `details_en` (JSONB): 선택지(A/B), 답변예시 등 (영어)
  - `gender_variants` (JSONB): `{ "var_m_f": "...", "var_f_m": "..." }`
  - `gender_variants_en` (JSONB): `{ "var_m_f": "...", ... }` (English Nuances)
  - `code_names` (TEXT[]): 타겟팅 태그 (`*-*-B-Ar-L3`) |

#### `gender_variants` JSON Structure
```json
{
  "M_to_F": "누나/동생에게 가장 고마웠던 순간은?", 
  "F_to_M": "오빠/동생에게 가장 고마웠던 순간은?",
  "M_to_M": "형/동생에게 가장 고마웠던 순간은?",
  "F_to_F": "언니/동생에게 가장 고마웠던 순간은?"
}
```

---

### 2.2 데이터 소스 및 매핑 (Data Mapping)

#### CSV Source (`doc/TruthQuizData_v2.csv`)
CSV 파일의 개별 컬럼들이 Supabase의 JSONB 필드로 매핑됩니다.

| CSV Column | Mapped to Supabase Column |
| :--- | :--- |
| `content` | `questions.content` (Fallback/Short ver.) |
| `var_m_f` | `questions.gender_variants ->> 'M_to_F'` |
| `var_f_m` | `questions.gender_variants ->> 'F_to_M'` |
| `var_m_m` | `questions.gender_variants ->> 'M_to_M'` |
| `var_f_f` | `questions.gender_variants ->> 'F_to_F'` |
| `CodeName` | `questions.code_names` (Array append) |

---

### 2.3 게임 로직 및 쿼리 전략 (Query Strategy)

#### Wildcard Matching Strategy
더 이상 호스트의 성별을 쿼리 조건에 넣지 않습니다. 대신 **관계(Relation)와 친밀도(Intimacy)**만으로 질문을 검색합니다.

**Fetch Logic (Client -> Supabase)**
```sql
-- 예: 고향친구(B-Ar), 친밀도 L3에 맞는 질문 검색
SELECT * FROM questions
WHERE 
  -- 1. 정확한 타겟팅 (성별은 Wildcard 처리)
  '*-*-B-Ar-L3' = ANY(code_names)
  OR
  -- 2. 상위 호환 (Relationship Broad)
  '*-*-B-*-L3' = ANY(code_names);
```

**Runtime Rendering (Client Side)**
1.  **Fetching**: 위 쿼리로 질문 리스트(25개)를 로드합니다.
2.  **Turn Check**: 현재 턴의 공격자(Attacker)와 수비자(Defender) 성별 확인.
3.  **Variant Selection**:
    *   Attacker(Male) → Defender(Female)인 경우: `variants['M_to_F']` 선택.
    *   해당 키가 없으면 `content` (기본값) 표시.

---

## 3. 결론
이 설계는 **DB의 단순함**과 **UI의 유연함**을 동시에 만족시킵니다.
*   **DB**: 중복 데이터 제거, 관리 포인트 일원화.
*   **App**: 실시간 턴 교체에 따른 자연스러운 호칭 변화 구현 가능.


