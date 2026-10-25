import Foundation

/// A feeder or device problem reported by the SANE fujitsu backend.
/// The backend logs the scanner's sense codes ("Medium error: paper jam") when
/// SANE_DEBUG_FUJITSU >= 2; scanimage itself only prints the coarse SANE status.
enum ScanProblem: Equatable {
    case doubleFeed
    case paperJam
    case coverOpen
    case stopButton
    case busy
    case disconnected
    case hardware(String)
    case other(String)

    /// Picks the most specific problem from scanimage's output, or nil for a clean run.
    static func detect(in output: String) -> ScanProblem? {
        let text = output.lowercased()
        func has(_ s: String) -> Bool { text.contains(s) }

        if has("medium error: double feed") { return .doubleFeed }
        if has("medium error: paper jam") { return .paperJam }
        if has("medium error: cover open") || has("scanner cover is open") { return .coverOpen }
        if has("medium error: stop button") { return .stopButton }
        if let line = firstLine(in: output, prefix: "Hardware error: ") { return .hardware(line) }
        for medium in ["unusual paper", "adf setup error", "adf blocked by card", "not enough paper",
                       "scanning halted", "carrier sheet"] where has("medium error: " + medium) {
            return .other(medium)
        }
        // Fall back to the coarse SANE status when no sense line was logged
        if has("document feeder jammed") { return .paperJam }
        if has("not ready: busy") || has("device busy") || has("resource busy") { return .busy }
        if has("error during device i/o") || has("no such device") { return .disconnected }
        return nil
    }

    private static func firstLine(in output: String, prefix: String) -> String? {
        for line in output.split(separator: "\n") {
            if let r = line.range(of: prefix) {
                let detail = line[r.upperBound...].trimmingCharacters(in: .whitespaces)
                if !detail.hasPrefix("unknown") { return detail }
                return String(line[r.lowerBound...])
            }
        }
        return nil
    }

    func message(_ s: Strings) -> String {
        switch self {
        case .doubleFeed: return s.doubleFeedWarning
        case .paperJam: return s.paperJam
        case .coverOpen: return s.coverOpen
        case .stopButton: return s.stopButton
        case .busy: return s.busy
        case .disconnected: return s.disconnected
        case .hardware(let detail): return "\(s.hardwareError): \(detail)"
        case .other(let detail): return "\(s.feederProblem): \(detail)"
        }
    }
}
