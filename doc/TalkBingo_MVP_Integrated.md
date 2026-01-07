
# 🧩 TalkBingo MVP – Integrated Product & Design PRD
**Version:** 2.6 (AI Supabase + Ephemeral WebApp + Unified UI Spec)  
**Prepared by:** Erica Im / CAMMUP Inc.  
**Date:** 2025.10.24  

---

## 1️⃣ Product Overview

**Name:** TalkBingo (Balance Bingo)  
**Concept:**  
A web app that lets two users play **Balance Quiz Bingo** without login —
analyzing their relationship via **Supabase** and generating new, personalized quizzes through an **AI Agent**.  
All chats and user interactions are ephemeral (disappear after session end), but all AI-generated questions are permanently learned into the Base DB.

**User Roles:**
- **호스트 (MP - Main Player)**: 빙고 게임을 생성하고 관리하는 주최자
- **게스트 (CP - Co-Player)**: 호스트의 초대를 받아 참여하는 플레이어
- **실시간 화면 공유**: 두 사용자가 동일한 화면을 실시간으로 공유하며 채팅과 빙고게임을 즐김

---

## 2️⃣ Objectives

| Goal | Description |
|------|-------------|
| **No-login onboarding** | Enter via shared link, no account needed |
| **Ephemeral session** | All chats vanish on exit; session temporary |
| **AI-Driven Personalization** | AI agent generates adaptive quizzes based on user similarity |
| **Relational DB Integration** | Relationship modeling and similarity scoring |
| **Emotional Design** | UI uses warm, glassmorphic, intimate visual cues |
| **Localization Strategy** | UI in English, User Data in Local Lang, Questions in Korean (MVP) |

---

## 3️⃣ System Architecture

| Layer | Tech Stack |
|--------|-------------|
| **Frontend** | Next.js + TypeScript + Zustand |
| **Styling** | TailwindCSS + Framer Motion |
| **AI Layer** | Custom AI Agent (LLM) |
| **Database** | Relational DB (Supabase / PostgreSQL) |
| **Session Handling** | `sessionStorage` (ephemeral) |
| **Deployment** | Vercel (frontend) + Supabase Cloud backend |

---

### Data Schema

| Table | Columns | Description |
|-------|-------------|-------------|
| **User** | id, email, nick, age, gender, role | User profile |
| **GameSession** | id, status, createdAt | Game session data |
| **Question** | id, type, content, choices, intimacy | Quiz content |
| **CodeName** | code, mp, cp, ir, sub_rel, intimacy | Question classification |
| **Relation** | mp_id, cp_id, type, intimacy | User relationship |
| **Log** | id, action, detail | Game activity log |

**Relationship Example (SQL)**
```sql
-- Profiles linked to Relation linked to Question Targets
SELECT * FROM questions 
WHERE id IN (
  SELECT question_id FROM question_relations 
  WHERE relation_type_id = (SELECT id FROM relation_types WHERE code = 'B')
);
```

---

## 4️⃣ AI Agent Workflow

1.  **Relationship Analysis**:
    - Users enter → AI analyzes relationship (Type, Intimacy) via Supabase.
    - Determines **CodeName** (e.g., `M-F-B-Ar-L3`).
2.  **Question Generation**:
    - Fetches questions linked to the CodeName.
    - Checks for **Holiday** and **Trend** context (e.g., "Upcoming Christmas").
    - Generates/Selects 25 optimized questions.
3.  **Game Interaction**:
    - Users answer questions → AI updates `RelationLog`.
    - If answers match → Increases `Trust Score` & `Intimacy`.
4.  **Session Summary**:
    - Game End → AI summarizes conversation & relationship progress.
    - Updates `User` and `Relation` tables in Supabase.  

---

## 5️⃣ Data Policy (Ephemeral vs Persistent)

| Data | Storage | Persistence |
|------|----------|-------------|
| Chat | sessionStorage | ❌ (temporary) |
| Player Choices | in-memory | ❌ |
| Generated Questions | Supabase | ✅ permanent |
| Relationship Data | Supabase | ✅ persistent |

---

## 6️⃣ Game Logic (Balance Bingo)

1. **호스트(MP)가 게임 생성** → 초대 링크 생성 및 게스트(CP) 초대
2. **실시간 화면 동기화** → 두 사용자가 동일한 빙고 보드와 채팅을 실시간으로 공유
3. AI Agent fills a 5×5 grid with 25 balance quiz tiles  
4. Player A starts and selects a tile  
5. Modal opens: question text + Option A/B  
6. Both players select → match = claim tile, mismatch = empty  
7. Popup feedback ("우린 통하네요 💕" / "다음에 다시 😅")  
8. AI logs result → updates Supabase similarity  
9. Next turn: switch players until Bingo achieved
10. **호스트 컨트롤**: Play/Pause/Start/End 게임 상태 관리  

---

## 7️⃣ Interaction Model

