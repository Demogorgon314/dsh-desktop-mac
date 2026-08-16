# DSH Launcher for macOS

DSH Launcher is a native macOS menu-bar client for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness). It starts the latest npm release of `@deepseek-ai/dsh`, waits for its loopback-only Web server, and displays the upstream UI in `WKWebView`. It does not bundle Electron or reimplement Harness.

## Current features

- Native AppKit menu-bar item and macOS window
- Left click to show or hide DSH; right click for status and actions
- Start, stop, restart, update, open log, open data directory, and quit actions
- Latest-version lookup through the npm registry with offline fallback
- Versioned, atomic DSH installation and rollback to the last working release
- Random `127.0.0.1` Web port with readiness checks
- Graceful child-process shutdown followed by forced termination on timeout
- Same-origin `WKWebView` navigation; external links open in the default browser

## Plugin and user-data compatibility

Launcher-managed DSH releases live below:

```text
~/Library/Application Support/DSH Launcher/runtime/versions/<version>
```

Harness state uses the same default `DSH_HOME` as the `dsh` command:

```text
~/.dsh
```

An explicitly inherited `DSH_HOME` overrides that default. Profiles, installed plugins, credentials, settings, presets, attachments, and sessions are therefore shared with direct `dsh` invocations and survive Launcher or DSH upgrades. Every managed DSH release also includes the upstream-compatible `pnpm` executable on `PATH`, because `dsh plugin --profile <name> ...` delegates plugin operations to `pnpm` inside `$DSH_HOME/profiles/<name>`.

Do not run a direct `dsh` service and the Launcher-managed service concurrently against the same `DSH_HOME`.

## Development

Requirements:

- macOS 13 or later
- Xcode 15 or later
- Node.js 22.19.x or Node.js 24 or later, including npm

Run the tests and app:

```sh
swift test
swift run DSHLauncher
```

On first launch, DSH Launcher downloads the current `@deepseek-ai/dsh` release and `pnpm` into Application Support. If the npm registry cannot be reached, it starts the last successfully used local release.

## Build an app bundle

```sh
./scripts/package-app.sh
open "build/DSH Launcher.app"
```

For a self-contained distribution, provide a macOS Node.js runtime directory that contains `bin/node`, `bin/npm`, and npm's supporting files:

```sh
DSH_NODE_RUNTIME=/path/to/node-runtime ./scripts/package-app.sh
```

The development build is ad-hoc signed. Distribution builds should set `CODE_SIGN_IDENTITY`, enable hardened runtime in the release pipeline, and be notarized before publication.
