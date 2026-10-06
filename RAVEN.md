# Raven's Tinycast fork

Personal build of [abue-ammar/tinycast](https://github.com/abue-ammar/tinycast): upstream's latest
**stable** release plus a few patches upstream declined. The installed app updates itself from this
fork's releases.

## Branches

- **`raven`** — the default branch. Upstream release tag + the patches below, nothing else.
- `main` — untouched mirror slot; not used.

## Patches on `raven`

| Patch | Why it isn't upstream |
| --- | --- |
| **Set Shortcut…** in the ⌘K Actions menu — records the hotkey inline in the palette, Raycast-style (`ShortcutRecorderScreen`) | Declined in upstream #981 ("not planned") |
| `ReleaseFeed.feedRepository` → `ravenintheforrest/tinycast` (update checks only; release-note links still point upstream) | Fork-only plumbing |
| `.github/workflows/raven-sync.yml` + this file | Fork-only plumbing |

Keep patches small and few: every line here is a future merge conflict.

## How updates flow

1. `raven-sync.yml` runs daily (11:17 UTC) on a GitHub macOS runner, and on demand from the Actions tab.
2. If upstream published a stable release this fork hasn't, it merges that tag into a throwaway copy of
   `raven`, runs `./Scripts/run-tests.sh`, builds Release (arm64, bundle id `com.tinycast.app`),
   signs with this fork's own `Tinycast Self-Signed` identity, and publishes `Tinycast-<version>.zip`
   as a release here, tagged with upstream's version.
3. The app's built-in updater sees the release and offers it. It trusts it because it is signed with
   the same certificate as the running copy.
4. **Conflict?** The job opens an issue here instead of publishing (GitHub emails you). Resolve locally:
   `git fetch upstream --tags && git switch raven && git merge vX.Y.Z`, fix, run tests, push `raven`,
   re-run the workflow.

The merge is never pushed by CI (`GITHUB_TOKEN` can't push upstream's workflow edits), so `raven`
only moves when you push it.

## Signing

Same scheme as upstream (`docs/signing.md`), different key: the `Tinycast Self-Signed` identity in
this Mac's login keychain, exported to the fork secrets `SIGNING_P12_BASE64` / `SIGNING_P12_PASSWORD`.
**Keep that identity.** Losing it means a one-time manual reinstall and re-granting Accessibility.
Created 2026-10-04 with docs/signing.md §1, plus `-legacy` on `openssl pkcs12 -export` (OpenSSL 3's
default encryption is unreadable by `security import`); secrets set straight from that `.p12`.
`find-identity` showing `CSSMERR_TP_NOT_TRUSTED` is expected for a self-signed identity.

## Building locally

```sh
xcodebuild -project Tinycast.xcodeproj -scheme Tinycast -configuration Release \
  -derivedDataPath /tmp/tc-build ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Tinycast Self-Signed" OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
  PRODUCT_NAME=Tinycast PRODUCT_BUNDLE_IDENTIFIER=com.tinycast.app MARKETING_VERSION=<upstream version> build
```

A patch-only change keeps upstream's version number, so the updater won't offer it. Install that
build by hand, or wait for the next upstream release.
