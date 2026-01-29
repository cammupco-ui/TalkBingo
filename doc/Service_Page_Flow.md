### 2. 전체 서비스 화면 구조 (Expanded Page Flow)

이 다이어그램은 TalkBingo 앱의 모든 주요 화면과 흐름을 나타냅니다.

```mermaid
graph TD
    Splash[Splash Screen\n(앱 로딩/초기화)] --> LoginFlow
    
    subgraph Auth [인증 및 초기 진입]
        LoginFlow[Login / Signup\n(로그인/회원가입)]
        Invite[Invite Code Input\n(초대코드 입력)]
        GuestInfo[Guest Info\n(게스트 정보 설정)]
        
        LoginFlow -.->|게스트 입장| Invite
        Invite --> GuestInfo
        GuestInfo --> Waiting
    end

    subgraph Main [메인 기능]
        Home[Home Screen\n(메인 대시보드/로비)]
        LoginFlow --> Home
        
        Home -->|게임 생성| GameSetup[Game Setup\n(게임/친밀도 설정)]
        Home -->|포인트| Purchase[Point Purchase\n(포인트 충전)]
        Home -->|기록| History[Bingo History\n(전적/기록)]
        Home -->|설정| Settings[Settings\n(설정/계정관리)]
        Home -->|공지| Notice[Notice Screen\n(공지사항)]
    end

    subgraph GameCreation [게임 생성 프로세스]
        GameSetup --> HostSetup[Host Setup\n(호스트 설정)]
        HostSetup --> HostInfo[Host Info\n(호스트 프로필)]
        HostInfo --> Waiting
    end

    subgraph InGame [게임 진행]
        Waiting[Waiting Screen\n(대기실)]
        Game[Game Screen\n(빙고/질문/미니게임)]
        Reward[Reward Screen\n(게임 결과/보상)]
        
        Waiting --> Game
        Game --> Reward
        Reward --> Home
    end

    Settings --> SignOut[Sign Out Landing\n(로그아웃 화면)]
```

#### 화면 목록 상세 (Files)
1. **Entry**: `splash_screen.dart`
2. **Auth**: `login_screen.dart`, `signup_screen.dart`, `sign_out_landing_screen.dart`
3. **Guest/Join**: `invite_code_screen.dart`, `guest_info_screen.dart`
4. **Main**: `home_screen.dart`
5. **Setup**: `game_setup_screen.dart`, `host_setup_screen.dart`, `host_info_screen.dart`
6. **Game Loop**: `waiting_screen.dart`, `game_screen.dart`, `reward_screen.dart`
7. **Utility**: `point_purchase_screen.dart`, `bingo_history_screen.dart`, `notice_screen.dart`, `settings_screen.dart`
