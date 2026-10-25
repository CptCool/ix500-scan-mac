import AppKit
import SwiftUI

/// App preferences, opened with ⌘, or from the app menu.
struct SettingsView: View {
    @EnvironmentObject private var scanner: Scanner

    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("language") private var language = Strings.defaultLanguage()

    private var s: Strings { Strings(lang: language) }
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    var body: some View {
        Form {
            Section {
                Picker(s.appearance, selection: $appearance) {
                    Text(s.system).tag("system")
                    Text(s.light).tag("light")
                    Text(s.dark).tag("dark")
                }
                .pickerStyle(.segmented)
                Picker(s.language, selection: $language) {
                    Text("Deutsch").tag("de")
                    Text("English").tag("en")
                }
                .pickerStyle(.segmented)
            }
            Section {
                LabeledContent("\(s.version) \(version)") {
                    Button(s.reportBug) { BugReport.open(log: scanner.log, language: language) }
                }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: appearance) { _, value in Appearance.apply(value) }
        .background(WindowTitle(title: s.settingsTitle))
    }
}

/// Sets the hosting window's title; the Settings scene otherwise uses the system language.
private struct WindowTitle: NSViewRepresentable {
    let title: String
    func makeNSView(context: Context) -> NSView { NSView() }
    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async { view.window?.title = title }
    }
}
