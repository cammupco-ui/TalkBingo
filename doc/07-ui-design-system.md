# UI/UX 디자인 시스템

## 개요

BalanceBingo의 UI/UX 디자인 시스템을 정의합니다. **네오모피즘(Neumorphism)** 스타일을 기본으로 하며, 모바일 우선 설계와 반응형 웹을 지원합니다.

### 디자인 철학
- **따뜻한 모노톤 기본**: 대부분의 UI는 따뜻한 화이트톤/베이지 톤의 모노톤으로 입체감 표현
- **선택적 색상**: 빙고 칸 차지, 알림, 중요한 액션 등 강조가 필요한 부분만 색상 사용
- **부드러운 입체감**: 부드러운 그림자와 하이라이트로 돌출/움푹 들어간 효과 구현
- **따뜻한 느낌**: 차가운 회색 대신 따뜻한 베이지/크림 계열 색상 사용

## 1. 디자인 원칙

### 1.1 모바일 우선 (Mobile-first)
- 모바일 화면을 기준으로 설계
- 태블릿/PC는 확장된 레이아웃

### 1.2 네오모피즘 (Neumorphism)
- 기본 디자인은 모노톤(흰색/밝은 회색)으로 입체감 표현
- 부드러운 그림자와 하이라이트로 돌출/움푹 들어간 효과
- 강조가 필요한 부분만 색상 사용 (빙고 칸 차지, 알림 등)

### 1.3 간결성
- 불필요한 요소 제거
- 핵심 기능에 집중

### 1.4 즉각적인 피드백
- 사용자 액션에 즉각 반응
- 로딩 상태 명확히 표시

## 2. 색상 팔레트 (Color Palette)

### 2.1 기본 색상 (Host & Guest Theme)

TalkBingo는 호스트(Host)와 게스트(Guest)에게 서로 다른 테마 색상을 제공하여 역할을 구분합니다.

```css
:root {
  /* Host Colors (Pink Theme) */
  --primary-pink: #BD0558;
  --primary-secondpink: #FF0077;
  --primary-darkpink: #610C39;
  
  /* Guest Colors (Purple Theme) */
  --primary-purple: #430887;
  --primary-secondpurple: #6B14EC;
  --primary-darkpurple: #2E0645;

  /* Backgrounds */
  --bg-main-a: #0C0219;      /* Host Main BG */
  --bg-main-b: #0C0219;      /* Guest Main BG */
  --bg-light: #FFF9FB;       /* Light BG */
  --bg-dark: #0C0219;        /* Dark BG */

  /* Player Backgrounds */
  --player-a: #F4E7E8;       /* Host Player BG */
  --player-b: #F0E7F4;       /* Guest Player BG */

  /* Text Colors */
  --text-primary-a: #FF0077;    /* Host Primary Text */
  --text-primary-b: #6B14EC;    /* Guest Primary Text */
  --text-secondary-a: #FFF4F6;  /* Host Secondary Text */
  --text-secondary-b: #FDF9FF;  /* Guest Secondary Text */
  --text-muted-a: #CDBFC1;      /* Host Muted Text */
  --text-muted-b: #C7BFCD;      /* Guest Muted Text */
  --text-dark-a: #610C39;       /* Host Dark Text */
  --text-dark-b: #2E0645;       /* Guest Dark Text */

  /* Functional Colors */
  --emphasize-warning: #FF0000;
  --explanation: #68CDFF;
}
```

### 2.2 역할별 색상 매핑

| 역할 | 테마 색상 | Primary | Secondary | Dark |
|---|---|---|---|---|
| **Host (A)** | **Pink** | `#BD0558` | `#FF0077` | `#610C39` |
| **Guest (B)** | **Purple** | `#430887` | `#6B14EC` | `#2E0645` |

### 2.3 Tailwind CSS 설정

