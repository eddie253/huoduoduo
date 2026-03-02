# Wave 4 Native Capability + Parity Matrix

## Target

Close native capability gaps and reach end-to-end core parity on Android + iOS.

Status values:

1. `todo`
2. `in_progress`
3. `done`
4. `deferred`

## Bridge method parity

| Method | Android | iOS | Current state | Notes |
|---|---|---|---|---|
| `error()` | done | done | done | keep behavior consistent |
| `RefreshEnable()` | done | done | done | keep behavior consistent |
| `redirect()` | done | done | done | keep behavior consistent |
| `openfile()` | done | code_first | in_progress | HTTPS + allowlist external open |
| `open_IMG_Scanner()` | done | code_first | in_progress | scanner page wired via mobile_scanner |
| `openMsgExit()` | done | done | done | dialog flow available |
| `cfs_sign()` | done | code_first | in_progress | signature canvas + PNG export route |
| `APPEvent()` | done | code_first | in_progress | split event handlers implemented |

## APPEvent sub-event parity

| Event kind | Android | iOS | Status | Notes |
|---|---|---|---|---|
| map navigation | done | code_first | in_progress | external map URI handling wired |
| dial phone | done | code_first | in_progress | tel scheme dispatch wired |
| close page | done | code_first | in_progress | navigator pop behavior wired |
| contract/open external page | done | code_first | in_progress | HTTPS allowlist external open |

## Non-bridge native capabilities

| Capability | Android | iOS | Status | Notes |
|---|---|---|---|---|
| push register flow | done | done | in_progress | verify end-to-end with BFF |
| shipment proof upload | done | code_first | in_progress | delivery/exception upload from queue flow |
| local media index + upload queue (SQLite) | done | code_first | in_progress | retry + dead-letter + startup maintenance wired |
| webview session/cache policy | in_progress | in_progress | in_progress | keepAlive + route cache policy + no-store headers landed |
| location permission + map fallback | in_progress | code_first | in_progress | map external flow wired, permission UX pending on-device |

## Parity acceptance

1. Core flow pass rate >= 95% on Android + iOS real devices.
2. Each deferred item must have explicit risk, owner, and target wave.
3. No regression on Wave 2 smoke path.
4. Transaction routes must prove `no-store/no-cache` header behavior in evidence.

## PLAN14 Exclusion

1. `maphwo.MapsActivity` is explicitly `out_of_scope` and excluded from parity blocker criteria.
