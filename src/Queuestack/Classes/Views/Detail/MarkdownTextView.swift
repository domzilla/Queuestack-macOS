//
//  MarkdownTextView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 01/03/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import AppKit
import SwiftUI

// MARK: - NSTextView Subclass

/// Custom `NSTextView` that intercepts Cmd+S to trigger a save action.
final class MarkdownNSTextView: NSTextView {
    var onSave: (() -> Void)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "s" {
            self.onSave?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

// MARK: - NSViewRepresentable

struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    var onSave: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        let textView = MarkdownNSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.textColor = .labelColor
        textView.drawsBackground = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 4, height: 8)
        textView.textContainer?.widthTracksTextView = true
        textView.onSave = self.onSave

        // Attach the markdown highlighter
        textView.textStorage?.delegate = context.coordinator.highlighter

        // Set initial text
        textView.string = self.text
        context.coordinator.textView = textView

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? MarkdownNSTextView else { return }

        // Update save closure in case it changed
        textView.onSave = self.onSave

        // Only push external changes (avoid loop from our own textDidChange)
        if !context.coordinator.isUpdating, textView.string != self.text {
            context.coordinator.isUpdating = true
            textView.string = self.text
            if let textStorage = textView.textStorage {
                let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                let fullRange = NSRange(location: 0, length: textStorage.length)
                textStorage.addAttribute(
                    .font,
                    value: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                    range: fullRange
                )
                textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
                if isDarkMode {
                    textStorage.delegate?.textStorage?(
                        textStorage,
                        didProcessEditing: .editedCharacters,
                        range: fullRange,
                        changeInLength: 0
                    )
                }
            }
            context.coordinator.isUpdating = false
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        let parent: MarkdownTextView
        let highlighter = MarkdownHighlighter()
        var isUpdating = false
        weak var textView: MarkdownNSTextView?

        init(_ parent: MarkdownTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !self.isUpdating else { return }
            guard let textView = notification.object as? NSTextView else { return }

            self.isUpdating = true
            self.parent.text = textView.string
            self.isUpdating = false
        }
    }
}
