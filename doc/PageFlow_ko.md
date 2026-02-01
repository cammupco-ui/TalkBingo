# TalkBingo 페이지 정의 및 탐색 흐름 (Navigation Flow)

이 문서는 TalkBingo 앱의 모든 화면을 정의하고, 사용자 역할(호스트 vs 게스트)에 따른 목적과 탐색 로직을 설명합니다.

## 1. 인증 및 진입 (Authentication & Entry)

### **SplashScreen** (`splash_screen.dart`)
-   **목적:** 앱의 시작점. 로그인 상태 확인, 익명 로그인 처리, 딥링크 감지.
-   **로직:**
    -   **보안 강화 (Security):** 비로그인 유저 진입 시 `signInAnonymously()`를 통해 **익명 세션**을 발급받아 RLS 보안을 준수함.
    -   신규/비로그인 -> **LoginScreen** 이동 (기본).
    -   로그인된 사용자 (익명/정식) -> **HomeScreen** 이동.
    -   **딥링크 (Deep Link):**
        -   (비로그인) 초대 코드 -> **InviteCodeScreen**.
        -   (로그인됨) 초대 코드 -> **HomeScreen**을 거쳐 **자동으로 WaitingScreen으로 납치(Fast Track)**.

### **LoginScreen** (`login_screen.dart`)
-   **목적:** 앱의 메인 진입점.
-   **기능:**
    1.  **Log in:** 이메일/비밀번호 로그인.
    2.  **Continue with Google:** 구글 계정 로그인.
    3.  **Enter Invite Code:** 초대 코드 입력 화면으로 이동 (게스트).
    4.  **Sign Up:** 회원가입 화면(`SignupScreen`)으로 이동 링크 제공.
-   **탐색 (Navigation):**
    -   로그인 성공 -> **Supabase Profile 확인**:
        -   **프로필 있음:** -> **HomeScreen** (즉시 이동).
        -   **프로필 없음:** -> **HostInfoScreen** (닉네임 설정/가입절차완료) -> **HomeScreen**.

### **SignupScreen** (`signup_screen.dart`)
-   **목적:** 신규 회원가입.
-   **기능:** 이메일, 비밀번호, 비밀번호 확인 입력 후 가입.
-   **탐색:** 가입 완료 및 이메일 인증 -> **LoginScreen** (로그인 유도).

### **Returning Guest** (재방문 게스트/익명 사용자)
-   **시나리오:** 인증되지 않은 사용자(게스트/익명)가 재접속 시.
-   **로직:**
    1.  `SplashScreen`에서 **익명 세션(Anonymous Session)**을 유지하여 **HomeScreen**으로 즉시 진입.
    2.  **Conversion (회원 전환):**
        -   **SettingsScreen**에서 "**Sign Up / Link Account**" 버튼 클릭.
        -   `SignupScreen`에서 계정 연동 진행.
    3.  **완료 후:** `HomeScreen`으로 복귀하여 정식 회원 권한 획득.

---

## 2. 호스트 흐름 (신규가입)

### **SignupScreen -> HostInfoScreen** (`host_info_screen.dart`)
-   **목적:** 호스트 가입 후 프로필 정보(닉네임, 성별) 설정.
-   **역할:** 호스트 (최초 1회).
-   **탐색 (Navigation):** -> **HomeScreen**.

### **HostSetupScreen** (`host_setup_screen.dart`)
-   **목적:** 게임 생성 1단계 - 초대 코드 생성.
-   **역할:** 호스트.
-   **기능:** 랜덤 코드 생성, 초대 링크 복사, 초대 링크 공유.
-   **탐색 (Navigation):** -> **GameSetupScreen**.

