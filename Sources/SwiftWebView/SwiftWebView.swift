import SwiftUI
import WebKit

public enum WebViewControlsVariant {
    case fixed, floating, hidden
}

enum NavigationAction: Equatable {
    case goBack, goForward, reload, goToUrl(String), none
}

public struct WebViewControls: View {
    @Binding var urlString: String
    var controlsVariant: WebViewControlsVariant
    var isGoBackEnabled: Bool
    var isGoForwardEnabled: Bool
    var onGoBack: () -> Void
    var onGoForward: () -> Void
    var onReload: () -> Void
    var onGoToUrl: (String) -> Void

    public var body: some View {
        HStack {
            Button(action: onGoBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!isGoBackEnabled)

            Button(action: onGoForward) {
                Image(systemName: "chevron.right")
            }
            .disabled(!isGoForwardEnabled)

            Button(action: onReload) {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .disabled(urlString.isEmpty)

            TextField("URL", text: $urlString)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            Button(action: {
                // Go to URL
                if !urlString.isEmpty {
                    var finalUrl = urlString
                    
                    // Add https:// prefix if needed
                    if !finalUrl.hasPrefix("http://") && !finalUrl.hasPrefix("https://") {
                        finalUrl = "https://" + finalUrl
                    }
                    
                    // Call the provided action to navigate to the URL
                    onGoToUrl(finalUrl)
                }
            }) {
                Text("Go")
            }
            .buttonStyle(.bordered)
            .disabled(urlString.isEmpty)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

@MainActor
public class WebViewCoordinator: NSObject, WKNavigationDelegate {
    var parent: WebViewRepresentable

    init(_ parent: WebViewRepresentable) {
        self.parent = parent
    }

    public func webView(
        _ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        DispatchQueue.main.async {
            self.parent.isLoading = true
            self.parent.isGoBackEnabled = webView.canGoBack
            self.parent.isGoForwardEnabled = webView.canGoForward
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.parent.isLoading = false
            self.parent.isGoBackEnabled = webView.canGoBack
            self.parent.isGoForwardEnabled = webView.canGoForward

            // Update URL string when navigation completes
            if let currentUrl = webView.url?.absoluteString {
                self.parent.urlString = currentUrl
            }
        }
    }

    public func webView(
        _ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error
    ) {
        DispatchQueue.main.async {
            self.parent.isLoading = false
            self.parent.isGoBackEnabled = webView.canGoBack
            self.parent.isGoForwardEnabled = webView.canGoForward
        }
    }
}

// MARK: - WebView Representable
@MainActor
public struct WebViewRepresentable: UIViewRepresentable {
    @Binding var urlString: String
    @Binding var isLoading: Bool
    @Binding var isGoBackEnabled: Bool
    @Binding var isGoForwardEnabled: Bool
    var navigationAction: NavigationAction?

    public func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }

    @MainActor
    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator

        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        return webView
    }

    @MainActor
    public func updateUIView(_ webView: WKWebView, context: Context) {
        // Check if URL has changed and load it
        if let urlToLoad = URL(string: urlString), webView.url?.absoluteString != urlString {
            let request = URLRequest(url: urlToLoad)
            webView.load(request)
        }

        // Handle navigation actions
        if let action = navigationAction, action != .none {
            switch action {
            case .goBack:
                webView.goBack()
            case .goForward:
                webView.goForward()
            case .reload:
                webView.reload()
            case .goToUrl(let url):
                // Force reload the current URL
                if let urlToLoad = URL(string: url) {
                    let request = URLRequest(url: urlToLoad)
                    webView.load(request)
                }
            case .none:
                break
            }
        }

        // Update navigation state
        DispatchQueue.main.async {
            isGoBackEnabled = webView.canGoBack
            isGoForwardEnabled = webView.canGoForward

            // Update the URL string when navigation completes
            if let currentUrl = webView.url?.absoluteString {
                self.urlString = currentUrl
            }
        }
    }
}

public struct SwiftWebView: View {
    @Binding var urlString: String
    var controls: WebViewControlsVariant = .hidden
    @State private var navigationAction: NavigationAction = .none
    @State private var isLoading: Bool = false
    @State private var isGoBackEnabled: Bool = false
    @State private var isGoForwardEnabled: Bool = false
    @State private var currentUrl: String = ""
    
    private func goToEnteredUrl(_ url: String) {
        // Update the main URL string with the input
        urlString = url
        navigationAction = .goToUrl(url)
    }


    public var body: some View {
        VStack(spacing: 0) {
            if controls != .hidden {
                WebViewControls(
                    urlString: $currentUrl,
                    controlsVariant: controls,
                    isGoBackEnabled: isGoBackEnabled,
                    isGoForwardEnabled: isGoForwardEnabled,
                    onGoBack: { self.navigationAction = .goBack },
                    onGoForward: { self.navigationAction = .goForward },
                    onReload: { self.navigationAction = .reload },
                    onGoToUrl: self.goToEnteredUrl
                )
            }
            
            WebViewRepresentable(
                urlString: $urlString,
                isLoading: $isLoading,
                isGoBackEnabled: $isGoBackEnabled,
                isGoForwardEnabled: $isGoForwardEnabled,
                navigationAction: navigationAction
            )
        }
        .onChange(of: navigationAction) { _, newValue in
            // Reset navigation action after it's been processed
            if newValue != .none {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.navigationAction = .none
                }
            }
        }
        .onChange(of: urlString) { oldValue, newValue in
            currentUrl = newValue
        }
    }
}

#Preview("Fixed controls") {
    @Previewable @State
    var urlString: String = "https://apple.com/"

    SwiftWebView(
        urlString: $urlString,
        controls: .fixed
    )
    .ignoresSafeArea(SafeAreaRegions.all, edges: [.bottom])
}

#Preview("Floating controls") {
    @Previewable @State
    var urlString: String = "https://apple.com/"

    SwiftWebView(
        urlString: $urlString,
        controls: .floating
    )
    .ignoresSafeArea(SafeAreaRegions.all, edges: [.bottom])
}

#Preview("Hidden controls") {
    @Previewable @State
    var urlString: String = "https://apple.com/"

    SwiftWebView(
        urlString: $urlString
    )
    .ignoresSafeArea(SafeAreaRegions.all, edges: [.bottom])
}
