//
//  AttachmentNSTableView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 03/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import AppKit
import Quartz

/// Custom NSTableView that handles keyboard events and Quick Look panel control.
final class AttachmentNSTableView: NSTableView {
    weak var coordinator: AttachmentTableView.Coordinator?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == KeyCode.space {
            self.coordinator?.toggleQuickLook()
        } else if event.keyCode == KeyCode.delete, event.modifierFlags.contains(.command) {
            self.coordinator?.deleteSelected()
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: - Quick Look Panel Control

    override nonisolated func acceptsPreviewPanelControl(_: QLPreviewPanel!) -> Bool {
        true
    }

    override nonisolated func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        MainActor.assumeIsolated {
            panel.dataSource = self.coordinator
            panel.delegate = self.coordinator
        }
    }

    override nonisolated func endPreviewPanelControl(_: QLPreviewPanel!) {
        // Panel control ended
    }
}
