# Payment System Strategy: Failure Handling & Refunds

This document outlines the proposed strategy for handling payment failures and implementing a refund system for TalkBingo.

## 1. Payment Failure Handling System

The goal allows for graceful degradation when payments fail, ensuring user trust and data integrity.

### Client-Side Handling (Flutter App)
- **Pre-Validation:**
  - Validate Card Number (Luhn Algorithm), Expiry Date (Future), and CVV format *before* sending to server.
  - Check for network connectivity before initiating transaction.
- **Error Feedback:**
  - **Network Error:** "Internet connection unstable. Please check and try again."
  - **Gateway Decline:** "Payment declined by bank. Please check card limits or details." (Do not reveal specific security reasons if sensitive).
  - **System Error:** "Temporary system error. No charge was made. Please try later."
- **Retry Mechanism:**
  - Allow 1 immediate retry for network timeouts.
  - For declines, prompt user to "Check Details" or "Use Different Card".

### Server-Side Handling (Supabase/Edge Functions)
- **Atomic Transactions:**
  - Payment processing and Point allocation MUST occur in a single atomic transaction or handled via idempotent webhooks.
  - **Flow:**
    1.  Create `transaction_record` (status: `pending`).
    2.  Call Payment Gateway (e.g., Stripe/KakaoPay).
    3.  **If Success:** Update `transaction_record` to `success`, Increment User Points.
    4.  **If Fail:** Update `transaction_record` to `failed`, store error code. Do NOT allocate points.
- **Idempotency:**
  - Use `request_id` to prevent double-charging if the client retrys the same request due to network lag.

---

## 2. Refund System Plan

The goal is to provide a fair and compliant refund process while simulating or implementing real admin controls.

### Refund Policy (Draft)
- **Eligibility:**
  - Refund requests must be made within **7 days** of purchase.
  - Only **unused** points can be refunded. If a user buys 1000 VP and uses 200 VP, the remaining 800 VP is eligible (partial) or non-refundable (full, depending on strictness).
  - *Recommendation:* "Full refund only if ZERO points from the pack were used."

### Implementation Flow
1.  **User Request:**
    - In `Settings` -> `Purchase History` (to be added).
    - User clicks "Request Refund" on a specific transaction.
    - System checks eligibility (Date < 7 days, Current Points >= Purchased Amount).
2.  **Processing:**
    - **Auto-Refund (Low Risk):** If within 24 hours and untouched, system auto-reverses.
    - **Manual Review (Standard):** Request logs to `refund_requests` table. Admin approves via Admin Panel.
3.  **Completion:**
    - Gateway processes refund.
    - Supabase deducts points from User.
    - Notification sent to User.

### Database Requirements
- **Table: `payment_transactions`**
  - `id`: UUID
  - `user_id`: UUID
  - `amount`: Integer (Currency)
  - `points`: Integer
  - `status`: `success`, `failed`, `refunded`, `pending`
  - `gateway_id`: String
  - `created_at`: Timestamp
- **Table: `refund_requests`**
  - `id`: UUID
  - `transaction_id`: UUID
  - `reason`: String
  - `status`: `pending`, `approved`, `rejected`

## 3. Next Steps
1.  **Frontend:** Update `PointPurchaseScreen` to show "History" and potentially "Refund" button (future).
2.  **Backend:** Design `payment_transactions` table in Supabase.
3.  **Gateway:** Select and integrate test mode of a Payment Gateway (Stripe Test Mode recommended).
