import CoreGraphics
import Foundation
import Vision

/// A line of text that OCR read from a screenshot. `frame` is in fractions of the image, measured from its top-left corner.
struct ScreenshotTextLine: Equatable {
    var text: String
    var frame: CGRect
}

/// Turns the OCR lines of one or more scrolling screenshots into a job description. It leaves out the status bar and
/// the bars that stay put while scrolling, keeps the text repeated where screenshots overlap once (sorting screenshots
/// chosen out of order by that overlap), and rejoins wrapped lines into paragraphs. For a LinkedIn job it keeps the text
/// under "About the job", leaves out LinkedIn's buttons and the sections after the description, and reads the title,
/// company, and job details from the top of the post.
struct JobScreenshotReader {
    func read(pages: [[ScreenshotTextLine]]) -> JobCaptureExtraction {
        let screens = withoutFixedBars(uniqueScreens(pages.enumerated().map { rows(from: $0.element, page: $0.offset) }))
        let isLinkedIn = screens.joined().contains { LinkedInVocabulary.isMarker($0) }
        let isFiller: (Row) -> Bool = { isLinkedIn && LinkedInVocabulary.content(of: $0) == nil }
        let merged = merge(ordered(screens, isFiller: isFiller), isFiller: isFiller)
        return isLinkedIn ? linkedInExtraction(from: merged) : JobCaptureExtraction(text: text(of: paragraphs(merged)))
    }

    /// Reads every line of text in a screenshot with Vision, on a background queue.
    static func lines(in image: CGImage) async throws -> [ScreenshotTextLine] {
        let found: [(String, CGRect)] = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["en-US"]
                request.usesLanguageCorrection = true
                do {
                    try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
                    continuation.resume(returning: (request.results ?? []).compactMap { observation in observation.topCandidates(1).first.map { ($0.string, observation.boundingBox) } })
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        // Vision measures from the bottom-left corner.
        return found.map { ScreenshotTextLine(text: $0.0, frame: CGRect(x: $0.1.minX, y: 1 - $0.1.maxY, width: $0.1.width, height: $0.1.height)) }
    }

    /// Lowercased letters and digits with single spaces, used to compare lines across screenshots.
    static func key(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
        let spaced = String(folded.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : " " })
        return spaced.split(separator: " ").joined(separator: " ")
    }

    static func isListItem(_ text: String) -> Bool {
        text.range(of: #"^\s*([•●▪◦‣∙·*\-–—]|\d{1,2}[.)])\s+\S"#, options: .regularExpression) != nil
    }
}

/// One visual line of a screenshot: the OCR lines that sit side by side, left to right.
private struct Row {
    let parts: [ScreenshotTextLine]
    let page: Int
    let text: String
    let frame: CGRect
    let key: String
    var startsParagraph: Bool

    init?(parts lines: [ScreenshotTextLine], page: Int, startsParagraph: Bool = false) {
        let parts = lines.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }.sorted { $0.frame.minX < $1.frame.minX }
        guard let first = parts.first else { return nil }
        self.parts = parts
        self.page = page
        self.startsParagraph = startsParagraph
        text = parts.map { $0.text.trimmingCharacters(in: .whitespaces) }.joined(separator: " ")
        frame = parts.dropFirst().reduce(first.frame) { $0.union($1.frame) }
        key = JobScreenshotReader.key(text)
        guard !key.isEmpty else { return nil }
    }

    /// The same row with its text replaced, for trimming LinkedIn's inline "…more".
    func replacingText(_ text: String) -> Row? {
        Row(parts: [ScreenshotTextLine(text: text, frame: frame)], page: page, startsParagraph: startsParagraph)
    }
}

/// Where one screenshot continues another: keep the first `keepFirst` rows of the first, then the second from `skipSecond`.
private struct Overlap {
    let keepFirst: Int
    let skipSecond: Int
    let run: Int
}

private extension JobScreenshotReader {
    func rows(from lines: [ScreenshotTextLine], page: Int) -> [Row] {
        var groups: [[ScreenshotTextLine]] = []
        for line in lines.filter({ !isStatusBar($0) }).sorted(by: { $0.frame.midY < $1.frame.midY }) {
            if let last = groups.indices.last {
                let band = groups[last].dropFirst().reduce(groups[last][0].frame) { $0.union($1.frame) }
                if line.frame.midY > band.minY, line.frame.midY < band.maxY { groups[last].append(line); continue }
            }
            groups.append([line])
        }
        return groups.compactMap { Row(parts: $0, page: page) }
    }

