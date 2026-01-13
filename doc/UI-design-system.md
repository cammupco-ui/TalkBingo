# UI/UX Unified Design System (Web & App)

This document serves as the **Single Source of Truth** for the TalkBingo UI/UX across both **Flutter App** and **Next.js Web** platforms.

## 1. Design Principles (Core)
- **Glassmorphism + Depth**: Translucent layers (`blur(20px)`) with white/light borders on dark backgrounds.
- **Role-Based Themes**:
    - **Host (MP)**: Vivid Pink (`#BD0558`)
    - **Guest (CP)**: Deep Purple (`#430887`)
- **Mobile-First**: Optimized for 360px~430px width.
- **Engraved Inputs**: Input fields use a "Filled" style (Light Grey) without borders to create depth.

---

## 2. Color Palette & Logic

| Role / Type | Color Name | Hex | Description |
|---|---|---|---|
| **Host** | `Primary` | `#BD0558` | Main Actions, Active State |
| | `Secondary` | `#FF0077` | Highlights, Accents |
| | `Dark` | `#610C39` | Text, Background Accents |
| | `Background`| `#F4E7E8` | My Message Bubble |
| **Guest** | `Primary` | `#430887` | Main Actions, Active State |
| | `Secondary` | `#6B14EC` | Highlights |
| | `Dark` | `#2E0645` | Text, Background Accents |
| | `Background`| `#F0E7F4` | My Message Bubble |
| **Common** | `White` | `#FFFFFF` | Text, Icons |
| | `Surface` | `#FFFFFF` | Cards, Modals (Glass) |
| | `Background`| `#0C0219` | Main App Background (Dark) |
| | `Input BG` | `#F5F5F5` | Engraved Input Background |
| | `Muted` | `#CDBFC1` | Inactive Text (Host) |
| | `Muted ` | `#C7BFCD` | Inactive Text (Guest) |
| | `Success` | `#2ECC71` | Valid/Completed |
| | `Error` | `#FF0000` | Invalid/Warning |

---

## 3. Typography (Unified)

**Font Family**:
- **Titles**: `NURA` (Fallback: System Sans)
- **Body (EN)**: `Alexandria`
- **Body (KO)**: `EliceDigitalBaeum` (Primary), `EliceDigitalCodingverH` (Secondary)

**Type Scale** (Optimized for Medium UI):
| Style | Size (px) | Weight | Line Height | Usage |
|---|---|---|---|---|
| **H1** | 22 | Bold | 1.2 | Page Titles |
| **H2** | 18 | Bold | 1.3 | Modal Titles, Section Headers |
| **H3** | 16 | SemiBold | 1.4 | **Large Button Text** (48px), Card Titles |
| **Body 1** | 14 | Medium | 1.5 | **Default Input/Button Text** (38px) |
| **Body 2** | 13 | Regular | 1.5 | Secondary Info, Chat Messages |
| **Caption** | 12 | Regular | 1.4 | Labels, Timestamps, Hints |
| **Micro** | 10 | Bold | 1.0 | Badges, Tiny Labels |

--

## 4. Spacing & Layout System

**Base Unit**: `4px` (All spacing should be divisible by 4)

| Token | Size | Value (px) | Usage |
|---|---|---|---|
| `xs` | 0.5x | 4px | Tight grouping, Icon padding |
| `sm` | 1x | 8px | Related elements, Input internal padding |
| `md` | 1.5x | 12px | **Standard Component Padding**, Section spacing |
| `lg` | 2x | 16px | Container padding, Card spacing |
| `xl` | 3x | 24px | Major Section dividers |
| `2xl` | 4x | 32px | Bottom safe area spacing |

**Global Layout Rules**:
- **Screen Padding**: `12px` (Mobile), `16px` (Tablet/Web)
- **Section Spacing**: `24px` between major logical blocks.
- **Component Grouping**: `6px` or `8px` vertical gap between related inputs (e.g., Profile Form).

---

## 5. Component Specifications (Strict)

### 5.1 Inputs (TextField / TextFormField)
- **Style**: Engraved (Filled)
- **Default Height**: `38px` (Medium Standard)
- **Background**: `#F5F5F5` (Light Grey)
- **Border**: None (`BorderSide.none`)
- **Radius**: `8px`
- **Content Padding**: Horizontal `12px`, Vertical `8px` (Compact)
- **Font**: Body 1 (14px)

### 5.2 Buttons
- **Primary Height (Save/Next)**: `48px` (Large)
- **Default Height (Secondary/Standard)**: `38px` (Medium)
- **Small Height**: `30px`
- **Radius**: `8px`
- **Font**: 
    - Primary: H3 (16px, Bold)
    - Default: Body 1 (14px, Medium)
- **Primary Style**: Filled Color (Host Pink / Guest Purple) + White Text
- **Secondary Style**: Outlined (1px solid Theme Color) or Soft Tint + Theme Text
- **Auth/Link Button**: Prominent "Sign Up / Link Account" button in Settings for converting anonymous users.

### 5.3 Cards & Containers
- **Radius**: `12px` (Standard), `16px` (Large Modal)
- **Padding**: `16px` (Inner content)
- **Shadow**: `BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))`
- **Border**: `1px solid console(0,0,0,0.05)` (Subtle outline for definition)

### 5.4 Separators
- **Dividers**: Thin Grey Line (`Colors.grey[200]`), 1px height.
- **Dotted Line**: Used for grouping distinct sections (e.g. Essential vs Additional Info).

---

## 6. Implementation Notes (Web vs App)

### Flutter (App)
- Use `SizedBox(height: 12)` for standard vertical spacing.
- Use `EdgeInsets.all(12)` for standard screen padding.
- Use `ThemeData` to define `inputDecorationTheme` globally.

### React / Tailwind (Web)
- `p-3` (12px) for padding.
- `gap-2` (8px) or `gap-1.5` (6px) for item spacing.
- `rounded-lg` (8px) or `rounded-xl` (12px).
- `bg-gray-100` (`#f3f4f6`) closes to `#F5F5F5`.

---

---

## 8. Payment & Shop UI Specification

Defined for the Hybrid Payment Model (`Payment_System_Plan.md`) and recent mockups.

### 8.1 Method Selector (Web Only)
*   **Style**: Segmented Control / Toggle Switch.
*   **Appearance**:
    *   Container: rounded-xl, light grey background (`#F5F5F5`).
    *   Selected: White shadow card, Bold text.
    *   Unselected: Transparent, Medium text, Muted color.
*   **Content**: `🇰🇷 Korea Card` vs `🌏 Global Card`.

### 8.2 Product Cards (Point Packs)
*   **Layout**: Vertical Stack (Icon -> Amount -> Price Button).
*   **Visual**:
    *   **Border**: `1px solid primary-color` (Host: Pink, Guest: Purple).
    *   **Background**: Glass-white gradient.
    *   **Price Button**: Full width, bottom rounded.
*   **Responsive**:
    *   **Mobile**: 2 columns grid.
    *   **Web**: 3 or 4 columns grid.

### 8.3 Transaction History
*   **List Item**:
    *   **Left**: Transaction Date & Type (Buy/Refund).
    *   **Right**: Amount (+1000 VP) & Status Badge.
*   **Status Badges**:
    *   `Success`: Green text / light green bg.
    *   `Refunded`: Red text / light red bg.
    *   `Pending`: Orange text.

### 8.4 Add Payment Method Button (Web)
*   **Style**: Large Outline Button with Request Icon.
*   **Border**: 1.5px solid Primary Color.
*   **Icon**: Credit Card / Plus symbol.
*   **Usage**: "Add Payment Method" or "Select Card".

---

