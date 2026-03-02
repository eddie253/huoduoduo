# Post Login Native UI Inventory (PLAN14)

## Scope
This inventory includes native UI surfaces reachable after successful login in the legacy Android app.

Out of scope in PLAN14:
1. `maphwo.MapsActivity`

## Discovery Sources
1. `app/src/main/java/controls/CheckData.java` (`LoginOK`, `openAWV`, native intents)
2. `app/src/main/java/didi/app/express/MainActivity.java` (toolbar routing, fragment swap)
3. `app/src/main/java/didi/app/express/Menu_GridView*.java` (post-login menu entry points)
4. `app/src/main/java/didi/app/express/AppWebView.java` (`window.android.*` bridge to native)
5. `app/src/main/AndroidManifest.xml` (activity declarations)

## Screen Inventory

| Screen ID | Legacy Type | Entry | Data Dependency | Risk |
|---|---|---|---|---|
| `NAT-HOME-TOOLBAR` | Fragment container (`MainActivity`) | `CheckData.LoginOK -> GoIndex/Create_Toolbar` | login state, user profile | high |
| `NAT-MENU-RESERVATION` | Fragment (`Menu_GridView_Reservation`) | toolbar click `Reservation` | session/cookie | medium |
| `NAT-MENU-SHIPMENT` | Fragment (`Menu_GridView`) | toolbar click `Shipment` | session/cookie, scanner permission | high |
| `NAT-MENU-ARRIVAL` | Fragment (`Menu_GridView_Arrival`) | toolbar click `Arrival` | session/cookie, camera/storage | high |
| `NAT-MENU-CURRENCY` | Fragment (`Menu_GridView_Currency`) | toolbar click `Currency/Settings` | session/cookie, role-based menu | medium |
| `NAT-WEBVIEW-SHELL` | Fragment (`AppWebView`) | menu item -> `CheckData.openAWV(...)` | cookies (`Account/Identify/Kind`) | high |
| `NAT-SCANNER` | Native scanner flow (`zbarscan` / `Img_scanner`) | menu actions or bridge `open_IMG_Scanner` | camera permission | high |
| `NAT-SIGNATURE` | Activity (`signature.main.SignatureActivity`) | bridge `cfs_sign` / delivery flows | storage/camera, local file output | high |
| `NAT-MAP-GOOGLE` | Activity (`mapgoogle.MapsActivity`) | shipment menu GPS / bridge map events | location permission, coordinates | medium |
| `NAT-MAP-EXTERNAL-URI` | External intent (`google maps URI`) | bridge `APPEvent(map)` -> `openGoogleMap` | map app availability | medium |
| `NAT-DIALER` | External intent (`ACTION_DIAL`) | bridge `APPEvent(dial)` | dial intent support | low |
| `NAT-OPEN-FILE` | External intent/browser | bridge `openfile` / `APPEvent(contract)` | URL allowlist + https | high |
| `NAT-UPLOAD-ERR-MSG` | Fragment (`UploadErrMsg`) | arrival menu upload error entry | local upload state | medium |
| `NAT-SETTING` | Fragment (`Setting`) | currency menu `Settings` | user settings/local prefs | medium |
| `NAT-LOGOUT-CONFIRM` | Dialog + exit flow | currency menu `Logout` -> `CheckData.logout` | local token/settings cleanup | high |

## Explicit Exclusion

| Legacy Surface | Status | Reason |
|---|---|---|
| `maphwo.MapsActivity` | `out_of_scope` | PLAN14 keeps one map engine (`mapgoogle`) plus external map URI only, to reduce parity and regression noise. |
