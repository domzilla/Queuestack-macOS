//
//  AttachmentTableView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 03/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import AppKit
import Carbon.HIToolbox
import DZFoundation
import Quartz
import SwiftUI

// MARK: - AttachmentTableView

struct AttachmentTableView: NSViewRepresentable {
    private static let columnIdentifier = NSUserInterfaceItemIdentifier("attachment")
    private static let cellIdentifier = NSUserInterfaceItemIdentifier("AttachmentCell")

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

        let column = NSTableColumn(identifier: Self.columnIdentifier)
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
        private var currentPreviewURL: URL?

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
            attachment.hasPrefix(CLIConstants.FileConventions.URLScheme.http)
                || attachment.hasPrefix(CLIConstants.FileConventions.URLScheme.https)
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

        // MARK: - Actions

        /// Toggles Quick Look panel for the given row, or the selected row if nil.
        func toggleQuickLook(forRow row: Int? = nil) {
            let targetRow = row ?? self.tableView?.selectedRow ?? -1
            guard targetRow >= 0, targetRow < self.attachments.count else { return }

            let attachment = self.attachments[targetRow]
            guard self.canQuickLook(attachment) else { return }

            // If panel is visible, close it
            if QLPreviewPanel.sharedPreviewPanelExists(), QLPreviewPanel.shared()!.isVisible {
                QLPreviewPanel.shared()!.orderOut(nil)
                return
            }

            // Select the row
            self.tableView?.selectRowIndexes(IndexSet(integer: targetRow), byExtendingSelection: false)

            // Make table view first responder so panel finds it via responder chain
            if let tableView = self.tableView {
                tableView.window?.makeFirstResponder(tableView)
            }

            let panel = QLPreviewPanel.shared()!

            // Ensure we're the data source
            panel.dataSource = self
            panel.delegate = self

            // Set the single preview item (Finder-like behavior)
            self.currentPreviewURL = self.attachmentURL(for: attachment)

            // Reload and show
            panel.reloadData()
            panel.makeKeyAndOrderFront(nil)
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
            let attachment = self.attachments[row]

            let cellView: AttachmentCellView
            if
                let reused = tableView.makeView(withIdentifier: AttachmentTableView.cellIdentifier, owner: self)
                as? AttachmentCellView
            {
                cellView = reused
            } else {
                cellView = AttachmentCellView()
                cellView.identifier = AttachmentTableView.cellIdentifier
            }

            cellView.textField?.stringValue = self.displayName(for: attachment)
            cellView.eyeButton.isHidden = !self.canQuickLook(attachment)
            cellView.eyeButton.tag = row
            cellView.eyeButton.target = self
            cellView.eyeButton.action = #selector(self.eyeButtonClicked(_:))

            return cellView
        }

        @objc
        func eyeButtonClicked(_ sender: NSButton) {
            self.toggleQuickLook(forRow: sender.tag)
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
                    // Update the single preview item and reload (Finder-like behavior)
                    self.currentPreviewURL = self.attachmentURL(for: attachment)
                    QLPreviewPanel.shared()!.reloadData()
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
            // Return single item like Finder does - this removes navigation arrows
            // and triggers proper resize when selection changes
            self.currentPreviewURL != nil ? 1 : 0
        }

        func previewPanel(_: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
            guard index == 0, let url = self.currentPreviewURL else { return nil }
            return url as NSURL
        }

        // MARK: - QLPreviewPanelDelegate

        func previewPanel(_: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
            if event.type == .keyDown {
                // Let arrow keys propagate to table view to change selection
                if event.keyCode == UInt16(kVK_DownArrow) || event.keyCode == UInt16(kVK_UpArrow) {
                    self.tableView?.keyDown(with: event)
                    return true
                }
            }
            return false
        }
    }
}
