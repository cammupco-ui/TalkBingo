# System Refactoring Plan: Dynamic Gender & Turn-Based Logic

## 1. Problem Analysis (현재 문제점 분석)

### 1.1 Static CodeName Limitation (정적 코드의 한계)
*   **Current**: 게임 시작 시 `GameSession`에 `M-F-B-Dc-L3`와 같이 **고정된 CodeName**으로 질문 25개를 한 번에 가져옵니다.
*   **Issue**: 이 방식은 "남성이 여성에게 질문하는 상황"만 가정하거나, 반대의 경우만 가정하게 됩니다.
*   **Scenario Fail**:
    *   **Game Loop**: 빙고 게임은 A와 B가 번갈아 가며 공격(질문)합니다. (남-여, 남-남, 여-여 등 다양한 조합 가능)
    *   **Mismatch**: 
        *   성별 특화 질문의 경우: A(남)의 턴일 때 "오빠..."(여성 화자) 질문이 나오면 어색합니다.
        *   범용 질문의 경우: 문제가 없지만, 성별 특화 질문과 섞여 있을 때 처리가 복잡해집니다.
    *   **Consequence**: 몰입도가 깨지고 대화가 부자연스러워집니다.

### 1.3 Role Definition (인게임 역할 정의)
*   **Host (MP) / Guest (CP)**: 방 생성/참여 기준의 정적 역할.
*   **Attacker (A)**: 현재 턴의 질문자 (화자).
*   **Defender (D)**: 현재 턴의 응답자 (청자).
*   **Logic Simplification**: 데이터 로직은 MP/CP가 아닌 **A/D 관계**를 기준으로 설계되어야 합니다.

### 1.2 Data Duplication & Fragmentation (데이터 파편화)
*   같은 주제(예: 스킨십)라도 남성용, 여성용 질문을 별개의 ID로 관리하면 데이터 양이 2~4배로 늘어나고 관리가 어렵습니다.

---

## 2. Updated Core Concept (개선된 핵심 컨셉)

### 2.1 Relationship-First Extraction (관계 우선 추출)
*   **Extraction**: 질문을 가져올 때 **성별(Gender) 조건을 제거**하고, 오직 **관계(Relation)와 친밀도(Intimacy)**만으로 질문 세트를 구성합니다.
    *   *Search Key*: `*-*-B-Dc-L3` (성별 무관, 동네친구 L3)
*   **Rendering**: 가져온 질문 데이터 내부에 **성별 변형(Gender Variants)** 정보를 포함하고, **실제 렌더링 시점(Turn)**에 그에 맞는 텍스트를 보여줍니다.

### 2.2 Gender Variants Structure (성별 변형 구조)
*   하나의 `question_id` 안에 모든 케이스를 담습니다.
    ```json
    {
      "q_id": "T26-00001",
      "base_content": "상대에게 고마운 순간은?",  // 빙고 타일에 표시될 중립적 텍스트
      "variants": {
        "M_to_F": "누나/동생한테 가장 고마웠던 순간은?",     // 남 -> 여 (연상/연하 통합)
        "F_to_M": "오빠/동생에게 제일 고마웠던 적이 언제였어?", // 여 -> 남 (연상/연하 통합)
        "M_to_M": "형/동생한테 고마운 적 있냐?",            // 남 -> 남
        "F_to_F": "언니/동생한테 고마운 적 있어?"            // 여 -> 여
      }
    }
    ```

---

## 3. Required Modifications (수정 및 보완 사항)

### 3.1 Document Updates (문서 수정)
1.  **`QuizDataRules.md / .json`**:
    *   `CodeName` 정의에서 성별 부분(`MP`, `CP`)의 역할을 **"필수 필터"**에서 **"렌더링 컨텍스트"**로 변경.
    *   `fallback_logic`을 '관계 우선 검색'으로 단순화.
    *   데이터 구조에 `gender_variants` 필드 추가 명시.
2.  **`RelationshipDefinition.md`**:
    *   성별 매트릭스 설명 수정 (정적인 관계 정의용 vs 동적인 게임 턴용 구분).

### 3.2 Database & Supabase (데이터 관련)
1.  **Schema Change**: `questions` 테이블에 `gender_variants` (JSONB) 컬럼 추가 필요.
### 3.2 Content Specific Strategy (콘텐츠별 적용 전략)

각 게임 유형의 특성에 따라 `gender_variants`를 다르게 적용합니다.

1.  **진실 게임 (Truth Game)**:
    *   **특징**: 심도 있는 대화 유도가 목적이므로 화자의 어조가 가장 중요합니다.
    *   **전략**: 질문 본문(`content`)에 풀버전의 Variant를 필수적으로 적용합니다.
    *   *예시*: "상대방의 가장 큰 매력은?" -> (남→여) "너가 생각하는 내 가장 큰 매력은 뭐야?"

2.  **밸런스 퀴즈 (Balance Quiz)**:
    *   **특징**: 두 가지 선택지(A/B)를 고르는 게임.
    *   **전략**: 질문 줄기(Stem)는 화자에 맞춰 변형하되, 선택지(A/B)는 보통 명사형이므로 변형 없이 공통 사용합니다.
    *   *예시 Stem*: "애인과 1박 2일 여행 간다면?" -> "나랑 여행 갈 때 넌 어떤 스타일이야?"
    *   *예시 A/B*: "철저한 계획" vs "즉흥적인 낭만" (변형 불필요)