### **GameSetupScreen** (`game_setup_screen.dart`)
-   **목적:** 게임 생성 2단계 - 호스트가 입력하는 게스트와의 관계 정보.
-   **역할:** 호스트.
-   **기능:** 관계, 세부관계, 친밀도 선택.
-   **보완점 (Robustness):**
    -   **임시 저장 (Draft Save):** 입력 도중 앱이 종료되더라도 재진입 시 선택 상태가 유지되어야 함 (`SharedPreferences`).
    -   **스마트 프리셋 (Smart Preset):** 이전에 선택했던 관계/친밀도 옵션을 기본값으로 제공하여 설정 피로도 감소.
-   **탐색 (Navigation):** -> **WaitingScreen**.

## 2. 호스트 흐름 (기존가입)

### **HomeScreen** (`home_screen.dart`)
-   **목적:** 호스트를 위한 메인 대시보드.
-   **역할:** **오직 회원가입한 유저만 접근가능**.
-   **기능:** 프로필/포인트 조회, 새 게임 시작, 게임 이어하기, 초대된 게임 참여, 설정 진입.
-   **탐색 (Navigation):**
    -   새 게임 시작 (Start New Game) -> **HostSetupScreen**.
    -   게임 이어하기 (Resume Game) -> **GameScreen**.
    -   초대된 게임 참여하기(Invite Game) -> 이 경로인 경우에는 "게스트"로 변환 ->**InviteCodeScreen** -> **WaitingScreen**.
    -   설정 (Settings) -> **SettingsScreen**.

    -   **히스토리 (History):**
        -   **Review Mode:** 지난 게임 기록 보기 (Read-Only). `GameScreen`으로 이동하되 입력이 차단됨.
        -   **Rematch (재대결):** [R] 버튼 클릭 시 새코드생성후 링크를 다시 유저에게 보내고(`HostSetupScreen`)을 그대로 사용하여 새 게임 생성.
            -   **Fast Track:** `HostSetupScreen`에서 링크를 보내고 나서, 잠시 로딩된 후 즉시 **GameSetupScreen**진입, 진입 시 설정이 **자동으로 적용**되고 **WaitingScreen**으로 넘어감.
    #### **SettingsScreen** (`settings_screen.dart`)
-   **목적:** 호스트 정보 수정 및 결제정보, 포인트 변환 및 구매 관리.
-   **역할:** 호스트.
-   **기능:**
    -   **프로필 수정:** 닉네임, 성별 수정.
    -   **계정 연동:** (익명일 경우) **Sign Up / Link Account** 버튼 노출.
    -   **결제 정보(TalkBingo Pay):**
        -   신용카드 정보 등록/수정 (카드번호, 유효기간, CVV, 소유자명).
        -   **TalkBingo Pay 비주얼 카드:** 입력 실시간 반영되는 그라데이션 카드 UI.
    -   **포인트 관리 이동:** "Manage Points / Purchase" 버튼 -> **PointPurchaseScreen**.
    -   **로그아웃:** -> **SignOutLandingScreen**.

    #### **PointPurchaseScreen** (`point_purchase_screen.dart`)
    -   **목적:** 포인트 소지 현황 조회, 포인트 구매 및 변환.
    -   **Hybrid Payment System (플랫폼별 구분):**
        -   **Web:** **PG 결제 (PortOne)** 사용. **"Korea Card / Global Card" 선택기** 노출.
        -   **App:** **In-App Purchase (IAP)** 사용. 선택기 숨김 (Store Policy).
    -   **포인트 구성:**
        1.  **VP (Victory Point):** 프리미엄 재화. 현금 구매로 충전. 광고 제거 등에 사용.
        2.  **AP (Attitude Point):** 게임 플레이(빙고 완성) 보상. VP로 전환 가능.
        3.  **EP (Emotion Point):** 타일 점유 보상. VP로 전환 가능.
    -   **기능:**
        -   **포인트 현황:** 실시간 애니메이션 숫자로 표시.
        -   **포인트 전환:** AP/EP -> VP 교환 (Exchange 버튼).
        -   **VP 구매:**
            -   구매 옵션 선택 ($1.00 ~ $9.50) -> 플랫폼별 결제 모듈 호출.
        -   **포인트 히스토리:** 상단 **History Icon** -> **포인트 이용내역(History) 모달** (구매/사용/교환 기록).
    -   **탐색 (Navigation):**
        -   **뒤로가기 (Back Icon):** -> **SettingsScreen**.
        -   **홈으로 이동 (Logo Tap):** -> **HomeScreen**.
    #### **SignOutLandingScreen** (`sign_out_landing_screen.dart`)
    -   **목적:** 로그아웃 후 사용자에게 다음 행동 옵션 제공.
    -   **기능:**
        1.  **Log In Again:** 초기 화면(**Splash**)으로 돌아가 재로그인 시도.
        2.  **Exit App:** 앱 종료. 

