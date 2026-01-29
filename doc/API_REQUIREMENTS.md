# ⭐ Important - TalkBingo - API 요구사항 명세서

## 📋 API 개요

TalkBingo 서비스의 핵심 기능별 API 요구사항을 정의합니다.
**최신 PRD (`doc/TalkBingoPRD.md`)**의 내용을 반영하여 **Dynamic Gender Variants**, **Supabase Wildcard Fetching**, **승인(Approval) 시스템**, **승리 단계(Victory Stages)**, **새로운 점수 체계(VP/AP/EP/TS)**를 포함합니다.

---

## 1. Auth (인증/계정)

### 1.1 회원가입 (Sign Up)
- **기능:** 새로운 사용자 계정 생성 (이메일 인증 기반)
- **입력:**
  - `email`: 이메일 주소
  - `nickname`: 닉네임
  - `age`: 나이
  - `gender`: 성별 (M/F)
- **출력:**
  - `user_id`: 생성된 사용자 고유 ID
  - `success`: 성공 여부 메시지 (인증 메일 발송)
- **HTTP Method:** POST
- **Endpoint:** `/api/auth/register`

### 1.2 로그인 (Sign In with OTP)
- **기능:** 사용자 인증 및 토큰 발급 (Magic Link / OTP)
- **입력:**
  - `email`: 이메일 주소
- **출력:**
  - `message`: "인증 메일이 발송되었습니다."
  - `otp_sent`: true
- **HTTP Method:** POST
- **Endpoint:** `/api/auth/login-otp`

### 1.3 프로필 생성/수정
- **기능:** 사용자 프로필 정보 관리
- **입력:**
  - `nickname`: 닉네임
  - `avatar`: 아바타 정보
  - `profile_image`: 프로필 이미지
- **출력:**
  - `message`: 수정 완료 메시지
- **HTTP Method:** PUT
- **Endpoint:** `/api/auth/profile`

### 1.4 위치 정보 설정
- **기능:** 사용자 위치 정보 설정 (연휴/트렌드 기반 맞춤 질문용)
- **입력:**
  - `country`: 국가 코드 (KR, US, JP 등)
  - `region`: 지역/시/도 정보
  - `timezone`: 시간대 정보
- **출력:**
  - `message`: 위치 정보 저장 완료 메시지
  - `holiday_info`: 다가오는 연휴 정보
- **HTTP Method:** PUT
- **Endpoint:** `/api/user/location`

### 1.5 트렌드 정보 조회
- **기능:** 현재 인기 트렌드 및 밈 정보 조회
- **입력:**
  - `region`: 지역 코드
  - `category`: 카테고리 (meme, slang, hashtag 등)
  - `limit`: 조회 수
- **출력:**
  - `trends`: 트렌드 리스트 (keyword, category, score, context, usage_examples)
  - `last_updated`: 마지막 업데이트 시간
- **HTTP Method:** GET
- **Endpoint:** `/api/trends`

---

## 2. Game (게임방 생성/참여)

### 2.1 사용자 정보 저장 및 타겟팅 설정 (Targeting Setup)
- **기능:** MP(호스트)의 입력 정보를 바탕으로 타겟팅 태그(Wildcard CodeName)를 생성
- **입력 (MP - Host):**
  - `gender`: 성별 (M/F)
  - `relationshipType`: 관계 유형 (예: "Friend")
  - `subRelationship`: 하위 관계 (예: "Ar")
  - `intimacyLevel`: 친밀도 레벨 (예: 3)
- **출력 (Client Logic / Helper):**
  - `targetTag`: `*-*-B-Ar-L3` (성별 무관, 관계/친밀도 기반 와일드카드)
  - `broadTag`: `*-*-B-*-L3` (Fallback용 광범위 태그)
- **HTTP Method:** (Client Internal or Supabase RPC)
- **Endpoint:** N/A (Client-Side Logic)

### 2.2 질문 조회 (Question Fetching)
- **기능:** 타겟팅 태그를 기반으로 Supabase에서 질문 조회 (Wildcard Matching)
- **입력:**
  - `tags`: 조회할 태그 배열 (`['*-*-B-Ar-L3', '*-*-B-*-L3']`)
  - `limit`: 조회할 질문 수 (25 + Alpha)
