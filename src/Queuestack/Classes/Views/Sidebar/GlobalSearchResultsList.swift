//
//  GlobalSearchResultsList.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 02/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

/// Displays global search results grouped by project in the sidebar
struct GlobalSearchResultsList: View {
    @Environment(WindowState.self) private var windowState

    var body: some View {
        List {
            if self.windowState.isGlobalSearching {
                self.loadingSection
            } else if self.windowState.globalSearchResults.isEmpty {
                self.emptySection
            } else {
                ForEach(self.windowState.globalSearchResults) { result in
                    self.projectSection(result)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .top) {
            self.scopePicker
        }
    }

    // MARK: - Scope Picker

    private var scopePicker: some View {
        Picker(selection: Bindable(self.windowState).globalSearchScope) {
            ForEach(WindowState.GlobalSearchScope.allCases) { scope in
                Text(scope.localizedName).tag(scope)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Loading State

    private var loadingSection: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Searching...", comment: "Global search loading indicator")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 20)
    }

    // MARK: - Empty State

    private var emptySection: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("No results", comment: "Global search no results message")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 20)
    }

    // MARK: - Results

    private func projectSection(_ result: WindowState.GlobalSearchResult) -> some View {
        Section {
            ForEach(result.items) { item in
                self.itemRow(item, in: result.project)
            }
        } header: {
            Text(result.project.name)
        }
    }

    private func itemRow(_ item: Item, in project: Project) -> some View {
        Button {
            self.selectItem(item, in: project)
        } label: {
            Text(item.title)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func selectItem(_ item: Item, in project: Project) {
        self.windowState.navigateToSearchResult(item, in: project)
    }
}

#Preview {
    GlobalSearchResultsList()
        .environment(WindowState(services: AppServices()))
}
