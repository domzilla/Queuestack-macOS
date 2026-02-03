//
//  AttachmentTableView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 03/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import AppKit
import DZFoundation
import Quartz
import SwiftUI

// MARK: - AttachmentTableView

struct AttachmentTableView: NSViewRepresentable {
    let attachments: [String]
    let attachmentsDirectoryURL: URL
    let onOpen: (Int) -> Void
    let onDelete: (Set<Int>) -> Void
    let onRevealInFinder: (Int) -> Void
    let onCopyPath: (Int) -> Void
    let onFilesDropped: ([URL]) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        let tableView = AttachmentNSTableView()
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.style = .plain
        tableView.rowHeight = 24
        tableView.intercellSpacing = NSSize(width: 0, height: 4)
        tableView.allowsMultipleSelection = true
        tableView.allowsEmptySelection = true
        tableView.usesAlternatingRowBackgroundColors = false

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("attachment"))
        column.isEditable = false
        tableView.addTableColumn(column)

        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        tableView.coordinator = context.coordinator
        tableView.doubleAction = #selector(Coordinator.tableViewDoubleClick(_:))
        tableView.target = context.coordinator

        // Register for drag types
        tableView.registerForDraggedTypes([.fileURL])
        tableView.setDraggingSourceOperationMask(.copy, forLocal: false)

        // Context menu
        let menu = NSMenu()
        menu.delegate = context.coordinator
        tableView.menu = menu

        scrollView.documentView = tableView
        context.coordinator.tableView = tableView

        return scrollView
    }

    func updateNSView(_: NSScrollView, context: Context) {
        context.coordinator.attachments = self.attachments
        context.coordinator.attachmentsDirectoryURL = self.attachmentsDirectoryURL
        context.coordinator.onOpen = self.onOpen
        context.coordinator.onDelete = self.onDelete
        context.coordinator.onRevealInFinder = self.onRevealInFinder
        context.coordinator.onCopyPath = self.onCopyPath
        context.coordinator.onFilesDropped = self.onFilesDropped

        context.coordinator.tableView?.reloadData()

        // Update Quick Look panel if showing
        if QLPreviewPanel.sharedPreviewPanelExists(), QLPreviewPanel.shared()!.isVisible {
            QLPreviewPanel.shared()!.reloadData()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            attachments: self.attachments,
            attachmentsDirectoryURL: self.attachmentsDirectoryURL,
            onOpen: self.onOpen,
            onDelete: self.onDelete,
            onRevealInFinder: self.onRevealInFinder,
            onCopyPath: self.onCopyPath,
            onFilesDropped: self.onFilesDropped
        )
    }
}

// MARK: - Custom NSTableView