- **출력:**
  - `success`: 성공 여부
  - `data.questions`: 질문 리스트
    - `content`: 기본 텍스트
    - `gender_variants`: { "M_to_F": "...", "F_to_M": "..." } (JSONB)
- **HTTP Method:** GET (Supabase Query)
- **Endpoint:** `/rest/v1/questions` (Supabase)

### 2.3 게임방 생성
- **기능:** 새로운 게임방 생성 및 초대 링크 생성
- **입력:**
  - `mp_id`: MP ID
  - `board_size`: 보드 크기 (5)
- **출력:**
  - `game_id`: 생성된 게임 ID
  - `invite_link`: 초대 링크
- **HTTP Method:** POST
- **Endpoint:** `/api/game/create`

### 2.4 게임 참여
- **기능:** 기존 게임방에 참여
- **입력:**
  - `game_id`: 게임 ID
  - `cp_id`: CP ID
- **출력:**
  - `success`: 참여 성공 여부
  - `waiting_room_info`: 대기실 정보
- **HTTP Method:** POST
- **Endpoint:** `/api/game/join`

### 2.5 게임 상태 확인 (대기실용)
- **기능:** 게스트 대기실에서 호스트의 게임 입장 여부(게임 시작) 확인
- **입력:**
  - `game_id`: 게임 ID
- **출력:**
  - `status`: "WAITING" | "PLAYING"
  - `mp_joined`: true (호스트가 이미 입장했는지 여부)
- **HTTP Method:** GET
- **Endpoint:** `/api/game/status/{game_id}`

---

## 3. Play (게임 진행 - 턴/승인/점유)

### 3.1 칸 선택 (Select Cell)
- **기능:** 턴을 가진 플레이어가 빙고칸 선택
- **입력:**
  - `game_id`: 게임 ID
  - `user_id`: 사용자 ID
  - `cell_coordinates`: 좌표 (x, y)
- **출력:**
  - `cell_type`: **T** (Truth), **B** (Balance), **M** (Mini - Lock된 경우)
  - `question`: 질문 내용 (기본 텍스트)
  - `variants`: 동적 텍스트 변형 데이터 (JSONB, Client Rendering용)
  - `choices`: 선택지 (B Type인 경우)
  - `time_limit`: 제한 시간 (기본 30초)
- **HTTP Method:** POST
- **Endpoint:** `/api/play/select-cell`

### 3.2 응답 제출 (Submit Response)
- **기능:** 퀴즈에 대한 답변 제출
- **입력:**
  - `game_id`: 게임 ID
  - `user_id`: 사용자 ID
  - `question_id`: 질문 ID
  - `response_data`: 답변 내용 (텍스트 또는 선택지 인덱스)
  - `time_taken`: 소요 시간
- **출력:**
  - `success`: 제출 성공
  - `waiting_for_approval`: 상대방 승인 대기 상태로 전환
- **HTTP Method:** POST
- **Endpoint:** `/api/play/submit-response`

### 3.3 승인/거절 처리 (Approve/Reject)
- **기능:** 상대방의 답변에 대해 승인 또는 거절
- **입력:**
  - `game_id`: 게임 ID
  - `user_id`: 승인하는 사용자 ID (상대방)
  - `target_cell_id`: 대상 칸 ID
  - `action`: **"APPROVE"** (인정/공감/납득) 또는 **"REJECT"** (거절)
- **출력:**
  - `result`:
    - `APPROVE`: 타일 **점유(Claim)** 성공 (EP 지급).
    - `REJECT`: 타일 **Lock** 처리 (점유 실패).
  - `bingo_check`: 빙고 라인 완성 여부 확인
- **HTTP Method:** POST
- **Endpoint:** `/api/play/approve-response`

### 3.4 미니게임 결과 (Mini Game Result)
- **기능:** Lock된 칸의 패자부활전(M Type) 결과 처리
- **입력:**
  - `game_id`: 게임 ID
  - `user_id`: 승리한 사용자 ID
  - `cell_coordinates`: 좌표
  - `mini_game_score`: 미니게임 점수
