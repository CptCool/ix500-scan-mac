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
        t("Doppeleinzug erkannt: Der Scanner hat angehalten. Blätter trennen und den Rest erneut scannen.",
          "Double feed detected: the scanner stopped. Separate the sheets and rescan the rest.")
    }
    var paperJam: String {
        t("Papierstau: Klappe öffnen, Blatt entnehmen und den Rest erneut scannen.",
          "Paper jam: open the lid, remove the sheet and rescan the rest.")
    }
    var coverOpen: String { t("Die Scannerklappe ist offen. Bitte schließen.", "The scanner lid is open. Please close it.") }
    var stopButton: String { t("Am Scanner abgebrochen.", "Stopped at the scanner.") }
    var busy: String {
        t("Der Scanner ist belegt. Läuft noch ScanSnap Home oder ein anderes Scanprogramm?",
          "The scanner is busy. Is ScanSnap Home or another scan app still running?")
    }
    var disconnected: String {
        t("Verbindung zum Scanner verloren. USB-Kabel und Strom prüfen.",
          "Lost connection to the scanner. Check the USB cable and power.")
    }
    var hardwareError: String { t("Hardwarefehler am Scanner", "Scanner hardware error") }
    var feederProblem: String { t("Problem am Einzug", "Feeder problem") }
    var pagesKept: String { t("Die Seiten davor wurden gespeichert.", "The pages before it were saved.") }
    var appearance: String { t("Darstellung", "Appearance") }
    var system: String { "System" }
    var light: String { t("Hell", "Light") }
    var dark: String { t("Dunkel", "Dark") }
    var language: String { t("Sprache", "Language") }
    var reportBug: String { t("Bug melden …", "Report a bug …") }
    var sectionScan: String { t("Bild", "Image") }
    var sectionFeed: String { t("Einzug", "Feeder") }
    var sectionSave: String { t("Speichern", "Saving") }
    var sectionApp: String { t("Programm", "App") }
    var sides: String { t("Seiten", "Sides") }
    var frontOnly: String { t("Nur Vorderseite", "Front only") }
    var bothSides: String { t("Beidseitig", "Both sides") }
    var doubleFeedHelp: String { t("Hält an, wenn zwei Blätter gleichzeitig eingezogen werden. Für Umschläge und Karten ausschalten.",
                                   "Stops when two sheets feed at once. Turn off for envelopes and cards.") }
    var skipBlank: String { t("Leere Seiten weglassen", "Skip blank pages") }
    var ocrHelp: String { t("Macht PDFs durchsuchbar (Deutsch + Englisch).", "Makes PDFs searchable (German + English).") }
    var openAfter: String { t("Nach dem Scannen öffnen", "Open after scanning") }
    var log: String { t("Protokoll", "Log") }
    var version: String { t("Version", "Version") }
    var device: String { t("Gerät", "Device") }
    var scanning: String { t("Scanne", "Scanning") }
    var pagesScanned: String { t("Seite(n) gescannt", "page(s) scanned") }
    var saved: String { t("Gespeichert", "Saved") }
    var cancelled: String { t("Abgebrochen.", "Cancelled.") }
    var noPages: String { t("Keine Seiten gescannt. Liegt Papier im Einzug?", "No pages scanned. Is there paper in the feeder?") }
    var noScanner: String {
        t("Kein iX500 gefunden. Per USB angeschlossen, Klappe offen und ScanSnap Home beendet?",
          "No iX500 found. Connected via USB, feeder lid open and ScanSnap Home quit?")
    }
    var settingsTitle: String { t("Einstellungen", "Settings") }
}
