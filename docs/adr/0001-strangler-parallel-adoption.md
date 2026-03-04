# ADR-0001: Strangler Parallel Adoption for Flutter Migration

Doc ID: HDD-DOCS-ADR-0001-STRANGLER-PARALLEL-ADOPTION
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A






## Status

Accepted

## Context

The legacy Android app has high coupling across Activity/Fragment + WebView + SOAP calls.
Full rewrite in one release has high delivery risk.

## Decision

Adopt a strangler parallel migration:

1. Introduce Flutter client and BFF in parallel with legacy app.
2. Route new client traffic through BFF while SOAP backend remains unchanged.
3. Preserve legacy WebView behavior via bridge compatibility layer.
4. Migrate feature slices incrementally with ring-based rollout and rollback.

## Consequences

Positive:

1. Lower release risk and easier rollback.
2. Better observability and security controls introduced early.
3. Allows phased API modernization without backend freeze.

Tradeoffs:

1. Temporary dual-stack operation cost.
2. Need strict contract governance to prevent drift.
3. Requires parallel QA strategy until full migration completes.

