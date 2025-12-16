# TalkBingo 개발 계획 (Development Plan)

본 문서는 TalkBingo PRD를 기반으로 작성된 단계별 개발 계획입니다.

## 1. 프로젝트 준비 및 환경 설정 (Phase 1: Foundation)
**목표**: 개발 환경을 구축하고 기본 아키텍처를 수립합니다.

- [x] **프로젝트 초기화**
    - Flutter 프로젝트 생성 (iOS/Android 설정)
    - Next.js (Admin/Web) 및 API 서버 프로젝트 생성
    - Git 저장소 설정 및 브랜치 전략 수립
- [x] **데이터베이스 설계 및 구축**
    - Neo4j 인스턴스 생성 및 연결 설정
    - 초기 노드(User, GameSession, Question, CodeName) 및 관계(Relationships) 스키마 설계
    - 테스트용 더미 데이터 생성
- [x] **디자인 시스템 구현**
    - **Logo Assets**: 메인 로고 (24px, 36px, 48px) 리소스 준비
    - Color Palette (Host: Pink, Guest: Purple) 적용
    - Typography (NURA, Alexandria, K2D) 설정
    - 공통 컴포넌트 (버튼, 입력 필드, 모달) 개발

## 2. 핵심 기능 개발 - 사용자 및 대기실 (Phase 2: Core Features)
**목표**: 사용자가 앱에 접속하여 게임 방을 만들고 입장하는 흐름을 완성합니다.

- [x] **호스트 플로우 구현**
    - **로딩 및 스플래시 화면**: 앱 초기 실행 시 로딩 페이지 구현
        - **UI**: 중앙에 48px 로고 배치, 하단에 로딩 진행률(%) 표시 바(Progress Bar)
        - **Animation**: 로고가 사각 한 면씩(90도) 회전하는 애니메이션 적용 (서버 로딩 중)
    - **회원가입 및 로그인 (Google Social Login)**
        - **[MODIFY] LoginScreen**: 이메일 입력란 제거 -> "Google로 계속하기" 버튼 추가
        - **[MODIFY] SignupScreen**: 별도 가입 절차 없이 로그인 화면으로 통합 (소셜 로그인은 가입/로그인 통합)
        - **Google Cloud & Supabase 설정**: `doc/GOOGLE_AUTH_SETUP.md` 가이드에 따라 설정 필요
        - **데이터 동기화**: 이메일 인증 완료된 유저 정보만 Neo4j 데이터베이스에 저장/동기화 (`auth.users` -> Neo4j `User` node)
    - 호스트 정보 입력 화면 (`/host/setup` -> `/host/info`)
    - 게임 세션 생성 및 초대 코드 발급 로직
    - **호스트 흐름**: Host Setup (Code) -> [Skip InviteCode] -> Host Info -> **Game Setup (Guest Age/Relation)** -> **Waiting (Loading Data)** -> **Game Screen (Immediate Entry)**
- [x] **게스트 플로우 구현**
    - **초대 코드 입력 화면 (`/invite-code`)**
        - UI: Host Setup과 동일 디자인, 6자리 개별 입력 필드 적용
        - Copy 버튼 삭제, 링크 접속 시 자동 입력 처리
    - **게스트 정보 입력 화면 (`/game/info`) - [NEW]**
        - **입력 항목**: 닉네임, 고향, 접속 지역 동의 (관계/나이 입력 제외)
    - **게스트 대기실 (`/waiting`)**
        - 호스트 게임 입장 여부 확인 (Active Game Check)
        - 호스트가 이미 게임 중이면 즉시 입장, 아니면 대기
    - **기존 회원 게스트 참여**:
        - 초대 링크 접속 시 **Home** 화면으로 이동
        - **Home** 화면 내 "Join Game" 입력란에 초대 코드 자동 기입 처리 (원클릭 입장)
- [ ] **실시간 통신 (Socket.io) - (현재 Supabase Realtime으로 대체 중)**
    - Socket.io 서버 구축 및 클라이언트 연동
    - 대기실 입장/퇴장 이벤트 처리
    - 실시간 정보 동기화 (게스트 정보 입력 시 호스트 화면 업데이트)

## 3. 게임 플레이 및 로직 구현 (Phase 3: Game Mechanics)
**목표**: 빙고 게임의 핵심 규칙과 턴 기반 플레이를 구현합니다.

