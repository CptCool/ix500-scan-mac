import AppKit
import SwiftUI

@main
struct IX500ScanApp: App {
    init() {
        // Needed when launched as a bare executable (swift run)
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        Window("iX500 Scan", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

final class Scanner: ObservableObject {
    @Published var running = false
    @Published var log = ""
    @Published var output: URL?
    @Published var doubleFeed = false

    private var process: Process?

    /// The scan script ships inside the app bundle; fall back to the repo copy for `swift run`.
    private var scriptURL: URL {
        if let bundled = Bundle.main.url(forResource: "scan-ix500", withExtension: nil) {
            return bundled
        }
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("scan-ix500")
    }

    func scan(mode: String, dpi: Int, duplex: Bool, ocr: Bool, detectDoubleFeed: Bool,
              save: String, outDir: String, failedToStart: String) {
        guard !running else { return }
        running = true
        output = nil
        doubleFeed = false
        log = ""

        var args = [scriptURL.path, "--mode", mode, "--dpi", String(dpi), "--save", save, "--out", outDir]
        if !duplex { args.append("--simplex") }
        if !ocr { args.append("--no-ocr") }
        if !detectDoubleFeed { args.append("--no-df") }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/bash")
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] h in
            let data = h.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async { self?.append(text) }
        }
        p.terminationHandler = { [weak self] proc in
            pipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async {
                guard let self else { return }
                self.running = false
                self.process = nil
                // 8 = stopped on a double feed; the pages before it were still saved
                self.doubleFeed = proc.terminationStatus == 8
                if proc.terminationStatus == 0 || self.doubleFeed, let out = self.output {
                    NSWorkspace.shared.open(out)
                }
            }
        }

        do {
            try p.run()
            process = p
        } catch {
            running = false
            log = "\(failedToStart): \(error.localizedDescription)"
        }
    }

    func cancel() {
        process?.terminate()
    }

    private func append(_ text: String) {
        log += text
        for line in text.split(separator: "\n") where line.hasPrefix("OUTPUT: ") {
            output = URL(fileURLWithPath: String(line.dropFirst(8)))
        }
    }
}

enum Appearance {
    static func apply(_ value: String) {
        switch value {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        default: NSApp.appearance = nil
        }
    }
}

enum BugReport {
    static let repo = "CptCool/ix500-scan-mac"

    /// Opens a prefilled "new issue" page; the user reviews and submits it in the browser.
    static func open(log: String, language: String) {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        // Keep the URL short enough for the browser
        let tail = String(log.suffix(1500))
        let body = """
            **\(language == "de" ? "Was ist passiert?" : "What happened?")**


            **\(language == "de" ? "Was hast du erwartet?" : "What did you expect?")**


            ---
            App: \(version)
            macOS: \(os)

            <details><summary>Log</summary>

            ```
            \(tail)
            ```
            </details>
            """
        var c = URLComponents(string: "https://github.com/\(repo)/issues/new")!
        c.queryItems = [URLQueryItem(name: "labels", value: "bug"), URLQueryItem(name: "body", value: body)]
        if let url = c.url { NSWorkspace.shared.open(url) }
    }
}
