# TalkBingo Product Requirements Document (PRD)

## 1. 프로젝트 개요 (Project Overview)

**TalkBingo**는 관계 기반 실시간 대화형 밸런스 빙고 게임 플랫폼입니다. 단순한 질문 생성을 넘어, **Supabase**를 활용한 실시간 데이터 동기화와 **동적 젠더 변형 시스템(Dynamic Gender Variants)**을 통해 사용자 간의 관계와 맥락에 딱 맞는 대화 경험을 제공합니다.

### 1.1 목표 (Goals)
- **관계 증진**: 사용자 간의 관계와 친밀도에 최적화된 질문을 통해 대화를 유도합니다.
- **동적 맥락 적응**: 정적인 텍스트 대신, 턴마다 화자와 청자의 성별/관계에 맞춰 질문이 자연스럽게 변형됩니다. (예: "형이 생각하기엔...", "누나가 볼 땐...")
- **지속적 상호작용**: 게임 횟수와 결과에 따라 친밀도 레벨을 조정하고, 이전 대화를 기억하여 맞춤형 경험을 제공합니다.

---

## 2. 시스템 아키텍처 (System Architecture)

### 2.1 기술 스택 (Tech Stack)
- **Frontend (Mobile App)**: Flutter (iOS/Android)
- **Backend**: Supabase (PostgreSQL, Realtime, Auth, Edge Functions)
- **Admin**: Python Scripts (Data Management)
- **AI Engine**: OpenAI GPT-4 (Used for Question Variant Generation)

### 2.2 Dynamic Variant System (동적 변형 시스템)
TalkBingo는 고정된 텍스트의 한계를 넘어, 실시간 상황에 맞는 질문을 제공합니다.

1.  **Wildcard Fetching (와일드카드 검색)**:
    - **기존 문제**: `M-F` (남->여) 질문은 `F-M` 상황에서 쓸 수 없어 데이터가 파편화됨.
    - **해결**: 모든 질문을 **관계(Relation)와 친밀도(Intimacy)** 기준으로만 검색합니다. (예: `*-*-Friend-L3`)
    - **효과**: 성별에 구애받지 않고 풍부한 질문 풀(Pool)을 확보합니다.

2.  **Gender Variants (성별 변형 데이터)**:
    - 하나의 질문 데이터(Row)는 내부적으로 4가지 텍스트 변형을 포함합니다.
    - **Data Structure (JSONB)**:
        ```json
        {
          "M_to_F": "누나/동생에게 바라는 점은?",
          "F_to_M": "오빠/동생에게 바라는 점은?",
          "M_to_M": "형/동생에게 바라는 점은?",
          "F_to_F": "언니/동생에게 바라는 점은?"
        }
        ```

3.  **Real-time Adaptation (실시간 적응)**:
    - 게임 중 **턴(Turn)**이 바뀔 때마다, 앱 클라이언트가 현재 **Attacker(질문자)**와 **Defender(응답자)**의 성별을 확인하여 위 JSON에서 적절한 텍스트를 즉시 렌더링합니다.

4.  **질문 큐레이션 (Question Curation)**:
    - **밸런스**: 게임당 **Balance(12~13)** + **Truth(12~13)** 비율을 맞춰 총 25개 배치.
    - **Fallback**: 특정 관계의 질문이 부족할 경우, 더 넓은 범위(Broad Relation)의 질문을 자동으로 가져와 채웁니다.

---

## 3. 사용자 플로우 (User Flows)

(기존 섹션 3.1 ~ 3.5 유지, 로직 설명만 Supabase 기준으로 이해)
*   **호스트 플로우**: 초대 코드 생성 -> 대기실(Realtime Subscribe).
*   **데이터 전달**: 호스트가 질문 세트(`gender_variants` 포함)를 `game_state`에 업로드 -> 게스트 동기화.

---

## 4. 기능 요구사항 (Functional Requirements)

### 4.1 Data Management & AI
- **CSV 기반 관리**: 기획자가 `Target`, `Content`, `Variants`를 작성한 CSV를 업로드합니다.
- **AI Variant Generation**: 기본 질문(`Content`)만 작성하면, AI가 자동으로 4가지 성별 변형(`var_m_f` 등)을 생성하여 CSV를 완성해줍니다. (Python Script 활용)

### 4.2 성능 및 최적화
- **Pre-fetching**: 게임 시작 전(Lobby)에 모든 변형 텍스트를 미리 로드하여, 게임 중에는 네트워크 지연 없는 텍스트 교체가 이루어집니다.
- **Supabase Realtime**: 게임 상태(Turn, Tile Selection)를 밀리세초 단위로 동기화합니다.

---

## 5. 데이터 모델 (Data Model - Supabase)

### 5.1 Tables
- **User**: `user_id`, `email`, `nick`, `gender`, `role` ...
- **GameSession**: `game_id`, `mp_id`, `cp_id`, `status`, `game_state` (JSONB)
- **Question**: 
    - `id` (UUID)
    - `type` (Truth/Balance)
    - `content` (Basic Text)
    - `details` (JSONB: choices/answers)
    - `gender_variants` (JSONB: M_to_F, etc.)
    - `code_names` (Array: Targeting Tags)
- **Reward**: `reward_id`, `vp`, `ap`, `ep` ...

### 5.2 Relationships (Logical)
- **Tagging**: `Question`은 `code_names` 배열을 통해 여러 관계 타겟(`B-Ar-L3`, `Fa-Si-L2` 등)에 동시에 속할 수 있습니다.
- **History**: `GameSession` 완료 시 `Log`가 생성되고, 유저의 `FriendRelation` 테이블에 플레이 횟수와 친밀도가 누적됩니다.

