# Local Media Storage Security Spec (Wave 4)

Doc ID: HDD-DOCS-ARCHITECTURE-LOCAL-MEDIA-STORAGE-SECURITY-SPEC
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A






## Purpose

Define how Flutter app stores shipment photo/signature data locally without repeating legacy risk.

## Decision

1. Use local SQLite only for media metadata and upload queue state.
2. Do not store secrets in SQLite.
3. Keep real credentials/tokens only in secure storage (`flutter_secure_storage`).

## Allowed in SQLite

1. `tracking_no`
2. `file_path`
3. `file_name`
4. `media_type` (`delivery_photo|exception_photo|signature`)
5. `status` (`pending|uploaded|failed`)
6. `retry_count`
7. `last_error_code`
8. `created_at`, `updated_at`

## Forbidden in SQLite

1. account/password
2. access token / refresh token
3. API secret, signing key, connection secret
4. plaintext personally sensitive payload not required for retry

## File storage rule

1. Media files must be stored in app private directory (`path_provider` app documents/support dir).
2. Do not use world-readable external public path as default.
3. Remove local file after successful upload and retention window check.

## Test data policy

1. Dev/UAT test fixtures are allowed in local SQLite only with non-production data.
2. Never commit local DB file, seed with runtime script.
3. Mask account identifiers in evidence docs.

## Threat controls

1. At-rest protection:
1. Minimum: OS sandbox + private app directory.
2. Recommended: encrypted SQLite (SQLCipher) for high-risk devices.
2. Integrity:
1. Verify file exists and hash before upload.
2. Reject path traversal (`..`, absolute override).
3. Abuse control:
1. Upload retry with capped backoff.
2. Dead-letter state after max retries.

## Implementation checklist (Wave 4)

1. Add local repository module (`media_local_repository`).
2. Add SQLite schema migration `v1_media_queue`.
3. Add queue worker for `pending/failed` upload retry.
4. Add cleanup job for uploaded artifacts.
5. Add tests:
1. schema migration
2. retry state transition
3. forbidden-field audit (no token/password persistence)

