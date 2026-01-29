# TalkBingo 게임 흐름 및 데이터 아키텍처 (Game Flow & Data Architecture)

이 문서는 게임 페이지와 채팅 화면의 구조, 유저 간 인터랙션, 그리고 클라이언트와 Supabase 간의 엔드투엔드 데이터 흐름(가져오기, 전달, 저장)을 상세히 설명합니다.

---

## 1. 화면 구조 (UI Construction)

애플리케이션은 **게임 보드(Game Board)**와 **채팅 인터페이스(Chat Interface)**를 `PageView` 구조로 통합하여 직관적인 스와이프 경험을 제공합니다.

### 1.1 게임 페이지 (`GameScreen`)
실시간 인터랙션을 관리하기 위해 복합적인 `Stack` 계층 구조를 사용합니다.

*   **상태 바 & 탑 바 (Top Bar)**:
    *   **호스트 전용 컨트롤**: 방장(Host)에게만 `PopupMenuButton`이 노출되어 게임 제어(일시정지, 재시작, 섞기, 종료)가 가능합니다. **[Safe Exit]** 종료 시 "저장하고 나가기" 옵션이 제공됩니다.
    *   **배경**: `AnnotatedRegion`을 사용해 투명 처리되어 배경과 일체감을 줍니다.

*   **메인 바디 (`PageView`)**:
    *   유저가 좌우로 스와이프하여 **빙고 보드**와 **채팅** 화면을 오갈 수 있습니다.
    *   **빙고 보드 (`BingoGrid`)**: 5x5 그리드. 상태별 애니메이션(Hover/Press, Pulse)과 역할별 색상(Host: Pink, Guest: Purple)이 적용됩니다.
    *   **인터랙션 레이어 (Interaction Layer)**: `Stack` 최상단에 조건부로 렌더링됩니다.
        *   `QuizOverlay`: 밸런스/진실게임 질문 및 대화창. **(Dynamic Content Adaptation: 턴과 성별에 따라 질문 텍스트가 자동 변환됨)**
        *   **Inline Mini-Games**: `StartInteraction` 시 전체 화면 오버레이가 아닌 보드 위 **인라인 형태**로 미니게임(승부차기 등)이 로드되어 양쪽 플레이어가 동시에 같은 UI를 공유합니다.

*   **플로팅 오버레이 (Floating Overlays)**:
    *   **점수/알림**: 획득 시 일시적으로 나타나는 `Positioned` 위젯.
    *   **승리 효과**: 빙고 달성 시 Confetti(꽃가루) 효과.
    *   **입장 알림 (Entrance Toast)**:
        *   호스트 입장 시(게스트 화면): "초대자가 입장하셨습니다" 모달.
        *   게스트 입장 시(호스트 화면): "ooo님이 입장하셨습니다" 모달.
    *   **광고 대기 (`Ad Handshake`)**: `paused_ad` 상태일 때 "상대방을 기다리는 중" 쉴드가 표시됩니다.

### 1.2 채팅 및 티커 (Chat & Ticker)
*   **구조**: `PageView`의 한 페이지로 존재하며, 게임 중 언제든 접근 가능합니다.
*   **티커 (Ticker)**:
    *   상단에 흐르는 메시지 바는 시스템 메시지를 제외한 **순수 유저 채팅**만 필터링하여 표시합니다 (`type: 'chat'`만 허용).
    *   이를 통해 게임 중에도 놓친 대화를 빠르게 확인할 수 있습니다.

---

## 2. 유저 인터랙션 (User Interactions)

### 2.1 미니멀리스트 인터랙션 루프 (Minimalist Gameplay Loop)
현재 게임 페이지는 몰입감을 높이고 인지 부하를 줄이기 위해 **"Context Preservation (맥락 유지)"** 및 **"Focus Mode"**를 적용합니다.

1.  **선택 및 포커스 모드 (Selection & Focus Mode)**:
    *   턴을 가진 플레이어가 타일을 탭하면 `QuizOverlay`가 열립니다.
    *   **동적 렌더링 (Dynamic Rendering)**:
        *   **Board**: 공간 제약상 `content`(기본 질문)가 표시됩니다.
        *   **Overlay**: 현재 턴의 **Attacker(질문자)와 Defender(응답자)** 성별 조합에 맞춰, `variants` 필드에서 가장 적합한 텍스트(예: "누나/동생...")를 찾아 표시합니다.
    *   **맥락 유지 (Context Preservation)**: 상대방에게도 동일한 변형 텍스트가 표시되어 완벽한 대화 맥락을 공유합니다.
