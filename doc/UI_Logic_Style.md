
# TalkBingo MVP — UI Logic & Style Spec
**Screen:** Mobile-first (Multi-screen App, Single Page Gameplay)  
**Grid:** Header · Center (Chat ⟷ Bingo) · Bottom Controls  
**Interaction Model:** Turn-based, host-controlled, modal-driven balance quiz
**User Roles:** 호스트(MP) - 게임 생성/관리, 게스트(CP) - 초대받아 참여
**Real-time Sync:** 두 사용자가 동일한 화면을 실시간으로 공유

---

## 0) Screen Architecture & Navigation Flows

**Application Structure:** Multi-screen App with SPA-like Gameplay
- **Entry Points:** App Launch (Splash), Deep Link (Invite Code)
- **Primary Roles:** Host (Organizer/Player A), Guest (Invitee/Player B)

### Navigation Maps

**A. Host Flows**
1.  **New User (Onboarding):**
    `Splash` → `Signup` (Google Auth) → `HostInfo` (Profile) → `HostSetup` (Create Game) → `GameSetup` → `Waiting` → `Game`
2.  **Existing User (Returning):**
    `Splash` → `Home` (Auto-login) OR `Signup` → `Home` (Google Login)
3.  **Game Creation:**
    `Home` → `HostSetup` → `GameSetup` → `Waiting` (Questions Loading) → `Game` → `Reward` → `Home`
4.  **Joining as Guest (Host playing as Guest):**
    `Home` → `InviteCode` → `Waiting` → `Game` → `Reward` → `Home`

**B. Guest Flows**
1.  **General Guest (Anonymous/New):**
    `Splash` → `Signup` (Select "Enter Invite Code") → `InviteCode` → `GuestInfo` → `Waiting` → `Game` → `Reward` → `Signup`/`Exit`
2.  **Member Guest (Registered User):**
    `Link` → `Home` (Auto-fill Code) → `InviteCode` → `Waiting` → `Game` → `Reward` → `Home`

---

## 1) Layout Regions

```
┌──────────────── Header ────────────────┐
│  Logo | Message showing | Badge | ⋮    │
│  (scroll hint for timeline preview)    │
├──────────────── Center ────────────────┤
│  [Chat Board]  ⟷  [Bingo Board]        │
│  • Arrow buttons (← →) to switch board  │
│  • Bingo: empty tiles → hover/click →   │
│    Modal with A/B options (Balance Quiz)│
├──────────────── Bottom ────────────────┤
│  Host Controls: Play/Pause/Start/End   │
│  Chat Input (≤ 50 chars) + STT button   │
│  Custom Keyboard (Hangul/EN/123/∿)      │
│  Real-time Sync Indicator               │
│  Safe area (≤ 30) empty                │
└────────────────────────────────────────┘
```

**Breakpoints (px)**  
- `sm ≤ 480`: mobile (primary target)  
- `md 481–768`: small tablet  
- `lg ≥ 769`: desktop preview (centered, max-width: 420–480)  

**Container**  
- `max-width: 420px` on desktop; full width on mobile.  
- Safe-area support: iOS notch padding via `env(safe-area-inset-*)`.

---

## 2) Header (Logo · Message showing · Message badge · Scroll)

### Elements
- **Logo** (left), 24–28px height SVG
- **Message showing**: single-line ticker of the latest chat (“…”) with subtle fade at edges
- **Badge**: `N` new messages counter (max 99+, pill)
- **Overflow/More**: `⋮` button (opens menu: Mute, Clear board, Settings)
- **Scroll hint**: a thin progress bar beneath the ticker when timeline is scrollable

### Logic
- Ticker auto-scrolls horizontally if text width > container
- Badge increments when **new message arrives and Center is on Bingo Board**
- Clicking the ticker focuses **Chat Board** (center switches if needed)

### Data hooks
- `data-role="header"`  
- `data-badge="0|N"`

