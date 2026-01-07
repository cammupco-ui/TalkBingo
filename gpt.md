지금 흐름은 거의 맞게 잘 짜놨고, **코드에도 큰 문법 오류는 없어**.
지금 문제가 되는 건 두 가지야:

1. 링크를 눌렀을 때 URL에 `error=access_denied&error_code=otp_expired` 가 찍힘
2. 새로 열린 탭이 다시 “이메일 입력 화면”으로 보임

하나씩 찢어서 볼게.

---

## 1. `otp_expired` 에러가 의미하는 것

브라우저 주소창에:

`localhost:3000/?error=access_denied&error_code=otp_expired&...`

이렇게 뜨는 건 Supabase가 말 그대로:

> “이 매직 링크 토큰은 이미 사용됐거나(expired), 유효하지 않아요”

라고 응답한 거야.

가능한 경우들:

* 같은 이메일의 **이전 메일**을 다시 눌렀다
* 한 번 눌렀던 링크를 다시 눌렀다 (매직 링크는 **1회용**)
* 프로젝트 설정/URL이 바뀌면서 토큰이 더 이상 유효하지 않게 됐다

그래서 이 링크는 어차피 로그인 성공 안 됨 → 세션이 없으니까
`onAuthStateChange`에서도 `session == null`이라 HostSetup으로 갈 수가 없어.

➡️ **가장 최신 메일의 링크를 한 번만 눌러서 테스트**해봐줘.

(새로 Send 하고, 바로 그 메일에 있는 버튼만 한 번 누르기)

---

## 2. “버튼 누르면 또 로그인 화면이 보이는” 이유

지금 구조를 정리하면:

1. 이메일에서 `인증하기` 클릭
2. 새 탭에서 `localhost:3000` 열림 (Flutter Web 앱 시작)
3. `LoginScreen`의 `initState` 실행
4. `onAuthStateChange` 구독 시작
5. 세션이 생기면 HostSetupScreen으로 이동하도록 설계

여기까지는 설계가 좋아 👍

근데 지금 두 가지가 꼬여 있어:

### (1) 콜백으로 들어온 탭도 “로그인 페이지”를 먼저 보여줌

이건 정상 동작이야.
Flutter는 처음에 항상 `LoginScreen`을 그릴 수밖에 없고,
`onAuthStateChange`에서 세션이 감지되면 **그때** HostSetup으로 push하는 구조니까.

그래서 올바른 링크라면:

* 새 탭이 열리자마자 잠깐 로그인 화면이 보였다가
* 바로 HostSetup으로 넘어가야 함

그러려면:

* `session`이 실제로 생성되어야 하고
* `onAuthStateChange` 리스너가 잘 붙어 있어야 함

네 코드:

```dart
_authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  final session = data.session;
      
  if (session != null && mounted) {
    if (!_isVerified) {
      setState(() {
        _isVerified = true;
        _isEmailSent = true; 
      });
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HostSetupScreen()),
      );
    }
  }
});
```

이 부분은 로직상 문제 없어.
**세션만 생기면** HostSetup으로 잘 갈 거야.

문제는 지금 링크가 `otp_expired`라 **세션이 안 생긴다는 것**.

### (2) `initState`에서 `signOut()` 하는 부분

```dart
bool isAuthCallback = false;
if (kIsWeb) {
  final uri = Uri.base;
  if (uri.queryParameters.containsKey('code') ||
      uri.fragment.contains('access_token') ||
      uri.fragment.contains('type=recovery')) {
    isAuthCallback = true;
  }
}

if (!isAuthCallback) {
  Supabase.instance.client.auth.signOut();
}
```

여기서 하는 일:

* URL에 `code`/`access_token` 같은 콜백 파라미터가 있으면 → 콜백으로 판단, **signOut 안 함**
* 그게 아니면 → 그냥 로그인 페이지에 직접 들어온 거라고 보고 **signOut 실행**