### **HostSetupScreen** (`host_setup_screen.dart`)
-   **목적:** 게임 생성 1단계 - 초대 코드 생성.
-   **역할:** 호스트.
-   **기능:** 랜덤 코드 생성, 초대 링크 복사.
-   **탐색 (Navigation):** -> **GameSetupScreen**.

### **GameSetupScreen** (`game_setup_screen.dart`)
-   **목적:** 게임 생성 2단계 - 호스트가 입력하는 게스트와의 관계 정보.
-   **역할:** 호스트.
-   **기능:** 관계, 세부관계, 친밀도 선택.
-   **탐색 (Navigation):** -> **WaitingScreen**.

---

## 3. 게스트 흐름 (게임 참여 - Joining)

### **SignupScreen** (`signup_screen.dart`)
-   **목적:** 앱의 진입점. 소셜 로그인(호스트) 또는 초대 코드 입력(게스트) 선택.
-   **역할:** 모든 사용자(Host/Guest)의 시작점. (Web 환경에서는 항상 이 화면이 먼저 표시됨)
-   **기능:**
    1.  **Sign up with Google:** 호스트 로그인/가입.
    2.  **Enter Invite Code:** 게스트로서 코드 입력 화면으로 이동.
-   **탐색 (Navigation):** -> **HostInfoScreen** (Google 로그인 시) / **InviteCodeScreen** (코드 입력 선택 시).

### **InviteCodeScreen** (`invite_code_screen.dart`)
-   **목적:** 게스트가 링크 또는 코드를 입력하여 입장하는 화면.
-   **역할:** **오직 게스트만 접근 가능**.
-   **기능:** 6자리 코드 입력. (링크로 접속 시 자동 입력됨)
-   **예외 처리 (Error Handling):**
    -   **유효하지 않은 코드:** "코드를 찾을 수 없습니다" 에러 메시지 + 다시 입력 유도.
    -   **종료된 게임:** "이미 종료된 게임입니다" 알림.
    -   **풀 방 (Full):** (향후 다자간 확장 시) "인원이 가득 찼습니다".
-   **탐색 (Navigation):** -> **GuestInfoScreen**.

### **GuestInfoScreen** (`guest_info_screen.dart`)
-   **목적:** 게임 참여를 위해 게스트의 프로필 정보를 입력.
-   **역할:** 게스트.
-   **기능:** 닉네임 입력.
-   **UX 개선 (Optimizations):**
    -   **Remember Me:** 한 번 입력한 닉네임은 로컬에 저장하여, 다음 접속 시 **자동 입력(Pre-fill)**.
    -   **Random Generator:** "익명123" 같은 닉네임을 고민 없이 생성해주는 '주사위' 버튼 제공.
-   **탐색 (Navigation):** -> **WaitingScreen**.

---

## 4. 공통 플레이 경험 (Shared Gameplay Experience)

