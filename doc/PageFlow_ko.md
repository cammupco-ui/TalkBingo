# TalkBingo 페이지 정의 및 탐색 흐름 (Navigation Flow)

이 문서는 TalkBingo 앱의 모든 화면을 정의하고, 사용자 역할(호스트 vs 게스트)에 따른 목적과 탐색 로직을 설명합니다.

## 1. 인증 및 진입 (Authentication & Entry)

### **SplashScreen** (`splash_screen.dart`)
-   **목적:** 앱의 시작점입니다. 로그인 상태를 확인하고 딥링크(초대 코드)를 감지합니다.
-   **로직:**
    -   신규 가입 또는 로그인되지 않은 경우 -> **SignupScreen**으로 이동.
    -   로그인된 사용자인 경우 -> **HomeScreen**으로 이동.
    -   초대코드로 접속된 익명 사용자이거나 URL에 `?code=...`가 있는 경우 -> **InviteCodeScreen** (게스트 흐름)으로 이동.
    -   초대코드로 접속하였지만 이미 회원가입된 사용자인 경우 -> **HomeScreen**으로 이동.

### **SignupScreen** (`signup_screen.dart`)
-   **목적:** 앱의 메인 진입점. 신규 가입(Host) 및 게스트 입장(Guest) 분기.
-   **역할:** 모든 사용자.
-   **기능:**
    1.  **Sign up with Google:** 구글 계정으로 간편 가입/로그인 (호스트).
    2.  **Enter Invite Code:** 초대 코드 입력 화면으로 이동 (게스트).
    3.  하단의 "Log In" 링크 -> **LoginScreen** (기존 회원 로그인).
-   **탐색 (Navigation):**
    -   Google 인증 성공 (신규) -> **HostInfoScreen**.
    -   Google 인증 성공 (기존) -> **HomeScreen**.
    -   초대 코드 입력 선택 -> **InviteCodeScreen**.

### **LoginScreen** (`login_screen.dart`)
-   **목적:** 기존 회원 로그인.
-   **역할:** 이미 가입된 호스트.
-   **기능:**
    1.  **Continue with Google:** 구글 계정으로 로그인.
    2.  하단의 "Sign Up" 링크 -> **SignupScreen**.
-   **탐색 (Navigation):**
    -   로그인 성공 -> **HomeScreen**.

---

## 2. 호스트 흐름 (신규가입)

### **SignupScreen** (`signup_screen.dart`)
-   **목적:** 신규 호스트 가입.
-   **역할:** 앱을 처음 설치한 호스트 사용자.
-   **기능:** **Sign up with Google** 버튼을 통해 원클릭 획원가입.
-   **탐색 (Navigation):**
    -   Google 인증 완료 -> **HostInfoScreen** (프로필 설정).
    -   (이미 가입된 계정일 경우 자동으로 **HomeScreen**으로 이동).

### **HostInfoScreen** (`host_info_screen.dart`)
-   **목적:** 호스트의 프로필 정보(닉네임, 성별)를 수집.
-   **역할:** 호스트 (최초 1회 설정).
-   **탐색 (Navigation):** -> **HostSetupScreen**.

### **HostSetupScreen** (`host_setup_screen.dart`)
-   **목적:** 게임 생성 1단계 - 초대 코드 생성.
-   **역할:** 호스트.
-   **기능:** 랜덤 코드 생성, 초대 링크 복사, 초대 링크 공유.
-   **탐색 (Navigation):** -> **GameSetupScreen**.