---

## 3) Center — Board Switcher

### 3.1 Switcher
- Two boards side-by-side in a horizontal pager
- **Arrow buttons (← →)** fixed at the sides of the pager
- Swipe gesture on mobile (20px threshold)

**State**
- `center.active = "chat" | "bingo"` (default: `"bingo"`)
- When switching to `"chat"`, header badge resets to 0

### 3.2 Chat Board
- Vertical list, newest at bottom
- **Alignment Rules**:
  1. **Incoming Messages** (Guest/Partner): **Left Align**
  2. **My Messages** (Host/Me): **Right Align**
  3. **Bingo/Selection Events**: **Center Align**
     - One question/event per cell
     - **MP Turn (Host)**: Bg `var(--primary-darkpink)`, Text `var(--text-secondary-a)`
     - **CP Turn (Guest)**: Bg `var(--primary-darkpurple)`, Text `var(--text-secondary-b)`
- Time separators per 5 min group
- Lazy virtualization after 100 items

**Message Item**
- Avatar (24px), name (visually hidden), bubble with text/emoji
- Reactions (❤️ 😂 👍) on long-press
- Copy on long-press (mobile) or hover action (desktop)

**Accessibility**
- `role="log"`, aria-live="polite", aria-relevant="additions"
- Provide “Jump to latest” floating button when scrolled up

