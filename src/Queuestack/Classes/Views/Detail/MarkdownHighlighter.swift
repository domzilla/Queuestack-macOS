//
//  MarkdownHighlighter.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 01/03/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import AppKit

final class MarkdownHighlighter: NSObject, NSTextStorageDelegate {
    // MARK: - Fonts

    private let baseFont: NSFont
    private let boldFont: NSFont
    private let italicFont: NSFont
    private let boldItalicFont: NSFont

    // MARK: - Regex Patterns

    private let headingPattern: NSRegularExpression
    private let boldItalicPattern: NSRegularExpression
    private let boldPattern: NSRegularExpression
    private let italicPattern: NSRegularExpression
    private let inlineCodePattern: NSRegularExpression
    private let fencedCodePattern: NSRegularExpression
    private let unorderedListPattern: NSRegularExpression
    private let orderedListPattern: NSRegularExpression
    private let blockquotePattern: NSRegularExpression
    private let linkPattern: NSRegularExpression

    // MARK: - Initialization

    override init() {
        let size = NSFont.systemFontSize
        self.baseFont = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        self.boldFont = NSFont.monospacedSystemFont(ofSize: size, weight: .bold)
        self.italicFont = NSFontManager.shared.convert(self.baseFont, toHaveTrait: .italicFontMask)
        self.boldItalicFont = NSFontManager.shared.convert(self.boldFont, toHaveTrait: .italicFontMask)

        // swiftlint:disable force_try
        self.headingPattern = try! NSRegularExpression(pattern: "^(#{1,6})\\s+(.+)$", options: .anchorsMatchLines)
        self.boldItalicPattern = try! NSRegularExpression(pattern: "\\*{3}(.+?)\\*{3}", options: [])
        self.boldPattern = try! NSRegularExpression(pattern: "\\*{2}(.+?)\\*{2}", options: [])
        self.italicPattern = try! NSRegularExpression(pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)", options: [])
        self.inlineCodePattern = try! NSRegularExpression(pattern: "(?<!`)`(?!`)(.+?)(?<!`)`(?!`)", options: [])
        self.fencedCodePattern = try! NSRegularExpression(
            pattern: "^```.*$\\n([\\s\\S]*?)^```\\s*$",
            options: .anchorsMatchLines
        )
        self.unorderedListPattern = try! NSRegularExpression(
            pattern: "^(\\s*[\\-\\*\\+])\\s",
            options: .anchorsMatchLines
        )
        self.orderedListPattern = try! NSRegularExpression(pattern: "^(\\s*\\d+\\.)\\s", options: .anchorsMatchLines)
        self.blockquotePattern = try! NSRegularExpression(pattern: "^(>+)\\s?(.*)$", options: .anchorsMatchLines)
        self.linkPattern = try! NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)", options: [])
        // swiftlint:enable force_try