```
┌───────────────────────────────┐
│ Header                        │
│  Logo | Message Preview | Badge│
├───────────────────────────────┤
│ Center                        │
│  ← Chat Board → Bingo Board   │
│  Swipe/Arrow Switch           │
│  Modal on Bingo click         │
├───────────────────────────────┤
│ Bottom                        │
│  Host Controls • Chat Input   │
│  Custom Keyboard (KR/EN/NUM)  │
└───────────────────────────────┘
```

### Header
- Shows logo, current message preview, and unread badge  
- Scroll hint for message history  
- Badge clears when switching to Chat view  

### Center
- **Chat Board:** sequential message list (right/left bubbles)  
- **Bingo Board:** interactive 5×5 grid (glass tiles)  
- Hover = glow; click = quiz modal  

### Bottom
- **호스트 전용 컨트롤**: Play/Pause/Start/End 게임 상태 관리
- Chat input (max 50 chars) with mic button (STT)  
- Custom keyboard slides up/down on focus
- **실시간 동기화**: 모든 액션이 두 사용자에게 즉시 반영  

---

## 8️⃣ Quiz Modal Logic

| Event | Behavior |
|--------|-----------|
| Click empty tile | Open modal with AI question |
| Select Option A/B | Save response |
| Both players answered | Compare → if same, claim tile |
| Match | Highlight tile (A: Sky, B: Pink) |
| Mismatch | Leave blank; feedback popup |
| Already owned | Show toast “이미 차지한 칸입니다” |

---

## 9️⃣ Visual Style — Glassmorphism UI

### Color Palette
| Role | Color |
|------|--------|
| Base | #FBEFF2 (Rose Mist) |
| Bingo Background | #14101A (Night Plum) |
| Player A | #7DD3FC (Sky) |
| Player B | #FBCFE8 (Pink) |
| Success | #34D399 (Mint) |
| Warning | #F59E0B (Amber) |

### Effects
- `backdrop-filter: blur(20px)`  
- Soft shadows: `0 8px 24px rgba(0,0,0,.18)`  
- Rounded corners: 16–20px (tiles 12px)  
- Glow transition for hover/focus  

### Typography
- **Pretendard / Inter**, size 14–16px  
- Line-height 1.5  
- Body text on glass panels, white/90% opacity  

---

## 🔟 Animation & Feedback

| Action | Effect |
|---------|--------|
| Hover Tile | Lift + shadow expand |
| Select | Pulse & highlight color |
| Match | “Pop” glow (0.2s) |
| Mismatch | Shake + fade |
| Modal In/Out | Framer Motion scale/fade (180ms) |
| Keyboard | Slide up/down (ease-in-out 220ms) |

---

## 11️⃣ Accessibility (A11y)

- Modal: `role="dialog"`, focus trap  
- Bingo Tiles: `aria-pressed`, keyboard-activatable  
- Chat: `aria-live="polite"`  
- Keyboard: `aria-expanded` on input focus  

---

## 12️⃣ Example Pseudo Code

```ts
type Player = "A" | "B";
type Tile = { id: string; owner: Player | null; quizId: number; };

function onTileClick(tile: Tile) {
  if (paused || tile.owner) return toast("이미 차지한 칸입니다");
  openModal(tile.quizId);
}

function onChoiceSubmit(a: "A" | "B", b: "A" | "B", tile: Tile) {
  const match = a === b;
  if (match) claimTile(tile);
  toast(match ? "우린 통하네요 💕" : "다음에 다시 😅");
  switchTurn();
}
```

---

## 13️⃣ Deliverables

| File | Description |
|-------|--------------|
| `src/app/page.tsx` | Root layout, board switcher |
| `src/components/BingoBoard.tsx` | Bingo logic & modal trigger |
| `src/components/ChatBoard.tsx` | Chat list & badge sync |
| `src/components/Keyboard.tsx` | Floating input keyboard |
| `src/components/QuizModal.tsx` | Modal for question/choices |
| `src/components/HostControls.tsx` | 호스트 전용 게임 컨트롤 (Play/Pause/Start/End) |
| `src/hooks/useRealtimeSync.ts` | 실시간 화면 동기화 로직 |
| `src/ai/agent.ts` | AI logic + Supabase interface |

---

## 14️⃣ Future Expansion

| Phase | Feature |
|--------|----------|
| Phase 2 | Real-time multiplayer (WebSocket sync) |
| Phase 3 | Relationship Graph Visualization |
| Phase 4 | Emotion-based quiz generation |
| Phase 5 | Optional light login (session recovery) |

---

## 15️⃣ Summary

> TalkBingo MVP 2.5 is an AI-personalized, no-login social webapp combining  
> **Balance Quiz Bingo, Relational Data Learning, and Glassmorphic Design.**  
> The experience is ephemeral yet intelligent — all user actions vanish after exit,  
> while the AI grows smarter with every question generated and stored in the Supabase.