```typescript
// tailwind.config.ts
export default {
  theme: {
    extend: {
      colors: {
        host: {
          primary: '#BD0558',
          secondary: '#FF0077',
          dark: '#610C39',
          bg: '#0C0219',
          player: '#F4E7E8',
          text: {
            primary: '#FF0077',
            secondary: '#FFF4F6',
            muted: '#CDBFC1',
            dark: '#610C39',
          }
        },
        guest: {
          primary: '#430887',
          secondary: '#6B14EC',
          dark: '#2E0645',
          bg: '#0C0219',
          player: '#F0E7F4',
          text: {
            primary: '#6B14EC',
            secondary: '#FDF9FF',
            muted: '#C7BFCD',
            dark: '#2E0645',
          }
        },
        common: {
          bg: {
            light: '#FFF9FB',
            dark: '#0C0219',
          },
          warning: '#FF0000',
          explanation: '#68CDFF',
        }
      },
    },
  },
};
```

## 3. 타이포그래피

### 3.1 폰트 (Fonts)

- **Title Font**: "NURA"
    - **Weights/Sizes**: 
        - 10px Light
        - 14px Semibold
        - 24px Extrabold
- **Body Font (English)**: "Alexandria"
- **Body Font (Korean)**: "K2D"
    - **Weights/Sizes**:
        - 10px Medium
        - 12px Semibold
        - 14px Semibold
        - 16px Bold

```css
/* Font Families */
--font-title: 'NURA', sans-serif;
--font-body-en: 'Alexandria', sans-serif;
--font-body-ko: 'K2D', sans-serif;
```

### 3.2 폰트 크기

```css
/* 모바일 */
--text-xs: 0.75rem;    /* 12px */
--text-sm: 0.875rem;   /* 14px */
--text-base: 1rem;     /* 16px */
--text-lg: 1.125rem;   /* 18px */
--text-xl: 1.25rem;    /* 20px */
--text-2xl: 1.5rem;    /* 24px */
--text-3xl: 1.875rem;  /* 30px */

/* 태블릿/PC */
@media (min-width: 768px) {
  --text-base: 1.125rem;  /* 18px */
  --text-lg: 1.25rem;     /* 20px */
  --text-xl: 1.5rem;      /* 24px */
}
```

## 4. 레이아웃

### 4.1 컨테이너

```typescript
// 모바일: 전체 너비
// 태블릿/PC: 최대 너비 600px, 중앙 정렬
// 네오모피즘 배경 적용
<div className="w-full max-w-[600px] mx-auto px-4 min-h-screen bg-neu-bg">
  {/* 내용 */}
</div>
```

### 4.2 그리드 시스템

```typescript
// 빙고판: 5x5 그리드
<div className="grid grid-cols-5 gap-2 aspect-square">
  {cells.map((cell, index) => (
    <BingoCell key={index} cell={cell} />
  ))}
</div>
```

### 4.3 Safe Area (모바일)

```css
/* iOS 홈바 영역 고려 */
padding-bottom: env(safe-area-inset-bottom);
```

## 5. 컴포넌트 스타일

### 5.1 버튼 (Buttons)

버튼은 역할(Host/Guest)에 따라 다른 색상 테마를 가집니다.

#### Primary Button (주요 액션)
- **Host (A)**: `#BD0558` (Pink)
- **Guest (B)**: `#430887` (Purple)

```typescript
// Host Primary Button
<button className="bg-[#BD0558] text-white px-6 py-3 rounded-2xl font-bold hover:opacity-90 transition-opacity">
  Host Action
</button>

// Guest Primary Button
<button className="bg-[#430887] text-white px-6 py-3 rounded-2xl font-bold hover:opacity-90 transition-opacity">
  Guest Action
</button>
```

#### Secondary Button (보조 액션)
- **Host (A)**: `#FFF9FB` (Hover Outline: `#610C39` 1px)
- **Guest (B)**: `#FDF9FF` (Hover Outline: `#2E0645` 1px)

