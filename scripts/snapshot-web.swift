// Renders web/index.html with WebKit to PNG for the README, seeded with demo data.
// Usage (from repo root): scripts/screenshots.sh
import AppKit
import WebKit

let out = CommandLine.arguments[1]
let page = URL(fileURLWithPath: "web/index.html").absoluteURL

let seed = """
(() => {
  const now = Date.now(), day = 864e5, h = [];
  const intents = ['Refactor the sync engine', 'Read: Designing Data-Intensive Apps', 'Inbox zero', 'Sketch onboarding flow'];
  const tags = ['deep', 'study', 'admin', 'write'];
  [[6,5],[5,7],[4,3],[3,8],[2,6],[1,4]].forEach(([back, n]) => {
    const d = new Date(now - back * day); d.setHours(9, 0, 0, 0);
    for (let k = 0; k < n; k++) h.push({ t: d.getTime() + k * 1.9e6, min: 25, intent: intents[k % 4], tag: tags[k % 4] });
  });
  const t = new Date(); t.setHours(9, 0, 0, 0);
  h.push({ t: t.getTime(), min: 25, intent: 'Inbox zero', tag: 'admin' });
  h.push({ t: t.getTime() + 1.9e6, min: 31, intent: 'Outline chapter 3', tag: 'write' });
  localStorage.setItem('pomelo.history', JSON.stringify(h));
  localStorage.setItem('pomelo.state', JSON.stringify({ mode: 'focus', status: 'paused', remainingMs: 1062000, endAt: 0, startedAt: 1, round: 2, tag: 'deep', intent: 'Draft the Q4 roadmap' }));
  localStorage.setItem('pomelo.theme', JSON.stringify(window.__THEME__));
})();
"""

final class Shooter: NSObject, WKNavigationDelegate {
    let jobs: [(name: String, theme: String, size: NSSize)] = [
        ("web-light", "light", NSSize(width: 1280, height: 820)),
        ("web-dark", "dark", NSSize(width: 1280, height: 820)),
        ("web-mobile-dark", "dark", NSSize(width: 390, height: 1400)),
    ]
    var i = 0
    var web: WKWebView!
    var window: NSWindow!

    func next() {
        guard i < jobs.count else { NSApp.terminate(nil); return }
        let j = jobs[i]
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .nonPersistent()
        cfg.userContentController.addUserScript(WKUserScript(source: "window.__THEME__='\(j.theme)';" + seed, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        web = WKWebView(frame: NSRect(origin: .zero, size: j.size), configuration: cfg)
        web.navigationDelegate = self
        window = NSWindow(contentRect: NSRect(x: -5000, y: 0, width: j.size.width, height: j.size.height), styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = web
        window.orderBack(nil)
        web.loadFileURL(page, allowingReadAccessTo: page.deletingLastPathComponent())
    }

    func webView(_ w: WKWebView, didFinish n: WKNavigation!) {
        // give web fonts time to arrive and the accent transition time to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            let c = WKSnapshotConfiguration()
            w.takeSnapshot(with: c) { img, err in
                if let img, let tiff = img.tiffRepresentation, let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                    let path = "\(out)/\(self.jobs[self.i].name).png"
                    try! png.write(to: URL(fileURLWithPath: path)); print("wrote \(path)")
                } else { print("snapshot failed: \(String(describing: err))") }
                self.i += 1; self.next()
            }
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let shooter = Shooter()
DispatchQueue.main.async { shooter.next() }
app.run()