    /// The clock, signal, and battery at the very top of a screenshot.
    func isStatusBar(_ line: ScreenshotTextLine) -> Bool {
        line.frame.maxY < 0.07 && line.text.trimmingCharacters(in: .whitespaces).range(of: #"^(\d{1,2}[:.]\d{2}(\s?[AP]M)?|\d{1,3}\s?%?|LTE\+?|[345]G\+?|5G ?(UW|E)|SOS|Wi-?Fi|[^\p{L}\p{N}]{1,3})$"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// Drops a screenshot taken twice without scrolling: nearly every row sits at the same height in both.
    func uniqueScreens(_ screens: [[Row]]) -> [[Row]] {
        var kept: [[Row]] = []
        for screen in screens where !screen.isEmpty && !kept.contains(where: { isSameScreen(screen, $0) }) { kept.append(screen) }
        return kept
    }

    func isSameScreen(_ first: [Row], _ second: [Row]) -> Bool {
        let shared = first.filter { row in second.contains { $0.key == row.key && abs($0.frame.midY - row.frame.midY) < 0.01 } }.count
        return Double(shared) >= Double(max(first.count, second.count)) * 0.9
    }

    /// A row at the same height near the top or bottom of two screenshots is the app's own bar: page content moves as you scroll.
    func withoutFixedBars(_ screens: [[Row]]) -> [[Row]] {
        guard screens.count > 1 else { return screens }
        return screens.enumerated().map { index, screen in
            screen.filter { row in
                guard row.frame.midY < 0.2 || row.frame.midY > 0.8 else { return true }
                return !screens.enumerated().contains { other, rows in
                    other != index && rows.contains { $0.key == row.key && abs($0.frame.midY - row.frame.midY) < 0.012 }
                }
            }
        }
    }

    /// Keeps the chosen order when each screenshot continues the one before it; otherwise follows the overlaps from the
    /// one screenshot that continues no other, and falls back to the chosen order when they don't make a single chain.
    func ordered(_ screens: [[Row]], isFiller: (Row) -> Bool) -> [[Row]] {
        guard screens.count > 1 else { return screens }
        if zip(screens, screens.dropFirst()).allSatisfy({ overlap($0, $1, isFiller: isFiller) != nil }) { return screens }
        let links = screens.indices.map { first in screens.indices.map { second in first == second ? nil : overlap(screens[first], screens[second], isFiller: isFiller) } }
        let starts = screens.indices.filter { screen in !screens.indices.contains { links[$0][screen] != nil } }
        guard starts.count == 1 else { return screens }
        var order = starts
        while let last = order.last,
              let next = screens.indices.filter({ !order.contains($0) && links[last][$0] != nil }).max(by: { (links[last][$0]?.run ?? 0) < (links[last][$1]?.run ?? 0) }) {
            order.append(next)
        }
        return order.count == screens.count ? order.map { screens[$0] } : screens
    }

    func merge(_ screens: [[Row]], isFiller: (Row) -> Bool) -> [Row] {
        guard var merged = screens.first else { return [] }
        for screen in screens.dropFirst() {
            if let link = overlap(merged, screen, isFiller: isFiller) {
                merged = Array(merged[..<link.keepFirst]) + screen[link.skipSecond...]
            } else if var first = screen.first {
                // No shared lines, so a few may be missing between these screenshots: start a new paragraph.
                first.startsParagraph = true
                merged.append(first)
                merged += screen.dropFirst()
            }
        }
        return merged
    }

    /// Finds where `second` picks up the end of `first`. Up to two rows at the top of `second` and at the bottom of
    /// `first` may differ, since a line cut in half by the screen edge reads as noise.
    func overlap(_ first: [Row], _ second: [Row], isFiller: (Row) -> Bool) -> Overlap? {
        var best: Overlap?
        for start in 0..<min(3, second.count) {
            for index in max(0, first.count - 80)..<first.count where similar(first[index], second[start]) {
                var run = 1
                while index + run < first.count, start + run < second.count, similar(first[index + run], second[start + run]) { run += 1 }
                guard run >= 2 || first[index].key.count >= 25, run > best?.run ?? 0 else { continue }
                if start + run == second.count {
                    best = Overlap(keepFirst: first.count, skipSecond: second.count, run: run)
                } else if first[(index + run)...].filter({ !isFiller($0) }).count <= 2 {
                    best = Overlap(keepFirst: index + run, skipSecond: start + run, run: run)
                }
            }
        }
        return best
    }

    func similar(_ first: Row, _ second: Row) -> Bool {
        if first.key == second.key { return true }
        let longer = max(first.key.count, second.key.count)
        guard longer >= 12, abs(first.key.count - second.key.count) <= longer / 8,
              first.key.prefix(3) == second.key.prefix(3) || first.key.suffix(3) == second.key.suffix(3) else { return false }
        return distance(first.key, second.key) <= longer / 8
    }

    func distance(_ lhs: String, _ rhs: String) -> Int {
        let first = Array(lhs), second = Array(rhs)
        var previous = Array(0...second.count)
        for (row, character) in first.enumerated() {
            var current = [row + 1] + Array(repeating: 0, count: second.count)
            for (column, other) in second.enumerated() {
                current[column + 1] = min(previous[column + 1] + 1, current[column] + 1, previous[column] + (character == other ? 0 : 1))
            }
            previous = current
        }
        return previous[second.count]
    }

    /// Rejoins wrapped lines. A paragraph ends at a list item, a line ending in a colon, a blank line, or a line that
    /// stops short of the right margin by more than the next line's first word.
    func paragraphs(_ rows: [Row]) -> [String] {
        guard let first = rows.first else { return [] }
        let right = percentile(rows.map(\.frame.maxX), 0.9)
        let width = max(right - percentile(rows.map(\.frame.minX), 0.1), 0.01)
        let lineHeight = percentile(rows.map(\.frame.height), 0.5)
        var paragraphs: [String] = []
        var current = first.text
        for (previous, row) in zip(rows, rows.dropFirst()) {
            let charWidth = previous.frame.width / CGFloat(max(previous.text.count, 1))
            let nextWord = CGFloat((row.text.split(separator: " ").first?.count ?? 0) + 1)
            let endsShort = right - previous.frame.maxX > charWidth * nextWord * 1.2 + width * 0.03
            let blankLine = row.page == previous.page && row.frame.minY - previous.frame.maxY > lineHeight * 0.9
            if row.startsParagraph || Self.isListItem(row.text) || previous.text.hasSuffix(":") || blankLine || endsShort {
                paragraphs.append(current)
                current = row.text
            } else {
                current += current.hasSuffix("-") && !current.hasSuffix(" -") ? row.text : " " + row.text
            }
        }
        paragraphs.append(current)
        return paragraphs
    }

    /// List items and the lines after a heading ending in a colon stay on consecutive lines; other paragraphs get a blank line between them.
    func text(of paragraphs: [String]) -> String {
        var text = ""
        for (index, paragraph) in paragraphs.enumerated() {
            if index > 0 { text += Self.isListItem(paragraph) || paragraphs[index - 1].hasSuffix(":") ? "\n" : "\n\n" }
            text += paragraph
        }
        return text
    }

    func percentile(_ values: [CGFloat], _ fraction: CGFloat) -> CGFloat {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        return sorted[min(sorted.count - 1, Int((CGFloat(sorted.count - 1) * fraction).rounded()))]
    }

    func linkedInExtraction(from rows: [Row]) -> JobCaptureExtraction {
        let start = rows.firstIndex { $0.key == "about the job" }
        let meta = rows.prefix(14).firstIndex { LinkedInVocabulary.isMeta($0) }
        let bodyStart = start.map { $0 + 1 } ?? meta.map { $0 + 1 } ?? 0
        let header = rows[..<(start ?? bodyStart)].compactMap { LinkedInVocabulary.content(of: $0) }
        var body = Array(rows[bodyStart...])
        // Without "About the job", the chips and buttons right below the post's details aren't description either.
        if start == nil, meta != nil { body = Array(body.drop { LinkedInVocabulary.content(of: $0) == nil || LinkedInVocabulary.jobTypes(in: $0.key) != nil }) }
        var isTruncated = false
        if let end = LinkedInVocabulary.end(of: body) {
            isTruncated = end.isTruncated
            body = Array(body[..<end.index])
        }
        let (title, company) = titleAndCompany(in: header)
        let repeated = Set([title, company].compactMap { $0.map { Self.key($0) } })
        body = body.compactMap { row -> Row? in
            // The navigation bar can show the title once the post scrolls under it.
            guard !(row.frame.minY < 0.15 && repeated.contains(row.key)), let row = LinkedInVocabulary.content(of: row) else { return nil }
            let trimmed = row.text.replacingOccurrences(of: LinkedInVocabulary.inlineMore, with: "", options: [.regularExpression, .caseInsensitive])
            guard trimmed != row.text else { return row }
            isTruncated = true
            return row.replacingText(trimmed)
        }
        let summary = [title, company, details(in: header, company: company)].compactMap { $0 }.joined(separator: "\n")
        let description = text(of: paragraphs(body))
        return JobCaptureExtraction(text: [summary, description].filter { !$0.isEmpty }.joined(separator: "\n\n"), title: title, company: company, isLinkedIn: true, isTruncated: isTruncated)
    }

    /// The title is the post's largest text (the row before the details line when sizes don't differ). The company sits
    /// just above it, or, in LinkedIn's older layout, leads the line below it ("Company · Location").
    func titleAndCompany(in rows: [Row]) -> (title: String?, company: String?) {
        let heights = rows.filter { !LinkedInVocabulary.isMeta($0) && LinkedInVocabulary.jobTypes(in: $0.key) == nil }.map(\.frame.height).sorted()
        let tallest = heights.last ?? 0
        var range: Range<Int>?
        if tallest > 0, tallest >= percentile(Array(heights.dropLast()), 0.5) * 1.2,
           let first = rows.firstIndex(where: { $0.frame.height >= tallest * 0.85 && !LinkedInVocabulary.isMeta($0) }) {
            var end = first + 1
            while end < rows.count, rows[end].frame.height >= tallest * 0.7, !LinkedInVocabulary.isMeta(rows[end]),
                  rows[end].frame.minY - rows[end - 1].frame.maxY < tallest * 0.6 { end += 1 }
            range = first..<end
        } else if let meta = rows.firstIndex(where: { LinkedInVocabulary.isMeta($0) }), meta > 0 {
            range = (meta - 1)..<meta
        }
        guard let range else { return (nil, nil) }
        let title = rows[range].map(\.text).joined(separator: " ")
        let isPlainLine: (Row) -> Bool = { !LinkedInVocabulary.isMeta($0) && LinkedInVocabulary.jobTypes(in: $0.key) == nil && $0.text.count <= 80 }
        if range.lowerBound > 0 {
            let above = rows[range.lowerBound - 1]
            // The logo sits to the left of the company name, so the name is the rightmost text on its row.
            if isPlainLine(above), above.page == rows[range.lowerBound].page, rows[range.lowerBound].frame.minY - above.frame.maxY < tallest * 1.5 {
                return (title, above.parts.last?.text.trimmingCharacters(in: .whitespaces) ?? above.text)
            }
        }
        guard range.upperBound < rows.count, isPlainLine(rows[range.upperBound]) else { return (title, nil) }
        let below = rows[range.upperBound].text
        return (title, below.components(separatedBy: LinkedInVocabulary.separators).first?.trimmingCharacters(in: .whitespaces) ?? below)
    }

    /// The location from the details line plus the workplace, job type, and level chips, such as "Manila · Hybrid · Full-time".
    func details(in rows: [Row], company: String?) -> String? {
        var items: [String] = []
        if let meta = rows.first(where: { LinkedInVocabulary.isMeta($0) }),
           let place = meta.text.components(separatedBy: LinkedInVocabulary.separators).map({ $0.trimmingCharacters(in: .whitespaces) }).first(where: { !$0.isEmpty && !LinkedInVocabulary.isMetaText(Self.key($0)) }),
           place != company {
            items.append(place)
        }
        for name in rows.compactMap({ LinkedInVocabulary.jobTypes(in: $0.key) }).joined() where !items.contains(name) { items.append(name) }
        return items.isEmpty ? nil : items.joined(separator: " · ")
    }
}

/// The words LinkedIn prints around a job post, compared as `JobScreenshotReader.key` values.
private enum LinkedInVocabulary {
    static let markers: Set<String> = ["about the job", "easy apply", "meet the hiring team", "set alert for similar jobs", "show match details", "job search faster with premium"]
    static let markerPattern = #"^(over )?\d[\d,]* applicants$|\b(promoted by hirer|actively reviewing applicants|responses managed off linkedin|people clicked apply)\b"#

    /// Buttons and badges, removed wherever they appear.
    static let controls: Set<String> = ["easy apply", "apply", "apply now", "applied", "save", "saved", "unsave", "share", "send", "show more", "see more", "show less", "see less", "show all", "see all", "message", "follow", "following", "connect", "promoted", "reposted", "premium", "show match details", "report this job", "set alert", "dismiss", "beta"]
    static let controlPattern = #"^(over )?\d[\d,]* (applicants?|people clicked apply)$|^(promoted by hirer|actively reviewing applicants|actively recruiting|responses managed off linkedin|be an early applicant|no longer accepting applications)|\b(try|retry) premium\b|\bwith premium\b|^see how you compare|^am i a good fit|^how can i best position myself|^tell me more about|^get ai powered|^\d[\d,]* (connections?|school alumni|alumni|employees?|followers?)( work| works)?( here)?$|^(your profile|your skills) (matches|is missing)|^\d+ of \d+ skills"#
    /// Tab bar and navigation bar labels, removed only near the top or bottom of a screenshot.
    static let barLabels: Set<String> = ["home", "video", "my network", "network", "notifications", "jobs", "post", "search", "messaging", "in", "linkedin", "back", "close", "done", "more", "sign in", "join now", "agree join"]

    /// Sections that follow the description.
    static let endMarkers: Set<String> = ["show less", "see less", "set alert for similar jobs", "job search faster with premium", "more jobs", "similar jobs", "people also viewed", "people you can reach out to", "looking for talent", "seniority level", "meet the hiring team", "company photos", "job activity", "show more jobs like this"]
    static let endPrefixes = ["referrals increase your chances", "get notified about new", "explore collaborative articles", "more jobs at ", "jobs you might be interested in"]
    /// LinkedIn separates details with a middle dot, which OCR sometimes reads as a bullet.
    static let separators = CharacterSet(charactersIn: "·•")
    static let moreLink = #"^(…|\.{3})\s*((see|show) )?more$"#
    static let inlineMore = #"\s*(…|\.{3})\s*((see|show) )?more$"#

    /// Workplace, job type, and level chips, longest first so "mid senior level" wins over shorter terms.
    static let jobTypeNames: [(key: String, name: String)] = [("mid senior level", "Mid-Senior level"), ("entry level", "Entry level"), ("internship", "Internship"), ("temporary", "Temporary"), ("full time", "Full-time"), ("part time", "Part-time"), ("volunteer", "Volunteer"), ("associate", "Associate"), ("executive", "Executive"), ("director", "Director"), ("contract", "Contract"), ("on site", "On-site"), ("onsite", "On-site"), ("remote", "Remote"), ("hybrid", "Hybrid")]

    static func isMarker(_ row: Row) -> Bool {
        markers.contains(row.key) || row.key.range(of: markerPattern, options: .regularExpression) != nil
    }

    /// The details line: location, how long ago it was posted, and how many applied.
    static func isMeta(_ row: Row) -> Bool { isMetaText(row.key) }

    static func isMetaText(_ key: String) -> Bool {
        key.range(of: #"\b\d+ (minute|hour|day|week|month|year)s? ago\b|\b\d[\d,]* (applicants?|people clicked apply)\b|\bearly applicant\b"#, options: .regularExpression) != nil
    }

    static func isControl(_ key: String, at midY: CGFloat) -> Bool {
        // Bars also carry badge counts, such as the number on Notifications.
        controls.contains(key) || key.range(of: controlPattern, options: .regularExpression) != nil
            || ((midY < 0.15 || midY > 0.88) && (barLabels.contains(key) || key.range(of: #"^\d{1,3}$"#, options: .regularExpression) != nil))
    }

    /// The row without LinkedIn's buttons and badges, or nil when nothing else is on it.
    static func content(of row: Row) -> Row? {
        Row(parts: row.parts.filter { !isControl(JobScreenshotReader.key($0.text), at: row.frame.midY) }, page: row.page, startsParagraph: row.startsParagraph)
    }

    /// The display names of the chips when a row holds only chips, such as ["On-site", "Full-time"].
    static func jobTypes(in key: String) -> [String]? {
        var rest = Substring(key)
        var names: [String] = []
        while !rest.isEmpty {
            guard let term = jobTypeNames.first(where: { rest.hasPrefix($0.key) && (rest.count == $0.key.count || rest.dropFirst($0.key.count).first == " ") }) else { return nil }
            names.append(term.name)
            rest = rest.dropFirst(term.key.count).drop { $0 == " " }
        }
        return names.isEmpty ? nil : names
    }

    /// Where the description ends: at "Show more" (still collapsed, so cut short), "Show less", or the next LinkedIn section.
    static func end(of body: [Row]) -> (index: Int, isTruncated: Bool)? {
        for (index, row) in body.enumerated() {
            if ["show more", "see more"].contains(row.key) || row.text.range(of: moreLink, options: [.regularExpression, .caseInsensitive]) != nil { return (index, true) }
            if endMarkers.contains(row.key) || endPrefixes.contains(where: { row.key.hasPrefix($0) }) { return (index, false) }
            // Employers also write "About the company", so only LinkedIn's own section, with its followers and size, ends the post.
            if row.key == "about the company", body[(index + 1)...].prefix(4).contains(where: { $0.key.range(of: #"\b(followers?|employees|on linkedin)\b|^follow$"#, options: .regularExpression) != nil }) {
                return (index, false)
            }
        }
        return nil
    }
}