```typescript
// Host Secondary Button
<button className="bg-[#FFF9FB] text-[#610C39] px-6 py-3 rounded-2xl font-medium border border-transparent hover:border-[#610C39] transition-colors">
  Host Secondary
</button>

// Guest Secondary Button
<button className="bg-[#FDF9FF] text-[#2E0645] px-6 py-3 rounded-2xl font-medium border border-transparent hover:border-[#2E0645] transition-colors">
  Guest Secondary
</button>
```

#### Deactivated Button (비활성)
- **Host (A)**: `#2E0645` (Hover Outline: `#FFF9FB` 1px)
- **Guest (B)**: `#C7BFCD` (Hover Outline: `#FDF9FF` 1px)

```typescript
// Host Deactivated
<button disabled className="bg-[#2E0645] text-[#CDBFC1] px-6 py-3 rounded-2xl cursor-not-allowed border border-transparent hover:border-[#FFF9FB]">
  Disabled
</button>
```

### 5.2 빙고 셀 상태별 스타일 (네오모피즘)

#### Idle (초기 상태) - 따뜻한 모노톤
```typescript
<div className="
  bg-neu-surface 
  rounded-2xl 
  p-2 
  aspect-square 
  flex items-center justify-center 
  text-xs text-center 
  text-[#3d3528]
  cursor-pointer 
  shadow-neu-light
  active:shadow-neu-pressed
  active:scale-[0.98]
  transition-all duration-200
">
  {cell.content}
</div>
```

#### Answered (한쪽만 선택) - 따뜻한 모노톤, 약간 강조
```typescript
<div className="
  bg-neu-elevated 
  rounded-2xl 
  p-2 
  aspect-square 
  flex items-center justify-center 
  text-xs text-center 
  text-[#3d3528]
  cursor-pointer 
  shadow-neu-light
  relative
  active:shadow-neu-pressed
  transition-all duration-200
">
  {cell.content}
  <span className="absolute top-1 right-1 text-[10px] text-[#6b6254] bg-neu-surface rounded-full w-5 h-5 flex items-center justify-center shadow-neu-dark">
    1/2
  </span>
</div>
```

#### Resolved Match (일치) - 빨간색 강조
```typescript
<div className="
  bg-success 
  rounded-2xl 
  p-2 
  aspect-square 
  flex items-center justify-center 
  text-white 
  font-semibold
  shadow-[6px_6px_12px_rgba(239,68,68,0.4),-6px_-6px_12px_rgba(255,107,107,0.2)]
  animate-pulse
  relative
">
  <CheckIcon className="w-6 h-6" />
</div>
```

#### Locked Mismatch (불일치) - 따뜻한 모노톤, 움푹 들어간 효과
```typescript
<div className="
  bg-neu-surface 
  rounded-2xl 
  p-2 
  aspect-square 
  flex flex-col items-center justify-center 
  text-[#6b6254]
  cursor-pointer 
  shadow-neu-dark
  hover:shadow-neu-light
  transition-all duration-200
  relative
">
  <LockIcon className="w-5 h-5 mb-1" />
  <span className="text-[9px]">광고 보고 해제</span>
</div>
```

#### Unlocked by Ad (광고로 해제) - 빨간색 강조
```typescript
<div className="
  bg-success 
  rounded-2xl 
  p-2 
  aspect-square 
  flex items-center justify-center 
  text-white 
  font-semibold
  shadow-[6px_6px_12px_rgba(239,68,68,0.4),-6px_-6px_12px_rgba(255,107,107,0.2)]
  relative
">
  <CheckIcon className="w-6 h-6" />
  <span className="absolute top-1 left-1 text-[8px] bg-white text-success px-1.5 py-0.5 rounded-full shadow-neu-dark font-bold">
    AD
  </span>
</div>
```

### 5.3 모달 (네오모피즘)

