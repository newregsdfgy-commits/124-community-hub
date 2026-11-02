# v1.1.25 — Respect Roblox chat permission

Context: the user's on-device read-only chat audit reports TextChatService:CanUserChatAsync(local UserId) = false, despite RBXGeneral and Гражданские having TextSource membership with CanSend=true. The game has a visible ChatInput ScreenGui and candidates named Network/Chat/SendChatMessage and Remotes/LocalChat.

The permissions are different scopes. Current chat module used RBXGeneral:SendAsync without first checking account-wide permission and called the feature Spam Chat although auto-sending was removed.

Changes:
- A click on "Отправить сообщение" checks global CanUserChatAsync using pcall before any SendAsync call.
- False and failed checks stop with visible status BLOCKED BY ROBLOX or PERMISSION UNKNOWN, leaving message unsent.
- Add manual "Проверить доступ к чату" button.
- Clarify Chat Timer is only a reminder; no automatic messages are sent.
- Protect inFlight across asynchronous permission check to prevent repeated overlapping button presses.
- No calls to unknown game-specific RemoteEvents and no attempts to circumvent Roblox chat restrictions.
- Booster performance and rest of UI untouched.
- Use new diagnostic Start.lua in the v1.1.25 branch. Main and v1.1.23 remain unchanged.

Actual Roblox/Delta/Xeno behavior is still not tested in-session. Only static regression tests and Luau syntax/compile checks are run by CI.