- [x] **게임 화면 구조 구현 (Game Page Structure)**
    - **TOP Section**
        - `Top bar_Logoarea`: 상단 로고 영역
        - `Top Messagebox`: 메시지 및 턴 표시 영역
            - `MessageShowingBox`: 시스템 메시지/피드백 표시
            - `TurnsignBar_a`: 상단 턴 인디케이터
    - **Middle Section (Swipeable Area)**
        - **PageView 구현**: 좌우 스와이프로 뷰 전환 기능
        - **Page 1**: `BoardBoard area 5x5` (빙고 보드)
        - **Page 2**: `Chat List View` (채팅 리스트 및 시스템 메시지 로그)
    - **BOTTOM Chatting Section**
        - `TurnsignBar_b`: 하단 턴 인디케이터
        - `Chat InputBox`: 채팅 입력창 (상단 정렬, 확장형)
        - `Safearea`: 하단 세이프 에어리어 처리
- [x] **빙고 보드 UI**
    - 5x5 빙고 그리드 구현 (Middle Section)
    - 질문 텍스트 표시 및 선택 인터랙션
    - 빙고 라인 완성 시 시각적 효과 (스낵바 알림)
- [x] **턴 시스템 및 상태 관리**
    - 게임 시작, 일시 정지, 종료 상태 관리
    - 호스트/게스트 턴 전환 로직
    - 턴 제한 시간 및 타임아웃 처리 (Heartbeat) - *진행 중*
- [x] **퀴즈 및 인터랙션 (Quiz & Interaction)**
    - **T-Type (Truth Game)**: 답변 입력(20자 제한) 및 승인 요청 (완료)
    - **B-Type (Balance Game)**: 선택지(A vs B) 선택 및 승인 요청 (완료)
    - **M-Type (Mini Game)**: 승인 거절 시 타일 Lock(잠김) 처리 (완료)
    - **승인 시스템 (Approval System)**: Approve/Reject 로직 구현 (완료)
    - 결과에 따른 피드백 메시지 (완료)
- [x] **채팅 시스템**
    - 실시간 채팅 UI 및 메시지 전송
    - 게임 로그(시스템 메시지) 표시

## 4. AI Agent 및 데이터 연동 (Phase 4: AI & Data)
**목표**: Neo4j와 AI 로직을 연동하여 지능형 질문 추천 시스템을 구축합니다.

- [ ] **GraphDB 스키마 구축**
    - `DATABASE_SCHEMA.md` 기반 노드/관계 생성
    - CodeName, Keyword, Holiday, Trend 테이블 구현
- [ ] **CodeName & 키워드 시스템 구현**
    - 사용자 정보 기반 CodeName 생성기 개발 (`[MP]-[CP]-[IR]-[SubRel]-[Intimacy]`)
    - CodeName별 키워드 매핑 로직 구현
- [ ] **지능형 질문 큐레이션**
    - CodeName + 키워드 기반 질문 추출 쿼리 최적화
    - **Holiday & Trend API 연동**: 연휴 및 트렌드 반영 질문 생성 로직 추가
- [ ] **게임 결과 분석 및 저장**
    - 게임 종료 후 결과(승패, 포인트, 선택 기록) 저장
    - AI 분석 리포트 생성 (친밀도 변화, 요약)

## 5. 고도화 및 수익화 (Phase 5: Polish & Monetization)
**목표**: 앱의 완성도를 높이고 수익 모델을 적용합니다.

- [ ] **광고 연동 (AdMob)**
    - 배너 광고, 보상형 광고(잠금 해제), 전면 광고 구현
    - 광고 제거 포인트 차감 로직
- [ ] **포인트 및 보상 시스템**
    - VP, AP, EP, TS 포인트 적립 및 관리 로직
    - 인앱 결제(IAP) 연동 (추후 확장 대비)
- [ ] **UI/UX 폴리싱**
    - 화면 전환 애니메이션 및 마이크로 인터랙션 추가
    - 사운드 이펙트 및 배경음악 적용
- [ ] **테스트 및 배포**
    - 단위 테스트 및 통합 테스트 수행
    - 앱 스토어 배포를 위한 빌드 및 심사 준비
