import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var scanner: Scanner

    @AppStorage("mode") private var mode = "color"
    @AppStorage("dpi") private var dpi = 300
    @AppStorage("duplex") private var duplex = true
    @AppStorage("detectDoubleFeed") private var detectDoubleFeed = true
    @AppStorage("skipBlank") private var skipBlank = true
    @AppStorage("save") private var save = "pdf"
    @AppStorage("ocr") private var ocr = true
    @AppStorage("outDir") private var outDir = NSHomeDirectory() + "/Documents/Scans"
    @AppStorage("openAfter") private var openAfter = true
    @AppStorage("appearance") private var appearance = "system"  // applied at launch; changed in Settings
    @AppStorage("language") private var language = Strings.defaultLanguage()
    @State private var showLog = false

    private var s: Strings { Strings(lang: language) }
    private var savesPDF: Bool { save == "pdf" || save == "pdf-pages" }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(s.sectionScan) {
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
                }

                Section(s.sectionFeed) {
                    Picker(s.sides, selection: $duplex) {
                        Text(s.frontOnly).tag(false)
                        Text(s.bothSides).tag(true)
                    }
                    .pickerStyle(.segmented)
                    Toggle(isOn: $detectDoubleFeed) {
                        Text(s.doubleFeed)
                        Text(s.doubleFeedHelp)
                    }
                    Toggle(s.skipBlank, isOn: $skipBlank)
                }

                Section(s.sectionSave) {
                    Picker(s.saveAs, selection: $save) {
                        Text(s.savePDF).tag("pdf")
                        Text(s.savePDFPages).tag("pdf-pages")
                        Text(s.saveJPEG).tag("jpeg")
                        Text(s.savePNG).tag("png")
                    }
                    Toggle(isOn: $ocr) {
                        Text(s.ocr)
                        Text(savesPDF ? s.ocrHelp : s.ocrPDFOnly)
                    }
                    .disabled(!savesPDF)
                    LabeledContent(s.folder) {
                        HStack {
                            Text((outDir as NSString).abbreviatingWithTildeInPath)
                                .lineLimit(1).truncationMode(.middle)
                                .foregroundStyle(.secondary)
                            Button(s.change, action: chooseFolder)
                        }
                    }
                    Toggle(s.openAfter, isOn: $openAfter)
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                if scanner.doubleFeed {
                    Label(s.doubleFeedWarning, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }

                HStack {
                    Button(showLog ? "▾ \(s.log)" : "▸ \(s.log)") { showLog.toggle() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let out = scanner.output, !scanner.running {
                        Button(s.showInFinder) {
                            NSWorkspace.shared.activateFileViewerSelecting([out])
                        }
                    }
                }

                if showLog || scanner.running {
                    ScrollView {
                        Text(scanner.log.isEmpty ? s.hint : scanner.log)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(height: 100)
                }

                if scanner.running {
                    Button(action: scanner.cancel) {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text(s.cancel)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .controlSize(.extraLarge)
                } else {
                    Button {
                        scanner.scan(mode: mode, dpi: dpi, duplex: duplex, ocr: ocr,
                                     detectDoubleFeed: detectDoubleFeed, skipBlank: skipBlank,
                                     save: save, outDir: outDir, openAfter: openAfter, strings: s)
                    } label: {
                        Label(s.scan, systemImage: "doc.viewfinder")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.extraLarge)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(16)
        }
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { Appearance.apply(appearance) }
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
