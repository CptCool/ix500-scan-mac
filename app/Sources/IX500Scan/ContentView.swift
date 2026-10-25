import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var scanner = Scanner()

    @AppStorage("mode") private var mode = "color"
    @AppStorage("dpi") private var dpi = 300
    @AppStorage("duplex") private var duplex = true
    @AppStorage("ocr") private var ocr = true
    @AppStorage("outDir") private var outDir = NSHomeDirectory() + "/Documents/Scans"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Form {
                Picker("Farbmodus", selection: $mode) {
                    Text("Farbe").tag("color")
                    Text("Graustufen").tag("gray")
                    Text("Schwarzweiß").tag("bw")
                }
                Picker("Auflösung", selection: $dpi) {
                    Text("150 dpi").tag(150)
                    Text("200 dpi").tag(200)
                    Text("300 dpi").tag(300)
                    Text("600 dpi").tag(600)
                }
                Toggle("Beidseitig (Duplex)", isOn: $duplex)
                Toggle("Texterkennung (OCR)", isOn: $ocr)
                LabeledContent("Ablage") {
                    HStack {
                        Text(outDir).lineLimit(1).truncationMode(.middle)
                        Button("Ändern …", action: chooseFolder)
                    }
                }
            }

            HStack {
                if scanner.running {
                    ProgressView().controlSize(.small)
                    Button("Abbrechen") { scanner.cancel() }
                } else {
                    Button("Scannen") {
                        scanner.scan(mode: mode, dpi: dpi, duplex: duplex, ocr: ocr, outDir: outDir)
                    }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
                }
                Spacer()
                if let pdf = scanner.lastPDF, !scanner.running {
                    Button("Im Finder zeigen") {
                        NSWorkspace.shared.activateFileViewerSelecting([pdf])
                    }
                }
            }

            ScrollView {
                Text(scanner.log.isEmpty ? "Papier einlegen und auf Scannen klicken." : scanner.log)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: 120)
        }
        .padding(20)
        .frame(width: 460)
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
