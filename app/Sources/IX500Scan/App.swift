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
    @Published var lastPDF: URL?

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

    func scan(mode: String, dpi: Int, duplex: Bool, ocr: Bool, outDir: String) {
        guard !running else { return }
        running = true
        lastPDF = nil
        log = ""

        var args = [scriptURL.path, "--mode", mode, "--dpi", String(dpi), "--out", outDir]
        if !duplex { args.append("--simplex") }
        if !ocr { args.append("--no-ocr") }

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
                if proc.terminationStatus == 0, let pdf = self.lastPDF {
                    NSWorkspace.shared.open(pdf)
                }
            }
        }

        do {
            try p.run()
            process = p
        } catch {
            running = false
            log = "Konnte Skript nicht starten: \(error.localizedDescription)"
        }
    }

    func cancel() {
        process?.terminate()
    }

    private func append(_ text: String) {
        log += text
        for line in text.split(separator: "\n") where line.hasPrefix("PDF: ") {
            lastPDF = URL(fileURLWithPath: String(line.dropFirst(5)))
        }
    }
}
