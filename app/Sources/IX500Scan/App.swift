import AppKit
import SwiftUI

@main
struct IX500ScanApp: App {
    @StateObject private var scanner = Scanner()
    @AppStorage("language") private var language = Strings.defaultLanguage()

    init() {
        // Needed when launched as a bare executable (swift run)
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        Window("iX500 Scan", id: "main") {
            ContentView()
                .environmentObject(scanner)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .help) {
                Button(Strings(lang: language).reportBug) {
                    BugReport.open(log: scanner.log, language: language)
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(scanner)
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
    private var cancelled = false

    /// SANE is bundled inside the app (self-contained build); for a plain `swift build`
    /// fall back to Homebrew's.
    private var sane: (scanimage: URL, env: [String: String]) {
        var env = ProcessInfo.processInfo.environment
        if let res = Bundle.main.resourceURL?.appendingPathComponent("sane"),
           FileManager.default.fileExists(atPath: res.appendingPathComponent("bin/scanimage").path) {
            env["SANE_CONFIG_DIR"] = res.appendingPathComponent("etc/sane.d").path
            env["LD_LIBRARY_PATH"] = res.appendingPathComponent("lib/sane").path
            return (res.appendingPathComponent("bin/scanimage"), env)
        }
        let brew = ["/opt/homebrew/bin/scanimage", "/usr/local/bin/scanimage"]
            .first { FileManager.default.fileExists(atPath: $0) } ?? "/opt/homebrew/bin/scanimage"
        return (URL(fileURLWithPath: brew), env)
    }

    func scan(mode: String, dpi: Int, duplex: Bool, ocr: Bool, detectDoubleFeed: Bool, skipBlank: Bool,
              save: String, outDir: String, openAfter: Bool, strings s: Strings) {
        guard !running else { return }
        running = true
        cancelled = false
        output = nil
        doubleFeed = false
        log = ""

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("ix500-" + UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: tmp) }
            var result: URL?
            var df = false
            do {
                try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
                let device = try findDevice(s)
                emit("\(s.device): \(device)\n")

                let saneMode = ["gray": "Gray", "bw": "Lineart"][mode] ?? "Color"
                var args = ["-d", device, "--source", duplex ? "ADF Duplex" : "ADF Front",
                            "--mode", saneMode, "--resolution", String(dpi),
                            "--swdeskew=yes", "--swcrop=yes", "--swskip", skipBlank ? "10" : "0",
                            "--format=tiff", "--batch=" + tmp.appendingPathComponent("page-%03d.tif").path]
                args += detectDoubleFeed
                    ? ["--df-action", "Stop", "--df-thickness=yes", "--df-length=yes"]
                    : ["--df-action", "Continue"]
                emit("\(s.scanning) …\n")
                // scanimage exits non-zero when the feeder runs empty, the normal end of a batch
                let out = try runProcess(sane.scanimage, args, env: sane.env, stream: true)
                if cancelled { throw CancellationError() }
                df = out.localizedCaseInsensitiveContains("jammed")
                if df { emit(s.doubleFeedWarning + "\n") }

                let pages = try FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil)
                    .filter { $0.pathExtension == "tif" }
                    .sorted { $0.lastPathComponent < $1.lastPathComponent }
                guard !pages.isEmpty else {
                    if df { throw ScanError(message: "") }
                    throw ScanError(message: s.noPages)
                }
                emit("\(pages.count) \(s.pagesScanned)\n")

                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd HH.mm.ss"
                let options = Pipeline.Options(save: save, ocr: ocr && save.hasPrefix("pdf"), dpi: dpi,
                                               outDir: URL(fileURLWithPath: outDir),
                                               name: "Scan " + f.string(from: Date()))
                result = try Pipeline.run(pages: pages, options: options) { emit($0) }
                emit("\(s.saved): \(result!.path)\n")
            } catch is CancellationError {
                emit(s.cancelled + "\n")
            } catch let e as ScanError {
                if !e.message.isEmpty { emit(e.message + "\n") }
            } catch {
                emit("\(error.localizedDescription)\n")
            }

            DispatchQueue.main.async {
                self.running = false
                self.process = nil
                self.doubleFeed = df
                self.output = result
                if openAfter, let result { NSWorkspace.shared.open(result) }
            }
        }
    }

    func cancel() {
        cancelled = true
        process?.terminate()
    }

    private struct ScanError: Error { let message: String }

    private func findDevice(_ s: Strings) throws -> String {
        let out = try runProcess(sane.scanimage, ["-f", "%d%n"], env: sane.env, stream: false)
        guard let dev = out.split(separator: "\n").first(where: { $0.hasPrefix("fujitsu:") }) else {
            throw ScanError(message: s.noScanner)
        }
        return String(dev)
    }

    /// Runs a tool, optionally streaming progress lines to the log, and returns all output.
    private func runProcess(_ exe: URL, _ args: [String], env: [String: String], stream: Bool) throws -> String {
        guard FileManager.default.isExecutableFile(atPath: exe.path) else {
            throw ScanError(message: "scanimage not found: \(exe.path)")
        }
        let p = Process()
        p.executableURL = exe
        p.arguments = args
        p.environment = env
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        var all = ""
        let lock = NSLock()
        pipe.fileHandleForReading.readabilityHandler = { [weak self] h in
            guard let text = String(data: h.availableData, encoding: .utf8), !text.isEmpty else { return }
            lock.lock(); all += text; lock.unlock()
            if stream {
                for line in text.split(separator: "\n") where line.hasPrefix("Scanned page") {
                    self?.emit(line + "\n")
                }
            }
        }
        if stream { DispatchQueue.main.sync { process = p } }
        try p.run()
        p.waitUntilExit()
        pipe.fileHandleForReading.readabilityHandler = nil
        if let rest = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) {
            lock.lock(); all += rest; lock.unlock()
        }
        return all
    }

    private func emit(_ text: String) {
        DispatchQueue.main.async { self.log += text }
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
