# Lookbook — Messaging Schema (Locked)

Status: **LOCKED** as of today. Do not rename or restructure existing fields.
Adding new fields later is fine — renaming or nesting differently is not.

Database: Firebase Realtime Database (matches the rest of the app —
`creator_profiles/`, `user-chats/` etc. all live at the root of the same tree).

Naming convention: **camelCase** for all fields, matching `syncyoutubefollowers`
(`followerCount`, `lastSynced`) rather than the older `snake_case` used in
`creator_profiles` (`full_name`, `is_subscribed`). New messaging code should
not introduce snake_case.

---

## 1. `chats/{chatId}`

One node per conversation between exactly two users.

```
chats/
  {chatId}/
    participants: { uidA: true, uidB: true }
    lastMessage: String
    lastMessageAt: Number        // server timestamp, millis since epoch
    lastSenderId: String
    unreadCount: { uidA: Number, uidB: Number }
    createdAt: Number            // server timestamp, millis since epoch
```

| Field | Type | Notes |
|---|---|---|
| `participants` | `Map<String, bool>` | Always exactly 2 keys (1:1 chat only, no group chat in v1). Used for security rules — a user can only read a chat node if `participants/{their uid}` exists. |
| `lastMessage` | `String` | Preview text shown in the chat list. For non-text message types, store a placeholder (e.g. `"📷 Photo"`, `"💰 Sent a rate card"`). |
| `lastMessageAt` | `Number` | Server timestamp (`ServerValue.timestamp`), not client `DateTime.now()` — avoids clock-skew between two phones. |
| `lastSenderId` | `String` | Lets the chat list show "You: ..." vs "them: ...". |
| `unreadCount` | `Map<String, Number>` | Keyed by uid. See rule in section 4. |
| `createdAt` | `Number` | Server timestamp, set once at chat creation, never updated. |

### `chatId` generation rule
Sort the two participant uids alphabetically and join with `_`:

```
chatId = [uidA, uidB]..sort()join('_')
// e.g. uid "zzz111" + uid "aaa999" -> chatId = "aaa999_zzz111"
```

This is deterministic — both users computing it independently always get the
same `chatId`, so there is no race condition where two chats get created if
both message each other at the same instant. Never generate `chatId` with
`push()` or a random ID.

---

## 2. `messages/{chatId}/{messageId}`

Kept as a **separate top-level tree** from `chats/`, not nested inside it —
so opening the chat list never pulls full message history, only the
lightweight `chats/{chatId}` summary node.

```
messages/
  {chatId}/
    {messageId}/            // auto-generated via push()
      senderId: String
      text: String
      type: String           // "text" | "image" | "rate_card" | "system" | "document" | "voice"
      sentAt: Number          // server timestamp, millis since epoch
      status: String          // "sent" | "delivered" | "read"
```

| Field | Type | Notes |
|---|---|---|
| `senderId` | `String` | uid of the sender. |
| `text` | `String` | For `type: "image"`, `type: "document"`, and `type: "voice"`, this holds the file download URL instead of body text. For `type: "rate_card"`, this holds a JSON-encoded snapshot of the rate. |
| `type` | `String` | Fixed enum: `text`, `image`, `rate_card`, `system`, `document`, `voice`. |
| `sentAt` | `Number` | Server timestamp — same reasoning as `lastMessageAt`. |
| `status` | `String` | `sent` on write. Client updates to `delivered` when the receiving device's listener fires, and to `read` when the receiver opens the thread. Sender-side UI only needs to read this, never write another user's status update path directly (see security rules note in section 5). |

`messageId` is generated with `push()` — not a deterministic ID like `chatId`,
since multiple messages can legitimately be created concurrently and each
needs its own unique key.

---

## 3. `user-chats/{uid}/{chatId}`

Pure index — exists only so "which chats does this user have" is a shallow,
O(1) read instead of scanning all of `chats/`.

```
user-chats/
  {uid}/
    {chatId}: true
```

Written once, at chat creation, for both participants simultaneously (same
write transaction/multi-path update as creating `chats/{chatId}` itself).
Never updated after that — deleting a chat, if that's ever built, would
remove the key here too, but v1 has no delete/archive feature.

---

## 4. Unread count rule

- When user A sends a message in a chat with user B:
  increment `chats/{chatId}/unreadCount/{B's uid}` by 1.
  Leave `chats/{chatId}/unreadCount/{A's uid}` untouched.
- When user B opens the chat thread:
  reset `chats/{chatId}/unreadCount/{B's uid}` to 0.
- The sender never touches their own unread counter, and a user only ever
  resets their own counter — never the other participant's.

---

## 5. Security rules note (for when rules are written)

- A user may read/write `chats/{chatId}` and `messages/{chatId}/*` only if
  `chats/{chatId}/participants/{their uid}` is `true`.
- A user may write to `messages/{chatId}/{messageId}/status` only to move it
  forward (`sent` → `delivered` → `read`), and only on messages where they are
  NOT `senderId` (you mark others' messages as read/delivered, not your own).
- `user-chats/{uid}` is only ever readable/writable by that same `uid`.

(This section is a note for the rules-writing task, not implemented yet —
capturing the intent now so it isn't re-decided later.)

---

## What's intentionally NOT in v1

- No group chats — `participants` is always exactly 2 keys.
- No message editing or deletion.
- No typing indicators or presence.
- No pagination strategy decided yet for `messages/{chatId}` — v1 assumes
  chat history stays small; revisit if a chat grows past ~500 messages.

Any of the above can be added later as new fields/nodes without breaking this
schema — that's the point of locking it now.