### **WaitingScreen** (`waiting_screen.dart`)
-   **목적:** 게임 시작 전 대기실.
-   **역할:** 공통 (역할에 따라 UI가 다름).
-   **로직:**
    -   **호스트 화면:** "게임설정 중입니다.". 호스트 클라이언트가 입력된 **관계(Relation) 및 친밀도(Intimacy)**를 기반으로 Supabase에서 질문을 선별조회(Wildcard Fetching)하여, 변형 데이터가 포함된 질문 세트를 구성하고 **GameSession**에 업로드합니다.
    -   **게스트 화면:** "호스트가 시작하길 기다리는 중...". 호스트가 **GameScreen**으로 이동함을 감지.
    -   **연결 안정성 (Connection Stability):**
        -   **Heartbeat:** 대기 중 네트워크 끊김 감지 시 "재연결 중..." 표시.
        -   **백그라운드 처리:** 호스트가 설정 중 앱을 잠깐 내려도(Background) 세션이 유지되어야 함.
-   **탐색 (Navigation):** -> **GameScreen** (선 호스트 입장 후 게스트 입장).

### **GameScreen** (`game_screen.dart`)
-   **목적:** 메인 게임 보드.
-   **역할:** 공통.
-   **기능:** 5x5 빙고 보드, 턴 표시, 채팅/상호작용.
-   **로직:** Supabase를 통해 타일 점유, 턴 변경, 메시지 등을 실시간 동기화.
-   **안정성 및 동기화 (Robustness & Sync):**
    -   **재접속 복구 (Reconnection):** 네트워크가 끊겼다가 다시 돌아왔을 때, 현재 보드 상태와 턴 정보를 최신 상태로 **Fetch & Sync** 해야 함.
    -   **Optimistic UI:** 타일 선택 시 즉시 UI 반영 후, 서버 실패 시 롤백 (반응 속도 향상).
    -   **Prevent Exit:** 게임 도중 뒤로가기 클릭 시 "게임을 저장 or 종료하시겠습니까?" 경고 팝업 필수.
    -   **강제 종료 복구 (Sudden Exit / Crash Recovery):**
        -   게임 중 예기치 않게 종료된 경우, 재접속 시 **Home**으로 이동.
        -   **점수 정산:** 이미 완성된 빙고 줄에 대한 점수는 서버에 저장되어 있으므로, **RewardScreen**으로 이동하여 해당 시점까지의 점수를 정산받을 수 있음.
    -   **입장 알림 (Entrance Toast):**
        -   **게스트 화면:** "초대자가 입장하셨습니다" 모달.
        -   **호스트 화면:** "ooo님이 입장하셨습니다" 모달.

---

### **RewardScreen** (`reward_screen.dart`)
-   **목적:** 게임 종료 후 결과 화면.
-   **역할:** 공통 (호스트/게스트별 UI 다름).
-   **기능:**
    -   획득 포인트 (VP, AP, EP) 표시.
    -   **포인트 구매/전환 (Point Shop & Exchange):**
        -   게임 결과 확인 후 즉시 부족한 **VP를 충전**하거나, 획득한 **AP/EP를 VP로 전환**할 수 있는 버튼/팝업 제공.
        -   (다음 게임을 바로 시작하기 위한 유도 장치).
    -   **호스트:** 홈으로 돌아가기 (즉시 **영구 저장**됨).
    -   **게스트:** 파트너 별점 평가, 회원가입 유도.
        -   **임시 저장 (Temp Save):** 게스트 상태로 종료 시 데이터는 임시 저장됨.
        -   **영구 저장 (Perma Save):** 리워드 페이지에서 **회원가입** 버튼 클릭 시 임시 저장된 데이터가 영구 저장으로 전환됨.
    -   **종료 (Exit):** 앱 종료 또는 홈으로.
-   **탐색 (Navigation):**
    -   호스트 -> **HomeScreen** 또는 **PointPurchaseScreen**.
    -   게스트 -> **SignupScreen** (저장+가입) 또는 **HomeScreen** (임시저장+홈).

---

### **NoticeScreen** (`notice_screen.dart`)
-   **목적:** 공지사항 및 이벤트 확인.
-   **역할:** 사용자에게 앱의 소식을 전달.
-   **기능:**
    -   공지사항 목록 표시 (제목, 날짜).
    -   읽지 않은 공지사항 표시 (뱃지 연동).
    -   공지사항 상세 보기 (확장 또는 팝업).