/// Custom NSTableView that handles keyboard events and Quick Look panel control.
final class AttachmentNSTableView: NSTableView {
    weak var coordinator: AttachmentTableView.Coordinator?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 { // Space bar
            self.coordinator?.toggleQuickLook()
        } else if event.keyCode == 51, event.modifierFlags.contains(.command) { // Cmd+Delete
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

// MARK: - Coordinator

extension AttachmentTableView {
    final class Coordinator: NSObject,
        NSTableViewDataSource,
        NSTableViewDelegate,
        NSMenuDelegate,
        QLPreviewPanelDataSource,
        QLPreviewPanelDelegate
    {
        var attachments: [String]
        var attachmentsDirectoryURL: URL
        var onOpen: (Int) -> Void
        var onDelete: (Set<Int>) -> Void
        var onRevealInFinder: (Int) -> Void
        var onCopyPath: (Int) -> Void
        var onFilesDropped: ([URL]) -> Void
        weak var tableView: AttachmentNSTableView?

        private var clickedRow: Int = -1

        init(
            attachments: [String],
            attachmentsDirectoryURL: URL,
            onOpen: @escaping (Int) -> Void,
            onDelete: @escaping (Set<Int>) -> Void,
            onRevealInFinder: @escaping (Int) -> Void,
            onCopyPath: @escaping (Int) -> Void,
            onFilesDropped: @escaping ([URL]) -> Void
        ) {
            self.attachments = attachments
            self.attachmentsDirectoryURL = attachmentsDirectoryURL
            self.onOpen = onOpen
            self.onDelete = onDelete
            self.onRevealInFinder = onRevealInFinder
            self.onCopyPath = onCopyPath
            self.onFilesDropped = onFilesDropped
        }

        // MARK: - Helpers

        private func isURL(_ attachment: String) -> Bool {
            attachment.hasPrefix("http://") || attachment.hasPrefix("https://")
        }

        private func attachmentURL(for attachment: String) -> URL {
            self.attachmentsDirectoryURL.appendingPathComponent(attachment)
        }

        private func displayName(for attachment: String) -> String {
            if self.isURL(attachment) {
                return attachment
            }
            return URL(filePath: attachment).lastPathComponent
        }

        private func canQuickLook(_ attachment: String) -> Bool {
            guard !self.isURL(attachment) else { return false }
            let url = self.attachmentURL(for: attachment)
            return FileManager.default.fileExists(atPath: url.path)
        }

        /// Returns file URLs for previewable attachments (files only, not web URLs).
        private var previewableURLs: [URL] {
            self.attachments.compactMap { attachment in
                guard self.canQuickLook(attachment) else { return nil }
                return self.attachmentURL(for: attachment)
            }
        }

        // MARK: - Actions

        func toggleQuickLook() {
            guard let tableView, tableView.selectedRow >= 0 else { return }

            if QLPreviewPanel.sharedPreviewPanelExists(), QLPreviewPanel.shared()!.isVisible {
                QLPreviewPanel.shared()!.orderOut(nil)
            } else {
                QLPreviewPanel.shared()!.makeKeyAndOrderFront(nil)
            }
        }

        func deleteSelected() {
            guard let tableView else { return }
            let indices = Set(tableView.selectedRowIndexes.map(\.self))
            guard !indices.isEmpty else { return }
            self.onDelete(indices)
        }

        // MARK: - NSTableViewDataSource

        func numberOfRows(in _: NSTableView) -> Int {
            self.attachments.count
        }

        // MARK: - NSTableViewDelegate

        func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
            let identifier = NSUserInterfaceItemIdentifier("AttachmentCell")
            let attachment = self.attachments[row]

            let cellView: NSTableCellView
            if let reused = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
                cellView = reused
            } else {
                cellView = NSTableCellView()
                cellView.identifier = identifier

                let textField = NSTextField(labelWithString: "")
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.lineBreakMode = .byTruncatingMiddle
                textField.cell?.truncatesLastVisibleLine = true
                cellView.addSubview(textField)
                cellView.textField = textField

                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 8),
                    textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -8),
                    textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                ])
            }

            cellView.textField?.stringValue = self.displayName(for: attachment)

            return cellView
        }

        func tableView(_: NSTableView, rowViewForRow _: Int) -> NSTableRowView? {
            AttachmentRowView()
        }

        func tableViewSelectionDidChange(_: Notification) {
            // Update Quick Look panel if visible
            if QLPreviewPanel.sharedPreviewPanelExists(), QLPreviewPanel.shared()!.isVisible {
                guard let tableView, tableView.selectedRow >= 0 else { return }

                let attachment = self.attachments[tableView.selectedRow]
                if self.canQuickLook(attachment) {
                    let url = self.attachmentURL(for: attachment)
                    if let index = self.previewableURLs.firstIndex(of: url) {
                        QLPreviewPanel.shared()!.currentPreviewItemIndex = index
                    }
                }
            }
        }

        func tableView(_: NSTableView, shouldSelectRow row: Int) -> Bool {
            row >= 0 && row < self.attachments.count
        }

        // MARK: - Double Click

        @objc
        func tableViewDoubleClick(_ sender: NSTableView) {
            let row = sender.clickedRow
            guard row >= 0 else { return }
            self.onOpen(row)
        }

        // MARK: - Drag and Drop

        func tableView(
            _: NSTableView,
            validateDrop info: any NSDraggingInfo,
            proposedRow _: Int,
            proposedDropOperation _: NSTableView.DropOperation
        )
            -> NSDragOperation
        {
            if info.draggingPasteboard.types?.contains(.fileURL) == true {
                return .copy
            }
            return []
        }

        func tableView(
            _: NSTableView,
            acceptDrop info: any NSDraggingInfo,
            row _: Int,
            dropOperation _: NSTableView.DropOperation
        )
            -> Bool
        {
            guard let items = info.draggingPasteboard.pasteboardItems else { return false }

            var urls: [URL] = []
            for item in items {
                if
                    let urlString = item.string(forType: .fileURL),
                    let url = URL(string: urlString),
                    url.isFileURL
                {
                    urls.append(url)
                }
            }

            guard !urls.isEmpty else { return false }
            self.onFilesDropped(urls)
            return true
        }

        // MARK: - NSMenuDelegate

        func menuNeedsUpdate(_ menu: NSMenu) {
            menu.removeAllItems()

            guard let tableView else { return }
            self.clickedRow = tableView.clickedRow

            guard self.clickedRow >= 0, self.clickedRow < self.attachments.count else { return }

            let attachment = self.attachments[self.clickedRow]
            let isURL = self.isURL(attachment)

            if !isURL {
                let revealItem = NSMenuItem(
                    title: String(localized: "Show in Finder", comment: "Context menu"),
                    action: #selector(self.revealInFinderAction(_:)),
                    keyEquivalent: ""
                )
                revealItem.target = self
                menu.addItem(revealItem)
            }

            let copyItem = NSMenuItem(
                title: isURL
                    ? String(localized: "Copy URL", comment: "Context menu")
                    : String(localized: "Copy File Path", comment: "Context menu"),
                action: #selector(self.copyPathAction(_:)),
                keyEquivalent: ""
            )
            copyItem.target = self
            menu.addItem(copyItem)

            menu.addItem(NSMenuItem.separator())

            let selectedCount = tableView.selectedRowIndexes.count
            let deleteTitle = if tableView.selectedRowIndexes.contains(self.clickedRow), selectedCount > 1 {
                String(
                    localized: "Delete \(selectedCount) Items",
                    comment: "Context menu item to delete multiple attachments"
                )
            } else {
                String(localized: "Delete", comment: "Context menu")
            }

            let deleteItem = NSMenuItem(
                title: deleteTitle,
                action: #selector(self.deleteAction(_:)),
                keyEquivalent: ""
            )
            deleteItem.target = self
            menu.addItem(deleteItem)
        }

        @objc
        private func revealInFinderAction(_: Any?) {
            guard self.clickedRow >= 0 else { return }
            self.onRevealInFinder(self.clickedRow)
        }

        @objc
        private func copyPathAction(_: Any?) {
            guard self.clickedRow >= 0 else { return }
            self.onCopyPath(self.clickedRow)
        }

        @objc
        private func deleteAction(_: Any?) {
            guard let tableView, self.clickedRow >= 0 else { return }

            let indices: Set<Int> = if
                tableView.selectedRowIndexes.contains(self.clickedRow),
                tableView.selectedRowIndexes.count > 1
            {
                Set(tableView.selectedRowIndexes.map(\.self))
            } else {
                [self.clickedRow]
            }

            self.onDelete(indices)
        }

        // MARK: - QLPreviewPanelDataSource

        func numberOfPreviewItems(in _: QLPreviewPanel!) -> Int {
            self.previewableURLs.count
        }

        func previewPanel(_: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
            guard index >= 0, index < self.previewableURLs.count else { return nil }
            return self.previewableURLs[index] as NSURL
        }

        // MARK: - QLPreviewPanelDelegate

        func previewPanel(_: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
            if event.type == .keyDown {
                // Let arrow keys propagate to table view to change selection
                if event.keyCode == 125 || event.keyCode == 126 { // Down/Up arrows
                    self.tableView?.keyDown(with: event)
                    return true
                }
            }
            return false
        }
    }
}

// MARK: - AttachmentRowView

/// Custom row view with rounded background.
private final class AttachmentRowView: NSTableRowView {
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
