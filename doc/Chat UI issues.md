## 1. 디자인 시스템 분석

### 핵심 디자인 원칙
- ✅ **글래스모피즘**: 반투명 레이어 + 흰색/밝은 테두리
- ✅ **역할 기반 테마**: Host(Pink #BD0558) vs Guest(Purple #430887)
- ✅ **배경 틴트**: playerA(#F4E7E8) vs playerB(#F0E7F4)
- ✅ **타이포그래피**: Body 2 (13px, Regular) for 채팅 메시지
- ✅ **간격 시스템**: 4px 베이스, md(12px), lg(16px)

## 2. 메시지 타입별 디자인

### 2.1 채팅 메시지 (type: 'chat')

**내 메시지 (오른쪽 정렬)**

```
                    ┌─────────────────────┐
                    │ 안녕하세요!          │
                    │                     │
                    │           12:34 PM  │
                    └─────────────────────┘
                         (나의 역할 색상 배경)
```

**스타일 스펙:**
```dart
// Host 메시지 예시
Container(
  margin: EdgeInsets.only(
    left: 60,    // 최대 너비 제한
    right: 12,   // 화면 여백
    bottom: 8,   // 메시지 간 간격
  ),
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.playerA,  // #F4E7E8 (핑크 틴트)
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(4),  // 꼬리 효과
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4,
        offset: Offset(0, 2),
      )
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        "안녕하세요!",
        style: GoogleFonts.doHyeon(
          fontSize: 13,        // Body 2
          color: Colors.black87,
          height: 1.5,
        ),
      ),
      SizedBox(height: 4),
      Text(
        "12:34 PM",
        style: GoogleFonts.alexandria(
          fontSize: 10,        // Micro
          color: Colors.black45,
        ),
      ),
    ],
  ),
)
```

**상대 메시지 (왼쪽 정렬)**

```
  ┌─────────────────────┐
  │ 반가워요!            │
  │                     │
  │ 12:35 PM            │
  └─────────────────────┘
  (상대 역할 색상 배경)
```

**스타일 스펙:**
```dart
// Guest 메시지 예시
Container(
  margin: EdgeInsets.only(
    left: 12,
    right: 60,
    bottom: 8,
  ),
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.playerB,  // #F0E7F4 (퍼플 틴트)
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(4),  // 꼬리 효과
      bottomRight: Radius.circular(16),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4,
        offset: Offset(0, 2),
      )
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "반가워요!",
        style: GoogleFonts.doHyeon(
          fontSize: 13,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
      SizedBox(height: 4),
      Text(
        "12:35 PM",
        style: GoogleFonts.alexandria(
          fontSize: 10,
          color: Colors.black45,
        ),
      ),
    ],
  ),
)
```

### 2.2 시스템 메시지 (type: 'system')

**중앙 정렬, 최소 강조**

```
              ─────────────────
              게임이 시작되었습니다
              ─────────────────
```

**스타일 스펙:**
```dart
Center(
  child: Container(
    margin: EdgeInsets.symmetric(vertical: 12),
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey[100],  // 뉴트럴 배경
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.grey[300]!,
        width: 1,
      ),
    ),
    child: Text(
      "게임이 시작되었습니다",
      style: GoogleFonts.alexandria(
        fontSize: 12,        // Caption
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    ),
  ),
)
```

### 2.3 질문 메시지 (sender: 'SYSTEM_Q')

              가장 좋아하는 음식은?
```

**스타일 스펙:**
```dart
Center(
  child: Container(
    margin: EdgeInsets.symmetric(vertical: 16),
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: userColor.withOpacity(0.3), // 유저 색상의 연한 테두리
        width: 1,
      ),
    ),
    child: Text(
      message.content, // 질문 또는 응답 텍스트만 출력
      style: GoogleFonts.doHyeon(
        fontSize: 15,
        color: userColor.withOpacity(0.8),
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    ),
  ),
)