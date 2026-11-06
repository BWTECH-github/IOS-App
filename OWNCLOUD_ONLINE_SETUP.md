# owncloud.online iOS App — Setup Guide

## Overview

This repository contains the ownCloud iOS app, adapted by BW-TECH GmbH as its own app **owncloud.online** for the
owncloud.online backend running PHP 8.4. It is not related to the
"ownCloud Online" app of ownCloud GmbH (bundle id `online.owncloud.ios-app`) and
can be installed side by side with it (own bundle ids, app group, keychain
group, URL schemes).

Visible texts never say "ownCloud"; the brand is written `owncloud.online`.
The GPL copyright notices of the original authors stay in the license /
acknowledgements area, source headers and internal identifiers (classes,
modules, file names) are unchanged.

## Changes from Upstream

### Branding
- **Organization Name**: "owncloud.online"
- **Server URL**: no pre-filled address (every customer has their own server);
  `branding.profile-url` is intentionally absent, the field shows the neutral
  placeholder `https://cloud.example.com` and stays editable
  (`branding.profile-allow-url-configuration`)
- **No account creation / trial offer**: `branding.profile-help-url`,
  `-help-button-label` and `-open-help-message` are intentionally absent
  (App Review 3.1.3(f), 5.1.1(v)); accounts exist only through a BW-TECH
  subscription and are deleted by cancelling it
- **App display name**: "owncloud.online" (CFBundleDisplayName/CFBundleName in
  the app Info.plist; the extensions derive theirs from the project build
  setting `APP_PRODUCT_NAME = owncloud.online`, Share/Action extension names
  are localized in their `InfoPlist.xcstrings`)
- **Bundle Identifier**: `owncloud.online.bw.tech` (extensions:
  `owncloud.online.bw.tech.<Suffix>`, see table below)
- **App Group**: `group.owncloud.online.bw.tech` (`OCAppGroupIdentifier`,
  `NSExtensionFileProviderDocumentGroup`, entitlements of all targets)
- **Keychain Access Group**: `$(AppIdentifierPrefix)group.owncloud.online.bw.tech`
  (`OCKeychainAccessGroupIdentifier = group.owncloud.online.bw.tech`)
- **Team**: BW-TECH GmbH (A7VZ8HFNR4), automatic signing (no manual profiles)
- **URL schemes**: `owncloud-online-bwtech` (app/private links) and
  `owncloud-online-bwtech-auth` (auth) — no collision with the apps of
  ownCloud GmbH (`owncloud`, `oc`, `owncloud-online`)
- **SDK texts**: SDK strings that name the original product are overridden
  via `locale.overrides` in Branding.plist
- **Branding Assets**: theme folder `Theming/online.owncloud.ios-app` (folder
  name kept, internal), generated from
  the official owncloud.online logo SVGs. All logo PNGs carry built-in
  transparent padding; `branding-logo-sidebar.png` (2:1) and
  `branding-logo-setup.png` are picked up automatically via the asset-suffix
  mechanism so the "ONLINE" wordmark is never clipped in the sidebar banner.
  The Icon Composer `AppIcon.icon` IS bundled (white cloud on brand navy) for
  the native iOS 26 glass icon; older iOS versions use the branded appiconset