2.  **답변 및 대화 (Answer & Discussion)**:
    *   **질문자 (Requester)**: 답변을 입력하거나(T-Type) 선택지를 고릅니다(B-Type). 선택 시 해당 항목이 강조됩니다.
    *   **가이드**: 하단 버튼 영역에 **"공감 할수 있게 대화 해 보세요"**라는 가이드 문구가 표시되어, 단순 입력보다 채팅/음성 대화를 유도합니다.
    *   **상대방 (Partner)**: 질문자가 선택하는 동안 동일한 화면을 보며 실시간 채팅으로 소통할 수 있습니다.
3.  **평가 단계 (Review Phase - Unified View)**:
    *   질문자가 입력을 완료하면 검토 단계(`step: reviewing`)로 전환됩니다.
    *   **시각적 동기화**: 상대방 화면에서도 질문자가 선택한 항목이 **선명한 색상**과 **입체적인 3D 효과(Elevation)**로 강하게 강조됩니다. 버튼이 솟아오른 듯한 시각적 피드백을 주며, 선택하지 않은 항목은 흐리게(Dimmed) 처리됩니다.
    *   **액션 버튼**: 상대방 하단에 **[비공감] (Reject)** 및 **[공감] (Approve)** 버튼이 나타납니다.
4.  **결과 처리 (Resolution)**:
    *   **공감 (Approve)**: 질문자가 타일을 점유하고 **+1 EP**를 획득합니다.
    *   **비공감 (Reject)**: 타일이 **잠김(LOCKED)** 상태가 되며 점수를 얻지 못합니다.
    *   **잠금 해제 (Unlock)**: 잠긴 타일을 탭하면 **미니게임 (승부차기/타겟슈터)**이 발동되어 승자가 타일을 차지합니다.

### 2.2 채팅 인터랙션
*   **보내기**: 유저가 텍스트 입력 -> 전송 탭 -> `GameSession.sendMessage()`.
*   **받기**: Supabase 구독이 `notifyListeners()`를 트리거하여 UI를 즉시 업데이트합니다.

---

## 3. 데이터 흐름 아키텍처 (Data Flow Architecture)

이 시스템은 데이터 가져오기에는 **중앙 집중식 호스트 권한(Centralized Host Authority)** 패턴을, 실시간 전달에는 **공유 상태 블롭(Shared State Blob)**을 사용합니다.

### 3.1 데이터 획득 (Fetch & Filter)
질문은 모든 클라이언트가 무작위로 가져오지 않습니다. **호스트(방장)**가 초기화 시 서버 측 권한을 행사합니다.

1.  **소스**: Supabase의 `public.questions` 테이블.
2.  **트리거**: 호스트가 `WaitingScreen`에 진입할 때 발생.
3.  **쿼리 로직** (`GameSession.fetchQuestionsFromSupabase`):
    *   **입력**: `targetCode` (예: `*-*-B-Ar-L3` - 성별 무관 Wildcard 사용).
    *   **필터링**: `code_names` 컬럼에 대해 Postgres 배열 포함 연산자(`@>`)를 사용하여 일치하는 질문을 찾습니다.
    *   **다이내믹 페칭**: 성별을 고정하지 않고 **관계와 친밀도**만으로 질문을 넓게 가져옵니다.
    *   **밸런스 알고리즘**: 약 100개의 후보를 가져와 사용한 질문(Local `SharedPreferences` 확인)을 필터링하고, 무작위로 **진실 13개**, **밸런스 12개**를 선택합니다.

### 3.2 데이터 전달 및 동기화 (Data Delivery)
가져온 질문은 게스트에게 전달되어야 합니다.