-   **탐색 (Navigation):**
    -   HomeScreen (AppBar Icon/Notice Card) -> **NoticeScreen**.
    -   Back -> **HomeScreen**.

---

## 탐색 경로 요약 (Summary of Navigation Paths)

### **호스트 경로 (Host Flows):**

**1. 신규 가입 (New User Onboarding):**
`Splash` -> `Signup` (이메일 인증) -> **`HostInfo` (프로필 설정)** -> `HostSetup` (게임 생성) -> `Waiting` -> `Game` -> `Reward` -> `Home`

**2. 기존 회원 (Existing User):**
`Splash` -> `Home` (자동 로그인)

**3. 게임 생성 (Game Creation from Home):**
`Home` -> `HostSetup` -> `GameSetup` -> `Waiting` -> `Game` -> `Reward` -> `Home`

**4. 초대된 게임 참여 (Join Game as Guest):**
`Home` ("초대된 게임 참여") -> `InviteCode` -> `Waiting` -> `Game` -> `Reward` -> `Home`
or `Link/Splash` (초대코드) -> `Home`("초대된 게임 참여") -> `InviteCode` -> `Waiting` -> `Game` -> `Reward` -> `Home`

**5. 재대결 (Rematch - Host):**
`Home` (History [R]) -> `HostSetup` (코드 생성/공유) -> `GameSetup` (**자동통과** / 설정 프리셋) -> `Waiting` -> ...

### **게스트 경로 (Guest Flows):**

**1. 일반 게스트 (General Guest):**
`Splash` -> `Signup` -> `Link/Splash` (초대코드) -> `InviteCode` -> `GuestInfo` -> `Waiting` -> `Game` -> `Reward` -> `Signup` / `Exit`

**2. 기존 회원이 게스트로 참여 (Member as Guest):**
초대 링크로 접속 시 이미 기기에 앱이 설치되어 있고 기존회원이라면 `Home`으로 이동하며 **초대 코드가 자동으로 입력**됩니다.
*Home 화면의 "Join a Game" 입력란에 코드가 자동 기입되어 있어, `Join` 버튼만 누르면 바로 참여 가능.*
`Splash` -> `Signup` -> `Link/Splash` (초대코드) -> `Home` (자동입력) -> `InviteCode` (검증) -> **`GuestInfo` (닉네임 자동완성/통과)** -> `Waiting` -> `Game` -> `Reward` -> `Home`
*(`GuestInfo` 단계에서 기존에 저장된 Guest Nickname이 있다면 그대로 유지되어 바로 입장 가능)*

**3. 재방문 게스트 (Returning Guest):**
인증되지 않은(익명) 상태로 재접속 시, 이전 세션을 유지하여 홈으로 진입하며 목적에 따라 두 가지 경로로 나뉩니다.

    **3-1. 게임 참여 (Join Game):**
    기존 익명 프로필을 그대로 사용하여 바로 게임에 참여합니다.
    `Splash` -> `Home` (게스트 모드) -> `Join Game` (초대코드 입력) -> `InviteCode` -> `Waiting` -> `Game`

    **3-2. 상태 확인 및 회원 전환 (Status Check & Conversion):**
    자신의 계정 상태(익명)를 확인하고, 정식 회원(Host)으로 전환하여 데이터를 보존합니다.
    `Splash` -> `Home` -> `Settings` (내 프로필/상태 확인: "Guest Mode") -> **`Sign Up / Link Account`** 버튼 클릭 -> `AuthScreen` (이메일 인증 or Google 연동) -> `HostInfo` (프로필 보완) -> `Home` (정식 Host 모드로 전환됨)

**4. 회원 전환 (Conversion: Guest to Host):**
익명 게스트가 정식 회원(Host)으로 전환하여 데이터를 보존하고 모든 기능을 사용합니다.
`Home` -> `Settings` -> **`Link Identity` (Google/이메일 연동)** -> `HostInfo` (프로필 보완) -> `Home` (정식 회원)

