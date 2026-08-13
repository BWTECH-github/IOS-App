# ownCloud Online iOS App — Setup Guide

## Overview

This repository contains the ownCloud iOS app, adapted for use with the **ownCloud Online** backend (`owncloud.online`) running PHP 8.4.

## Changes from Upstream

### Branding
- **Organization Name**: "ownCloud Online"
- **Default Server URL**: `https://owncloud.online` — pre-filled via the flat
  `branding.profile-url` key (the array-style `branding.profile-definitions`
  from older docs is NOT read by this app version); the URL stays editable
  (`branding.profile-allow-url-configuration`)
- **App display name**: "ownCloud Online" (hardcoded CFBundleDisplayName; the
  extensions derive theirs from APP_PRODUCT_NAME)
- **Bundle Identifier**: `online.owncloud.ios-app` (and `.ownCloud-*` extension ids)
- **Team**: BW-TECH GmbH (4545KLA52K), automatic signing (no manual profiles)
- **URL schemes**: `owncloud-online` (app/private links) and `oco` (auth) — no
  collision with the official ownCloud app
- **Branding Assets**: `online.owncloud.ios-app` branding theme (logo, icons,
  colors; `branding.theme-colors` drives the system light/dark themes). The
  Icon Composer `AppIcon.icon` is intentionally NOT bundled so the branded
  appiconset is used on iOS 26, too
- **Help / Privacy / Terms URLs**: `owncloud.online/faq/`, `/privacy-policy/`, `/terms/`

### Authentication
- **Basic Auth**: the only allowed method right now
  (`connection.allowed-authentication-methods = [com.owncloud.basicauth]`)
- **OAuth2 / OpenID Connect**: currently DISABLED — no client is registered on
  owncloud.online yet. To enable: register the iOS client on the server
  (redirect URI `oco://ios.owncloud.online`), then re-add
  `com.owncloud.oauth2` to the allowed methods and set
  `authentication-oauth2.oa2-client-id`/`-secret` in Branding.plist

### PHP 8.4 Compatibility
The ownCloud Online backend runs PHP 8.4 with the following key dependencies:
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
git clone https://github.com/GrossLukas/IOS-App.git
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
| Main App | `online.owncloud.ios-app` |
| File Provider | `online.owncloud.ios-app.ownCloud-File-Provider` |
| File Provider UI | `online.owncloud.ios-app.ownCloud-File-ProviderUI` |
| Share Extension | `online.owncloud.ios-app.ownCloud-Share-Extension` |
| Action Extension | `online.owncloud.ios-app.ownCloud-Action-Extension` |
| Intents | `online.owncloud.ios-app.ownCloud-Intents` |

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