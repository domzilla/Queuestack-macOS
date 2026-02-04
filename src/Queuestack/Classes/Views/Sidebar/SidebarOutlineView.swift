//
//  SidebarOutlineView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 01/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - SidebarOutlineView

struct SidebarOutlineView: NSViewRepresentable {
    private static let columnIdentifier = NSUserInterfaceItemIdentifier("main")
    private static let cellIdentifier = NSUserInterfaceItemIdentifier("SidebarCell")

    @Bindable var settings: SettingsManager
    @Binding var selectedProjectID: UUID?
    let onAddProject: (UUID?) -> Void
    let onAddGroup: (UUID?) -> Void
    let onProjectAddError: (Error) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        let outlineView = NSOutlineView()
        outlineView.headerView = nil
        outlineView.style = .sourceList
        outlineView.rowSizeStyle = .default
        outlineView.indentationPerLevel = 14
        outlineView.allowsMultipleSelection = false
        outlineView.allowsEmptySelection = true

        let column = NSTableColumn(identifier: Self.columnIdentifier)
        column.isEditable = true
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column

        outlineView.dataSource = context.coordinator
        outlineView.delegate = context.coordinator

        // Register for drag types
        outlineView.registerForDraggedTypes([.sidebarNode, .fileURL])
        outlineView.setDraggingSourceOperationMask(.move, forLocal: true)
        outlineView.setDraggingSourceOperationMask(.copy, forLocal: false)

        // Context menu
        let menu = NSMenu()
        menu.delegate = context.coordinator

        let revealItem = NSMenuItem(
            title: String(localized: "Reveal in Finder", comment: "Context menu"),
            action: #selector(Coordinator.revealInFinder(_:)),
            keyEquivalent: ""
        )
        revealItem.target = context.coordinator
        menu.addItem(revealItem)

        menu.addItem(NSMenuItem.separator())

        let renameItem = NSMenuItem(
            title: String(localized: "Rename", comment: "Context menu"),
            action: #selector(Coordinator.renameItem(_:)),
            keyEquivalent: ""
        )
        renameItem.target = context.coordinator
        menu.addItem(renameItem)

        let removeItem = NSMenuItem(
            title: String(localized: "Remove", comment: "Context menu"),
            action: #selector(Coordinator.removeItem(_:)),
            keyEquivalent: ""
        )
        removeItem.target = context.coordinator
        menu.addItem(removeItem)

        outlineView.menu = menu

        scrollView.documentView = outlineView
        context.coordinator.outlineView = outlineView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let outlineView = scrollView.documentView as? NSOutlineView else { return }

        context.coordinator.settings = self.settings
        context.coordinator.selectedProjectID = self.selectedProjectID
        context.coordinator.onAddProject = self.onAddProject
        context.coordinator.onAddGroup = self.onAddGroup
        context.coordinator.onProjectAddError = self.onProjectAddError

        // End any active editing before reloading to ensure changes are committed
        outlineView.window?.endEditing(for: nil)

        // Reload data and restore expansion state
        outlineView.reloadData()
        context.coordinator.restoreExpansionState()
        context.coordinator.syncSelection()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            settings: self.settings,
            selectedProjectID: self.selectedProjectID,
            onSelectionChanged: { id in self.selectedProjectID = id },
            onAddProject: self.onAddProject,
            onAddGroup: self.onAddGroup,
            onProjectAddError: self.onProjectAddError
        )
    }
}

// MARK: - Coordinator

extension SidebarOutlineView {
    final class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, NSMenuDelegate,
        NSTextFieldDelegate
    {
        var settings: SettingsManager
        var selectedProjectID: UUID?
        var onSelectionChanged: (UUID?) -> Void
        var onAddProject: (UUID?) -> Void
        var onAddGroup: (UUID?) -> Void
        var onProjectAddError: (Error) -> Void
        weak var outlineView: NSOutlineView?

        private var isUpdatingSelection = false
        private var clickedNode: SidebarNode?

        init(
            settings: SettingsManager,
            selectedProjectID: UUID?,
            onSelectionChanged: @escaping (UUID?) -> Void,
            onAddProject: @escaping (UUID?) -> Void,
            onAddGroup: @escaping (UUID?) -> Void,
            onProjectAddError: @escaping (Error) -> Void
        ) {
            self.settings = settings
            self.selectedProjectID = selectedProjectID
            self.onSelectionChanged = onSelectionChanged
            self.onAddProject = onAddProject
            self.onAddGroup = onAddGroup
            self.onProjectAddError = onProjectAddError
        }

        // MARK: - Data Source

        func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
            if item == nil {
                return self.settings.sidebarTree.count
            }
            if let node = item as? SidebarNode, case let .group(group) = node {
                return group.children.count
            }
            return 0
        }