```typescript
<div className="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center z-50 p-4">
  <div className="bg-neu-elevated rounded-3xl p-6 max-w-sm w-full shadow-neu-light">
    <h3 className="text-xl font-bold mb-4 text-[#3d3528]">{question.content}</h3>
    <div className="space-y-3">
      <button className="
        w-full 
        bg-neu-surface 
        text-[#3d3528] 
        py-3 
        rounded-2xl 
        font-semibold
        shadow-neu-light
        active:shadow-neu-pressed
        active:scale-[0.98]
        transition-all duration-200
      ">
        {question.choice_a}
      </button>
      <button className="
        w-full 
        bg-success 
        text-white 
        py-3 
        rounded-2xl 
        font-semibold
        shadow-[6px_6px_12px_rgba(239,68,68,0.3),-6px_-6px_12px_rgba(255,255,255,0.1)]
        active:shadow-[inset_4px_4px_8px_rgba(220,38,38,0.3),inset_-4px_-4px_8px_rgba(255,107,107,0.2)]
        active:scale-[0.98]
        transition-all duration-200
      ">
        {question.choice_b}
      </button>
    </div>
  </div>
</div>
```

### 5.4 토스트 알림 (네오모피즘)

#### 일반 알림 (따뜻한 모노톤)
```typescript
<div className="
  fixed top-4 left-1/2 transform -translate-x-1/2 
  bg-neu-elevated 
  text-[#3d3528] 
  px-4 py-3 
  rounded-2xl 
  shadow-neu-light
  z-50
  animate-slide-down
  border border-[#e8e0d5]
">
  {message}
</div>
```

#### 성공/경고 알림 (색상 강조)
```typescript
<div className="
  fixed top-4 left-1/2 transform -translate-x-1/2 
  bg-success 
  text-white 
  px-4 py-3 
  rounded-2xl 
  shadow-[6px_6px_12px_rgba(239,68,68,0.4),-6px_-6px_12px_rgba(255,107,107,0.2)]
  z-50
  animate-slide-down
">
  {message}
</div>
```

## 6. 애니메이션

### 6.1 셀 채워짐 애니메이션 (따뜻한 네오모피즘)

```css
@keyframes cellFill {
  0% {
    transform: scale(0.9);
    opacity: 0;
    box-shadow: inset 6px 6px 12px rgba(200, 190, 175, 0.15), 
                inset -6px -6px 12px rgba(255, 252, 247, 0.8);
  }
  50% {
    transform: scale(1.05);
    box-shadow: 8px 8px 16px rgba(239, 68, 68, 0.3), 
                -8px -8px 16px rgba(255, 107, 107, 0.2);
  }
  100% {
    transform: scale(1);
    opacity: 1;
    box-shadow: 6px 6px 12px rgba(239, 68, 68, 0.4), 
                -6px -6px 12px rgba(255, 107, 107, 0.2);
  }
}

.cell-filled {
  animation: cellFill 0.4s ease-out;
}
```

### 6.2 빙고 라인 애니메이션

```css
@keyframes bingoLine {
  0% {
    width: 0;
  }
  100% {
    width: 100%;
  }
}

.bingo-line {
  animation: bingoLine 0.5s ease-out;
}
```

### 6.3 Tailwind 애니메이션 설정

```typescript
// tailwind.config.ts
export default {
  theme: {
    extend: {
      keyframes: {
        'cell-fill': {
          '0%': { 
            transform: 'scale(0.9)', 
            opacity: '0',
            boxShadow: 'inset 6px 6px 12px rgba(200, 190, 175, 0.15), inset -6px -6px 12px rgba(255, 252, 247, 0.8)',
          },
          '50%': { 
            transform: 'scale(1.05)',
            boxShadow: '8px 8px 16px rgba(239, 68, 68, 0.3), -8px -8px 16px rgba(255, 107, 107, 0.2)',
          },
          '100%': { 
            transform: 'scale(1)', 
            opacity: '1',
            boxShadow: '6px 6px 12px rgba(239, 68, 68, 0.4), -6px -6px 12px rgba(255, 107, 107, 0.2)',
          },
        },
        'slide-down': {
          '0%': { transform: 'translateY(-100%)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
      animation: {
        'cell-fill': 'cellFill 0.4s ease-out',
        'slide-down': 'slideDown 0.3s ease-out',
      },
    },
  },
};
```

