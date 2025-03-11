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
2. Enter the repository URL: `https://github.com/honzachalupa/SwiftWebView.git`
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
            urlString: $urlString
        )
    }
}
```

### Control Variants

SwiftWebView offers three control variants:

- `.fixed`: Shows controls fixed at the top of the view
- `.closable`: Shows controls that can be collapsed/expanded with a button
- `.hidden`: Hides all controls (default)

```swift
// With fixed controls
SwiftWebView(
    urlString: $urlString,
    controls: .fixed
)

// With closable controls
SwiftWebView(
    urlString: $urlString,
    controls: .closable
)

// With hidden controls (default)
SwiftWebView(
    urlString: $urlString,
    controls: .hidden
)
```

### Custom Submit Button Label

You can customize the label of the submit button in the controls:

```swift
SwiftWebView(
    urlString: $urlString,
    controls: .fixed,
    submitButtonLabel: "Search"
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

### Full-Screen Implementation

For a full-screen implementation, you can ignore safe areas:

```swift
SwiftWebView(
    urlString: $urlString,
    controls: .closable
)
.ignoresSafeArea(SafeAreaRegions.all, edges: [.bottom])
```

## Features

- Automatic handling of URL prefixes (adds https:// if missing)
- Built-in navigation controls (back, forward, reload)
- URL input field with submit functionality
- Synchronization of displayed URL with the address bar
- Support for collapsible controls to maximize screen space

## License

This library is available under the MIT license. See the LICENSE file for more info.