        func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
            if item == nil {
                return self.settings.sidebarTree[index]
            }
            if let node = item as? SidebarNode, case let .group(group) = node {
                return group.children[index]
            }
            fatalError("Invalid item")
        }

        func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
            if let node = item as? SidebarNode {
                return node.isGroup
            }
            return false
        }

        // MARK: - Delegate

        func outlineView(_ outlineView: NSOutlineView, viewFor _: NSTableColumn?, item: Any) -> NSView? {
            guard let node = item as? SidebarNode else { return nil }

            let cellView: NSTableCellView
            if
                let reused = outlineView.makeView(withIdentifier: SidebarOutlineView.cellIdentifier, owner: self)
                as? NSTableCellView
            {
                cellView = reused
            } else {
                cellView = NSTableCellView()
                cellView.identifier = SidebarOutlineView.cellIdentifier

                let imageView = NSImageView()
                imageView.translatesAutoresizingMaskIntoConstraints = false
                cellView.addSubview(imageView)
                cellView.imageView = imageView

                let textField = NSTextField()
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.lineBreakMode = .byTruncatingTail
                textField.isBordered = false
                textField.drawsBackground = false
                textField.isEditable = true
                textField.delegate = self
                cellView.addSubview(textField)
                cellView.textField = textField

                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor),
                    imageView.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: 18),
                    imageView.heightAnchor.constraint(equalToConstant: 18),
                    textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 4),
                    textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor),
                    textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor),
                ])
            }

            // Store node ID for retrieval during editing
            cellView.objectValue = node.id

            switch node {
            case let .group(group):
                cellView.textField?.stringValue = group.name
                cellView.textField?.isEditable = true
                cellView.imageView?.image = NSImage(systemSymbolName: "archivebox", accessibilityDescription: nil)
            case let .project(project):
                cellView.textField?.stringValue = project.name
                cellView.textField?.isEditable = false
                cellView.imageView?.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
            }

            return cellView
        }

        func outlineView(_: NSOutlineView, shouldSelectItem item: Any) -> Bool {
            guard let node = item as? SidebarNode else { return false }
            return node.isProject
        }

        func outlineViewSelectionDidChange(_ notification: Notification) {
            guard !self.isUpdatingSelection else { return }
            guard let outlineView = notification.object as? NSOutlineView else { return }

            let selectedRow = outlineView.selectedRow
            if selectedRow >= 0, let node = outlineView.item(atRow: selectedRow) as? SidebarNode {
                self.onSelectionChanged(node.project?.id)
            } else {
                self.onSelectionChanged(nil)
            }
        }

        func outlineViewItemDidExpand(_ notification: Notification) {
            guard
                let node = notification.userInfo?["NSObject"] as? SidebarNode,
                let group = node.group else { return }
            Task { @MainActor in
                self.settings.setGroupExpanded(true, forGroupWithID: group.id)
            }
        }

        func outlineViewItemDidCollapse(_ notification: Notification) {
            guard
                let node = notification.userInfo?["NSObject"] as? SidebarNode,
                let group = node.group else { return }
            Task { @MainActor in
                self.settings.setGroupExpanded(false, forGroupWithID: group.id)
            }
        }

        // MARK: - Drag Source

        func outlineView(_: NSOutlineView, pasteboardWriterForItem item: Any) -> (any NSPasteboardWriting)? {
            guard let node = item as? SidebarNode else { return nil }

            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setString(node.id.uuidString, forType: .sidebarNode)
            return pasteboardItem
        }

        // MARK: - Drop Destination

        func outlineView(
            _: NSOutlineView,
            validateDrop info: any NSDraggingInfo,
            proposedItem item: Any?,
            proposedChildIndex _: Int
        )
            -> NSDragOperation
        {
            let pasteboard = info.draggingPasteboard

            // Internal node move
            if
                let uuidString = pasteboard.string(forType: .sidebarNode),
                let draggedID = UUID(uuidString: uuidString)
            {
                // Can't drop on self
                if let targetNode = item as? SidebarNode, targetNode.id == draggedID {
                    return []
                }

                // Can't drop group into its own descendants
                if let targetNode = item as? SidebarNode {
                    if self.settings.sidebarTree.isAncestor(draggedID, of: targetNode.id) {
                        return []
                    }
                }

                // Must drop into a group or at root
                if item == nil || (item as? SidebarNode)?.isGroup == true {
                    return .move
                }

                return []
            }

            // External file drop
            if pasteboard.types?.contains(.fileURL) == true {
                if item == nil || (item as? SidebarNode)?.isGroup == true {
                    return .copy
                }
            }

            return []
        }

        func outlineView(
            _: NSOutlineView,
            acceptDrop info: any NSDraggingInfo,
            item: Any?,
            childIndex index: Int
        )
            -> Bool
        {
            let pasteboard = info.draggingPasteboard
            let targetGroupID = (item as? SidebarNode)?.group?.id
            let insertIndex = index == NSOutlineViewDropOnItemIndex ? 0 : index

            // Internal node move
            if
                let uuidString = pasteboard.string(forType: .sidebarNode),
                let draggedID = UUID(uuidString: uuidString)
            {
                Task { @MainActor in
                    self.settings.moveNode(id: draggedID, toGroupWithID: targetGroupID, at: insertIndex)
                }
                return true
            }

            // External file drop
            if let items = pasteboard.pasteboardItems {
                var addedAny = false
                for item in items {
                    guard
                        let urlString = item.string(forType: .fileURL),
                        let url = URL(string: urlString) else { continue }

                    Task { @MainActor in
                        do {
                            try self.settings.validateAndAddProject(from: url, toGroupWithID: targetGroupID)
                        } catch {
                            self.onProjectAddError(error)
                        }
                    }
                    addedAny = true
                }
                if addedAny { return true }
            }

            return false
        }

        // MARK: - Context Menu

        func menuNeedsUpdate(_ menu: NSMenu) {
            guard let outlineView else { return }

            let clickedRow = outlineView.clickedRow
            self.clickedNode = clickedRow >= 0 ? outlineView.item(atRow: clickedRow) as? SidebarNode : nil

            let isProject = self.clickedNode?.isProject == true
            let isGroup = self.clickedNode?.isGroup == true

            for item in menu.items {
                switch item.action {
                case #selector(self.revealInFinder(_:)):
                    item.isHidden = !isProject
                case #selector(self.renameItem(_:)):
                    item.isHidden = !isGroup
                case #selector(self.removeItem(_:)):
                    item.isHidden = self.clickedNode == nil
                default:
                    break
                }
            }
        }

        @objc
        func revealInFinder(_: Any?) {
            guard let project = self.clickedNode?.project else { return }
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.path.path)
        }

        @objc
        func renameItem(_: Any?) {
            guard let outlineView, let node = self.clickedNode, node.isGroup else { return }

            let row = outlineView.row(forItem: node)
            guard
                row >= 0,
                let cellView = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as? NSTableCellView,
                let textField = cellView.textField else { return }

            outlineView.window?.makeFirstResponder(textField)
            textField.selectText(nil)
        }

        @objc
        func removeItem(_: Any?) {
            guard let node = self.clickedNode else { return }
            Task { @MainActor in
                self.settings.removeNode(id: node.id)
                if node.project?.id == self.selectedProjectID {
                    self.onSelectionChanged(nil)
                }
            }
        }

        // MARK: - Text Field Delegate

        func controlTextDidEndEditing(_ notification: Notification) {
            guard
                let textField = notification.object as? NSTextField,
                let cellView = textField.superview as? NSTableCellView,
                let nodeID = cellView.objectValue as? UUID else { return }

            // Only allow renaming groups
            guard
                let node = self.settings.sidebarTree.findNode(id: nodeID),
                node.isGroup else { return }

            let newName = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !newName.isEmpty else {
                // Revert to original name by reloading
                self.outlineView?.reloadData()
                self.restoreExpansionState()
                return
            }

            self.settings.renameNode(id: nodeID, to: newName)
        }

        // MARK: - Helpers

        func restoreExpansionState() {
            guard let outlineView else { return }
            self.restoreExpansion(for: self.settings.sidebarTree, in: outlineView)
        }

        private func restoreExpansion(for nodes: [SidebarNode], in outlineView: NSOutlineView) {
            for node in nodes {
                if case let .group(group) = node {
                    if group.isExpanded {
                        outlineView.expandItem(node)
                    } else {
                        outlineView.collapseItem(node)
                    }
                    self.restoreExpansion(for: group.children, in: outlineView)
                }
            }
        }

        func syncSelection() {
            guard let outlineView, let targetID = self.selectedProjectID else {
                outlineView?.deselectAll(nil)
                return
            }

            self.isUpdatingSelection = true
            defer { self.isUpdatingSelection = false }

            // Find and select the row
            for row in 0..<outlineView.numberOfRows {
                if
                    let node = outlineView.item(atRow: row) as? SidebarNode,
                    node.id == targetID
                {
                    outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                    return
                }
            }
        }
    }
}