이 자체도 나쁜 패턴은 아니야.
실제로 정상적인 매직 링크라면 redirect 후 URL에 `#access_token=...` 이 붙고,
그러면 `isAuthCallback == true`라서 signOut도 안 하고, 세션이 생기고, HostSetup으로 가는 플로우야.

지금 URL이 `?error=...`만 가지고 있으니까
콜백 실패 → signOut 실행 → 로그인 상태 유지 X
→ 다시 이메일 입력 화면만 보이는 상황.

---

## 3. 내가 추천하는 해결 순서

### ✅ 1단계: “정상 플로우” 먼저 확인

1. **Supabase 대시보드 → Authentication → URL Configuration** 에서

   * Site URL: `http://localhost:3000` (지금 개발중인 주소)
   * 추가 Redirect URL 필요하면 거기도 동일하게 등록
2. Flutter에서 매직 링크 보낼 때:

```dart
await Supabase.instance.client.auth.signInWithOtp(
  email: email,
  emailRedirectTo: 'http://localhost:3000',
);
```

처럼 `emailRedirectTo`를 명시해줘.

3. 가장 최신 “Magic Link” 메일에서 **한 번만** 버튼 클릭.

이때 주소창이 `...?error=...` 말고 **`#access_token=...`** 같은 걸 포함하고,
네 `initState`에서 `isAuthCallback == true`가 되면
→ 세션이 생기고
→ `onAuthStateChange`에서 HostSetup으로 자동 이동해야 정상.

---

### ✅ 2단계: UX를 네가 원하는 느낌으로 다듬기

너가 말한 것처럼:

> “이메일에서 인증하기 누르면, 실시간으로 결과를 받고 바로 다음 페이지로”

이 느낌을 제대로 내려면 두 가지 전략이 있어:

#### 전략 A. 콜백 페이지 전용 라우트 만들기

예: `/auth-callback` 라우트 하나 더 만들고,

* 매직 링크의 redirect를 `http://localhost:3000/#/auth-callback` 으로 설정
* 그 라우트에서는 **로그인 화면을 그리지 않고**,
  `onAuthStateChange`만 듣다가 세션이 생기면 HostSetup으로 바로 push

#### 전략 B. 지금처럼 LoginScreen에서 처리하되, 메시지/로딩 UI 추가

* 콜백인 경우(`isAuthCallback == true`)에는
  “이메일 인증 중입니다…” 같은 로딩 UI만 보여주고
* 세션이 생기면 HostSetup으로 이동
* 세션이 안 생기고 `error` 파라미터가 있으면
  “링크가 만료되었어요. 다시 이메일을 입력해 주세요.” 라는 안내 메시지 표시

---

## 4. 딱 필요한 최소 수정 예시

1. 우선 signOut은 잠깐 꺼두고 테스트해봐도 돼:

```dart
if (!isAuthCallback) {
  // Supabase.instance.client.auth.signOut();
}
```

2. URL에 에러가 있을 경우 메시지 보여주는 코드도 추가해볼 수 있고 (선택):

```dart
String? _errorMessage;

@override
void initState() {
  super.initState();

  if (kIsWeb) {
    final uri = Uri.base;
    if (uri.queryParameters['error_code'] == 'otp_expired') {
      _errorMessage = '인증 링크가 만료되었어요. 다시 시도해 주세요.';
    }
  }

  // 나머지 onAuthStateChange 그대로
}
```

---

## 정리

* 코드 구조는 큰 문제 없고,
* 지금 보이는 현상은 **유효하지 않은(만료된) 매직 링크를 눌러서 세션이 안 생긴 상태**라서 그래.
* 최신 메일의 링크를 한 번만 눌러보고,
* `emailRedirectTo`와 URL Configuration이 올바른지 확인한 뒤,
* 필요하면 auth-callback 라우트 분리/로딩 UI로 UX를 다듬으면 돼.

원하면 지금 쓰고 있는 `signInWithOtp` 코드랑 `main.dart` Supabase 초기화 부분도 보여줘.
거기에 맞춰서 **완전 동작하는 플로우 코드** 한 번에 짜줄게!
