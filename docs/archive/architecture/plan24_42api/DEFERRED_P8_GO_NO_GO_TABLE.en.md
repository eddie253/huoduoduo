# P8 Deferred APIs Go/No-Go Decision Table

Doc ID: HDD-DOC-ARCHITECTURE-PLAN24-42API-DEFERRED-P8-GO-NO-GO-TABLE-EN
Version: v1.0
Owner: Project Lead
Last Updated: 2026-03-05
Review Status: Archived
CN/EN Pair Link: docs/archive/architecture/plan24_42api/DEFERRED_P8_GO_NO_GO_TABLE.zh-TW.md







1. CN: `docs/architecture/plan24_42api/DEFERRED_P8_GO_NO_GO_TABLE.zh-TW.md`
2. EN: `docs/architecture/plan24_42api/DEFERRED_P8_GO_NO_GO_TABLE.en.md`

## 1. Scope
1. This document is the governance decision gate for the 12 `deferred` legacy methods.
2. P8 does not implement new endpoints; it only decides whether each deferred item can enter implementation.
3. Decision output must include owner, trigger, risks, estimate, and product-decision dependency.

## 2. Decision Status Legend
1. `No-Go`: cannot enter implementation phase yet; keep status as `deferred`.
2. `Conditional-Go`: can enter the next implementation phase only when all listed triggers are satisfied.

## 3. P8 Decision Table (12/12)
| # | Legacy Method | Domain | Current Decision | Owner | Trigger Conditions | Risk If Delayed | Estimated Effort | Product Decision Required | Target Milestone | Re-open / Start Condition |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `DeleteRegID` | Auth/Push | `Conditional-Go` | BFF Lead | Security confirms logout un-register policy; mobile confirms token lifecycle | Push token orphaning on logout edge cases | 2-3 eng days | No | `P9` | Start after security checklist and API contract review are both approved |
| 2 | `AddOrder_elf` | Shipment | `No-Go` | Product Lead + BFF Lead | Accept-order business flow/state machine approved | Wrong order state transitions if rushed | 4-6 eng days | Yes | `P9+` | Re-open only with signed product flow and error-code matrix |
| 3 | `BackOrder` | Shipment | `No-Go` | Product Lead + BFF Lead | Back-order cancellation policy approved | Inconsistent rollback and dispute handling | 4-6 eng days | Yes | `P9+` | Re-open only with signed rollback rules and audit requirements |
| 4 | `UpdateArrivalErr_Multi_NEW` | Arrival | `No-Go` | Product Lead + BFF Lead | Batch upload UX/retry/partial-failure policy approved | Data inconsistency from undefined batch semantics | 5-8 eng days | Yes | `P9+` | Re-open after batch contract and UX spec are signed |
| 5 | `ClearArrival` | Arrival | `No-Go` | Product Lead | Legacy clear-arrival behavior confirmed still required | Accidental data clearing if behavior is misunderstood | 3-4 eng days | Yes | `P9+` | Re-open after product confirms business value and guardrails |
| 6 | `UpdateArrival_Multi` | Arrival | `No-Go` | Product Lead + BFF Lead | Batch delivery requirements approved with failure policy | Delivery proof mismatch across batch records | 5-8 eng days | Yes | `P9+` | Re-open after batch delivery data rules are finalized |
| 7 | `Alr_Order` | Shipment List | `No-Go` | Mobile Lead | Native list vs WebView ownership decision made | Duplicate list surfaces and user confusion | 3-5 eng days | Yes | `P9+` | Re-open after UI ownership decision and parity test scope are locked |
| 8 | `Alr_Shipment` | Shipment List | `No-Go` | Mobile Lead | Delivered-list UX ownership and filtering rules approved | Regression risk on delivered list behavior | 3-5 eng days | Yes | `P9+` | Re-open after usage analytics and UX decision are confirmed |
| 9 | `CreatePath` | Map/Route | `No-Go` | Product Lead | Map roadmap is approved and map dependency budget is accepted | Scope expansion into map domain without readiness | 6-10 eng days | Yes | `P10+` | Re-open only when map capability is moved in-scope by product |
| 10 | `CheckedArrivalErr` | Arrival | `No-Go` | BFF Lead | Pre-check validation data rules approved by QA and Product | False positives/negatives in pre-check behavior | 2-4 eng days | Yes | `P9+` | Re-open after validation matrix and expected error outcomes are signed |
| 11 | `GetSystemDate` | System | `No-Go` | BFF Lead | Hard dependency on endpoint time source is proven | Redundant API surface if server time header is sufficient | 1-2 eng days | No | `P9-review` | Re-open only if integration cannot rely on existing server time headers |
| 12 | `GetVersion` | System | `Conditional-Go` | Mobile Lead + BFF Lead | Version-gate policy (soft/hard update) is approved | Inconsistent force-update behavior across clients | 2-3 eng days | Yes | `P9` | Start after release policy and app-store rollout strategy are signed |

## 4. P8 Outcome Summary
1. `No-Go`: 10 methods.
2. `Conditional-Go`: 2 methods (`DeleteRegID`, `GetVersion`).
3. 12/12 deferred methods now have explicit owner, trigger, risk, estimate, and target milestone.
4. No deferred method is auto-promoted to `implemented` in P8.

## 5. Governance Rules for Next Step
1. Any deferred item can enter implementation only after this table's trigger conditions are fully met.
2. For `Conditional-Go` items, start implementation in `P9` only after owner sign-off.
3. If conditions are not met, keep status as `deferred` and review in the next governance checkpoint.

## 6. Follow-up Status (P9)
1. `DeleteRegID` is implemented in P9 as `POST /v1/push/unregister`.
2. `GetVersion` is implemented in P9 as `GET /v1/system/version?name=...`.
3. Remaining deferred methods continue under `No-Go` governance until triggers are met.

## Governance Waiver

- Reason: historical document retained for traceability under archive_waiver policy.
- Owner: Architecture Lead
- Original Date: N/A
- Retention: long-term archive retention.
- Reactivation Trigger: audit or historical trace request.

