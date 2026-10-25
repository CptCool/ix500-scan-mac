# iX500 Scan for macOS

Use a Fujitsu/PFU **ScanSnap iX500** on current macOS without ScanSnap Home.
Scans over USB via [SANE](http://www.sane-project.org/)'s `fujitsu` backend and
produces searchable PDFs.

- `app/` — a small SwiftUI app. It bundles SANE and does OCR with Apple's Vision
  framework, so it needs nothing else installed.
- `scan-ix500` — a command-line script (uses Homebrew's SANE, `img2pdf` and
  `ocrmypdf`/Tesseract)

No pairing key, no network protocol reverse engineering: the iX500 is a
supported SANE device over USB. Apple silicon only.

## Install

### Option 1: Homebrew

```bash
brew install --cask cptcool/tap/ix500-scan
```

Installs the app and the `scan-ix500` command, with the tools the command needs.

### Option 2: App bundle

Download `iX500-Scan-<version>.zip` from
[Releases](https://github.com/CptCool/ix500-scan-mac/releases), unzip it and drag
*iX500 Scan* into *Applications*. Nothing else to install.

### First launch

The app isn't notarized by Apple. On first launch macOS refuses to open it: go to
*System Settings → Privacy & Security* and click *Open Anyway*. (Homebrew users can
also run `xattr -d com.apple.quarantine "/Applications/iX500 Scan.app"`.)

### Build from source

```bash
git clone https://github.com/CptCool/ix500-scan-mac.git
cd ix500-scan-mac
brew install sane-backends   # bundled into the app at build time
app/build.sh install         # or: app/build.sh zip
```

Needs the Xcode Command Line Tools (`xcode-select --install`).

## ScanSnap Home must not be running

ScanSnap Home opens the scanner exclusively over USB, so SANE can't see it while
it runs. Quit it, and stop it from launching at login:

```bash
for l in com.ricoh.pfu.SshAutoLaunch.plist com.fujitsu.pfu.ScanSnap.AOUMonitor jp.co.pfu.SearchablePDFConverter; do
  launchctl disable gui/$(id -u)/$l
done
```

Undo with `launchctl enable` on the same labels.

## Use

**App:** open *iX500 Scan*, pick color mode, resolution, save format, duplex,
OCR and double-feed detection, put paper in the feeder, click *Scan*. The result
opens when it's done. Settings are remembered. Appearance (light, dark, system)
and language (German, English) live in the Settings window (⌘,). *Report a bug*
(Settings window or Help menu) opens a prefilled GitHub issue in your browser.

Save formats: one PDF with all pages, one PDF per page, or one JPEG/PNG per page
(per-page output goes into a folder named after the scan).

Double-feed detection uses the scanner's ultrasonic sensor: when two sheets go
through at once, the scan stops and the pages before it are kept.

**Command line** (needs `brew install sane-backends img2pdf ocrmypdf tesseract-lang`,
which the Homebrew install does for you):

```bash
./scan-ix500                         # color, 300 dpi, duplex, OCR deu+eng
./scan-ix500 --mode gray --dpi 200   # grayscale
./scan-ix500 --simplex --no-ocr --out ~/Desktop
./scan-ix500 --save png              # pdf | pdf-pages | jpeg | png
./scan-ix500 --no-df                 # no double-feed detection (envelopes, cards)
```

PDFs go to `~/Documents/Scans` by default. Blank pages are skipped (`--keep-blank` keeps them), pages are
deskewed and cropped.

## Check that the scanner is visible

```bash
scanimage -L
# device `fujitsu:ScanSnap iX500:…' is a FUJITSU ScanSnap iX500 scanner
```

If nothing shows up: USB cable connected, feeder lid open, ScanSnap Home quit.

## License

MIT
