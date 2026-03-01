//
//  ItemTable.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import SwiftUI

struct ItemTable: View {
    @Environment(WindowState.self) private var windowState

    @State private var itemToEdit: Item?
    @State private var itemToDelete: Item?

    var body: some View {
        @Bindable var windowState = self.windowState

        List(self.windowState.filteredItems, selection: $windowState.selectedItemID) { item in
            ItemRow(item: item)
                .id("\(item.id)-\(item.labels.count)")
        }
        .listStyle(.inset)
        .alternatingRowBackgrounds(.disabled)
        .contextMenu(forSelectionType: String.self) { selectedIDs in
            if
                let itemID = selectedIDs.first,
                let item = self.windowState.currentProjectState?.item(withID: itemID)
            {
                self.itemContextMenu(item)
            }
        }
        .sheet(item: self.$itemToEdit) { item in
            EditItemSheet(item: item)
        }
        .confirmationDialog(
            String(localized: "Delete Item", comment: "Delete confirmation title"),
            isPresented: Binding(
                get: { self.itemToDelete != nil },
                set: { if !$0 { self.itemToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete", comment: "Delete button"), role: .destructive) {
                if let item = self.itemToDelete {
                    self.deleteItem(item)
                }
            }
            Button(String(localized: "Cancel", comment: "Cancel button"), role: .cancel) {
                self.itemToDelete = nil
            }
        } message: {
            Text(String(
                localized: "Are you sure you want to delete this item? This action cannot be undone.",
                comment: "Delete confirmation message"
            ))
        }
    }

    private func deleteItem(_ item: Item) {
        Task {
            do {
                // Trash the item file
                let trashProcess = Process()
                trashProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                trashProcess.arguments = ["trash", item.filePath.path]
                try trashProcess.run()
                trashProcess.waitUntilExit()

                // Also trash the attachments directory if it exists
                let stem = item.filePath.deletingPathExtension().lastPathComponent
                let attachmentsDir = item.filePath.deletingLastPathComponent()
                    .appendingPathComponent("\(stem).attachments")
                if FileManager.default.fileExists(atPath: attachmentsDir.path) {
                    let attachmentsProcess = Process()
                    attachmentsProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                    attachmentsProcess.arguments = ["trash", attachmentsDir.path]
                    try attachmentsProcess.run()
                    attachmentsProcess.waitUntilExit()
                }

                // Reload items after deletion
                await self.windowState.currentProjectState?.loadItems()
                self.windowState.selectedItemID = nil
            } catch {
                DZFoundation.DZErrorLog(error)
            }
        }
    }

    @ViewBuilder
    private func itemContextMenu(_ item: Item) -> some View {
        // Edit (only for open items or templates)
        if item.status == .open || item.isTemplate {
            Button {
                self.itemToEdit = item
            } label: {
                SwiftUI.Label(
                    String(localized: "Edit...", comment: "Context menu edit item"),
                    systemImage: "pencil"
                )
            }
        }

        // Close/Reopen
        if item.status == .open {
            Button {
                Task {
                    try? await self.windowState.currentProjectState?.closeItem(item)
                }
            } label: {
                SwiftUI.Label(
                    String(localized: "Close Item", comment: "Context menu close item"),
                    systemImage: "archivebox"
                )
            }
        } else if item.status == .closed {
            Button {
                Task {
                    try? await self.windowState.currentProjectState?.reopenItem(item)
                }
            } label: {
                SwiftUI.Label(
                    String(localized: "Reopen Item", comment: "Context menu reopen item"),
                    systemImage: "arrow.uturn.backward"
                )
            }
        }

        Divider()

        Button {
            NSWorkspace.shared.selectFile(
                item.filePath.path,
                inFileViewerRootedAtPath: item.filePath.deletingLastPathComponent().path
            )
        } label: {
            SwiftUI.Label(
                String(localized: "Show in Finder", comment: "Context menu show in Finder"),
                systemImage: "folder"
            )
        }

        Divider()

        // Delete
        Button(role: .destructive) {
            self.itemToDelete = item
        } label: {
            SwiftUI.Label(
                String(localized: "Delete...", comment: "Context menu delete item"),
                systemImage: "trash"
            )
        }
    }
}

#Preview {
    ItemTable()
        .environment(WindowState(services: AppServices()))
}