3.  **미니 게임 (Locked Cells / Mini-Games)**:
    *   **특징**: 승부차기, 타겟슈터 등 피지컬 게임.
    *   **전략**: 게임 설명이나 승리/패배 문구는 대부분 중립적("승리!", "터치하여 발사")이므로 `variants` 적용이 거의 필요 없습니다. 필요한 경우(도발 멘트 등)에만 선택적으로 적용합니다.

### 3.3 Practical Workflow (제작 및 업로드 방식)
*   **Rule**: Supabase는 저장소일 뿐이므로, **변형된 텍스트는 기획 단계에서 미리 작성하여 업로드해야 합니다.** (서버에서 실시간 자동 생성 아님)
*   **CSV Structure**: 엑셀 파일에 다음 컬럼을 추가하여 관리합니다.
    *   `var_m_f`: 남(A) -> 여(D) (썸녀, 여동생, 누나, 여사친 등)
    *   `var_f_m`: 여(A) -> 남(D) (썸남, 남동생, 오빠, 남사친 등)
    *   `var_m_m`: 남(A) -> 남(D) (친구, 형제, 부자지간 등)
    *   `var_f_f`: 여(A) -> 여(D) (친구, 자매, 모녀지간 등)
*   **AI Assistance**: 모든 변형을 직접 쓰기 번거롭다면, 기본 질문(`content`)만 작성 후 **저에게 요청해주세요.** 맥락에 맞게 4가지 변형을 자동 생성하여 CSV 형식으로 만들어 드립니다.

### 3.4 Flutter Client Logic (`GameSession.dart`) (앱 로직 상세)

1.  **`fetchQuestions` Update (질문 가져오기)**:
    *   **Logic**: 더 이상 `M-F...`와 같이 성별을 고정하지 않습니다.
    *   **Query CodeName**: 항상 `*-*-Rel-Sub-Lvl` (예: `*-*-B-Dc-L3`) 패턴으로만 질문을 요청합니다.
    *   **Result**: 성별에 구애받지 않고 해당 관계와 친밀도에 맞는 질문 25개를 확보합니다.

2.  **`Question` Model Update (모델 파싱)**:
    *   **Field**: `Map<String, String> variants` 필드를 추가합니다.
    *   **Parsing**: Supabase JSONB 컬럼에서 `var_m_f`, `var_f_m` 등을 읽어와 Map으로 변환하여 메모리에 보유합니다.

3.  **Dynamic UI Rendering (동적 렌더링)**:
    *   **Scenario**: 현재 턴이 'Host(Male)'이고 상대가 'Guest(Female)'인 경우.
    *   **BingoTile (Board)**: 공간이 좁으므로 가장 짧고 중립적인 `content` (나에게 고마운 점은?)를 표시합니다.
    *   **QuizOverlay (Modal)**: 
        *   `Key Gen`: `M_to_F` 키를 생성.
        *   `Lookup`: `variants['M_to_F']` 값을 확인.
        *   `Display`: 값이 존재하면 "누나/동생한테 가장 고마웠던 순간은?" 표시, 없으면 기본 `content` 표시.
        *   **Effect**: 오직 질문 텍스트만 바뀌며, 선택지나 게임 로직은 유지됩니다.

### 3.5 Real-time Stability & Safety (실시간 안정성 확보)
*   **Zero Network Risk**: 모든 Variant 데이터는 게임 시작 전(Lobby)에 **미리 로딩(Pre-fetch)**됩니다. 게임 중에는 네트워크 통신 없이 로컬 메모리에서 즉시 텍스트만 교체하므로 딜레이나 끊김이 발생하지 않습니다.
*   **Safe Fallback**: 만약 특정 키(예: `M_to_F`)가 비어있거나 에러가 생겨도, 즉시 **`base_content` (기본 질문)**를 보여주도록 **안전 장치**가 적용되어 게임이 중단되지 않습니다.

---

## 4. Expected Benefits (기대 효과)
1.  **완벽한 턴 기반 몰입감**: 누가 공격하든 그 사람의 말투와 입장에 맞는 질문이 나갑니다.
2.  **보드 가독성 향상**: 타일에는 짧고 간결한 `base_content`만 보여 깔끔해집니다.
3.  **데이터 관리 효율화**: 질문 개수는 줄어들고(ID 기준), 퀄리티(디테일)는 높아집니다.
4.  **확장성**: 추후 '존댓말/반말' 모드 등 톤앤매너 확장도 `variants`에 추가하기 쉽습니다.

---

## 5. Next Steps (다음 실행 계획)
1.  `doc/QuizDataRules.md` 업데이트: 변형 구조 반영.
2.  `import_supabase.py` (시스템 내부 관리용) 로직 수정 계획 수립 (필요 시).
3.  `GameSession.dart`의 `fetchQuestions` 및 질문 파싱 로직 리팩토링.
