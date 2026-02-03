//
//  QuickLookController.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 03/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import AppKit
import DZFoundation
import Quartz
import SwiftUI

// MARK: - QuickLookController

/// A SwiftUI-compatible controller for displaying Quick Look previews using QLPreviewPanel.
struct QuickLookController: NSViewRepresentable {
    let urls: [URL]
    @Binding var selectedIndex: Int
    @Binding var isPresented: Bool

    func makeNSView(context: Context) -> QuickLookHostView {
        let view = QuickLookHostView()
        view.coordinator = context.coordinator
        context.coordinator.hostView = view
        return view
    }

    func updateNSView(_ nsView: QuickLookHostView, context: Context) {
        context.coordinator.urls = self.urls
        context.coordinator.selectedIndex = self.selectedIndex

        if self.isPresented {
            context.coordinator.showQuickLook(from: nsView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            urls: self.urls,
            selectedIndex: self.selectedIndex,
            onDismiss: { self.isPresented = false },
            onSelectionChanged: { self.selectedIndex = $0 }
        )
    }
}

// MARK: - QuickLookHostView

/// An NSView that can become first responder to control QLPreviewPanel.
final class QuickLookHostView: NSView {
    weak var coordinator: QuickLookController.Coordinator?

    override var acceptsFirstResponder: Bool { true }

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
        MainActor.assumeIsolated {
            self.coordinator?.handlePanelClosed()
        }
    }
}

// MARK: - Coordinator

extension QuickLookController {
    final class Coordinator: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
        var urls: [URL]
        var selectedIndex: Int
        var onDismiss: () -> Void
        var onSelectionChanged: (Int) -> Void
        weak var hostView: QuickLookHostView?
        private var isShowing = false

        init(
            urls: [URL],
            selectedIndex: Int,
            onDismiss: @escaping () -> Void,
            onSelectionChanged: @escaping (Int) -> Void
        ) {
            self.urls = urls
            self.selectedIndex = selectedIndex
            self.onDismiss = onDismiss
            self.onSelectionChanged = onSelectionChanged
            super.init()

            // Observe when the Quick Look panel closes
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.handleWindowWillClose(_:)),
                name: NSWindow.willCloseNotification,
                object: nil
            )
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        @objc
        private func handleWindowWillClose(_ notification: Notification) {
            if notification.object is QLPreviewPanel {
                self.handlePanelClosed()
            }
        }

        func showQuickLook(from view: NSView) {
            guard !self.urls.isEmpty, !self.isShowing else { return }

            self.isShowing = true

            // Make the host view first responder so the panel finds it
            view.window?.makeFirstResponder(view)

            let panel = QLPreviewPanel.shared()!

            // Update controller to use our view
            panel.updateController()

            // Set the data source and delegate directly as backup
            panel.dataSource = self
            panel.delegate = self

            // Set the index and reload
            panel.currentPreviewItemIndex = self.selectedIndex
            panel.reloadData()

            panel.makeKeyAndOrderFront(nil)
        }

        func handlePanelClosed() {
            guard self.isShowing else { return }
            self.isShowing = false
            self.onDismiss()
        }

        // MARK: - QLPreviewPanelDataSource

        func numberOfPreviewItems(in _: QLPreviewPanel!) -> Int {
            DZLog("Quick Look requesting item count: \(self.urls.count)")
            return self.urls.count
        }

        func previewPanel(_: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
            guard index >= 0, index < self.urls.count else {
                DZLog("Quick Look index out of bounds: \(index)")
                return nil
            }
            DZLog("Quick Look requesting item at \(index): \(self.urls[index])")
            return self.urls[index] as NSURL
        }

        // MARK: - QLPreviewPanelDelegate

        func previewPanel(_: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
            if event.type == .keyDown, event.keyCode == 53 { // Escape key
                return false // Let the panel handle escape to close
            }
            return false
        }
    }
}

// MARK: - View Extension

extension View {
    /// Presents a Quick Look preview panel for the specified file URLs.
    func quickLookPreview(urls: [URL], selectedIndex: Binding<Int>, isPresented: Binding<Bool>) -> some View {
        self.background(
            QuickLookController(
                urls: urls,
                selectedIndex: selectedIndex,
                isPresented: isPresented
            )
            .frame(width: 0, height: 0)
        )
    }
}