### **GameSetupScreen** (`game_setup_screen.dart`)
-   **목적:** 게임 생성 2단계 - 호스트가 입력하는 게스트와의 관계 정보.
-   **역할:** 호스트.
-   **기능:** 관계, 세부관계, 친밀도 선택.
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
    -   **결제 정보(TalkBingo Pay):**
        -   신용카드 정보 등록/수정 (카드번호, 유효기간, CVV, 소유자명).
        -   **TalkBingo Pay 비주얼 카드:** 입력 실시간 반영되는 그라데이션 카드 UI.
    -   **포인트 관리 이동:** "Manage Points / Purchase" 버튼 -> **PointPurchaseScreen**.
    -   **로그아웃:** -> **SignOutLandingScreen**.

    #### **PointPurchaseScreen** (`point_purchase_screen.dart`)
    -   **목적:** 포인트 소지 현황 조회, 포인트 구매 및 변환.
    -   **포인트 구성:**
        1.  **VP (Victory Point):** 프리미엄 재화. 현금 구매로 충전. 광고 제거 등에 사용.
        2.  **AP (Attitude Point):** 게임 플레이(빙고 완성) 보상. VP로 전환 가능.
        3.  **EP (Emotion Point):** 타일 점유 보상. VP로 전환 가능.
    -   **기능:**
        -   **포인트 현황:** 실시간 애니메이션 숫자로 표시.
        -   **포인트 전환:** AP/EP -> VP 교환 (Exchange 버튼).
        -   **VP 구매 (In-App Payment):**
            -   구매 옵션 선택 ($1.00 ~ $9.50).
            -   **결제 프로세스:**
                1.  **설정된 카드 확인:** `SettingsScreen`에 저장된 결제 정보 확인.
                2.  **정보 있음:** "Confirm Purchase" 팝업 (카드 뒷 4자리 표시) -> 구매 확정 -> VP 충전.
                3.  **정보 없음:** "No Payment Info" 알림 -> `SettingsScreen`으로 리다이렉트.
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
-   **탐색 (Navigation):** -> **GuestInfoScreen**.

### **GuestInfoScreen** (`guest_info_screen.dart`)
-   **목적:** 게임 참여를 위해 게스트의 프로필 정보를 입력.
-   **역할:** 게스트.
-   **기능:** 닉네임 입력.
-   **탐색 (Navigation):** -> **WaitingScreen**.

---

## 4. 공통 플레이 경험 (Shared Gameplay Experience)

### **WaitingScreen** (`waiting_screen.dart`)
-   **목적:** 게임 시작 전 대기실.
-   **역할:** 공통 (역할에 따라 UI가 다름).
-   **로직:**
    -   **호스트 화면:** "게임설정 중입니다.". 백엔드에서 호스트 프로필 정보 + 호스트가 입력한 게스트와의 관계 정보 + 게스트 프로필 정보등 Supabase에서 CodeName을 통해 질문 정보 선별 추출 -> **GameScreen**.
    -   **게스트 화면:** "호스트가 시작하길 기다리는 중...". 호스트가 **GameScreen**으로 이동함을 감지.
-   **탐색 (Navigation):** -> **GameScreen** (선 호스트 입장 후 게스트 입장).

### **GameScreen** (`game_screen.dart`)
-   **목적:** 메인 게임 보드.
-   **역할:** 공통.
-   **기능:** 5x5 빙고 보드, 턴 표시, 채팅/상호작용.
-   **로직:** Supabase를 통해 타일 점유, 턴 변경, 메시지 등을 실시간 동기화.

---

### **RewardScreen** (`reward_screen.dart`)
-   **목적:** 게임 종료 후 결과 화면.
-   **역할:** 공통 (호스트/게스트별 UI 다름).
-   **기능:**
    -   획득 포인트 (VP, AP, EP) 표시.
    -   **호스트:** 홈으로 돌아가기.
    -   **게스트:** 파트너 별점 평가, 회원가입 유도, 종료, 이미 회원인 경우 홈으로 돌아가기.
-   **탐색 (Navigation):**
    -   호스트 -> **HomeScreen**.
    -   게스트 -> **SignupScreen** 또는 종료 또는 **HomeScreen**.

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
or `Splash` -> `Signup` -> `Login` (로그인) -> `Home`

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

