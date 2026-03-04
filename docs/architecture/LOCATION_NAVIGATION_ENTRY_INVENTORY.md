# Location / Navigation Entry Inventory

Doc ID: HDD-DOCS-ARCHITECTURE-LOCATION-NAVIGATION-ENTRY-INVENTORY
Version: v1.0
Owner: Architecture Lead
Last Updated: 2026-03-05
Review Status: Draft
CN/EN Pair Link: N/A






## Purpose

1. Inventory legacy location/navigation trigger points.
2. Define one fixed preflight entry for Flutter map/navigation flows.
3. Avoid scattered checks and inconsistent runtime behavior.

## Legacy App Inventory (Java)

### Route planning / navigation trigger points

1. `controls/TitleBar.java`
   1. Right button calls `main_activity.dtl.Start路徑規劃()`.
2. `didi/app/express/Detail.java`
   1. `Start路徑規劃()` and `Send路徑規劃()` use current location and route APIs.
3. `controls/Detail_ListView_Adapter.java`
   1. Per-row `Img定位` triggers external Google Maps intent.
4. Reservation list variants
   1. `controls/Reservation_ListView_Adapter.java`
   2. `controls/Reservation_BH_ListView_Adapter.java`
   3. `controls/Reservation_Cancel_ListView_Adapter.java`
   4. `controls/Reservation_BH_Cancel_ListView_Adapter.java`
5. Arrival / currency / deposit detail variants
   1. `controls/Arrived_ListView_Adapter.java`
   2. `controls/Currency_Detail_ListView_Adapter.java`
   3. `didi/app/express/Deposit_Detail.java`
6. Web bridge events
   1. `didi/app/express/AppWebView.java` `APPEvent(...)` map branches.
7. Map launch wrappers
   1. `controls/CheckData.java` `openMap...` and `openGoogleMap(...)`.

### Location usage points

1. `controls/LocationService.java`
2. `network/DataConvert.java` (`Get定位經緯度`)
3. `controls/shipmentEvent.java` (multiple upload/signature flows include geo data)
4. `mapgoogle/MapsActivity.java` (`setMyLocationEnabled(true)` + permission request)

## Flutter Fixed Entry

All Google Maps navigation paths should pass through:

1. `DefaultMapNavigationPreflightService.ensureReady()`
   1. Location service enabled check.
   2. Location permission check/request.
   3. Google Maps app availability check (`google.navigation` / `comgooglemaps`).
   4. Google account state check on Android (method channel).

## Flutter Integration Points

1. Bridge map event:
   1. `features/webview_shell/application/js_bridge_service.dart` `_handleMapEvent(...)`
2. Native map page:
   1. `features/maps/presentation/maps_page.dart` `_openMap()`

## Runtime Policy

1. If any preflight step fails, block map launch and return explicit message.
2. Keep all map preflight decisions in one service; avoid duplicate ad-hoc checks in UI pages.
3. If Android Google account state cannot be verified, treat as blocked and ask user to sign in first.