---

## 6. API 인터페이스 (API Interface)

### 6.1 Backend API (Flutter Client Integration)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET/POST | `/api/init-neo4j` | Neo4j 연결 확인 및 초기화 |
| POST | `/api/users/save-and-select-codename` | 사용자 정보 저장 및 CodeName 선별 |
| GET | `/api/questions/by-codename` | CodeName 기반 질문 조회 (Limit, Offset 지원) |
| POST | `/api/relation/update` | 관계 및 친밀도 업데이트 |
| POST | `/api/agent/analyze-result` | 게임 종료 후 결과 분석 및 요약 |

### 6.2 Socket Events
#### Client → Server (Emit)
- `join-waiting-room`: 대기실 참가 요청 (gameId, role)
- `guest-info-updated`: 게스트 정보 업데이트 전송
- `game-status-updated`: 게임 상태 변경 요청 (start, pause, end)

#### Server → Client (Listen)
- `player-joined`: 플레이어 참가 알림
- `guest-info-changed`: 게스트 정보 변경 알림 (호스트 수신)
- `codename-updated`: CodeName 생성/업데이트 알림
- `questions-ready`: 질문 큐레이션 완료 알림
- `game-status-changed`: 게임 상태 변경 알림
- `turn-change`: 턴 변경 알림
- `bingo-completed`: 빙고 달성 알림

---

## 7. UI/UX Design System

### 7.1 Color Palette (Host & Guest Theme)
- **Host (Pink Theme)**:
    - **Primary**: `#BD0558`, **Secondary**: `#FF0077`, **Dark**: `#610C39`
    - **Background**: `#0C0219` (Main), `#F4E7E8` (Player)
    - **Text**: `#FF0077` (Primary), `#FFF4F6` (Secondary), `#CDBFC1` (Muted), `#610C39` (Dark)
- **Guest (Purple Theme)**:
    - **Primary**: `#430887`, **Secondary**: `#6B14EC`, **Dark**: `#2E0645`
    - **Background**: `#0C0219` (Main), `#F0E7F4` (Player)
    - **Text**: `#6B14EC` (Primary), `#FDF9FF` (Secondary), `#C7BFCD` (Muted), `#2E0645` (Dark)
- **Common**:
    - **Background**: `#FFF9FB` (Light), `#0C0219` (Dark)
    - **Functional**: `#FF0000` (Warning), `#68CDFF` (Explanation)

### 7.2 Button Styles
- **Primary Button**:
    - **Host**: `#BD0558` (Pink)
    - **Guest**: `#430887` (Purple)
- **Secondary Button**:
    - **Host**: `#FFF9FB` (Hover Outline: `#610C39`)
    - **Guest**: `#FDF9FF` (Hover Outline: `#2E0645`)
- **Deactivated Button**:
    - **Host**: `#2E0645` (Hover Outline: `#FFF9FB`)
    - **Guest**: `#C7BFCD` (Hover Outline: `#FDF9FF`)

### 7.3 Typography
- **Title Font**: "NURA"
    - **Weights/Sizes**: 10px Light, 14px Semibold, 24px Extrabold.
- **Body Font (English)**: "Alexandria"
- **Body Font (Korean)**: "K2D"
    - **Weights/Sizes**: 10px Medium, 12px Semibold, 14px Semibold, 16px Bold.
- **Colors**:
    - **Host**: `#FFF4F6` (Main Pink), `#FF0077` (Secondary Pink)
    - **Guest**: `#FDF9FF` (Main Purple), `#6B14EC` (Secondary Purple)

### 7.4 Localization Policy (언어 표기 원칙)
1.  **Static UI (고정 텍스트)**:
    - 앱의 타이틀, 버튼, 필드 제목, 메뉴 등 앱의 구조를 이루는 모든 텍스트는 **영어(English)** 표기를 원칙으로 합니다.
    - *Example*: `Start Game`, `Nickname`, `Hometown`, `Chat`, `Bingo`
2.  **Dynamic Content (동적/입력 데이터)**:
    - 사용자가 직접 입력하거나 선택하는 데이터(닉네임, 고향, 지역 등)는 **사용자의 국가/언어 설정**에 따릅니다.
    - 한국 사용자의 경우 한국어로, 그 외 지역은 영어로 표기합니다.
3.  **Content Exception (질문 데이터 예외)**:
    - 현재 Neo4j 데이터베이스에 구축된 질문 데이터가 한국어만 지원하므로, **질문(Question)과 선택지(Options)**는 **한국어(Korean)**로 표기합니다.
    - 추후 다국어 데이터 구축 시 사용자 언어 설정에 맞춰 확장 예정입니다.

---

## 8. 수익 모델 (Revenue Model)

### 8.1 광고 (Advertising)
- **배너 광고 (Banner Ad)**: 화면 하단(Footer)에 상시 노출.
- **보상형 광고 (Rewarded Ad)**: 잠긴 빙고 칸(Mismatch) 해제 시 시청.
- **전면 광고 (Interstitial Ad)**: 게임 종료 후 결과 페이지 진입 전 노출.

### 8.2 인앱 결제 (In-App Purchase)
- **포인트 구매**:
    - **1,000 Point**: 900 KRW
    - **10,000 Point**: 9,000 KRW
- **포인트 사용**:
    - **광고 제거**: 게임 1회당 **200 Point** 차감 (모든 광고 제거).
    - **아이템 구매**: (추후 예정) 캐릭터, 이모티콘 등.


