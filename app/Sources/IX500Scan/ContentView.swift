import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var scanner = Scanner()

    @AppStorage("mode") private var mode = "color"
    @AppStorage("dpi") private var dpi = 300
    @AppStorage("duplex") private var duplex = true
    @AppStorage("ocr") private var ocr = true
    @AppStorage("detectDoubleFeed") private var detectDoubleFeed = true
    @AppStorage("save") private var save = "pdf"
    @AppStorage("outDir") private var outDir = NSHomeDirectory() + "/Documents/Scans"
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("language") private var language = Strings.defaultLanguage()

    private var s: Strings { Strings(lang: language) }
    private var savesPDF: Bool { save == "pdf" || save == "pdf-pages" }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Form {
                Picker(s.colorMode, selection: $mode) {
                    Text(s.color).tag("color")
                    Text(s.gray).tag("gray")
                    Text(s.bw).tag("bw")
                }
                Picker(s.resolution, selection: $dpi) {
                    Text("150 dpi").tag(150)
                    Text("200 dpi").tag(200)
                    Text("300 dpi").tag(300)
                    Text("600 dpi").tag(600)
                }
                Picker(s.saveAs, selection: $save) {
                    Text(s.savePDF).tag("pdf")
                    Text(s.savePDFPages).tag("pdf-pages")
                    Text(s.saveJPEG).tag("jpeg")
                    Text(s.savePNG).tag("png")
                }
                Toggle(s.duplex, isOn: $duplex)
                Toggle(isOn: $ocr) {
                    Text(s.ocr) + Text(savesPDF ? "" : "  (\(s.ocrPDFOnly))").foregroundColor(.secondary)
                }
                .disabled(!savesPDF)
                Toggle(s.doubleFeed, isOn: $detectDoubleFeed)
                LabeledContent(s.folder) {
                    HStack {
                        Text(outDir).lineLimit(1).truncationMode(.middle)
                        Button(s.change, action: chooseFolder)
                    }
                }
            }

            HStack {
                if scanner.running {
                    ProgressView().controlSize(.small)
                    Button(s.cancel) { scanner.cancel() }
                } else {
                    Button(s.scan) {
                        scanner.scan(mode: mode, dpi: dpi, duplex: duplex, ocr: ocr,
                                     detectDoubleFeed: detectDoubleFeed, save: save,
                                     outDir: outDir, failedToStart: s.failedToStart)
                    }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
                }
                Spacer()
                if let out = scanner.output, !scanner.running {
                    Button(s.showInFinder) {
                        NSWorkspace.shared.activateFileViewerSelecting([out])
                    }
                }
            }

            if scanner.doubleFeed {
                Label(s.doubleFeedWarning, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }

            ScrollView {
                Text(scanner.log.isEmpty ? s.hint : scanner.log)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: 120)

            Divider()

            HStack {
                Picker(s.appearance, selection: $appearance) {
                    Text(s.system).tag("system")
                    Text(s.light).tag("light")
                    Text(s.dark).tag("dark")
                }
                .pickerStyle(.segmented)
                .fixedSize()
                Spacer()
                Picker(s.language, selection: $language) {
                    Text("Deutsch").tag("de")
                    Text("English").tag("en")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
            HStack {
                Spacer()
                Button(s.reportBug) { BugReport.open(log: scanner.log, language: language) }
                    .buttonStyle(.link)
            }
        }
        .padding(20)
        .frame(width: 480)
        .onAppear { Appearance.apply(appearance) }
        .onChange(of: appearance) { _, value in Appearance.apply(value) }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.directoryURL = URL(fileURLWithPath: outDir)
        if panel.runModal() == .OK, let url = panel.url {
            outDir = url.path
        }
    }
}
