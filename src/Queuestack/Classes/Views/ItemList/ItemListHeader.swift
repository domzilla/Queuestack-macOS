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

        VStack(alignment: .leading, spacing: 8) {
            // Row 1: Filter picker (left) + Category picker (right)
            HStack {
                self.filterPicker
                Spacer()
                self.categoryPicker
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
        .disabled(self.appState.selectedProject == nil)
    }

    private var filterPicker: some View {
        @Bindable var appState = self.appState

        return Picker("", selection: $appState.filter.mode) {
            Text(String(localized: "Open", comment: "Open filter option"))
                .tag(ItemFilter.FilterMode.open)
            Text(String(localized: "Closed", comment: "Closed filter option"))
                .tag(ItemFilter.FilterMode.closed)
            Text(String(localized: "Templates", comment: "Templates filter option"))
                .tag(ItemFilter.FilterMode.templates)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
    }

    private var categoryPicker: some View {
        let categories = self.appState.currentProjectState?.categories ?? []
        let isFiltering = self.appState.filter.category != nil

        return Menu {
            Button(String(localized: "All Categories", comment: "All categories filter option")) {
                self.appState.filter.category = nil
            }
            Divider()
            ForEach(categories, id: \.name) { category in
                Button(category.name) {
                    self.appState.filter.category = category.name
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle\(isFiltering ? ".fill" : "")")
                .foregroundStyle(isFiltering ? Color.accentColor : .secondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

#Preview {
    ItemListHeader()
        .environment(AppState())
}
