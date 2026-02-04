//
//  AttachmentRowView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 03/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import AppKit

/// Custom row view with rounded background.
final class AttachmentRowView: NSTableRowView {
    override func drawSelection(in _: NSRect) {
        guard self.selectionHighlightStyle != .none else { return }

        let rect = self.bounds.insetBy(dx: 0, dy: 2)
        let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)

        NSColor.selectedContentBackgroundColor.setFill()
        path.fill()
    }

    override func drawBackground(in _: NSRect) {
        guard !self.isSelected else { return }

        let rect = self.bounds.insetBy(dx: 0, dy: 2)
        let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)

        NSColor.gray.withAlphaComponent(0.1).setFill()
        path.fill()
    }
}
