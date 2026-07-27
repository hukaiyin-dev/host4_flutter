# Firmware Fixtures

Place local firmware `.bin` files in this directory for manual download testing.

The binary fixtures are intentionally ignored by Git. The Python test server
uses this directory as its default document root. Request logs are also local
manual-test evidence and should be written outside this directory, for example
under `/tmp`; do not commit `.bin` fixtures or request-log files.

## Start The Server

From `packages/host4_flutter_download`:

```sh
python3 tool/firmware_test_server.py \
  --host 127.0.0.1 \
  --port 18080 \
  --mode range \
  --chunk-size 4096 \
  --chunk-delay-ms 100 \
  --request-log /tmp/firmware-requests.csv
```

Switch `--mode no-range` to verify the client fallback path where a server
ignores `Range` and responds with `200 OK`.

Example local URLs after starting the server:

- `http://127.0.0.1:18080/OTA_GDF-G911405_3C03_V1.0_260716A.bin`
- `http://127.0.0.1:18080/OTA_GDF-G911405_62A2_V1.0_260713A.bin`

For a device on the same network, replace `127.0.0.1` with the development
machine LAN IP and keep the same fixture file name. For the Android emulator,
use `10.0.2.2` when the server runs on the host machine.

## Verify Range Behavior

```sh
curl -D - -o /tmp/range.bin \
  -H 'Range: bytes=1-3' \
  http://127.0.0.1:18080/OTA_GDF-G911405_3C03_V1.0_260716A.bin
```

Expected:

- `--mode range`: `206 Partial Content` with `Content-Range`.
- `--mode no-range`: `200 OK` with the full file length.

The request log is CSV with these fields:

- `method`
- `path`
- `range`
- `status`

Use a small `--chunk-size` and non-zero `--chunk-delay-ms` when testing cancel
or pause behavior from the Flutter playground.

## Manual Range Link

1. Start the server with `--mode range --chunk-size 4096 --chunk-delay-ms 100`
   and `--request-log /tmp/firmware-range.csv`.
2. Open the Flutter playground and enter a fixture URL.
3. Start the download, wait for progress to advance, then pause or cancel.
4. Resume the paused task, or start the same URL again after canceling.
5. Inspect `/tmp/firmware-range.csv`; the resumed request should include a
   `Range` value and `status` `206`.

This verifies the manual resumable path against a fixed local `.bin` fixture.

## Manual No-Range Link

1. Start the server with `--mode no-range --chunk-size 4096
   --chunk-delay-ms 100` and `--request-log /tmp/firmware-no-range.csv`.
2. Open the Flutter playground and enter the same fixture URL.
3. Start the download, cancel after progress advances, then start again.
4. Inspect `/tmp/firmware-no-range.csv`; the follow-up request may include a
   `Range` value, but the server returns `status` `200`.

The client treats this as the 200 fallback path: it deletes the partial file and
downloads the fixture from byte zero. This behavior does not require prior
backend confirmation.

## OI-R001-01 Probe

For a real backend or CDN firmware URL, confirm Range support with:

```sh
curl -I https://example.com/firmware.bin
curl -H 'Range: bytes=0-0' -I https://example.com/firmware.bin
```

Expected Range support evidence is `206 Partial Content`, `Content-Range`, and
optionally `Accept-Ranges: bytes`. This check documents server capability only;
the client still handles `200` or non-206 responses by removing the partial file
and downloading from the beginning.

## Platform Configuration Checks

Before using local HTTP fixture URLs from the example app, verify the Debug-only
platform exceptions from `packages/host4_flutter_download`:

```sh
rg -n "usesCleartextTraffic|networkSecurityConfig|INTERNET" \
  example/android/app/src/debug/AndroidManifest.xml
rg -n "cleartextTrafficPermitted" \
  example/android/app/src/debug/res/xml/network_security_config.xml
rg -n "usesCleartextTraffic|networkSecurityConfig" \
  example/android/app/src/main/AndroidManifest.xml
```

The first two Android commands should find the Debug cleartext configuration;
the main manifest command should find no Release cleartext policy.

```sh
rg -n "INFOPLIST_FILE = \"Runner/Info-Debug.plist\"" \
  example/ios/Runner.xcodeproj/project.pbxproj
rg -n "NSAppTransportSecurity|NSAllowsLocalNetworking" \
  example/ios/Runner/Info-Debug.plist
rg -n "NSAllowsArbitraryLoads|NSExceptionDomains|NSAppTransportSecurity" \
  example/ios/Runner/Info.plist example/ios/Runner.xcodeproj/project.pbxproj
```

The first two iOS commands should find the Debug local-networking setup; the
Release plist/project command should find no ATS cleartext exception.
