//
//  ContentView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import SwiftUI

struct ContentView: View {
    @Environment(AppServices.self) private var services
    @State private var windowState: WindowState?

    var body: some View {
        SwiftUI.Group {
            if let windowState {
                WindowContent(windowState: windowState)
                    .environment(windowState)
                    .focusedSceneValue(\.windowState, windowState)
            }
        }
        .task {
            if self.windowState == nil {
                self.windowState = WindowState(services: self.services)
            }
        }
    }
}

/// The actual window content, requiring an initialized WindowState
private struct WindowContent: View {
    @Bindable var windowState: WindowState

    @State private var showingNewItemSheet = false
    @State private var showingNewTemplateSheet = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: self.$columnVisibility) {
            ProjectSidebar()
        } content: {
            ItemListView()
                .navigationSplitViewColumnWidth(min: 280, ideal: 350, max: 500)
        } detail: {
            ItemDetailView()
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(
            text: self.$windowState.globalSearchQuery,
            placement: .sidebar,
            prompt: String(localized: "Search all projects...", comment: "Global search placeholder")
        )
        .task(id: self.windowState.globalSearchQuery) {
            // Debounce: wait 300ms before searching
            do {
                try await Task.sleep(for: .milliseconds(300))
                await self.windowState.performGlobalSearch()
            } catch {
                // Task cancelled (user typed more) - no action needed
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    self.showingNewItemSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(self.windowState.selectedProject == nil)
                .help(String(localized: "Create new item", comment: "Tooltip for new item button"))
            }
        }
        .sheet(isPresented: self.$showingNewItemSheet) {
            NewItemSheet(isTemplate: false)
        }
        .sheet(isPresented: self.$showingNewTemplateSheet) {
            NewItemSheet(isTemplate: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewItem)) { _ in
            self.showingNewItemSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewTemplate)) { _ in
            self.showingNewTemplateSheet = true
        }
    }
}

#Preview {
    ContentView()
        .environment(AppServices())
}
