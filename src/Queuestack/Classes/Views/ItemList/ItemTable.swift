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

        List(self.appState.filteredItems, selection: $appState.selectedItemID) { item in
            ItemRow(item: item)
                .listRowSeparator(.hidden)
                .contextMenu {
                    self.itemContextMenu(item)
                }
        }
        .listStyle(.plain)
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

struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            // Category
            Text(self.item.category ?? "—")
                .font(.caption)
                .foregroundStyle(self.item.category != nil ? .secondary : .quaternary)
                .frame(width: 80, alignment: .leading)

            // Title
            Text(self.item.title)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Labels
            if self.item.labels.isEmpty {
                Text("—")
                    .foregroundStyle(.quaternary)
                    .frame(width: 100, alignment: .trailing)
            } else {
                HStack(spacing: 4) {
                    ForEach(self.item.labels, id: \.self) { label in
                        LabelBadge(label: label)
                    }
                }
                .frame(width: 100, alignment: .trailing)
            }
        }
        .padding(.vertical, 6)
        .tag(self.item.id)
    }
}

#Preview {
    ItemTable()
        .environment(AppState())
}
