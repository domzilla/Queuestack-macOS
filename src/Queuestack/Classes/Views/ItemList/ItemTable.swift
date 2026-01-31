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
            TableColumn(String(localized: "Category", comment: "Table column header")) { item in
                if let category = item.category {
                    Text(category)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    Text("—")
                        .foregroundStyle(.quaternary)
                }
            }
            .width(min: 60, ideal: 100, max: 150)

            TableColumn(String(localized: "Title", comment: "Table column header")) { item in
                Text(item.title)
                    .lineLimit(1)
            }
            .width(min: 150)

            TableColumn(String(localized: "Labels", comment: "Table column header")) { item in
                self.labelsView(for: item)
            }
            .width(min: 100, ideal: 150, max: 300)
        }
        .tableStyle(.inset)
        .alternatingRowBackgrounds(.enabled)
        .contextMenu(forSelectionType: String.self) { ids in
            if let id = ids.first, let item = self.appState.currentProjectState?.item(withID: id) {
                self.itemContextMenu(item)
            }
        } primaryAction: { _ in
            // Double-click opens item (already handled by selection)
        }
    }

    @ViewBuilder
    private func labelsView(for item: Item) -> some View {
        if item.labels.isEmpty {
            Text("—")
                .foregroundStyle(.quaternary)
        } else {
            HStack(spacing: 4) {
                ForEach(item.labels, id: \.self) { label in
                    LabelBadge(label: label)
                }
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