## 7. 반응형 브레이크포인트

```typescript
// Tailwind 기본 브레이크포인트
sm: '640px',   // 작은 태블릿
md: '768px',   // 태블릿
lg: '1024px',  // 작은 데스크톱
xl: '1280px',  // 데스크톱
```

### 사용 예시

```typescript
<div className="
  text-sm md:text-base lg:text-lg
  p-4 md:p-6 lg:p-8
">
  내용
</div>
```

## 8. 빙고판 레이아웃

### 8.1 모바일 (기본) - 네오모피즘

```typescript
<div className="w-full px-4 min-h-screen bg-neu-bg">
  {/* 헤더 */}
  <header className="mb-4 pt-4">
    <h1 className="text-2xl font-bold text-[#3d3528]">BalanceBingo</h1>
    <p className="text-sm text-[#6b6254]">같이 선택하면 빙고!</p>
  </header>
  
  {/* 상태바 */}
  <div className="mb-4 flex justify-between items-center bg-neu-surface rounded-2xl px-4 py-3 shadow-neu-light">
    <span className="text-[#3d3528] font-medium">Player 1 vs Player 2</span>
    <span className="text-success font-bold">빙고: 0</span>
  </div>
  
  {/* 빙고판 */}
  <div className="grid grid-cols-5 gap-2 aspect-square mb-4 p-2 bg-neu-surface rounded-3xl shadow-neu-dark">
    {/* 셀들 */}
  </div>
  
  {/* 액션 버튼 */}
  <div className="flex gap-3 mb-4">
    <button className="flex-1 bg-neu-surface text-[#3d3528] px-4 py-3 rounded-2xl font-semibold shadow-neu-light active:shadow-neu-pressed">
      새 게임
    </button>
    <button className="flex-1 bg-success text-white px-4 py-3 rounded-2xl font-semibold shadow-[6px_6px_12px_rgba(239,68,68,0.3),-6px_-6px_12px_rgba(255,255,255,0.1)] active:shadow-neu-pressed">
      친구 초대
    </button>
  </div>
  
  {/* 배너 광고 */}
  <div className="h-20 bg-neu-surface rounded-2xl mb-4 shadow-neu-dark flex items-center justify-center">
    {/* 광고 영역 */}
  </div>
</div>
```

### 8.2 태블릿/PC

```typescript
<div className="w-full max-w-[600px] mx-auto px-4 min-h-screen bg-neu-bg">
  {/* 동일한 구조, 더 큰 여백과 폰트 */}
</div>
```

## 9. 로딩 상태

### 9.1 스켈레톤 UI (네오모피즘)

```typescript
<div className="animate-pulse">
  <div className="bg-neu-surface rounded-2xl h-20 mb-2 shadow-neu-dark"></div>
  <div className="bg-neu-surface rounded-2xl h-20 mb-2 shadow-neu-dark"></div>
</div>
```

### 9.2 스피너 (따뜻한 네오모피즘)

```typescript
<div className="flex items-center justify-center">
  <div className="
    animate-spin 
    rounded-full 
    h-8 w-8 
    border-4 
    border-neu-surface 
    border-t-[#9a9080]
    shadow-neu-light
  "></div>
</div>
```

### 9.3 강조 스피너 (색상 사용)

```typescript
<div className="flex items-center justify-center">
  <div className="
    animate-spin 
    rounded-full 
    h-8 w-8 
    border-4 
    border-success/20 
    border-t-success
    shadow-[6px_6px_12px_rgba(239,68,68,0.2),-6px_-6px_12px_rgba(255,255,255,0.1)]
  "></div>
</div>
```

