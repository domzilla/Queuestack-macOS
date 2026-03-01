//
//  NSColor+SyntaxHighlighting.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 01/03/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import AppKit

extension NSColor {
    enum SyntaxHighlighting {
        static let heading = NSColor.systemPurple
        static let bold = NSColor.systemOrange
        static let italic = NSColor.systemYellow
        static let inlineCode = NSColor.systemGreen
        static let codeBlock = NSColor.labelColor
        static let listMarker = NSColor.systemCyan
        static let linkURL = NSColor.systemPink
        static let linkText = NSColor.labelColor
        static let blockquote = NSColor.labelColor
        static let text = NSColor.labelColor
    }
}
