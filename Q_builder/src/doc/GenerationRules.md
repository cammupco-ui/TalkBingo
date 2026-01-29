# Question Generation & Compression Rules

이 문서는 `Question Composer`가 Enrichment 데이터를 게임 질문으로 변환할 때 사용하는 **생성 로직**과 **압축 규칙(Compression Logic)**을 정의합니다.

## 1. 공통 목표 (Design Goals)
- **Mobile First**: 모바일 화면에서 한 눈에 들어오도록 짧고 간결해야 한다. (질문 50자, 옵션/답변 15자 내외)
- **Conversational Tone**: 딱딱한 문어체가 아닌, 친구에게 말을 거는 듯한 구어체(`해봤어?`, `뭐야?`)를 사용한다.
- **Context Preservation**: 원본 컨텍스트(`Context Variant`)의 핵심 의미를 왜곡하지 않으면서 군더더기를 제거한다.

---

## 2. Balance Game (밸런스 게임)

### 생성 로직 (Generation Logic)
- **Input**: `enrichment_psychological_tensions` (심리적 텐션)
- **Process**:
  1. 텐션 문자열을 `|`로 분리하여 후보군 생성.
  2. 랜덤으로 하나의 텐션을 선택.
  3. 선택된 텐션이 `vs`를 포함하면 `[A] vs [B]`로 분리.
  4. `vs`가 없으면 `[선택] vs [선택 안 함]` 형태로 자동 확장.
  5. 각 옵션에 대해 **압축 로직(Compression)** 적용.

### 압축 규칙 (Compression Rules) - `compressOption`
1. **서술어구 삭제 (Predicate Reduction)**
   - `쪽을 선택` -> (삭제)
   - `반대 선택` -> `아님`
   - `선택 안 함` -> `안 함`
   - `~하는 것`, `~하기`, `~함`, `~됨` -> (삭제)
   
2. **패턴 치환 (Pattern Replacement)**
   - `하루 꽉 채운 액티비티 여행` -> `꽉찬 액티비티`
   - `숙소 중심으로 쉬는 힐링 여행` -> `숙소 힐링`
   - `미리 계획한 일정대로` -> `계획대로`
   - `그날 기분대로 움직이기` -> `기분따라`
   - `칭찬과 솔직함 사이의` -> `칭찬 vs 솔직`

3. **조사 삭제 (Aggressive Stopwords Removal)**
   - `에 대한`, `을 위한`, `에 관한`, `으로 인한`, `때문에` -> (삭제)
   - `은`, `는`, `이`, `가`, `을`, `를`, `의`, `와`, `과`, `로` -> (삭제)
   - `있다`, `하다` -> (삭제)

4. **길이 제한 (Hard Limit)**
   - **최대 15자**. 초과 시 뒷부분 절삭 (`slice(0, 15)`).

---

## 3. Truth Game (진실 게임)

### 생성 로직 (Generation Logic)
- **Input**:
  - `enrichment_psychological_tensions`
  - `enrichment_conversation_friendly_terms`
- **Process**:
  1. 텐션과 친화적 용어(Friendly Terms)를 모두 수집.
  2. 텐션에 `vs`가 있으면 분리하여 개별 답변으로 추가.
  3. 각 답변 후보에 **압축 로직** 적용.
  4. 중복 제거 후 최대 4개의 `expected_answers` 선정.

### 질문 압축 규칙 (Question Compression) - `compressQuestion`
1. **구어체 치환**
   - `아이들과` -> `아이와`
   - `함께 해본 적 있어?` -> `해봤어?`
   - `어떤 시간 보내?` -> `뭐 해?`
   - `무엇인가요?` -> `뭐야?`
   - `가장 좋아하는` -> `최애`
   - `기억에 남는` -> `기억남는`

2. **길이 제한**
   - **최대 50자**. 초과 시 `…` 처리.
   - 문장 끝에 `?`가 없으면 자동 추가.

### 답변 압축 규칙 (Answer Compression) - `compressAnswer`
1. **서술어구 삭제**
   - `쪽인 것 같아`, `쪽이야` -> (삭제)
   - `기억이 더 남아` -> `기억`
   - `생각이 들어` -> `생각`
   - `느낌이야` -> `느낌`
   - `놀아줘야 한다는` -> `의무적인`

2. **조사 삭제**
   - Balance와 동일하게 모든 주요 조사(`은/는/이/가/을/를` 등) 제거.

3. **길이 제한**
   - **최대 15자**.

---

## 4. 파일 및 코드 위치
- **Balance Composer**: `src/lib/composer/BalanceQuestionComposer.ts`
- **Truth Composer**: `src/lib/composer/TruthQuestionComposer.ts`
- **Test Data**: `src/data/raw_opal/sample_enrichment_test.json`