## 10. 접근성 (A11y)

### 10.1 키보드 네비게이션

- 모든 인터랙티브 요소는 키보드로 접근 가능
- 포커스 표시 명확히

### 10.2 ARIA 레이블

```typescript
<button
  aria-label="셀 선택"
  aria-pressed={isSelected}
>
  {content}
</button>
```

### 10.3 색상 대비

- WCAG AA 기준 준수 (4.5:1 이상)

## 11. 아이콘

### 11.1 사용 라이브러리

- **Heroicons** (권장) 또는 **Lucide React**

### 11.2 주요 아이콘

- ✓ CheckIcon (일치)
- 🔒 LockIcon (잠금)
- 📋 CopyIcon (링크 복사)
- 🎮 GameIcon (게임)
- 📊 ChartIcon (결과)

## 12. 네오모피즘 구현 가이드

### 12.1 CSS 변수 설정

```css
/* app/globals.css */
:root {
  /* 네오모피즘 배경 (따뜻한 톤) */
  --neu-bg: #f5f1e8;        /* 따뜻한 베이지 배경 */
  --neu-surface: #faf8f3;   /* 따뜻한 크림 배경 */
  --neu-elevated: #fffefb;  /* 따뜻한 화이트 */
  
  /* 그림자 (따뜻한 톤) */
  --shadow-soft-light: 6px 6px 12px rgba(255, 252, 247, 0.8),
                       -6px -6px 12px rgba(200, 190, 175, 0.15);
  --shadow-soft-dark: inset 6px 6px 12px rgba(200, 190, 175, 0.15),
                      inset -6px -6px 12px rgba(255, 252, 247, 0.8);
  --shadow-pressed: inset 4px 4px 8px rgba(180, 170, 155, 0.2),
                    inset -4px -4px 8px rgba(255, 252, 247, 0.6);
  
  /* 텍스트 (따뜻한 톤) */
  --color-text-primary: #3d3528;
  --color-text-secondary: #6b6254;
  --color-text-tertiary: #9a9080;
  
  /* 강조 색상 */
  --color-success: #ef4444;
  --color-success-light: #ff6b6b;
  --color-success-dark: #dc2626;
}

body {
  background-color: var(--neu-bg);
  color: var(--color-text-primary);
}
```

### 12.2 네오모피즘 유틸리티 컴포넌트

```typescript
// components/ui/NeumorphicBox.tsx
interface NeumorphicBoxProps {
  children: React.ReactNode;
  variant?: 'raised' | 'pressed' | 'flat';
  className?: string;
}

export function NeumorphicBox({ 
  children, 
  variant = 'raised',
  className = '' 
}: NeumorphicBoxProps) {
  const shadowClass = {
    raised: 'shadow-neu-light',
    pressed: 'shadow-neu-dark',
    flat: 'shadow-none',
  }[variant];
  
  return (
    <div className={`
      bg-neu-surface 
      rounded-2xl 
      ${shadowClass} 
      ${className}
    `}>
      {children}
    </div>
  );
}
```

### 12.3 주의사항

- **배경색**: 모든 네오모피즘 요소는 `#f5f1e8` (따뜻한 베이지) 배경 위에서만 제대로 보입니다
- **색상 사용**: 빙고 칸 차지, 알림, 중요한 액션 버튼에만 색상 사용
- **그림자**: 따뜻한 톤의 부드러운 그림자 사용 (차가운 회색 그림자 피하기)
- **대비**: 텍스트 가독성을 위해 충분한 대비 확보 (따뜻한 갈색 계열 텍스트 사용)
- **일관성**: 모든 요소에서 따뜻한 톤 유지 (차가운 회색/흰색 피하기)

## 13. 다음 단계

1. 보안 가이드 확인 (`08-security.md`)
2. 프로젝트 구조 확인 (`09-project-structure.md`)

