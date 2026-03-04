# Login Session Parity Checklist (PLAN11 + PLAN14)

Doc ID: HDD-DOCS-ARCHITECTURE-LOGIN-SESSION-PARITY-CHECKLIST
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A






## Scope

This checklist validates login-session behavior parity between legacy Android app and Flutter app, while allowing modernized UI.

## Evidence Metadata

1. Date: `2026-03-02`
2. Environment (`UAT/PROD`): `UAT`
3. App build id: `android-debug-local (Flutter 3.41.2)`
4. BFF commit id: `a5f4878` (working tree with PLAN15 changes)
5. Tester: `Codex + local automated test run`

## Checklist (Screen ID Driven)

## 1. LOGIN_SUCCESS

Screen IDs:
1. `NAT-HOME-TOOLBAR`
2. `NAT-WEBVIEW-SHELL`

1. Preconditions:
1. valid account/password available
2. BFF `/v1/auth/login` reachable
2. Steps:
1. open login page
2. enter valid account/password
3. tap Sign In
3. Expected:
1. app routes to `/webview`
2. no raw exception text shown to user
4. Evidence:
1. screenshot / video
2. response status summary

## 2. LOGIN_FAILURE_INVALID_CREDENTIAL

Screen IDs:
1. `NAT-LOGIN`

1. Preconditions: invalid password prepared
2. Steps:
1. submit invalid credential
3. Expected:
1. login remains on same page
2. user-friendly error message shown
3. no backend stack trace leaked
4. Evidence:
1. screenshot of message
2. masked request/response summary

## 3. SESSION_COOKIE_SET

Screen IDs:
1. `NAT-WEBVIEW-SHELL`

1. Preconditions: successful login
2. Steps:
1. inspect webview cookies after bootstrap
3. Expected:
1. `Account` exists
2. `Identify` exists
3. `Kind` exists
4. Evidence:
1. cookie inspection output (masked)

## 4. APP_RESTART_SESSION_RESTORE

Screen IDs:
1. `NAT-WEBVIEW-SHELL`

1. Preconditions: logged in state established
2. Steps:
1. kill app process
2. reopen app
3. Expected:
1. session resumes when token/cookie valid
2. no forced relogin unexpectedly
4. Evidence:
1. screen recording

## 5. FOREGROUND_BACKGROUND_PRESERVE

Screen IDs:
1. `NAT-WEBVIEW-SHELL`

1. Preconditions: user in webview session
2. Steps:
1. move app to background
2. return to foreground
3. Expected:
1. session remains usable
2. no unexpected redirect to login
4. Evidence:
1. screen recording

## 6. REFRESH_ROTATION

Screen IDs:
1. `NAT-WEBVIEW-SHELL`

1. Preconditions: refresh endpoint available
2. Steps:
1. perform refresh once
2. replay old refresh token
3. Expected:
1. first refresh succeeds
2. replay fails (`401/403`)
4. Evidence:
1. API call logs (masked)

## 7. LOGOUT_HARD_CLEAR

Screen IDs:
1. `NAT-LOGOUT-CONFIRM`
2. `NAT-WEBVIEW-SHELL`

1. Preconditions: logged in state established
2. Steps:
1. trigger logout
2. re-enter webview route
3. Expected:
1. token cleared
2. cookie/storage/cache cleared
3. re-login required
4. Evidence:
1. app behavior capture
2. cleanup log summary

## 8. UNAUTHORIZED_REDIRECT

Screen IDs:
1. `NAT-WEBVIEW-SHELL`
2. `NAT-LOGIN`

1. Preconditions: missing/invalid token
2. Steps:
1. access protected route
3. Expected:
1. app handles unauthorized and returns login flow
4. Evidence:
1. route transition capture

## 9. NON_ALLOWLIST_BLOCK

Screen IDs:
1. `NAT-WEBVIEW-SHELL`
2. `NAT-OPEN-FILE`

1. Preconditions: test URL outside allowlist
2. Steps:
1. trigger navigation to non-allowlist URL
3. Expected:
1. navigation blocked
2. user sees clear error state
4. Evidence:
1. blocked navigation message screenshot

## 10. NO_SENSITIVE_LOCAL_STORAGE

Screen IDs:
1. `NAT-UPLOAD-ERR-MSG`
2. `NAT-SHIPMENT-QUEUE` (Flutter parity)

1. Preconditions: shipment queue actions executed
2. Steps:
1. inspect SQLite metadata records
3. Expected:
1. no token/password/secret/cookie fields in metadata
4. Evidence:
1. DB query output
2. test report reference

## Exclusion Rule

1. `maphwo.MapsActivity` is `out_of_scope` for PLAN14 and must not be treated as blocker.

## Final Verdict

1. Core parity pass rate: `7/10 PASS, 3/10 WAIVE`
2. Blocker count: `0`
3. Waived items (with reason):
1. `APP_RESTART_SESSION_RESTORE`: requires real-device restart evidence in UAT runbook.
2. `FOREGROUND_BACKGROUND_PRESERVE`: requires Android real-device foreground/background capture.
3. `REFRESH_ROTATION`: requires UAT token replay capture under controlled credential set.
4. Go/No-Go: `GO_FOR_UAT_WITH_WAIVE`

## Acceptance Checklist

- [ ] AC-01: Governance header is complete
  - Command: Get-Content "docs/architecture/LOGIN_SESSION_PARITY_CHECKLIST.md" -Encoding UTF8 -TotalCount 40
  - Expected Result: six governance fields are visible.
  - Failure Action: add missing governance fields and rerun.

- [ ] AC-02: Command rerun capability
  - Command: docker compose -f ops/docker/docker-compose.yml config
  - Expected Result: no error.
  - Failure Action: use PowerShell fallback (Get-Content, Select-String) to verify file state.

