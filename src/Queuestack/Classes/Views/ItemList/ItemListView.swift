//
//  ItemListView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct ItemListView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        SwiftUI.Group {
            if self.appState.selectedProject == nil {
                self.noProjectSelectedView
            } else if let projectState = self.appState.currentProjectState {
                self.itemListContent(projectState)
            }
        }
    }

    private var noProjectSelectedView: some View {
        ContentUnavailableView {
            SwiftUI.Label(
                String(localized: "No Project Selected", comment: "Empty state title"),
                systemImage: "folder"
            )
        } description: {
            Text(String(
                localized: "Select a project from the sidebar or add one to get started.",
                comment: "Empty state description"
            ))
        }
    }

    @ViewBuilder
    private func itemListContent(_ projectState: ProjectState) -> some View {
        VStack(spacing: 0) {
            ItemListHeader()

            Divider()

            if projectState.isLoading {
                self.loadingView
            } else if self.appState.filteredItems.isEmpty {
                self.emptyStateView
            } else {
                ItemTable()
            }
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text(String(localized: "Loading items...", comment: "Loading indicator text"))
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            Spacer()
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            SwiftUI.Label(
                self.emptyStateTitle,
                systemImage: self.emptyStateIcon
            )
        } description: {
            Text(self.emptyStateDescription)
        }
    }

    private var emptyStateTitle: String {
        if !self.appState.filter.searchQuery.isEmpty {
            return String(localized: "No Results", comment: "Empty search results title")
        }
        switch self.appState.filter.mode {
        case .open:
            return String(localized: "No Open Items", comment: "Empty open items title")
        case .closed:
            return String(localized: "No Closed Items", comment: "Empty closed items title")
        case .templates:
            return String(localized: "No Templates", comment: "Empty templates title")
        }
    }

    private var emptyStateIcon: String {
        if !self.appState.filter.searchQuery.isEmpty {
            return "magnifyingglass"
        }
        switch self.appState.filter.mode {
        case .open:
            return "tray"
        case .closed:
            return "archivebox"
        case .templates:
            return "doc.on.doc"
        }
    }

    private var emptyStateDescription: String {
        if !self.appState.filter.searchQuery.isEmpty {
            return String(localized: "No items match your search query.", comment: "Empty search results description")
        }
        switch self.appState.filter.mode {
        case .open:
            return String(localized: "Create a new item to get started.", comment: "Empty open items description")
        case .closed:
            return String(localized: "Closed items will appear here.", comment: "Empty closed items description")
        case .templates:
            return String(
                localized: "Create a template using File > New Template.",
                comment: "Empty templates description"
            )
        }
    }
}

#Preview {
    ItemListView()
        .environment(AppState())
}
