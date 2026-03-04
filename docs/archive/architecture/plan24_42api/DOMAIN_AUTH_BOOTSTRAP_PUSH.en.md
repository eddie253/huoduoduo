# DOMAIN: Auth / Bootstrap / Push

Doc ID: HDD-DOC-ARCHITECTURE-PLAN24-42API-DOMAIN-AUTH-BOOTSTRAP-PUSH-EN
Version: v1.0
Owner: Project Lead
Last Updated: 2026-03-04
Review Status: Draft
CN/EN Pair Link: docs/architecture/plan24_42api/DOMAIN_AUTH_BOOTSTRAP_PUSH.zh-TW.md

1. CN: `docs/architecture/plan24_42api/DOMAIN_AUTH_BOOTSTRAP_PUSH.zh-TW.md`
2. EN: `docs/architecture/plan24_42api/DOMAIN_AUTH_BOOTSTRAP_PUSH.en.md`

## 1. In-scope Methods
1. `GetLogin` -> `POST /v1/auth/login`
2. `UpdateRegID` -> `POST /v1/push/register`
3. `DeleteRegID` -> `POST /v1/push/unregister` (implemented in P9)
4. `GetBulletin` -> `GET /v1/bootstrap/bulletin`
5. `GET /v1/bootstrap/webview` (BFF-composed, not a single legacy method)

## 2. Current Status
1. implemented: `GetLogin`, `UpdateRegID`, `DeleteRegID`, `GetBulletin`.
2. deferred in this domain: none.
3. P4 hardening includes global error-response contract and health contract governance.
4. P9 adds push unregistration endpoint without changing logout business logic.

## 3. Contract Highlights
1. request `MaxLength` is enforced for login/refresh/logout.
2. response enforcement is active for login/bootstrap/bulletin.
3. error response contract is unified as `{ code, message }` with length protection.

## 4. Next Actions
1. Keep `POST /v1/push/unregister` as an independent endpoint from logout.
2. Preserve current logout behavior (no side-effect expansion).

