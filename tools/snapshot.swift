// Renders a web page to a PNG with WebKit, without opening a browser.
//
//   swift tools/snapshot.swift <file-or-url> <out.png> <width> [height] [scale]
//
// With a height of 0, or none, the whole page is captured. The scale is how
// many image pixels there are to each CSS pixel: 2 for a sharp picture of
// the page, 1 for an image whose size has to be exact. A page with no
// background of its own comes out transparent.

import AppKit
import WebKit

@MainActor
final class Snapper: NSObject, WKNavigationDelegate {
    let webView: WKWebView
    let window: NSWindow
    let output: URL
    let width: CGFloat
    let height: CGFloat?
    let scale: CGFloat

    init(output: URL, width: CGFloat, height: CGFloat?, scale: CGFloat) {
        self.output = output
        self.width = width
        self.height = height
        self.scale = scale
        let frame = NSRect(x: 0, y: 0, width: width, height: height ?? 900)
        webView = WKWebView(frame: frame)
        // Where the page paints no background, the picture is transparent
        // rather than white. That is what an icon needs.
        webView.setValue(false, forKey: "drawsBackground")
        // A web view only lays out and paints inside a window. This one is
        // placed far off the screen and never comes to the front.
        window = NSWindow(
            contentRect: frame.offsetBy(dx: -30000, dy: -30000),
            styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = webView
        window.orderBack(nil)
        super.init()
        webView.navigationDelegate = self
    }

    func load(_ source: String) {
        if source.contains("://") {
            webView.load(URLRequest(url: URL(string: source)!))
        } else {
            let file = URL(fileURLWithPath: source)
            // A page may use files beside it and one folder up (`../mark.svg`).
            let folder = file.deletingLastPathComponent()
            webView.loadFileURL(file, allowingReadAccessTo: folder.deletingLastPathComponent())
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Web fonts and images arrive after the page itself. Images marked to
        // load lazily would wait to be scrolled to, which never happens here,
        // so they are told to load now; and no single image is waited on for
        // more than a few seconds.
        let settle = """
            for (const image of document.images) image.loading = 'eager';
            await document.fonts.ready;
            const patient = (work) => Promise.race([work, new Promise(done => setTimeout(done, 5000))]);
            await Promise.all(Array.from(document.images, image => patient(image.decode().catch(() => 0))));
            return Math.max(document.documentElement.scrollHeight, document.body ? document.body.scrollHeight : 0);
            """
        webView.callAsyncJavaScript(
            settle, arguments: [:], in: nil, in: .page
        ) { result in
            let whole = (try? result.get()) as? CGFloat ?? 900
            let height = self.height ?? whole
            let size = NSSize(width: self.width, height: height)
            self.window.setContentSize(size)
            webView.setFrameSize(size)
            // A moment for the new size to be painted.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 800_000_000)
                self.snap(size)
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        fail("could not load the page: \(error.localizedDescription)")
    }

    func webView(
        _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        fail("could not load the page: \(error.localizedDescription)")
    }

    func snap(_ size: NSSize) {
        let configuration = WKSnapshotConfiguration()
        configuration.rect = NSRect(origin: .zero, size: size)
        configuration.snapshotWidth = NSNumber(value: Double(size.width * scale))
        webView.takeSnapshot(with: configuration) { image, error in
            guard let image, let tiff = image.tiffRepresentation,
                let bitmap = NSBitmapImageRep(data: tiff),
                let png = bitmap.representation(using: .png, properties: [:])
            else {
                self.fail("no picture: \(error?.localizedDescription ?? "unknown")")
            }
            do {
                try png.write(to: self.output)
                print("\(self.output.path): \(bitmap.pixelsWide) x \(bitmap.pixelsHigh)")
                exit(0)
            } catch {
                self.fail("could not write \(self.output.path): \(error.localizedDescription)")
            }
        }
    }

    func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("snapshot: \(message)\n".utf8))
        exit(1)
    }
}

@MainActor
func run() -> Never {
    let arguments = CommandLine.arguments
    guard arguments.count >= 4, let width = Double(arguments[3]) else {
        FileHandle.standardError.write(
            Data("usage: swift snapshot.swift <file-or-url> <out.png> <width> [height] [scale]\n".utf8))
        exit(2)
    }
    let height = arguments.count > 4 ? Double(arguments[4]).flatMap { $0 > 0 ? $0 : nil } : nil
    let scale = arguments.count > 5 ? Double(arguments[5]) ?? 1 : 1

    let app = NSApplication.shared
    // No Dock icon, and it never takes the keyboard.
    app.setActivationPolicy(.accessory)
    let snapper = Snapper(
        output: URL(fileURLWithPath: arguments[2]), width: CGFloat(width),
        height: height.map { CGFloat($0) }, scale: CGFloat(scale))
    snapper.load(arguments[1])
    // Give up rather than hang if the page never finishes loading.
    Task { @MainActor in
        try? await Task.sleep(nanoseconds: 60_000_000_000)
        snapper.fail("timed out")
    }
    app.run()
    exit(0)
}

MainActor.assumeIsolated { run() }
