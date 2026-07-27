# host4_flutter_download

`host4_flutter_download` provides a small Host4-owned firmware download API for
HTTP and HTTPS URLs. It stores managed files in the app's private Application
Support directory and returns absolute local file information after a successful
download. The package only downloads files; existing firmware upgrade code should
consume the returned file information through its own upgrade interface.

## Runtime Usage

Use the package entrypoint only:

```dart
import 'package:host4_flutter_download/host4_flutter_download.dart';

final download = Host4Download();
final task = await download.download(Uri.parse(firmwareUrl));

task.pause();
task.resume();
task.cancel();

final Host4DownloadedFile file = await task.result;
print(file.localPath); // Absolute private local file path.
print(file.fileName);
print(file.size);
```

`Host4DownloadTask` is a `Listenable`. Add a listener when UI or business code
needs live status and progress updates:

```dart
void onChanged() {
  print(task.status);
  print(task.progress); // 0.0 to 1.0
}

task.addListener(onChanged);
try {
  final file = await task.result;
  print(file.localPath);
} finally {
  task.removeListener(onChanged);
}
```

`Host4Download.download(Uri)` accepts HTTP and HTTPS URLs and is shorthand for
`downloadRequest(Host4DownloadRequest(url: url))`. Use
`downloadRequest(...)` when the backend also provides integrity metadata:

```dart
final task = await download.downloadRequest(
  Host4DownloadRequest(
    url: Uri.parse(firmwareUrl),
    expectedSize: 123456,
    expectedSha256: backendSha256,
    forceRefresh: false,
  ),
);
```

The default `Host4Download()` allows two concurrent downloads. Different URLs
create independent tasks, and a second request for the same active URL returns
the existing active task instead of creating a duplicate task item.

Task controls are state-bound:

- `pause()` is valid only while `Host4DownloadStatus.downloading`.
- `resume()` is valid only while `Host4DownloadStatus.paused`.
- `cancel()` is valid while the task is queued, downloading, or paused.
- Invalid controls throw `StateError` and do not change files.

On success, `task.result` completes with `Host4DownloadedFile`, containing:

- `localPath`: absolute path to the downloaded file in private app storage.
- `fileName`: the managed file name.
- `size`: downloaded file size in bytes.
- `expectedSha256`: the backend-provided expected hash, if any.
- `observedSha256`: the hash calculated from the downloaded file.
- `verified`: true when no expected hash was provided or when the hashes match.

After success, pass this absolute local file information to the existing firmware
update flow. This package does not define firmware transport, device connection,
or update sequencing behavior.

## Task And File Management

Use the task key returned by `Host4DownloadTask.taskKey` as the stable local
identifier. The package manages files under a private `host4/downloads` tree and
does not accept a business-supplied save directory.

`cancel()` only stops the selected active task. It marks the task canceled and
keeps the partial file when one exists so a later request can probe Range support.
It does not delete the task directory.

`clear(taskKey)` deletes one terminal task's complete file, partial file,
manifest, and index entry. It rejects queued, downloading, and paused tasks with
`StateError`.

`clearCompleted()` removes all terminal tasks and keeps active tasks.

If business code needs to clear by URL, list records first and clear by task key:

```dart
final records = await download.list();
for (final record in records.where((item) => item.url == firmwareUri)) {
  if (!record.status.isActive) {
    await download.clear(record.taskKey);
  }
}
```

`enforceStorageLimit()` applies the module capacity policy:

```dart
final cleanup = await download.enforceStorageLimit();
```

The default limit is `1024 * 1024 * 1024` bytes. Only files inside the managed
`host4/downloads` directory are counted. When the directory exceeds the limit,
terminal tasks are deleted from oldest to newest by `completedAt`, falling back
to `updatedAt` when `completedAt` is missing. Queued, downloading, paused tasks
and paused partial files are never deleted by capacity cleanup. If no terminal
candidate can be deleted, the method returns `Host4DownloadCleanupResult` with
`deletedCount == 0` so callers can explain why storage remains above the limit.

## Integrity Semantics

When `expectedSha256` is provided, the package compares it with the downloaded
file's `observedSha256`. A mismatch fails the task and does not return a usable
`Host4DownloadedFile`. When the backend does not provide `expectedSha256`, the
package still calculates `observedSha256` from the file and returns it for
logging or later business verification; in that case `verified` is true because
there is no expected hash to compare against.

## Manual Test Server

Place local `.bin` fixtures under:

```text
packages/host4_flutter_download/tool/firmware-fixtures/
```

Those `.bin` files are local-only fixtures and must not be committed. Start the
test server from `packages/host4_flutter_download`:

```sh
python3 tool/firmware_test_server.py \
  --host 0.0.0.0 \
  --port 18080 \
  --mode range \
  --chunk-size 4096 \
  --chunk-delay-ms 100 \
  --request-log /tmp/firmware-requests.csv
```

