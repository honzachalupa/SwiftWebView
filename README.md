# SwiftWebView

A lightweight, customizable WebView component for SwiftUI applications.

## Overview

SwiftWebView is a Swift Package that provides an easy-to-use WebView implementation for SwiftUI. It wraps WKWebView functionality in a SwiftUI-friendly way, with built-in navigation controls and customization options.

## Requirements

- iOS 17.0+
- watchOS 10.0+
- tvOS 17.0+
- visionOS 1.0+
- macOS 14.0+
- Swift 6.0+

## Installation

### Swift Package Manager

1. In Xcode, select File > Add Packages...
2. Enter the repository URL: `https://github.com/yourusername/SwiftWebView.git`
3. Select the version or branch you want to use
4. Click "Add Package"

## Usage

### Basic Implementation

```swift
import SwiftUI
import SwiftWebView

struct ContentView: View {
    @State private var urlString = "https://apple.com"

    var body: some View {
        SwiftWebView(
            urlString: $urlString,
            controls: .fixed
        )
    }
}
```

### Control Variants

SwiftWebView offers three control variants:

- `.fixed`: Shows controls at the top of the view
- `.floating`: Shows floating controls (useful for overlay UI)
- `.hidden`: Hides all controls

```swift
// With fixed controls
SwiftWebView(
    urlString: $urlString,
    controls: .fixed
)

// With hidden controls
SwiftWebView(
    urlString: $urlString,
    controls: .hidden
)
```

### Programmatic Navigation

You can programmatically navigate to URLs by changing the `urlString` binding:

```swift
struct ContentView: View {
    @State private var urlString = "https://apple.com"

    var body: some View {
        VStack {
            SwiftWebView(
                urlString: $urlString,
                controls: .fixed
            )

            Button("Go to Google") {
                urlString = "https://google.com"
            }
        }
    }
}
```

## License

This library is available under the MIT license. See the LICENSE file for more info.
