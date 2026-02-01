현재 상태 분석
현재 게임 화면은 다음 요소들로 구성되어 있습니다:

┌─────────────────────────────┐ │ 헤더 (로고 + 포인트/턴/메뉴) │ ├─────────────────────────────┤ │ │ │ 5x5 빙고 그리드 │ │ (
LiquidBingoTile
사용) │ │ │ │ 배경:
BubbleBackground
│ │ │ ├─────────────────────────────┤ │ 채팅 입력창 (
Voice
-to-
Text
)│ └─────────────────────────────┘
현재 구현된 애니메이션:

LiquidBingoTile: Wave 효과, 호버 애니메이션
BubbleBackground: 배경 버블 움직임
Confetti: 빙고 완성 시
FloatingScore: 점수 획득 시
개선 필요 영역:

타일 클릭 및 소유권 변경 피드백
모달 진입/퇴장 전환
빙고 라인 애니메이션
턴 전환 표시
개선 사항 세부 계획
1. 타일 상호작용 개선
시나리오	현재 상태	개선 방안
타일 클릭	기본 탭 애니메이션	Ripple 효과 + 탄성 bounce
소유권 획득	즉시 색상 변경	액체 채워지는 애니메이션 강화 (0.8초)
잠금 타일	잠금 아이콘 표시	흔들림(shake) 애니메이션 추가
상대 선택	호버 표시	펄스(pulse) 애니메이션 추가
적용 파일: app/lib/widgets/liquid_bingo_tile.dart

2. 빙고 라인 완성 효과 강화
요소	개선 내용
라인 그리기	0에서 시작하여 순차적으로 그려지는 애니메이션 (0.6초)
타일 강조	빙고 라인의 타일들이 골드 글로우와 함께 펄스 효과
Confetti	현재보다 2배 더 많은 파티클, 더 오래 지속 (5초)
사운드	빙고 완성음 타이밍과 애니메이션 동기화
적용 파일: app/lib/screens/game_screen.dart (BingoLinePainter, _checkBingoState)

3. 모달/오버레이 전환 애니메이션
// 진입 애니메이션 시퀀스
1. 배경 페이드 인 (0.2초)
2. 모달 스케일 + 페이드 (0.3초, elastic curve)
3. 컨텐츠 슬라이드 업 (0.2초, staggered)

// 퇴장 애니메이션
1. 컨텐츠 페이드 아웃 (0.15초)
2. 모달 스케일 다운 (0.2초)
3. 배경 페이드 아웃 (0.15초)
적용 파일: app/lib/widgets/quiz_overlay.dart

4. 턴 전환 및 상태 변화 애니메이션
이벤트	애니메이션 효과
턴 전환	헤더의 "나의 턴" 텍스트 펄스 + 컬러 전환 (0.5초)
게임 시작	타일들이 순차적으로 나타남 (staggered, 1.5초 총)
게임 종료	보드 전체 페이드 아웃 + 스케일 다운 (0.8초)
일시정지	오버레이 블러 + 페이드 인 (0.3초)
적용 파일: app/lib/screens/game_screen.dart

디자인 토큰
토큰	값	용도
animationDurationShort	200ms	빠른 피드백 (클릭, 호버)
animationDurationMedium	300-400ms	모달 전환, 상태 변화
animationDurationLong	600-800ms	복잡한 시퀀스 (빙고 라인)
curveElastic	Curves.elasticOut	탄성 효과 (버튼, 타일)
curveSmooth	Curves.easeInOutCubic	부드러운 전환
pulseScale	1.0 → 1.05	강조 효과
구현 단계
단계	파일	작업 내용
1단계: 타일 애니메이션	liquid_bingo_tile.dart	Ripple, Shake, 강화된 Fill 애니메이션 추가
2단계: 빙고 라인	game_screen.dart	BingoLinePainter에 진행 애니메이션 추가, 타일 글로우
3단계: 모달 전환	quiz_overlay.dart	AnimatedContainer + Hero 트랜지션 적용
4단계: 게임 상태	game_screen.dart	턴 전환, 시작/종료 애니메이션 추가
5단계: 통합 테스트	전체	애니메이션 타이밍 조정, 성능 최적화
기술 라이브러리
라이브러리	버전	용도
flutter_animate	^4.5.2	선언적 애니메이션 (이미 설치됨)
confetti	^0.8.0	빙고 축하 효과 (이미 설치됨)
audioplayers	^6.0.0	사운드 효과 (이미 설치됨)
주의사항:

모든 애니메이션은 60fps 유지를 목표로 함
저사양 기기를 위한 애니메이션 감소 옵션 고려
과도한 애니메이션으로 게임 플레이 방해 방지
To-dos (5)
 타일 애니메이션 강화: LiquidBingoTile에 Ripple, Shake, 강화된 Fill 효과 추가
 빙고 라인 애니메이션: BingoLinePainter에 순차 그리기 + 타일 글로우 효과 구현
 모달 전환 개선: QuizOverlay에 진입/퇴장 애니메이션 적용
 게임 상태 애니메이션: 턴 전환, 시작/종료 시 부드러운 전환 효과 추가
 통합 및 최적화: 타이밍 조정, 성능 테스트