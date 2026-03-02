# Scripts 使用說明

以下指令都在 **repo 根目錄** 執行。

## 1) 啟動本機 BFF（終端機 A）

```powershell
npm run bff:start:local
```

## 2) Flutter 全清重建 + 模擬器啟動（終端機 B）

```powershell
$root=(Get-Location).Path; $adb='C:\Users\EDDIE\AppData\Local\Android\Sdk\platform-tools\adb.exe'; $emu='C:\Users\EDDIE\AppData\Local\Android\Sdk\emulator\emulator.exe'; Get-Process -Name qemu-system-x86_64,emulator,adb -ErrorAction SilentlyContinue | Stop-Process -Force; Remove-Item -Recurse -Force "$root\apps\mobile_flutter\build","$root\apps\mobile_flutter\.dart_tool","$root\apps\mobile_flutter\android\.gradle","$root\apps\mobile_flutter\android\app\build" -ErrorAction SilentlyContinue; pushd "$root\apps\mobile_flutter"; flutter clean; flutter pub get; popd; Start-Process -FilePath $emu -ArgumentList '-avd didi_api34 -wipe-data -no-snapshot-load -netdelay none -netspeed full'; & $adb wait-for-device; do { Start-Sleep 2; $ok=(& $adb shell getprop sys.boot_completed).Trim() } while ($ok -ne '1'); & $adb uninstall com.example.mobile_flutter | Out-Null; pushd "$root\apps\mobile_flutter"; flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000/v1; popd
```

## 3) 可選：單終端背景啟動 BFF + App

```powershell
$root=(Get-Location).Path; $adb='C:\Users\EDDIE\AppData\Local\Android\Sdk\platform-tools\adb.exe'; $emu='C:\Users\EDDIE\AppData\Local\Android\Sdk\emulator\emulator.exe'; Start-Job -Name bff -ScriptBlock { param($p) Set-Location $p; npm run bff:start:local } -ArgumentList $root | Out-Null; Start-Sleep 3; Start-Process -FilePath $emu -ArgumentList '-avd didi_api34 -wipe-data -no-snapshot-load -netdelay none -netspeed full'; & $adb wait-for-device; do { Start-Sleep 2; $ok=(& $adb shell getprop sys.boot_completed).Trim() } while ($ok -ne '1'); pushd "$root\apps\mobile_flutter"; flutter clean; flutter pub get; flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000/v1; popd
```

結束後關閉背景 BFF：

```powershell
Get-Job bff | Stop-Job; Get-Job bff | Remove-Job
```

## 4) 登入整合測試（可選）

```powershell
cd apps/mobile_flutter
flutter test integration_test/login_to_webview_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000/v1 --dart-define=UAT_ACCOUNT=<你的帳號> --dart-define=UAT_PASSWORD=<你的密碼> --dart-define=UAT_LOGIN_TIMEOUT_SECONDS=90
```

## 5) Troubleshooting：模擬器右側黑條/多餘畫面

症狀通常是 AVD 設定異常（多螢幕旗標或 GPU 關閉），不是 Flutter 程式碼問題。

```powershell
$cfg=Join-Path $env:USERPROFILE '.android\avd\didi_api34.avd\config.ini'; (Get-Content $cfg) `
  -replace '^hw\.gpu\.enabled\s*=.*','hw.gpu.enabled = yes' `
  -replace '^hw\.display1\.flag\s*=.*','hw.display1.flag = 0' `
  -replace '^hw\.display1\.width\s*=.*','hw.display1.width = 0' `
  -replace '^hw\.display1\.height\s*=.*','hw.display1.height = 0' `
  -replace '^hw\.display1\.density\s*=.*','hw.display1.density = 0' `
  | Set-Content $cfg -Encoding UTF8; Get-Process -Name qemu-system-x86_64,emulator -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Process -FilePath 'C:\Users\EDDIE\AppData\Local\Android\Sdk\emulator\emulator.exe' -ArgumentList '-avd didi_api34 -wipe-data -no-snapshot-load -no-snapshot-save'
```
