# CastBrowser-iOS

[![iOS CI](https://github.com/romanasa/CastBrowser-iOS/actions/workflows/ios.yml/badge.svg)](https://github.com/romanasa/CastBrowser-iOS/actions/workflows/ios.yml)

iOS web browser with Google Chromecast integration for casting video content to TV.

## Features

- **Web Browsing**: Full-featured web browser built with WKWebView
- **Chromecast Integration**: Cast HTML5 videos to any Chromecast device
- **Smart Video Detection**: Automatic detection of video content on web pages
- **Cast Device Discovery**: Real-time monitoring of available Cast devices
- **Custom URL Scheme**: Support for `castbrowser://` deep linking

## Requirements

- iOS 13.0+
- Xcode 12.0+
- CocoaPods

## Setup

1. Clone the repository:
```bash
git clone https://github.com/romanasa/CastBrowser-iOS.git
cd CastBrowser-iOS
```

2. Install dependencies:
```bash
pod install
```

3. Open the workspace (not the project file):
```bash
open CastBrowser-iOS.xcworkspace
```

## Building

### For Device
```bash
xcodebuild -workspace CastBrowser-iOS.xcworkspace -scheme CastBrowser-iOS -destination 'platform=iOS' build
```

### For Simulator
```bash
xcodebuild -workspace CastBrowser-iOS.xcworkspace -scheme CastBrowser-iOS -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Testing

```bash
# Run all tests
xcodebuild test -workspace CastBrowser-iOS.xcworkspace -scheme CastBrowser-iOS -destination 'platform=iOS Simulator,name=iPhone 16'

# Unit tests only
xcodebuild test -workspace CastBrowser-iOS.xcworkspace -scheme CastBrowser-iOS -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CastBrowser-iOSTests

# UI tests only
xcodebuild test -workspace CastBrowser-iOS.xcworkspace -scheme CastBrowser-iOS -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CastBrowser-iOSUITests
```

## Architecture

- **Pattern**: MVC with UIKit
- **UI**: Programmatic UI creation (no Storyboards)
- **Web Engine**: WKWebView for web content rendering
- **Cast SDK**: GoogleCastSDK-no-bluetooth for Chromecast integration

## Key Components

- **AppDelegate**: Cast SDK configuration and app lifecycle
- **SceneDelegate**: Scene-based UI setup
- **BrowserViewController**: Main browser interface with Cast integration

## Dependencies

- [GoogleCastSDK-no-bluetooth](https://developers.google.com/cast/docs/ios_sender) (~> 4.7): Chromecast integration
- WebKit: Web content rendering
- UIKit: Core UI framework

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request