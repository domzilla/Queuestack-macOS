//
//  ItemTable.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct ItemTable: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = self.appState

        Table(self.appState.filteredItems, selection: $appState.selectedItemID) {
            TableColumn(String(localized: "Category", comment: "Column header for category")) { item in
                Text(item.category ?? "—")
                    .foregroundStyle(item.category != nil ? .secondary : .quaternary)
            }
            .width(min: 60, ideal: 80, max: 150)

            TableColumn(String(localized: "Title", comment: "Column header for title")) { item in
                Text(item.title)
                    .lineLimit(1)
            }

            TableColumn(String(localized: "Labels", comment: "Column header for labels")) { item in
                Text(item.labels.isEmpty ? "—" : item.labels.joined(separator: ", "))
                    .foregroundStyle(item.labels.isEmpty ? .quaternary : .secondary)
                    .lineLimit(1)
            }
            .width(min: 60, ideal: 100, max: 200)
        }
        .tableStyle(.inset)
        .alternatingRowBackgrounds(.disabled)
        .contextMenu(forSelectionType: String.self) { selectedIDs in
            if
                let itemID = selectedIDs.first,
                let item = self.appState.currentProjectState?.item(withID: itemID)
            {
                self.itemContextMenu(item)
            }
        }
    }

    @ViewBuilder
    private func itemContextMenu(_ item: Item) -> some View {
        if item.status == .open {
            Button {
                Task {
                    try? await self.appState.currentProjectState?.closeItem(item)
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
                    try? await self.appState.currentProjectState?.reopenItem(item)
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
    }
}

#Preview {
    ItemTable()
        .environment(AppState())
}
