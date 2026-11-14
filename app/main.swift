// Мітки — нативна оболонка для macOS: одне вікно із системним WebKit, що показує index.html із бандла.
// Жодного вбудованого браузера чи сервера: пам'ять іде лише на одну веб-сторінку.
import Cocoa
import WebKit
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate, WKUIDelegate, WKNavigationDelegate, WKDownloadDelegate {
    var window: NSWindow!
    var web: WKWebView!

    func applicationDidFinishLaunching(_ note: Notification) {
        buildMenu()
        web = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        web.uiDelegate = self
        web.navigationDelegate = self

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1040, height: 840),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Мітки"
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = NSColor(red: 0.04, green: 0.06, blue: 0.14, alpha: 1)
        window.minSize = NSSize(width: 380, height: 480)
        window.contentView = web
        window.center()
        window.setFrameAutosaveName("MitkyMain") // пам'ятає розмір і місце вікна
        window.makeKeyAndOrderFront(nil)

        guard let page = Bundle.main.url(forResource: "index", withExtension: "html") else {
            fatalError("index.html не знайдено в бандлі")
        }
        web.loadFileURL(page, allowingReadAccessTo: page.deletingLastPathComponent())
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // Меню потрібне, щоб працювали ⌘C / ⌘V / ⌘Z / ⌘Q у полях вводу.
    private func buildMenu() {
        let main = NSMenu()
        func add(_ title: String, _ items: [NSMenuItem]) {
            let item = NSMenuItem(), menu = NSMenu(title: title)
            items.forEach(menu.addItem)
            item.submenu = menu
            main.addItem(item)
        }
        func mi(_ title: String, _ sel: Selector?, _ key: String, shift: Bool = false) -> NSMenuItem {
            let m = NSMenuItem(title: title, action: sel, keyEquivalent: key)
            if shift { m.keyEquivalentModifierMask = [.command, .shift] }
            return m
        }
        let reload = mi("Оновити", #selector(reloadPage), "r")
        reload.target = self
        add("Мітки", [mi("Сховати Мітки", #selector(NSApplication.hide(_:)), "h"), .separator(),
                      mi("Завершити Мітки", #selector(NSApplication.terminate(_:)), "q")])
        add("Редагування", [mi("Скасувати", Selector(("undo:")), "z"), mi("Повторити", Selector(("redo:")), "z", shift: true), .separator(),
                            mi("Вирізати", #selector(NSText.cut(_:)), "x"), mi("Копіювати", #selector(NSText.copy(_:)), "c"),
                            mi("Вставити", #selector(NSText.paste(_:)), "v"), mi("Вибрати все", #selector(NSText.selectAll(_:)), "a")])
        add("Вигляд", [reload, mi("На весь екран", #selector(NSWindow.toggleFullScreen(_:)), "f")])
        add("Вікно", [mi("Згорнути", #selector(NSWindow.performMiniaturize(_:)), "m"), mi("Закрити", #selector(NSWindow.performClose(_:)), "w")])
        NSApp.mainMenu = main
    }
    @objc func reloadPage() { web.reload() }

    // ── confirm() / alert() зі сторінки ──
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let a = NSAlert()
        a.messageText = message
        a.addButton(withTitle: "Так")
        a.addButton(withTitle: "Скасувати")
        a.beginSheetModal(for: window) { completionHandler($0 == .alertFirstButtonReturn) }
    }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let a = NSAlert()
        a.messageText = message
        a.beginSheetModal(for: window) { _ in completionHandler() }
    }

    // ── <input type=file>: імпорт резервної копії та власний фон ──
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let p = NSOpenPanel()
        p.canChooseFiles = true
        p.canChooseDirectories = false
        p.allowsMultipleSelection = parameters.allowsMultipleSelection
        p.beginSheetModal(for: window) { completionHandler($0 == .OK ? p.urls : nil) }
    }

    // ── навігація: зовнішні посилання — у браузер, завантаження (експорт) — у файл ──
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if action.shouldPerformDownload { decisionHandler(.download); return }
        if let u = action.request.url, let s = u.scheme, s == "http" || s == "https" {
            NSWorkspace.shared.open(u)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(response.canShowMIMEType ? .allow : .download)
    }
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) { download.delegate = self }
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) { download.delegate = self }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String,
                  completionHandler: @escaping (URL?) -> Void) {
        let p = NSSavePanel()
        p.nameFieldStringValue = suggestedFilename
        p.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        p.beginSheetModal(for: window) { r in
            guard r == .OK, let url = p.url else { completionHandler(nil); return }
            try? FileManager.default.removeItem(at: url) // панель уже спитала про заміну; WKDownload не перезаписує сам
            completionHandler(url)
        }
    }
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        let a = NSAlert()
        a.messageText = "Не вдалося зберегти файл"
        a.informativeText = error.localizedDescription
        a.beginSheetModal(for: window)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