- **출력:**
  - `success`: 성공 여부
  - `cell_claimed`: 타일 점유 성공 (Lock 해제)
- **HTTP Method:** POST
- **Endpoint:** `/api/play/minigame-result`

---

## 4. Result (게임 결과 & 승리 단계)

### 4.1 게임 종료/결과 저장
- **기능:** 게임 종료 및 최종 결과 저장
- **입력:**
  - `game_id`: 게임 ID
  - `victory_stage`: 승리 단계 (**1st**, **2nd**, **Final**)
  - `winner_id`: 승리자 ID (또는 'DRAW')
  - `mp_score`: MP 최종 점수 (VP/AP 포함)
  - `cp_score`: CP 최종 점수 (VP/AP 포함)
  - `ts_evaluation`: TS 평가 점수 (CP -> MP)
- **출력:**
  - `success`: 저장 성공
  - `rewards_distributed`: 보상 지급 내역
- **HTTP Method:** POST
- **Endpoint:** `/api/result/save`

### 4.2 결과 조회
- **기능:** 게임 결과 상세 조회
- **입력:**
  - `game_id`: 게임 ID
- **출력:**
  - `winner`: 승자 정보
  - `stage`: 달성한 승리 단계 (1/2/3)
  - `points_breakdown`: VP, AP, EP 상세 내역
  - `ts_summary`: 신뢰도 평가 결과
- **HTTP Method:** GET
- **Endpoint:** `/api/result/{game_id}`

---

## 5. Reward (보상 시스템)

### 5.1 포인트 지급 규칙 (참고)
API 내부 로직에서 다음 규칙을 따릅니다.
*   **VP (Victory Point)**:
    *   1줄 승리: **50 VP**
    *   2줄 승리: **100 VP**
    *   3줄 승리: **150 VP**
    *   무승부: 각 **25 VP**
*   **AP (Activity Point)**: 빙고 1줄당 **5 AP**
*   **EP (Experience Point)**: 타일 1개 점유당 **1 EP**

### 5.2 포인트 수동 지급 (Admin/System)
- **기능:** 포인트 지급/차감
- **입력:**
  - `user_id`: 사용자 ID
  - `type`: VP/AP/EP
  - `amount`: 수량
  - `reason`: 지급 사유 (예: "Monthly TS Bonus")
- **출력:**
  - `current_balance`: 현재 잔액
- **HTTP Method:** POST
- **Endpoint:** `/api/reward/manage`

### 5.3 TS 평가 및 보너스
- **기능:** TS 평가 저장 및 월간 보너스 체크
- **입력:**
  - `mp_id`: 평가 대상 (MP)
  - `score`: 별점 (1.0 ~ 5.0)
- **로직:**
  - 월간 평균 4.5 이상 시 **5 VP** 추가 지급 로직 트리거.
- **HTTP Method:** POST
- **Endpoint:** `/api/reward/ts-eval`

---

## 6. Admin/Internal

### 6.1 Admin/Internal
*   기존 `8.3`, `8.4`, `8.5`, `8.6` 항목 유지 (연휴/트렌드 기반 질문 생성 로직은 `3.1`에서 활용됨).

---

## � API 사용 시나리오 (Example)

### 턴 진행 및 승인 프로세스
1.  **MP**가 `(2,2)` 좌표 선택 -> `/api/play/select-cell` 호출.
    *   응답: `type: "T"`, `question: "가장 기억에 남는 여행은?"`
2.  **MP**가 답변 입력 후 제출 -> `/api/play/submit-response`.
    *   상태: `WAITING_FOR_APPROVAL`
3.  **CP** 화면에 답변 표시됨. **CP**가 "인정" 버튼 클릭 -> `/api/play/approve-response` (action: "APPROVE").
4.  서버:
    *   `(2,2)` 타일 MP 소유로 변경.
    *   **EP +1** 지급.
    *   빙고 라인 체크 -> 1줄 완성 확인.
    *   응답: `bingo_check: { lines: 1, is_victory: true }`
5.  **MP** 화면에 "1차 승리! 계속하시겠습니까?" 팝업 표시.
