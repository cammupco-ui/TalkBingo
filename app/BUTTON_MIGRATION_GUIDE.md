# 🎨 AnimatedButton 마이그레이션 가이드

## ✅ 완료된 작업

### 1. AnimatedButton 위젯 생성
- 파일: `app/lib/widgets/animated_button.dart`
- 4가지 버튼 타입 구현:
  - `AnimatedButton` (ElevatedButton 대체)
  - `AnimatedTextButton` (TextButton 대체)
  - `AnimatedOutlinedButton` (OutlinedButton 대체)
  - `AnimatedIconButton` (IconButton 대체)

### 2. Import 추가 완료
다음 파일들에 import 추가됨:
- ✅ signup_screen.dart
- ✅ login_screen.dart
- ✅ guest_info_screen.dart
- ✅ host_info_screen.dart
- ✅ host_setup_screen.dart
- ✅ game_setup_screen.dart
- ✅ sign_out_landing_screen.dart
- ✅ reward_screen.dart
- ✅ invite_code_screen.dart
- ✅ settings_screen.dart
- ✅ point_purchase_screen.dart
- ✅ game_screen.dart
- ✅ home_screen.dart
- ✅ quiz_overlay.dart

## 📝 남은 작업: 버튼 교체

각 파일에서 다음과 같이 교체하세요:

### ElevatedButton → AnimatedButton

**Before:**
```dart
ElevatedButton(
  onPressed: _onTap,
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.hostPrimary,
  ),
  child: Text('Button'),
)
```

**After:**
```dart
AnimatedButton(
  onPressed: _onTap,
  backgroundColor: AppColors.hostPrimary,
  child: Text('Button'),
)
```

### TextButton → AnimatedTextButton

**Before:**
```dart
TextButton(
  onPressed: _onTap,
  child: Text('Cancel'),
)
```

**After:**
```dart
AnimatedTextButton(
  onPressed: _onTap,
  child: Text('Cancel'),
)
```

### OutlinedButton → AnimatedOutlinedButton

**Before:**
```dart
OutlinedButton(
  onPressed: _onTap,
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.hostPrimary,
  ),
  child: Text('Button'),
)
```

**After:**
```dart
AnimatedOutlinedButton(
  onPressed: _onTap,
  foregroundColor: AppColors.hostPrimary,
  child: Text('Button'),
)
```

### IconButton → AnimatedIconButton

**Before:**
```dart
IconButton(
  icon: Icon(Icons.settings),
  onPressed: _onTap,
)
```

**After:**
```dart
AnimatedIconButton(
  icon: Icon(Icons.settings),
  onPressed: _onTap,
)
```

## 🎯 빙고 보드 타일 제외

**중요:** `game_screen.dart`의 `LiquidBingoTile`은 변경하지 마세요!

```dart
// 이 부분은 그대로 유지
Widget _buildBingoTile(int index) {
  return LiquidBingoTile(...); // ✅ 변경 없음
}
```

## 🔧 애니메이션 커스터마이징

```dart
AnimatedButton(
  hoverScale: 1.05,  // 호버 시 크기 (기본값)
  tapScale: 0.95,    // 탭 시 크기 (기본값)
  duration: Duration(milliseconds: 150),  // 애니메이션 속도
  enableHaptic: true,  // 햅틱 피드백 (기본값)
  child: Text('Custom Button'),
  onPressed: () {},
)
```

## 📊 교체 진행 상황

| 파일 | 버튼 수 | 상태 |
|------|---------|------|
| signup_screen.dart | 3 | ⏳ 일부 완료 |
| login_screen.dart | 2 | 🔲 대기 |
| guest_info_screen.dart | 2 | 🔲 대기 |
| host_info_screen.dart | 2 | 🔲 대기 |
| host_setup_screen.dart | 4 | 🔲 대기 |
| game_setup_screen.dart | 4 | 🔲 대기 |
| sign_out_landing_screen.dart | 2 | 🔲 대기 |
| reward_screen.dart | 6 | 🔲 대기 |
| invite_code_screen.dart | 2 | 🔲 대기 |
| settings_screen.dart | 4 | 🔲 대기 |
| point_purchase_screen.dart | 8 | 🔲 대기 |
| game_screen.dart | 14 | 🔲 대기 |
| home_screen.dart | 4 | 🔲 대기 |
| quiz_overlay.dart | 3 | 🔲 대기 |

**총:** ~60개 버튼 (빙고 보드 25개 제외)

## ✨ 기대 효과

- 🎭 모든 버튼에 부드러운 호버/탭 애니메이션
- 📱 햅틱 피드백으로 더 나은 UX
- ♿ Reduced Motion 접근성 지원
- 🎨 일관된 인터랙션 경험