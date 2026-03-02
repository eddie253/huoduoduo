# PLAN14: Post-Login Native UI Inventory and Design-First Alignment (Exclude maphwo)

## Summary
1. PLAN14 focuses on post-login native UI inventory, Figma flow/screen mapping, and Legacy-to-Flutter parity tracking.
2. Map scope is fixed to `mapgoogle.MapsActivity + external map URI`.
3. `maphwo.MapsActivity` is excluded from implementation and acceptance in this wave.
4. High-risk tests are expanded for `auth`, `webview shell`, and `shipment queue`, with Flutter coverage gate raised to `>=50`.

## Scope
1. Deliver `POST_LOGIN_NATIVE_UI_INVENTORY` and `NATIVE_UI_PARITY_MAPPING`.
2. Update login/session checklist to Screen ID driven verification.
3. Raise Flutter coverage threshold from 40 to 50 in local scripts and CI.
4. Capture evidence and keep contracts unchanged.

## Figma Outputs
1. Flow Layer (FigJam):
[PLAN14 Post-Login Native UI Flow](https://www.figma.com/online-whiteboard/create-diagram/c8acc83a-7de0-425a-8ed1-77e9aab33b14?utm_source=other&utm_content=edit_in_figjam&oai_id=&request_id=e00a7907-fe5c-4f5e-8ff0-df2c0fc64031)
2. Screen Layer (FigJam):
[PLAN14 Native Screen Map](https://www.figma.com/online-whiteboard/create-diagram/ebde4d59-66f0-43a4-bbcc-3d45b89dea83?utm_source=other&utm_content=edit_in_figjam&oai_id=&request_id=044f893e-74b7-4540-bb63-0f38b477293d)
3. Both diagrams explicitly mark `maphwo.MapsActivity` as `out_of_scope`.

## Acceptance
1. Every reachable post-login native surface has a Screen ID.
2. All `maphwo.*` entries are `out_of_scope` in parity docs.
3. `flutter analyze`, `flutter test`, and `mobile coverage >= 50` all pass.
