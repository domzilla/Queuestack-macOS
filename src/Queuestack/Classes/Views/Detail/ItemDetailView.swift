//
//  ItemDetailView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import SwiftUI

struct ItemDetailView: View {
    @Environment(WindowState.self) private var windowState

    @State private var showingEditSheet = false
    @State private var showingUnsavedAlert = false
    @State private var pendingItemID: String?
    @State private var isProcessing = false

    /// The item to display - either the editing item or selected item
    private var displayedItem: Item? {
        // If we're editing an item and there are unsaved changes, show that item
        if
            let editingID = self.windowState.editingBodyItemID,
            self.windowState.hasUnsavedBodyChanges,
            let item = self.windowState.currentProjectState?.item(withID: editingID)
        {
            return item
        }
        // Otherwise show the selected item
        return self.windowState.selectedItem
    }

    var body: some View {
        SwiftUI.Group {
            if let item = self.displayedItem {
                self.detailContent(item)
            } else {
                Color.clear
            }
        }
        .onChange(of: self.windowState.selectedItemID) { oldID, newID in
            self.handleSelectionChange(from: oldID, to: newID)
        }
        .onChange(of: self.windowState.selectedItem?.body) { _, _ in
            // Sync editing state when item body changes externally (e.g., from another window)
            if let item = self.windowState.selectedItem {
                self.windowState.syncBodyWithItem(item)
            }
        }
        .alert(
            String(localized: "Unsaved Changes", comment: "Unsaved changes alert title"),
            isPresented: self.$showingUnsavedAlert
        ) {
            Button(String(localized: "Save", comment: "Save button")) {
                self.windowState.saveBodyChanges()
                self.commitPendingSelection()
            }
            Button(String(localized: "Discard", comment: "Discard button"), role: .destructive) {
                self.windowState.discardBodyChanges()
                self.commitPendingSelection()
            }
            Button(String(localized: "Cancel", comment: "Cancel button"), role: .cancel) {
                self.revertSelection()
            }
        } message: {
            Text(String(
                localized: "Do you want to save your changes?",
                comment: "Unsaved changes alert message"
            ))
        }
    }

    private func handleSelectionChange(from _: String?, to newID: String?) {
        // If selecting the same item we're already editing, do nothing
        if newID == self.windowState.editingBodyItemID {
            return
        }

        // If there are unsaved changes and we're switching to a different item
        if self.windowState.hasUnsavedBodyChanges {
            self.pendingItemID = newID
            self.showingUnsavedAlert = true
        } else if let newID, let item = self.windowState.currentProjectState?.item(withID: newID) {
            // No unsaved changes, just start editing the new item
            self.windowState.startEditingBody(for: item)
        } else {
            // Selection cleared
            self.windowState.clearBodyEditing()
        }
    }

    private func commitPendingSelection() {
        if
            let pendingID = self.pendingItemID,
            let item = self.windowState.currentProjectState?.item(withID: pendingID)
        {
            self.windowState.startEditingBody(for: item)
        } else {
            self.windowState.clearBodyEditing()
        }
        self.pendingItemID = nil
    }

    private func revertSelection() {
        // Revert selection back to the item we were editing
        self.windowState.selectedItemID = self.windowState.editingBodyItemID
        self.pendingItemID = nil
    }

    @ViewBuilder
    private func detailContent(_ item: Item) -> some View {
        VStack(spacing: 0) {
            // Fixed header
            self.headerSection(item)

            Divider()

            // Resizable split between body and attachments
            VSplitView {
                // Body section (TextEditor is already scrollable)
                ItemBody()
                    .padding()

                // Attachments section
                VStack(spacing: 0) {
                    Divider()

                    ScrollView {
                        AttachmentSection(item: item)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(minHeight: 80)
            }
        }
        .sheet(isPresented: self.$showingEditSheet) {
            EditItemSheet(item: item)
        }
    }

    private func headerSection(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row with Close button
            HStack(alignment: .top) {
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .textSelection(.enabled)

                Spacer()

                self.actionButton(item)
            }

            // Id and Created at row
            HStack {
                HStack(spacing: 4) {
                    Text(String(localized: "Id:", comment: "Item ID label"))
                        .foregroundStyle(.secondary)
                    Text(item.id)
                        .textSelection(.enabled)
                }
                .font(.caption)

                Spacer()

                HStack(spacing: 4) {
                    Text(String(localized: "Created at:", comment: "Created date label"))
                        .foregroundStyle(.secondary)
                    Text(item.createdAt, style: .date)
                }
                .font(.caption)
            }

            // Author and Labels row
            HStack {
                HStack(spacing: 4) {
                    Text(String(localized: "Author:", comment: "Author label"))
                        .foregroundStyle(.secondary)
                    Text(item.author)
                }
                .font(.caption)

                Spacer()

                HStack(spacing: 4) {
                    Text(String(localized: "Labels:", comment: "Labels label"))
                        .foregroundStyle(.secondary)
                    if item.labels.isEmpty {
                        Text("—")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(item.labels.joined(separator: ", "))
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .background(.bar)
    }

    @ViewBuilder
    private func actionButton(_ item: Item) -> some View {
        if item.status == .open {
            Button {
                self.closeItem()
            } label: {
                Text(String(localized: "Close", comment: "Close item button"))
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(self.isProcessing)
        } else {
            Button {
                self.reopenItem()
            } label: {
                Text(String(localized: "Reopen", comment: "Reopen item button"))
            }
            .buttonStyle(.borderedProminent)
            .disabled(self.isProcessing)
        }
    }

    private func closeItem() {
        self.isProcessing = true
        Task {
            do {
                try await self.windowState.closeSelectedItem()
            } catch {
                DZErrorLog(error)
            }
            self.isProcessing = false
        }
    }

    private func reopenItem() {
        self.isProcessing = true
        Task {
            do {
                try await self.windowState.reopenSelectedItem()
            } catch {
                DZErrorLog(error)
            }
            self.isProcessing = false
        }
    }
}

#Preview {
    ItemDetailView()
        .environment(WindowState(services: AppServices()))
}