- **Colors** (official owncloud.online web palette):
  - Tint: `#00866F` (dark mint — readable links/accents on white, AA)
  - CTA buttons: mint `#00E4BD` fill with navy `#262B45` text via
    `branding.theme-css-records` (matches the website's button style)
  - Backgrounds: slate `#547A9E` → navy `#262B45` gradient
  - Folder icons: mint `#00E4BD` via the `icon-folder.fill` CSS record (the
    TVG icons read `tvgIcon.[icon].[variable].fill`, NOT the legacy
    `folder-icon-color` key)
- **Help / Privacy / Terms URLs**: `owncloud.online/faq/`, `/privacy-policy/`, `/terms/`

### Authentication
- **Allowed methods** (`connection.allowed-authentication-methods`): OpenID Connect,
  OAuth2 and Basic Auth, as in the original app. The server decides: if it answers
  with `WWW-Authenticate: Bearer`, the app opens the login page of the server
  (needed for Azure and other single sign-on), otherwise it asks for user name and
  password.
- **OAuth2 client**: the app uses the SDK defaults, client "iOS" with the redirect URI
  `oc://ios.owncloud.com`. Do not set `authentication-oauth2.*` in Branding.plist: a
  different client or redirect URI would have to be registered on every server first.
- **Managed devices**: the MDM browser session classes `MIBrowser`, `AWBrowser` and
  `CustomScheme` are not supported. They return through the URL scheme `oc`, which this
  app does not register because it belongs to the original app.
- **Check a server** without an account: `POST /index.php/apps/oauth2/api/v1/token` with the
  client id and secret as HTTP Basic and `grant_type=authorization_code&code=x`.
  `invalid_grant` means the client is registered, `invalid_client` means it is missing
  and the login page would fail. Checked 2026-11-06: testoo.bw.tech, oc.bw.tech and
  antgueupho850.owncloud.online have it.

### PHP 8.4 Compatibility
The owncloud.online backend runs PHP 8.4 with the following key dependencies:
- Symfony 7.4
- sabre/dav 4.4
- firebase/php-jwt 6.8+

**No iOS app changes were required for PHP 8.4 compatibility** because:
1. All API endpoints remain standard OCS/WebDAV
2. JSON response formats are unchanged
3. The iOS SDK uses `NSJSONSerialization` which handles all valid JSON
4. WebDAV protocol behavior is unchanged with sabre/dav 4.4

### API Endpoints (Verified Compatible)
| Endpoint | Path | Status |
|---|---|---|
| Status | `/status.php` | ✅ Standard |
| Capabilities | `/ocs/v2.php/cloud/capabilities` | ✅ Standard |
| WebDAV | `/remote.php/dav/files/{user}` | ✅ Standard |
| WebDAV (legacy) | `/remote.php/webdav` | ✅ Standard |
| Sharing API | `/ocs/v2.php/apps/files_sharing/api/v1/shares` | ✅ Standard |
| User Info | `/ocs/v2.php/cloud/user` | ✅ Standard |

## Building

### Prerequisites
- Xcode (see `.xcode-version` for required version)
- Apple Developer Account with appropriate certificates
- Git with submodule support

### Steps
```bash
# 1. Clone repository
git clone https://github.com/BWTECH-github/IOS-App.git
cd IOS-App

# 2. Initialize submodules
git submodule update --init --recursive

# 3. Open in Xcode
open ownCloud.xcodeproj

# 4. Configure signing
#    - Set your Apple Developer Team
#    - Set appropriate Provisioning Profiles for all targets

# 5. Build and run
```

### Bundle Identifiers
| Target | Bundle ID |
|---|---|
| Main App | `owncloud.online.bw.tech` |
| File Provider | `owncloud.online.bw.tech.FileProvider` |
| File Provider UI | `owncloud.online.bw.tech.FileProviderUI` |
| Share Extension | `owncloud.online.bw.tech.ShareExtension` |
| Action Extension | `owncloud.online.bw.tech.ActionExtension` |
| Intents | `owncloud.online.bw.tech.Intents` |

App group: `group.owncloud.online.bw.tech` (all targets).

## Updating from Upstream

To pull new changes from the official ownCloud iOS app:

```bash
git remote add upstream https://github.com/owncloud/ios-app.git
git fetch upstream
git merge upstream/master
git submodule update --init --recursive
```

> **Note**: After merging upstream changes, verify that the branding configuration
> and bundle identifiers haven't been overwritten.

### Workflows after an upstream merge

An upstream merge brings back the workflow files of `owncloud/ios-app`. Those are
written for the upstream repository, whose default branch is `master` and which
owns the Transifex project and the deployment secrets. In this fork they either
never run or fail — the nightly "Pull translations from Transifex" already failed
this way every night once before.

So check `.github/workflows/` after every upstream merge:

| Workflow | Expected in this fork |
|---|---|
| `build-and-analyze.yml` | runs on `push`/`pull_request` for **`main`** — the only automatic workflow |
| `pull-transifex.yml` | `workflow_dispatch` only, no `schedule`; `ref`/`base` = `main` |
| `push-transifex.yml` | `workflow_dispatch` only, no `push` trigger |
| `calens.yml`, `generate-sbom.yml` | `workflow_dispatch` only; `ref`/`base` = `main` |
| `configuration-documentation.yml`, `pull-ocis-icons.yml` | `workflow_dispatch` only (need the upstream `DEPLOYMENT_SSH_KEY`) |

A quick check: `grep -rn "master" .github/workflows/` should not report any
`ref:`, `base:` or `branches:` entry.