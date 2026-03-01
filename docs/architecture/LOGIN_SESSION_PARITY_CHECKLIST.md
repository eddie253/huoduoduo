# Login Session Parity Checklist (PLAN11)

## Scope

This checklist validates login-session behavior parity between legacy Android app and Flutter app, while allowing modernized UI.

## Evidence Metadata

1. Date:
2. Environment (`UAT/PROD`):
3. App build id:
4. BFF commit id:
5. Tester:

## Checklist

## 1. LOGIN_SUCCESS

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

1. Preconditions: missing/invalid token
2. Steps:
1. access protected route
3. Expected:
1. app handles unauthorized and returns login flow
4. Evidence:
1. route transition capture

## 9. NON_ALLOWLIST_BLOCK

1. Preconditions: test URL outside allowlist
2. Steps:
1. trigger navigation to non-allowlist URL
3. Expected:
1. navigation blocked
2. user sees clear error state
4. Evidence:
1. blocked navigation message screenshot

## 10. NO_SENSITIVE_LOCAL_STORAGE

1. Preconditions: shipment queue actions executed
2. Steps:
1. inspect SQLite metadata records
3. Expected:
1. no token/password/secret/cookie fields in metadata
4. Evidence:
1. DB query output
2. test report reference

## Final Verdict

1. Core parity pass rate:
2. Blocker count:
3. Waived items (with reason):
4. Go/No-Go:
