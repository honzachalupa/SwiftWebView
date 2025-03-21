import SwiftUI
import WebKit

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public enum WebViewControlsVariant {
    case fixed, closable, hidden
}

public enum NavigationAction: Equatable {
    case goBack, goForward, reload
    case goToUrl(String)
    case none
}

public struct WebViewControls: View {
    @Binding public var urlString: String
    @Binding public var paddingTop: Double
    public var controlsVariant: WebViewControlsVariant
    public var submitButtonLabel: String
    public var isGoBackEnabled: Bool
    public var isGoForwardEnabled: Bool
    public var onGoBack: () -> Void
    public var onGoForward: () -> Void
    public var onReload: () -> Void
    public var onGoToUrl: (String) -> Void
    
    @State private var isControlsPresented: Bool = false
    
    private func setTopPadding() {
        paddingTop = isControlsPresented ? 35 : 0
    }
    
    private func submitUrl() {
        if !urlString.isEmpty {
            var finalUrl = urlString

            // Add https:// prefix if needed
            if !finalUrl.hasPrefix("http://") && !finalUrl.hasPrefix("https://") {
                finalUrl = "https://" + finalUrl
            }

            // Call the provided action to navigate to the URL
            onGoToUrl(finalUrl)
        }
    }

    public var body: some View {
        VStack {
            if (isControlsPresented) {
                HStack {
                    Button(action: onGoBack) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                    .disabled(!isGoBackEnabled)
                    
                    Button(action: onGoForward) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.borderless)
                    .disabled(!isGoForwardEnabled)
                    
                    Button(action: onReload) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .disabled(urlString.isEmpty)
                    
                    TextField("URL", text: $urlString)
#if os(iOS) || os(tvOS) || os(visionOS)
                        .autocapitalization(.none)
#endif
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                        .onSubmit { submitUrl() }
                    
                    Button(submitButtonLabel) { submitUrl() }
                        .buttonStyle(.bordered)
                        .disabled(urlString.isEmpty)
                }
                .padding(5)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            if (controlsVariant == .closable) {
                Button {
                    withAnimation {
                        isControlsPresented.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .rotationEffect(Angle(degrees: isControlsPresented ? 0 : 180))
                        .padding(5)
                        .background(Material.ultraThin)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .padding(.top, 3)
            }
            
            Spacer()
        }
        .animation(.easeInOut, value: isControlsPresented)
        .onAppear {
            setTopPadding()
            
            if (urlString.isEmpty) {
                withAnimation {
                    isControlsPresented = true
                }
            }
        }
        .onChange(of: isControlsPresented) {
            withAnimation {
                setTopPadding()
            }
        }
    }
}

#if os(iOS) || os(tvOS) || os(visionOS)
@MainActor
public class WebViewCoordinator: NSObject, WKNavigationDelegate {
    var parent: WebViewRepresentable

    public init(_ parent: WebViewRepresentable) {
        self.parent = parent
    }

    public func webView(
        _ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        DispatchQueue.main.async {
            self.parent.isGoBackEnabled = webView.canGoBack
            self.parent.isGoForwardEnabled = webView.canGoForward
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
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
            self.parent.isGoBackEnabled = webView.canGoBack
            self.parent.isGoForwardEnabled = webView.canGoForward
        }
    }
}

@MainActor
public struct WebViewRepresentable: UIViewRepresentable {
    @Binding public var urlString: String
    @Binding public var zoom: Double?
    @Binding public var isGoBackEnabled: Bool
    @Binding public var isGoForwardEnabled: Bool
    var navigationAction: NavigationAction?

    public func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator

        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        if let zoom {
            webView.pageZoom = zoom / 100
        }

        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        // Check if URL has changed and load it
        if let urlToLoad = URL(string: urlString), webView.url?.absoluteString != urlString {
            let request = URLRequest(url: urlToLoad)
            webView.load(request)
        }
        
        if let zoom {
            webView.pageZoom = zoom / 100
        }

        // Handle navigation actions
        if let action = navigationAction, action != NavigationAction.none {
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
#elseif os(macOS)
@MainActor
public class WebViewCoordinator: NSObject, WKNavigationDelegate {
    var parent: WebViewRepresentable

    public init(_ parent: WebViewRepresentable) {
        self.parent = parent
    }

    public func webView(
        _ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        DispatchQueue.main.async {
            self.parent.isGoBackEnabled = webView.canGoBack
            self.parent.isGoForwardEnabled = webView.canGoForward
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
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
            self.parent.isGoBackEnabled = webView.canGoBack
            self.parent.isGoForwardEnabled = webView.canGoForward
        }
    }
}

@MainActor
public struct WebViewRepresentable: NSViewRepresentable {
    @Binding public var urlString: String
    @Binding public var zoom: Double?
    @Binding public var isGoBackEnabled: Bool
    @Binding public var isGoForwardEnabled: Bool
    var navigationAction: NavigationAction?

    public func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }

    public func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        if let zoom {
            webView.pageZoom = zoom / 100
        }

        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        // Check if URL has changed and load it
        if let urlToLoad = URL(string: urlString), webView.url?.absoluteString != urlString {
            let request = URLRequest(url: urlToLoad)
            webView.load(request)
        }
        
        if let zoom {
            webView.pageZoom = zoom / 100
        }

        // Handle navigation actions
        if let action = navigationAction, action != NavigationAction.none {
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
#endif

public struct SwiftWebView: View {
    @Binding public var urlString: String
    public var controls: WebViewControlsVariant = .hidden
    @Binding public var zoom: Double?
    public var submitButtonLabel: String = "Go"
    
    @State private var paddingTop: Double = 0
    @State private var navigationAction: NavigationAction = .none
    @State private var isGoBackEnabled: Bool = false
    @State private var isGoForwardEnabled: Bool = false
    @State private var currentUrl: String = ""
    
    public init(
        urlString: Binding<String>,
        controls: WebViewControlsVariant = .hidden,
        zoom: Binding<Double?> = .constant(nil),
        submitButtonLabel: String = "Go"
    ) {
        self._urlString = urlString
        self.controls = controls
        self._zoom = zoom
        self.submitButtonLabel = submitButtonLabel
        self._currentUrl = State(initialValue: urlString.wrappedValue)
    }

    private func goToEnteredUrl(_ url: String) {
        urlString = url
        navigationAction = .goToUrl(url)
    }

    public var body: some View {
        ZStack {
            if (urlString.isEmpty) {
                ContentUnavailableView("Blank window", systemImage: "uiwindow.split.2x1")
            } else {
                WebViewRepresentable(
                    urlString: $urlString,
                    zoom: $zoom,
                    isGoBackEnabled: $isGoBackEnabled,
                    isGoForwardEnabled: $isGoForwardEnabled,
                    navigationAction: navigationAction
                )
                .padding(.top, paddingTop)
            }
            
            if controls != .hidden {
                WebViewControls(
                    urlString: $currentUrl,
                    paddingTop: $paddingTop,
                    controlsVariant: controls,
                    submitButtonLabel: submitButtonLabel,
                    isGoBackEnabled: isGoBackEnabled,
                    isGoForwardEnabled: isGoForwardEnabled,
                    onGoBack: { self.navigationAction = .goBack },
                    onGoForward: { self.navigationAction = .goForward },
                    onReload: { self.navigationAction = .reload },
                    onGoToUrl: self.goToEnteredUrl
                )
            }
        }
        .frame(maxWidth: .infinity)
        .background(Material.bar)
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

#Preview {
    @Previewable @State
    var urlString: String = "https://apple.com/"

    SwiftWebView(
        urlString: $urlString
    )
    .ignoresSafeArea(SafeAreaRegions.all, edges: [.bottom])
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

#Preview("Closable controls") {
    @Previewable @State
    var urlString: String = "https://apple.com/"

    SwiftWebView(
        urlString: $urlString,
        controls: .closable
    )
    .ignoresSafeArea(SafeAreaRegions.all, edges: [.bottom])
}