        super.init()
    }

    // MARK: - NSTextStorageDelegate

    func textStorage(
        _ textStorage: NSTextStorage,
        didProcessEditing editedMask: NSTextStorageEditActions,
        range _: NSRange,
        changeInLength _: Int
    ) {
        guard editedMask.contains(.editedCharacters) else { return }

        self.highlightAll(in: textStorage)
    }

    // MARK: - Highlighting

    private func highlightAll(in textStorage: NSTextStorage) {
        let fullRange = NSRange(location: 0, length: textStorage.length)
        let text = textStorage.string

        // Batch all attribute changes so the layout manager recalculates only once
        // (without this, each addAttribute triggers a separate layout pass,
        //  and the intermediate "all-baseFont" layout causes visible flicker on word breaks)
        textStorage.beginEditing()

        // Reset to defaults
        textStorage.addAttribute(.font, value: self.baseFont, range: fullRange)
        textStorage.addAttribute(.foregroundColor, value: NSColor.SyntaxHighlighting.text, range: fullRange)
        textStorage.removeAttribute(.underlineStyle, range: fullRange)

        // Fenced code blocks first (so inline patterns don't match inside them)
        var fencedRanges: [NSRange] = []
        self.fencedCodePattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match else { return }
            fencedRanges.append(match.range)
            // Apply monospace font to the content inside fences
            if match.numberOfRanges > 1 {
                let contentRange = match.range(at: 1)
                textStorage.addAttribute(.font, value: self.baseFont, range: contentRange)
            }
        }

        // Headings
        self.headingPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match, !self.isInsideFencedCode(match.range, fencedRanges: fencedRanges) else { return }
            textStorage.addAttribute(.foregroundColor, value: NSColor.SyntaxHighlighting.heading, range: match.range)
            textStorage.addAttribute(.font, value: self.boldFont, range: match.range)
        }

        // Bold italic (before bold and italic to take precedence)
        self.boldItalicPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match, !self.isInsideFencedCode(match.range, fencedRanges: fencedRanges) else { return }
            textStorage.addAttribute(.foregroundColor, value: NSColor.SyntaxHighlighting.bold, range: match.range)
            textStorage.addAttribute(.font, value: self.boldItalicFont, range: match.range)
        }

        // Bold
        self.boldPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match, !self.isInsideFencedCode(match.range, fencedRanges: fencedRanges) else { return }
            textStorage.addAttribute(.foregroundColor, value: NSColor.SyntaxHighlighting.bold, range: match.range)
            textStorage.addAttribute(.font, value: self.boldFont, range: match.range)
        }

        // Italic
        self.italicPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match, !self.isInsideFencedCode(match.range, fencedRanges: fencedRanges) else { return }
            textStorage.addAttribute(.foregroundColor, value: NSColor.SyntaxHighlighting.italic, range: match.range)
            textStorage.addAttribute(.font, value: self.italicFont, range: match.range)
        }

        // Inline code
        self.inlineCodePattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match, !self.isInsideFencedCode(match.range, fencedRanges: fencedRanges) else { return }
            textStorage.addAttribute(.foregroundColor, value: NSColor.SyntaxHighlighting.inlineCode, range: match.range)
            textStorage.addAttribute(.font, value: self.baseFont, range: match.range)
        }

        // Unordered list markers
        self.unorderedListPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match, !self.isInsideFencedCode(match.range, fencedRanges: fencedRanges) else { return }
            let markerRange = match.range(at: 1)
            textStorage.addAttribute(.foregroundColor, value: NSColor.SyntaxHighlighting.listMarker, range: markerRange)
        }

        // Ordered list markers
        self.orderedListPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match, !self.isInsideFencedCode(match.range, fencedRanges: fencedRanges) else { return }
            let markerRange = match.range(at: 1)
            textStorage.addAttribute(.foregroundColor, value: NSColor.SyntaxHighlighting.listMarker, range: markerRange)
        }

        // Blockquotes
        self.blockquotePattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match, !self.isInsideFencedCode(match.range, fencedRanges: fencedRanges) else { return }
            textStorage.addAttribute(.foregroundColor, value: NSColor.SyntaxHighlighting.blockquote, range: match.range)
            textStorage.addAttribute(.font, value: self.italicFont, range: match.range)
        }

        // Links — color only the URL part
        self.linkPattern.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match, !self.isInsideFencedCode(match.range, fencedRanges: fencedRanges) else { return }
            if match.numberOfRanges > 2 {
                let urlRange = match.range(at: 2)
                textStorage.addAttribute(.foregroundColor, value: NSColor.SyntaxHighlighting.linkURL, range: urlRange)
                textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: urlRange)
            }
        }

        textStorage.endEditing()
    }

    // MARK: - Helpers

    private func isInsideFencedCode(_ range: NSRange, fencedRanges: [NSRange]) -> Bool {
        for fenced in fencedRanges {
            if NSIntersectionRange(fenced, range).length > 0 {
                return true
            }
        }
        return false
    }
}
