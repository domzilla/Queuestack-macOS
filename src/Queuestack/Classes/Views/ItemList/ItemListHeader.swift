//
//  ItemListHeader.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct ItemListHeader: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = self.appState

        VStack(spacing: 8) {
            // Row 1: Breadcrumb + Filter buttons
            HStack {
                self.breadcrumb
                Spacer()
                self.filterButtons
            }

            // Row 2: Local search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(
                    String(localized: "Search locally...", comment: "Local search placeholder"),
                    text: $appState.filter.searchQuery
                )
                .textFieldStyle(.plain)

                if !self.appState.filter.searchQuery.isEmpty {
                    Button {
                        self.appState.filter.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    @ViewBuilder
    private var breadcrumb: some View {
        if let project = self.appState.selectedProject {
            HStack(spacing: 4) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(project.path.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var filterButtons: some View {
        HStack(spacing: 4) {
            FilterToggle(
                title: String(localized: "Open", comment: "Open filter button"),
                isSelected: self.appState.filter.mode == .open
            ) {
                self.appState.filter.mode = .open
            }

            FilterToggle(
                title: String(localized: "Closed", comment: "Closed filter button"),
                isSelected: self.appState.filter.mode == .closed
            ) {
                self.appState.filter.mode = .closed
            }

            FilterToggle(
                title: String(localized: "Templates", comment: "Templates filter button"),
                isSelected: self.appState.filter.mode == .templates
            ) {
                self.appState.filter.mode = .templates
            }
        }
    }
}

private struct FilterToggle: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            Text(self.title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .background(self.isSelected ? Color.accentColor : Color.clear)
        .foregroundStyle(self.isSelected ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    ItemListHeader()
        .environment(AppState())
}
