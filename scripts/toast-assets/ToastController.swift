import Cocoa
import WebKit

class ToastWindowController: NSObject, WKNavigationDelegate {
    let window: NSWindow
    let webView: WKWebView
    var titleObservation: NSKeyValueObservation?
    var globalMonitor: Any?
    var localMonitor: Any?
    var lastHitTestTime: CFAbsoluteTime = 0
    let hitTestThrottle: CFAbsoluteTime = 0.05  // 50ms

    override init() {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let winWidth: CGFloat = 420
        let winHeight: CGFloat = 160
        let x = screenFrame.maxX - winWidth - 20
        let y = screenFrame.maxY - winHeight - 20

        let rect = NSRect(x: x, y: y, width: winWidth, height: winHeight)

        window = NSWindow(
            contentRect: rect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.ignoresMouseEvents = true  // Click-through by default

        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        webView = WKWebView(frame: rect, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")

        super.init()
        webView.navigationDelegate = self

        window.contentView = webView

        titleObservation = webView.observe(\.title, options: [.new]) { _, change in
            guard let newTitle = change.newValue as? String else { return }
            if newTitle == "ACTIVATE" {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/bash")
                task.arguments = ["/tmp/toast-activate.sh"]
                try? task.run()
                task.waitUntilExit()
                NSApplication.shared.terminate(nil)
            } else if newTitle == "CLOSE" {
                NSApplication.shared.terminate(nil)
            }
        }

        setupMouseMonitors()
    }

    func setupMouseMonitors() {
        // Global monitor: fires when window ignoresMouseEvents = true
        // Detects cursor entering interactive regions
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self] _ in
            self?.performHitTest()
        }

        // Local monitor: fires when window accepts events
        // Detects cursor leaving interactive regions
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self] event in
            self?.performHitTest()
            return event
        }
    }

    func performHitTest() {
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastHitTestTime >= hitTestThrottle else { return }
        lastHitTestTime = now

        let mouseLocation = NSEvent.mouseLocation
        let windowFrame = window.frame

        // Check if cursor is within the window bounds
        guard windowFrame.contains(mouseLocation) else {
            if window.ignoresMouseEvents { return }  // Already ignoring
            window.ignoresMouseEvents = true
            return
        }

        // Convert screen coords to WebView CSS coords
        // macOS Y is bottom-up, HTML Y is top-down
        let localX = mouseLocation.x - windowFrame.origin.x
        let localY = windowFrame.height - (mouseLocation.y - windowFrame.origin.y)

        let js = "document.elementFromPoint(\(localX),\(localY))?.closest('.bubble,.mascot-wrap,.stats-hud') !== null"
        webView.evaluateJavaScript(js) { [weak self] result, _ in
            guard let self = self else { return }
            let isInteractive = result as? Bool ?? false
            DispatchQueue.main.async {
                self.window.ignoresMouseEvents = !isInteractive
            }
        }
    }

    func cleanup() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    func load(url: URL) {
        webView.load(URLRequest(url: url))
        window.orderFrontRegardless()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let controller = ToastWindowController()

let totalTimeoutMs = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "6000"

controller.load(url: URL(fileURLWithPath: "/tmp/toast.html"))

let totalTimeout = (Double(totalTimeoutMs) ?? 6000) / 1000.0
DispatchQueue.main.asyncAfter(deadline: .now() + totalTimeout) {
    controller.cleanup()
    NSApplication.shared.terminate(nil)
}

app.run()
