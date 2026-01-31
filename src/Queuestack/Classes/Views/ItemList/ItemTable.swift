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
    @Environment(AppState.self) private var appState
    let item: Item

    // Match header resize handle spacing: 1px line + 6px padding each side = 13px
    private let columnSpacing: CGFloat = 13

    var body: some View {
        HStack(spacing: 0) {
            // Category
            Text(self.item.category ?? "—")
                .font(.caption)
                .foregroundStyle(self.item.category != nil ? .secondary : .quaternary)
                .frame(width: self.appState.categoryColumnWidth, alignment: .leading)

            Spacer()
                .frame(width: self.columnSpacing)

            // Title
            Text(self.item.title)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
                .frame(width: self.columnSpacing)

            // Labels
            Text(self.item.labels.isEmpty ? "—" : self.item.labels.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(self.item.labels.isEmpty ? .quaternary : .secondary)
                .lineLimit(1)
                .frame(width: self.appState.labelsColumnWidth, alignment: .leading)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .tag(self.item.id)
    }
}

#Preview {
    ItemTable()
        .environment(AppState())
}
