//
//  ContentView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    @State private var showingNewItemSheet = false
    @State private var showingNewTemplateSheet = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        @Bindable var appState = self.appState

        NavigationSplitView(columnVisibility: self.$columnVisibility) {
            ProjectSidebar()
        } content: {
            ItemListView()
        } detail: {
            ItemDetailView()
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    self.showingNewItemSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(self.appState.selectedProject == nil)
                .help(String(localized: "Create new item", comment: "Tooltip for new item button"))
            }

            ToolbarItem(placement: .primaryAction) {
                TextField(
                    String(localized: "Search globally...", comment: "Global search placeholder"),
                    text: $appState.globalSearchQuery
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .onSubmit {
                    Task {
                        await self.appState.performGlobalSearch()
                    }
                }
            }
        }
        .sheet(isPresented: self.$showingNewItemSheet) {
            NewItemSheet(isTemplate: false)
        }
        .sheet(isPresented: self.$showingNewTemplateSheet) {
            NewItemSheet(isTemplate: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewTemplate)) { _ in
            self.showingNewTemplateSheet = true
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
