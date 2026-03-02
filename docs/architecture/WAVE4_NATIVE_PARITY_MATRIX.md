# Wave 4 Native Capability + Parity Matrix

## Target

Close native capability gaps and reach end-to-end core parity on Android + iOS.

Status values:

1. `todo`
2. `done`
3. `deferred`

## Bridge method parity

| Method | Android | iOS | Current state | Notes |
|---|---|---|---|---|
| `error()` | done | done | done | keep behavior consistent |
| `RefreshEnable()` | done | done | done | keep behavior consistent |
| `redirect()` | done | done | done | keep behavior consistent |
| `openfile()` | done | code_first | done | HTTPS + allowlist external open validated in bridge tests. |
| `open_IMG_Scanner()` | done | code_first | deferred | Owner: Mobile Native Feature Team, Wave 16, Risk: camera/device variance. |
| `openMsgExit()` | done | done | done | dialog flow available |
| `cfs_sign()` | done | code_first | deferred | Owner: Mobile Native Feature Team, Wave 16, Risk: signature UX and output parity on-device. |
| `APPEvent()` | done | code_first | done | map/dial/close/contract handlers implemented and tested. |

## APPEvent sub-event parity

| Event kind | Android | iOS | Status | Notes |
|---|---|---|---|---|
| map navigation | done | code_first | done | external map URI and coordinate conversion wired. |
| dial phone | done | code_first | done | tel scheme dispatch wired. |
| close page | done | code_first | done | navigator pop behavior wired. |
| contract/open external page | done | code_first | done | HTTPS allowlist external open wired. |

## Non-bridge native capabilities

| Capability | Android | iOS | Status | Notes |
|---|---|---|---|---|
| push register flow | done | done | deferred | Owner: BFF + Mobile Integration, Wave 16, Risk: end-to-end environment dependencies. |
| shipment proof upload | done | code_first | done | delivery/exception upload queue flow verified. |
| local media index + upload queue (SQLite) | done | code_first | done | retry + dead-letter + startup maintenance verified. |
| webview session/cache policy | done | deferred | deferred | Owner: Mobile WebView Team, Wave 16, Risk: iOS cache/session real-device evidence pending. |
| location permission + map fallback | deferred | code_first | deferred | Owner: Mobile Native Feature Team, Wave 16, Risk: permission UX parity on real devices. |

## Deferred Item Register (Required by Acceptance Rule #2)

| Item | Owner | Risk | Target Wave |
|---|---|---|---|
| Scanner native parity (`open_IMG_Scanner`, `NAT-SCANNER`) | Mobile Native Feature Team | camera behavior differs by device vendor/OS | Wave 16 |
| Signature parity (`cfs_sign`, `NAT-SIGNATURE`) | Mobile Native Feature Team | gesture/render/file export variance | Wave 16 |
| iOS webview cache/session parity evidence | Mobile WebView Team | iOS-specific storage/cache behavior | Wave 16 |
| location permission + map fallback | Mobile Native Feature Team | permission prompts and app-switch behavior | Wave 16 |
| push register end-to-end proof | BFF + Mobile Integration | environment/token lifecycle coupling | Wave 16 |

## Parity acceptance

1. Core flow pass rate >= 95% on Android + iOS real devices.
2. Each deferred item must have explicit risk, owner, and target wave.
3. No regression on Wave 2 smoke path.
4. Transaction routes must prove `no-store/no-cache` header behavior in evidence.

## PLAN14 Exclusion

1. `maphwo.MapsActivity` is explicitly `out_of_scope` and excluded from parity blocker criteria.