Use `--chunk-size` and `--chunk-delay-ms` to slow transfer enough for
pause/resume/cancel checks. Use `--request-log` to capture method, path, Range
request header, and response status evidence.

For a simulator or device, use a reachable URL:

- Android emulator to host: `http://10.0.2.2:18080/<fixture>.bin`
- iOS simulator to host: `http://127.0.0.1:18080/<fixture>.bin`
- Physical device: `http://<dev-machine-lan-ip>:18080/<fixture>.bin`

## Range And Fallback Checks

Use `range` mode to verify resumable download evidence:

```sh
python3 tool/firmware_test_server.py \
  --host 0.0.0.0 \
  --port 18080 \
  --mode range \
  --chunk-size 4096 \
  --chunk-delay-ms 100 \
  --request-log /tmp/firmware-range.csv
```

In the example playground, enter the fixture URL, start the download, pause or
cancel after progress advances, then resume or start again. The request log
should include a later request with a `Range` header and `206` status.

Use `no-range` mode to verify the fallback path:

```sh
python3 tool/firmware_test_server.py \
  --host 0.0.0.0 \
  --port 18080 \
  --mode no-range \
  --chunk-size 4096 \
  --chunk-delay-ms 100 \
  --request-log /tmp/firmware-no-range.csv
```

Start, cancel or interrupt after a partial file exists, then start again. The
server ignores `Range` and returns `200`; the client deletes the partial file and
downloads from byte zero.

## OI-R001-01 Backend Confirmation

For a real firmware URL, backend/CDN Range support can be confirmed with either:

```sh
curl -I https://example.com/firmware.bin
curl -H 'Range: bytes=0-0' -I https://example.com/firmware.bin
```

Confirm whether the response includes `206 Partial Content`, `Content-Range`,
and optionally `Accept-Ranges: bytes`.

This confirmation is operational evidence only. The client does not depend on a
manual OI-R001-01 check before running. At runtime, only a `206` Range probe
continues from a partial file; `200`, non-206 responses, and probe errors delete
the partial file and fall back to a fresh download from byte zero.

## Android Debug Configuration Check

For local HTTP fixture URLs, verify the example app uses the Debug variant:

```sh
rg -n "usesCleartextTraffic|networkSecurityConfig|INTERNET" \
  example/android/app/src/debug/AndroidManifest.xml
rg -n "cleartextTrafficPermitted" \
  example/android/app/src/debug/res/xml/network_security_config.xml
rg -n "usesCleartextTraffic|networkSecurityConfig" \
  example/android/app/src/main/AndroidManifest.xml
```

Expected Debug configuration:

- `android.permission.INTERNET` is present.
- `android:usesCleartextTraffic="true"` is present.
- `android:networkSecurityConfig="@xml/network_security_config"` is present.
- `cleartextTrafficPermitted="true"` is present in the Debug network security
  config.
- The main manifest command returns no matches; Release must not inherit the
  Debug cleartext policy.

Production host URLs should remain HTTPS.

## Dependency Upgrade Regression

Download-module dependencies are intentionally pinned in `pubspec.yaml`, for
example `flutter_download_manager: 0.5.5`, `dio: 5.10.0`, `crypto: 3.0.7`,
`path: 1.9.1`, and `path_provider: 2.1.6`. Upgrading any of these dependencies
must be called out to QA and covered with at least:

- `cd packages/host4_flutter_download && flutter analyze`
- `cd packages/host4_flutter_download && flutter test`
- `cd packages/host4_flutter_download/example && flutter test test/download_playground_page_test.dart test/download_playground_golden_test.dart`
- Python range-mode integration with request log evidence showing a Range request
  and `206`.
- Python no-range integration with request log evidence showing a Range request
  answered with `200` and a subsequent fresh `200` request.
- sha256 success and mismatch unit coverage.
- playground regression for multi-task controls and stable identifiers.

Record the previous version, new version, reason for upgrade, and actual
regression results in the requirement evidence before merging.

## iOS Debug Configuration Check

For local HTTP fixture URLs, verify the Debug build uses `Info-Debug.plist` and
allows local networking:

```sh
rg -n "INFOPLIST_FILE = \"Runner/Info-Debug.plist\"" \
  example/ios/Runner.xcodeproj/project.pbxproj
rg -n "NSAppTransportSecurity|NSAllowsLocalNetworking" \
  example/ios/Runner/Info-Debug.plist
rg -n "NSAllowsArbitraryLoads|NSExceptionDomains|NSAppTransportSecurity" \
  example/ios/Runner/Info.plist example/ios/Runner.xcodeproj/project.pbxproj
```

Expected Debug configuration:

- Debug `INFOPLIST_FILE` points to `Runner/Info-Debug.plist`.
- `NSAppTransportSecurity` includes `NSAllowsLocalNetworking`.
- The Release plist and project command should not find
  `NSAllowsArbitraryLoads`, `NSExceptionDomains`, or another Release ATS
  cleartext exception.

Production host URLs should remain HTTPS.
