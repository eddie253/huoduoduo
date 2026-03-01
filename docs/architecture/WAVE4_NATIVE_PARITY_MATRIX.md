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
| `openfile()` | todo | todo | deferred | implement file picker/download flow |
| `open_IMG_Scanner()` | todo | todo | deferred | scanner plugin integration |
| `openMsgExit()` | done | done | done | dialog flow available |
| `cfs_sign()` | todo | todo | deferred | signature UX and upload path |
| `APPEvent()` | todo | todo | deferred | split per event kind below |

## APPEvent sub-event parity

| Event kind | Android | iOS | Status | Notes |
|---|---|---|---|---|
| map navigation | todo | todo | todo | external map/open native map |
| dial phone | todo | todo | todo | tel scheme/permission flow |
| close page | todo | todo | todo | router pop/back behavior |
| contract/open external page | todo | todo | todo | deep link / web redirect |

## Non-bridge native capabilities

| Capability | Android | iOS | Status | Notes |
|---|---|---|---|---|
| push register flow | done | done | in_progress | verify end-to-end with BFF |
| shipment proof upload | todo | todo | todo | delivery/exception payload parity |
| local media index + upload queue (SQLite) | in_progress | in_progress | in_progress | repository + orchestrator foundation landed, retry worker remains |
| webview session/cache policy | in_progress | in_progress | in_progress | keepAlive + route cache policy + no-store headers landed |
| location permission + map fallback | todo | todo | todo | align permission UX |

## Parity acceptance

1. Core flow pass rate >= 95% on Android + iOS real devices.
2. Each deferred item must have explicit risk, owner, and target wave.
3. No regression on Wave 2 smoke path.
4. Transaction routes must prove `no-store/no-cache` header behavior in evidence.
