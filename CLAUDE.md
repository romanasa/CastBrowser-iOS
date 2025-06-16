# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CastBrowser-iOS is an iOS web browser application with Google Chromecast integration. Built with UIKit and WKWebView, it allows users to browse the web and cast video content to Chromecast devices.

## Development Commands

### Setup
```bash
# Install CocoaPods dependencies
pod install

# Always open the workspace, not the project file
open CastBrowser-iOS.xcworkspace
```

### Building
```bash
# Build for iOS device
xcodebuild -workspace CastBrowser-iOS.xcworkspace -scheme CastBrowser-iOS -destination 'platform=iOS' build

# Build for simulator (use iPhone 16 as available simulator)
xcodebuild -workspace CastBrowser-iOS.xcworkspace -scheme CastBrowser-iOS -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Testing
```bash
# Run all tests on simulator
xcodebuild test -workspace CastBrowser-iOS.xcworkspace -scheme CastBrowser-iOS -destination 'platform=iOS Simulator,name=iPhone 16'

# Run unit tests only
xcodebuild test -workspace CastBrowser-iOS.xcworkspace -scheme CastBrowser-iOS -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CastBrowser-iOSTests

# Run UI tests only
xcodebuild test -workspace CastBrowser-iOS.xcworkspace -scheme CastBrowser-iOS -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CastBrowser-iOSUITests
```

## Architecture

**Pattern**: MVC with UIKit and programmatic UI creation

### Key Components
- **AppDelegate.swift**: Google Cast SDK configuration, custom URL scheme handling, volume button integration
- **SceneDelegate.swift**: Scene-based app lifecycle, programmatic root view controller setup
- **BrowserViewController.swift**: Main browser interface with WKWebView, Cast integration, and video detection
- **ViewController.swift**: Empty placeholder (legacy)

### Dependencies
- **GoogleCastSDK-no-bluetooth (~> 4.7)**: Chromecast integration without Bluetooth
- **WebKit**: Web content rendering with WKWebView
- **UIKit**: Core UI framework

### App Configuration
- **iOS 13.0+** minimum deployment target
- **Custom URL scheme**: `castbrowser://` for deep linking  
- **Network Security**: HTTP content allowed for web browsing
- **Orientation**: Portrait and landscape support

## Key Features

### Web Browsing
- Full-screen WKWebView with address bar navigation
- Automatic HTTPS prefixing for URLs
- Default YouTube homepage
- Media playback optimized configuration

### Chromecast Integration
- Automatic HTML5 video detection via JavaScript injection with comprehensive pattern matching
- Enhanced video detection for custom streaming services (iframe detection, URL patterns)
- Cast session management with proper delegate handling
- Cast button integration with automatic device discovery monitoring
- Real-time Cast device discovery status feedback to users
- Cast button visibility management with user-friendly error messages
- Media metadata handling for Cast devices
- Physical volume button control for Cast devices

### Testing
- **Unit Tests**: Comprehensive coverage including UI components, URL validation, JavaScript injection, and Cast integration
- **UI Tests**: End-to-end testing with Cast button functionality, orientation handling, and accessibility
- **Mock Objects**: Custom mocks for Cast SDK components

## Important Notes

- Always use the `.xcworkspace` file, not `.xcodeproj` when opening in Xcode
- Cast functionality requires physical iOS device for full testing (x86_64 simulator incompatibility)
- JavaScript video detection script is injected into web pages for Cast media discovery
- App handles custom URL scheme `castbrowser://` for deep linking integration
- For simulator testing on x86_64, GoogleCast code may need to be temporarily commented out due to Protobuf framework linking issues

## Recent Fixes & Enhancements

### Cast Button Creation Failure - RESOLVED (December 2025)
**Problem**: GCKUICastButton creation consistently failed on physical iPhone devices, returning nil despite proper Cast SDK initialization and device discovery working.

**Root Cause**: Missing iOS entitlements for multicast networking and iOS version compatibility issues with GoogleCast SDK 4.8.0 targeting iOS 18.5.

**Solution Implemented**:
1. **Required Entitlements Added**: 
   - `com.apple.developer.networking.multicast` for Cast device discovery
   - `com.apple.developer.networking.wifi-info` for network access
2. **Network Permissions**: Added `NSLocalNetworkUsageDescription` to Info.plist explaining Cast device discovery usage
3. **iOS Compatibility**: Lowered deployment target from iOS 18.5 to iOS 13.0 for better Cast SDK compatibility
4. **Custom Cast Button Fallback**: Implemented custom Cast button using `GCKCastContext.presentCastDialog()` when GCKUICastButton creation fails
5. **Manual Device Selection**: Added alert-based device picker as additional fallback mechanism
6. **Session State Management**: Custom Cast button updates appearance based on connection status (blue=disconnected, green=connected)

**Result**: Cast button functionality now works reliably on all device configurations with multiple fallback mechanisms ensuring users can always connect to Cast devices.

### Cast Button Visibility Issue (Fixed - June 2025)
**Problem**: Users only saw "Cast Video" button but not the GCKUICastButton for connecting to devices.

**Solution**: Added comprehensive Cast device discovery monitoring:
- Real-time discovery status feedback in navigation title
- User notifications when Cast devices are found/lost
- Enhanced error messages explaining Cast button behavior
- GCKDiscoveryManagerListener implementation for live device monitoring
- Debug logging for troubleshooting Cast connectivity issues

### Video Detection Enhancement (Fixed - June 2025)
**Problem**: Video detection failed for custom streaming services.

**Solution**: Enhanced JavaScript injection with:
- Pattern-based detection for custom streaming URLs (`/embed/`, `/player/`, `/content/`)
- Multiple fallback detection methods for various streaming platforms
- Comprehensive debugging output for troubleshooting video detection
- Support for both known platforms (YouTube, Vimeo) and custom services

### Key Files Modified
- `BrowserViewController.swift`: Enhanced Cast device discovery monitoring and video detection
- `CLAUDE.md`: Updated documentation with recent fixes and available simulator names