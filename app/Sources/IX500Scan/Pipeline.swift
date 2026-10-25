import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers
import Vision

/// Turns scanned page images into the requested output, without external tools:
/// PDFs via Core Graphics (with an invisible OCR text layer from Vision),
/// JPEG/PNG via ImageIO.
enum Pipeline {
    struct Options {
        var save: String        // pdf | pdf-pages | jpeg | png
        var ocr: Bool
        var dpi: Int
        var outDir: URL
        var name: String        // base name, e.g. "Scan 2026-10-25 20.00.00"
    }

    /// Returns the written file (single PDF) or folder (per-page output).
    static func run(pages: [URL], options o: Options, log: (String) -> Void) throws -> URL {
        try FileManager.default.createDirectory(at: o.outDir, withIntermediateDirectories: true)
        let images = try pages.map(loadForPDF)

        switch o.save {
        case "pdf":
            let out = o.outDir.appendingPathComponent(o.name + ".pdf")
            if o.ocr { log("OCR …\n") }
            try writePDF(images, dpi: o.dpi, ocr: o.ocr, to: out)
            return out
        case "pdf-pages":
            let dir = try makeFolder(o)
            if o.ocr { log("OCR …\n") }
            for (i, img) in images.enumerated() {
                try writePDF([img], dpi: o.dpi, ocr: o.ocr, to: dir.appendingPathComponent(pageName(i) + ".pdf"))
            }
            return dir
        default:
            let dir = try makeFolder(o)
            let (type, ext) = o.save == "png" ? (UTType.png, "png") : (UTType.jpeg, "jpg")
            for (i, page) in pages.enumerated() {
                let img = try load(page)
                try writeImage(img, type: type, dpi: o.dpi, to: dir.appendingPathComponent(pageName(i) + "." + ext))
            }
            return dir
        }
    }

    private static func pageName(_ i: Int) -> String { String(format: "Seite %03d", i + 1) }

    private static func makeFolder(_ o: Options) throws -> URL {
        let dir = o.outDir.appendingPathComponent(o.name)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func load(_ url: URL) throws -> CGImage {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            throw CocoaError(.fileReadCorruptFile, userInfo: [NSFilePathErrorKey: url.path])
        }
        return img
    }

    /// Re-encodes color and gray pages as JPEG so the PDF stays small;
    /// Core Graphics passes JPEG data through unchanged. Line art stays lossless.
    private static func loadForPDF(_ url: URL) throws -> CGImage {
        let img = try load(url)
        guard img.bitsPerPixel > 1 else { return img }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else { return img }
        CGImageDestinationAddImage(dest, img, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(dest),
              let src = CGImageSourceCreateWithData(data, nil),
              let jpeg = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return img }
        return jpeg
    }

    private static func writeImage(_ img: CGImage, type: UTType, dpi: Int, to url: URL) throws {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path])
        }
        let props: [CFString: Any] = [
            kCGImagePropertyDPIWidth: dpi, kCGImagePropertyDPIHeight: dpi,
            kCGImageDestinationLossyCompressionQuality: 0.85,
        ]
        CGImageDestinationAddImage(dest, img, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path])
        }
    }

    private static func writePDF(_ images: [CGImage], dpi: Int, ocr: Bool, to url: URL) throws {
        guard let ctx = CGContext(url as CFURL, mediaBox: nil, nil) else {
            throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path])
        }
        for img in images {
            // Page size in points from pixel size and scan resolution
            var box = CGRect(x: 0, y: 0,
                             width: CGFloat(img.width) * 72 / CGFloat(dpi),
                             height: CGFloat(img.height) * 72 / CGFloat(dpi))
            ctx.beginPage(mediaBox: &box)
            ctx.draw(img, in: box)
            if ocr { drawTextLayer(for: img, in: box, ctx: ctx) }
            ctx.endPage()
        }
        ctx.closePDF()
    }

    /// Recognizes text and draws it invisibly over the image, so the PDF is searchable and selectable.
    private static func drawTextLayer(for img: CGImage, in box: CGRect, ctx: CGContext) {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["de-DE", "en-US"]
        request.usesLanguageCorrection = true
        try? VNImageRequestHandler(cgImage: img).perform([request])

        ctx.saveGState()
        ctx.setTextDrawingMode(.invisible)
        for obs in request.results ?? [] {
            guard let text = obs.topCandidates(1).first?.string, !text.isEmpty else { continue }
            // Vision boxes are normalized with the origin bottom-left, like PDF space
            let r = VNImageRectForNormalizedRect(obs.boundingBox, Int(box.width), Int(box.height))
            let font = CTFontCreateWithName("Helvetica" as CFString, r.height * 0.85, nil)
            let line = CTLineCreateWithAttributedString(
                NSAttributedString(string: text, attributes: [.init(kCTFontAttributeName as String): font]))
            let width = CTLineGetTypographicBounds(line, nil, nil, nil)
            guard width > 0 else { continue }
            ctx.saveGState()
            ctx.translateBy(x: r.minX, y: r.minY + r.height * 0.15)
            // Stretch the line to the recognized width so selections match the image
            ctx.scaleBy(x: r.width / CGFloat(width), y: 1)
            ctx.textPosition = .zero
            CTLineDraw(line, ctx)
            ctx.restoreGState()
        }
        ctx.restoreGState()
    }
}
