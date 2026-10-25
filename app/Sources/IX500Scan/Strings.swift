import Foundation

/// UI strings in German and English, switchable at runtime.
struct Strings {
    let lang: String

    static func defaultLanguage() -> String {
        Locale.preferredLanguages.first?.hasPrefix("de") == true ? "de" : "en"
    }

    private func t(_ de: String, _ en: String) -> String { lang == "de" ? de : en }

    var colorMode: String { t("Farbmodus", "Color mode") }
    var color: String { t("Farbe", "Color") }
    var gray: String { t("Graustufen", "Grayscale") }
    var bw: String { t("Schwarzweiß", "Black & white") }
    var resolution: String { t("Auflösung", "Resolution") }
    var duplex: String { t("Beidseitig (Duplex)", "Both sides (duplex)") }
    var ocr: String { t("Texterkennung (OCR)", "Text recognition (OCR)") }
    var ocrPDFOnly: String { t("nur bei PDF", "PDF only") }
    var doubleFeed: String { t("Doppeleinzug erkennen", "Detect double feed") }
    var saveAs: String { t("Speichern als", "Save as") }
    var savePDF: String { t("Ein PDF mit allen Seiten", "One PDF, all pages") }
    var savePDFPages: String { t("Ein PDF pro Seite", "One PDF per page") }
    var saveJPEG: String { t("JPEG pro Seite", "JPEG per page") }
    var savePNG: String { t("PNG pro Seite", "PNG per page") }
    var folder: String { t("Ablage", "Folder") }
    var change: String { t("Ändern …", "Change …") }
    var scan: String { t("Scannen", "Scan") }
    var cancel: String { t("Abbrechen", "Cancel") }
    var showInFinder: String { t("Im Finder zeigen", "Show in Finder") }
    var hint: String { t("Papier einlegen und auf Scannen klicken.", "Load paper and click Scan.") }
    var doubleFeedWarning: String {
        t("Doppeleinzug erkannt: Der Scanner hat angehalten. Letzte Seite prüfen und den Rest erneut scannen.",
          "Double feed detected: the scanner stopped. Check the last page and rescan the rest.")
    }
    var appearance: String { t("Darstellung", "Appearance") }
    var system: String { "System" }
    var light: String { t("Hell", "Light") }
    var dark: String { t("Dunkel", "Dark") }
    var language: String { t("Sprache", "Language") }
    var reportBug: String { t("Bug melden …", "Report a bug …") }
    var failedToStart: String { t("Konnte Skript nicht starten", "Could not start script") }
}
