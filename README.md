<p align="center">
  <img src="docs/assets/readme-hero.png" alt="DSH Desktop — native macOS client for DeepSeek Harness" width="100%">
</p>

<p align="center">
  <strong>English</strong> · <a href="README.zh-CN.md">简体中文</a>
</p>

# DSH Desktop for macOS

DSH Desktop is a native macOS menu-bar client for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness). It starts the latest npm release of `@deepseek-ai/dsh`, waits for its loopback-only Web server, and displays the upstream UI in `WKWebView`. It does not bundle Electron or reimplement Harness.

## Current features

- Native AppKit menu-bar item and macOS window
- Persistent Dock icon while DSH Desktop is running
- Official upstream DeepSeek fish icon for the menu bar and app bundle
- Left click to show or hide DSH; right click for status and actions
- Start, stop, restart, update, open log, open data directory, and quit actions
- Latest-version startup through `npm exec` with npm-cache offline fallback
- Elapsed time and npm network activity while dependencies are prepared
- Last-known-good version tracking without a private DSH installation
- Random `127.0.0.1` Web port with readiness checks
- Graceful child-process shutdown followed by forced termination on timeout
- Same-origin `WKWebView` navigation; external links open in the default browser

## Plugin and user-data compatibility

DSH Desktop does not keep a private DSH installation. `@deepseek-ai/dsh` and `pnpm` use npm's normal cache:

```text
~/.npm
```

Harness state uses the same default `DSH_HOME` as the `dsh` command:

```text
~/.dsh
```

An explicitly inherited `DSH_HOME` overrides that default. Profiles, installed plugins, credentials, settings, presets, attachments, and sessions are therefore shared with direct `dsh` invocations and survive DSH Desktop or DSH upgrades. DSH Desktop asks `npm exec` to expose the upstream-compatible `pnpm` executable on `PATH`, because `dsh plugin --profile <name> ...` delegates plugin operations to `pnpm` inside `$DSH_HOME/profiles/<name>`.

Do not run a direct `dsh` service and the DSH Desktop-managed service concurrently against the same `DSH_HOME`.

## Development

Requirements:

- macOS 13 or later
- Xcode 15 or later
- Node.js 22.19.x or Node.js 24 or later, including npm

Run the tests and app:

```sh
swift test
swift run DSHDesktop
```

On every launch, DSH Desktop checks npm's `latest` tag. If the version is unchanged, it starts the last successfully launched exact version directly from npm's offline cache. A new version is prepared online through `npm exec`; if the local cache was cleared or damaged, the app automatically downloads that version again. The first launch therefore requires npm registry access.

## Build an app bundle

```sh
./scripts/package-app.sh
open "build/DSH Desktop.app"
```

Build and verify a drag-to-install disk image after packaging the app:

```sh
./scripts/package-dmg.sh
open "build/DSH Desktop.dmg"
```

For a self-contained distribution, provide a macOS Node.js runtime directory that contains `bin/node`, `bin/npm`, and npm's supporting files:

```sh
DSH_NODE_RUNTIME=/path/to/node-runtime ./scripts/package-app.sh
```

The development build is ad-hoc signed. Distribution builds should set `CODE_SIGN_IDENTITY`, enable hardened runtime in the release pipeline, and be notarized before publication.

## Releases

Pushing a semantic version tag runs the release workflow, tests and packages Apple Silicon and Intel builds, and publishes drag-to-install DMG images with SHA-256 checksums:

```sh
git tag v0.1.0
git push origin v0.1.0
```

Until the app is signed with a Developer ID certificate and notarized by Apple, users may need to remove the quarantine attribute after moving it to Applications:

```sh
sudo xattr -dr com.apple.quarantine "/Applications/DSH Desktop.app"
open "/Applications/DSH Desktop.app"
```

Only run this command for an app downloaded from this repository's official GitHub Releases.

Brand asset attribution is documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
