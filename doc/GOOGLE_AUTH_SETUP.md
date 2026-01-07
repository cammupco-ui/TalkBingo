# Google Social Login Setup Guide

TalkBingo 앱에 구글 로그인을 적용하기 위한 설정 단계입니다.

## 1. Google Cloud Console 설정
1. [Google Cloud Console](https://console.cloud.google.com/) 접속 및 로그인.
2. 좌측 상단 프로젝트 선택 -> **[새 프로젝트]** 생성 (이름: `TalkBingo` 등).
3. **[API 및 서비스]** -> **[OAuth 동의 화면]** 이동.
    - `User Type`: **외부 (External)** 선택 -> 만들기.
    - 앱 정보 입력 (앱 이름, 이메일 등 기본 정보만).
    - [저장 후 계속] 반복하여 완료.
4. **[사용자 인증 정보] (Credentials)** 메뉴 이동.
    - **[+ 사용자 인증 정보 만들기]** -> **[OAuth 클라이언트 ID]** 선택.
    - **애플리케이션 유형**: `웹 애플리케이션` (Flutter Web 및 모바일 겸용).
    - **승인된 리디렉션 URI (Authorized redirect URIs)**:
        - `https://jmihbovtywtwqdjrmuey.supabase.co/auth/v1/callback`
        - (Supabase 대시보드 -> Authentication -> Providers -> Google 에서 `Callback URL` 복사 가능)
    - **만들기** 클릭.
    - 생성된 **`클라이언트 ID`**와 **`클라이언트 보안 비밀(Secret)`**을 메모해두세요.

## 2. Supabase 설정
1. [Supabase Dashboard](https://supabase.com/dashboard) 접속.
2. 프로젝트 선택 -> **Authentication** -> **Providers**.
3. **Google** 선택 및 `Enable Google` 활성화.
4. 아까 메모한 정보를 입력:
    - `Client ID`: (Google Cloud에서 복사한 값)
    - `Client Secret`: (Google Cloud에서 복사한 값)
5. **Save** 저장.

## 3. Flutter 코드 적용 (개발자가 처리)
- 설정이 완료되면 제가 `LoginScreen`에 **"구글로 시작하기"** 버튼을 추가합니다.
- 클릭 시 구글 로그인 창이 뜨고, 완료되면 바로 Home으로 이동합니다.