### 3.3 Bingo Board (Balance Quiz)
- Matrix: **5×5** by default (3×3 / 4×4 variants allowed)
- Tile size (mobile 390–430w): **56–60px** min, gap 8–10px
- Empty tile = soft glass square with inner shadow
- **Hover/Focus**: soft glow; **Click/Tap**: open Modal
- Owning a tile tints it to **Player color** (A: #7DD3FC / B: #FBCFE8)

**Data hooks**
- `data-event="B"` (Balance quiz), `data-row`, `data-col`, `data-owner="A|B|null"`

---

## 4) Quiz Modal (Overlay)

### Structure
- **Question** (2 lines max; clamp with ellipsis)
- **Options**: Button A · Button B (full-width on mobile, stacked)
- **Subtext**: “둘이 같은 선택이면 칸을 차지합니다.”
- **Close** (esc / backdrop click)

### Interaction
1. Tile click → open Modal with the tile’s quiz
2. Player A, Player B 각각 선택 제출 (same device: two-step input or toggled “current player”)
   *Host Solo Start*: 호스트 혼자 먼저 들어온 경우, 게스트가 들어올 때까지 대기하거나 혼자 둘러볼 수 있음 (점유는 불가).
3. **Match** → acquire tile; show toast: “우린 통하네요!”  
   **Mismatch** → keep empty; toast: “다음에 다시!”
4. Modal closes → turn switches

### Edge cases
- If a tile already owned → clicking opens **read-only** toast (“이미 차지한 칸”)
- Networkless MVP: choices kept in client state only

---

## 5) Bottom — Host Controls & Chat Input

### 5.1 Host Controls (호스트 전용)
- **Play/Pause** toggle: freezes/unfreezes interactions (board input + chat submit)
- **Start Game**: 새로운 빙고 게임 시작
- **End Game**: 현재 게임 종료 및 결과 표시
- **Settings** (optional): board size, color theme
- **실시간 동기화**: 모든 컨트롤 액션이 게스트에게 즉시 반영

**Data hooks**
- `data-host="true|false"` (only host sees controls)
- `data-sync-status="connected|disconnected"` (실시간 연결 상태)

### 5.2 Chat Input
- Single line input, **maxLength = 50**
- Buttons: **STT (mic)**, **Send (paper plane)**
- Disabled when `paused = true`
- STT: when recording, show waveform and elapsed seconds; stop on blur

**Validation**
- Trim whitespace; collapse multiple spaces
- If empty after trim → ignore submit

---

## 6) Custom Keyboard (Hangul/EN/123/∿ Special)

### Behavior
- **Click into input** → keyboard slides up from bottom (200–240ms ease-out)
- **Tap outside / scroll** → keyboard slides down (ease-in)
- Modes: **KOR**, **ENG**, **NUM**, **SYM**  
  - Mode toggle persists per session
- Key press anim: scale 0.98 with shadow burst (40ms)
- Long-press on key opens alternate glyphs (e.g., ㅐ/ㅒ, punctuation variants)

### Layout (mobile width 360–430)
- Key size ~ **44×48px**, row gap 6px, column gap 5px
- Last row: `Mode` · `Space` · `Backspace` · `Enter`
- STT active → mic glows; pressing `Enter` submits

**Dismiss rules**
- Swipe down gesture over keyboard area
- Press **↓** chevron button on top of keyboard
- Programmatic: `keyboard.hide()` on route change or modal open

---

## 7) Visual Style (Glassmorphism + Depth)

### Palette & Effects
- **Glassmorphism**: `backdrop-filter: blur(20px)` on cards/modals.
- **Background**: Dark Theme (`#0C0219`) with floating glass layers (`rgba(255,255,255,0.1)`).
- **Shadows**: Soft glows for highlights, Deep shadows for depth.
- **Corners**: **16–20px** (tiles 12px).
- **Focus ring**: 2px outline using current accent.

### Typography
- Inter / Pretendard, **13–14px** body, **20px** page title, **14px** section title
- Label/Caption: **12px**
- Line-height 1.4–1.5; ellipsis for overflow

### Localization Rules
- **Static UI**: English (e.g., `Start`, `Pause`, `Settings`)
- **User Input**: Localized (KR/EN)
- **Questions**: Korean (MVP only)

---

## 8) State & Events (Pseudo)

```ts
type Player = "A" | "B";
type Owner = Player | null;
type UserRole = "host" | "guest";

type Tile = { id: string; row: number; col: number; owner: Owner; quizId: number };
type Center = "bingo" | "chat";
type GameState = "waiting" | "playing" | "paused" | "ended";

const state = {
  userRole: "host" as UserRole,
  gameState: "waiting" as GameState,
  center: "bingo" as Center,
  paused: false,
  turn: "A" as Player,
  tiles: [] as Tile[],
  badge: 0,
  syncStatus: "connected" as "connected" | "disconnected"
};

function onTileClick(tile: Tile) {
  if (state.paused || tile.owner) return toast("이미 차지한 칸");
  openModal(tile.quizId);
}

function onSubmitChoice(tileId: string, aChoice: "A"|"B", bChoice: "A"|"B") {
  const match = aChoice === bChoice;
  if (match) claimTile(tileId, state.turn);
  toast(match ? "우린 통하네요!" : "다음에 다시!");
  switchTurn();
  checkBingo();
}

function switchTurn() { state.turn = state.turn === "A" ? "B" : "A"; }

function onNewMessage() {
  if (state.center !== "chat") state.badge = Math.min(99, state.badge + 1);
}

function onCenterSwitch(next: Center) {
  state.center = next;
  if (next === "chat") state.badge = 0;
}

// 호스트 전용 게임 컨트롤 함수들
function onStartGame() {
  if (state.userRole !== "host") return;
  state.gameState = "playing";
  state.paused = false;
  syncToGuest("gameStarted");
}

function onPauseGame() {
  if (state.userRole !== "host") return;
  state.gameState = "paused";
  state.paused = true;
  syncToGuest("gamePaused");
}

function onEndGame() {
  if (state.userRole !== "host") return;
  state.gameState = "ended";
  syncToGuest("gameEnded");
}

// 실시간 동기화 함수
function syncToGuest(action: string, data?: any) {
  // WebSocket 또는 실시간 통신으로 게스트에게 상태 전송
  websocket.send({ action, data, timestamp: Date.now() });
}
```

---

## 9) Accessibility (A11y)
- Modal: `role="dialog"`, focus trap, `aria-labelledby` question text
- Tiles: `role="button"`, `aria-pressed` when owned, `tabIndex=0`, activate on Enter/Space
- Arrow switch: `aria-label="다음 보드" / "이전 보드"`
- Keyboard: expose `aria-expanded` on input

---

## 10) CSS/Tailwind Snippets

```css
/* Glass card */
.glass {
  background: rgba(255,255,255,.8);
  backdrop-filter: blur(20px);
  box-shadow: 0 8px 24px rgba(0,0,0,.18);
  border-radius: 16px;
}

/* Bingo tile */
.tile {
  background: rgba(255,255,255,.08);
  box-shadow: inset 0 2px 6px rgba(0,0,0,.35), 0 4px 12px rgba(0,0,0,.25);
  border-radius: 12px;
  transition: transform .12s ease, box-shadow .12s ease;
}
.tile:hover, .tile:focus { transform: translateY(-1px); box-shadow: 0 8px 18px rgba(0,0,0,.25); }
.tile--A { background: rgba(125,211,252,.25); outline: 2px solid rgba(125,211,252,.55); }
.tile--B { background: rgba(251,207,232,.25); outline: 2px solid rgba(251,207,232,.55); }
```

---

## 11) Files & IDs (for dev handoff)
- `src/app/page.tsx` (board switcher + layout)
- `src/components/BingoBoard.tsx` (tiles, ownership, modal trigger)
- `src/components/ChatBoard.tsx` (virtualized list)
- `src/components/QuizModal.tsx` (A/B select)
- `src/components/HostControls.tsx` (호스트 전용 게임 컨트롤)
- `src/components/Keyboard.tsx` (custom keyboard overlay)
- `src/hooks/useRealtimeSync.ts` (실시간 동기화 로직)
- `src/hooks/useGameState.ts` (게임 상태 관리)
- `data-ids`: `data-owner`, `data-event="B"`, `data-role="header"`, `data-host`, `data-sync-status`

---

## 12) Empty → Owned Tile Transition
- Duration 180–220ms, ease-out
- Scale 0.96 → 1.00 with color wash
- Add 140ms “completion sparkle” (subtle particle or glow) when line completed

---

## 13) Error & Edge UX
- If paused: clicking tile or send button shows toast "일시정지 중입니다"
- If input > 50 chars: block and shake, helper text "최대 50자"
- Keyboard open + Modal open: keyboard first hides, then show modal
- **호스트 권한 없음**: 게스트가 컨트롤 버튼 클릭 시 "호스트만 사용할 수 있습니다" 토스트
- **연결 끊김**: 실시간 동기화 실패 시 "연결이 끊어졌습니다" 표시 및 재연결 시도
- **게임 상태 불일치**: 호스트와 게스트 간 상태 차이 발생 시 자동 동기화

---

**Notes for Figma handoff**  
- Export style tokens (colors, radii, shadows) as variables  
- Component props: `ownedBy: 'A'|'B'|null`, `question`, `options: ['A','B']`  
- Provide a prototype showing: Empty → Modal → Match/Mismatch → Ownership

---

## 14) Mobile Component Specifications (Strict)

### Layout & Spacing
- **PagePadding**: 12px
- **SectionSpacing**: 12px
- **ElementSpacing**: 8–10px

### Typography
- **Title**: 20px / Bold
- **SectionTitle**: 14px / Bold
- **Label**: 12px
- **Body**: 13–14px

### Components

#### Input Fields
- **InputHeight**: 38px
- **InputPadding**: 10px horizontal, 6px vertical

#### Buttons
- **ButtonHeight**: 44px
- **ButtonFontSize**: 14px
- **ButtonRadius**: 8px

#### Chips
- **ChipFont**: 12px
- **ChipPadding**: 12px horizontal, 6px vertical
- **ChipHeight**: 28–32px
  