1.  **초기 핸드셰이크 ("업로드")**:
    *   호스트는 질문을 하나씩 보내지 않습니다.
    *   **동작**: 호스트가 `uploadInitialQuestions()`를 호출합니다.
    *   **페이로드**: 호스트는 선택된 25개의 질문 리스트(Variant 포함)를 직렬화하여 `game_sessions` 테이블의 `game_state` JSON 컬럼에 저장합니다.
    *   *이유*: 이를 통해 두 플레이어가 전체 세션 동안 *정확히 동일한* 보드 레이아웃과 질문 세트를 공유하게 됩니다.

2.  **전송 데이터 구조**:
    ```json
    // game_sessions.game_state 내부
    {
      "questions": [
        { 
          "id": "...", 
          "content": "질문 내용...", 
          "type": "truth",
          "gender_variants": { "M_to_F": "...", "F_to_M": "..." } 
        },
        ... 25 items
      ],
      "tileOwnership": [null, "A", null, ...],
      "currentTurn": "A"
    }
    ```

### 3.3 실시간 업데이트 (Delivery)
*   **프로토콜**: Supabase Realtime (Postgres Changes 감지).
*   **채널**: `public:game_sessions:id=eq.SESSION_ID`.
*   **게스트 흐름**:
    *   게스트는 채널을 구독합니다.
    *   호스트가 `game_state`를 업로드하면, 게스트가 페이로드를 수신합니다.
    *   앱이 `questions` 배열을 파싱 -> `BingoBoard` 재구축 -> `GameScreen`으로 자동 이동.

### 3.4 데이터 저장 및 지속성 (Storage & Persistence)
데이터는 복구 가능성과 기록 보존을 위해 여러 계층에 저장됩니다.

1.  **세션 저장소 (Hot Storage)**:
    *   **위치**: `game_sessions` 테이블 -> `game_state` 컬럼 (JSONB).
    *   **내용**: 전체 보드 상태, 채팅 기록(`messages` 배열), 현재 턴, 인터랙션 단계.
    *   **목적**: 앱이 종료되어도 유저가 진행 상황 손실 없이 재접속(Reconnection)할 수 있게 합니다.

2.  **유저 기록 (Cold Storage)**:
    *   **위치**: 로컬 `SharedPreferences`의 `played_questions`.
    *   **목적**: 유저가 바로 다음 게임에서 동일한 질문을 다시 보지 않도록 방지합니다.

3.  **보상 (Secure Storage)**:
    *   **위치**: `profiles` 테이블 (VP/포인트 잔액).
    *   **방법**: `charge_vp()` RPC 함수.
    *   **목적**: 보안. 포인트는 클라이언트에서 테이블에 직접 쓰지 않고 서버 측 함수를 통해 업데이트하여 변조를 방지합니다.
    *   **익명 유저**: 익명 사용자의 VP/History도 `profiles`에 저장되나, 안전한 보존을 위해 **계정 연동(Link)**이 권장됩니다.

    *   **지속성**: 이 과정 후 로컬(`SharedPreferences`) 데이터도 동기화되어 유저는 끊김 없는 경험을 유지합니다.

### 3.5 게임 저장 및 종료 흐름 (Save & Exit Flow)
*   **게임 저장 (Save)**: "저장하기" 클릭 시 현재 상태를 **임시 저장** 상태로 플래그합니다.
*   **게임 종료 (End)**:
    *   **호스트**: `game_sessions` 상태를 즉시 `saved`로 확정하고 종료 절차를 밟습니다. (영구 저장)
    *   **게스트**: `temporary_saved` 상태로 마킹하고 **리워드 페이지**로 이동합니다.
    *   **게스트 전환 (Conversion)**: 리워드 페이지에서 "회원가입"을 완료하면, 해당 임시 저장된 게임이 유저의 프로필에 연결되어 **영구 저장**됩니다.
*   **오류 복구 (Error Recovery)**:
    *   시스템 크래시나 예기치 않은 종료 발생 시, 앱 재실행 -> 스플래시 -> 오류 메시지 -> 홈 화면으로 이동합니다.
    *   이전 상태가 `temporary_saved`나 `playing`으로 남아있다면, 홈 화면의 "이어하기(Resume)" 기능을 통해 복구를 시도할 수 있습니다.
    *   **정산 보장**: 빙고 완성 후 강제 종료 시, 완성 시점의 점수는 이미 DB/Session에 반영되어 있으므로 리워드 페이지에서 올바르게 표시됩니다.
