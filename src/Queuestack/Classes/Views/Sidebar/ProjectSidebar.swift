//
//  ProjectSidebar.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct ProjectSidebar: View {
    @Environment(AppState.self) private var appState

    @State private var showingAddMenu = false
    @State private var showingAddProjectSheet = false
    @State private var showingAddGroupSheet = false
    @State private var targetGroupID: UUID?

    var body: some View {
        @Bindable var appState = self.appState

        List(selection: $appState.selectedProjectID) {
            SidebarTreeView(
                nodes: self.appState.settings.sidebarTree,
                onAddProject: { groupID in
                    self.targetGroupID = groupID
                    self.showingAddProjectSheet = true
                },
                onAddGroup: { groupID in
                    self.targetGroupID = groupID
                    self.showingAddGroupSheet = true
                }
            )
        }
        .listStyle(.sidebar)
        .navigationTitle(String(localized: "Projects", comment: "Sidebar title"))
        .safeAreaInset(edge: .bottom) {
            self.bottomBar
        }
        .sheet(isPresented: self.$showingAddProjectSheet) {
            AddProjectSheet(targetGroupID: self.targetGroupID)
        }
        .sheet(isPresented: self.$showingAddGroupSheet) {
            AddGroupSheet(targetGroupID: self.targetGroupID)
        }
    }

    private var bottomBar: some View {
        HStack {
            Menu {
                Button {
                    self.targetGroupID = nil
                    self.showingAddProjectSheet = true
                } label: {
                    SwiftUI.Label(
                        String(localized: "Add Project...", comment: "Menu item to add project"),
                        systemImage: "folder.badge.plus"
                    )
                }

                Button {
                    self.targetGroupID = nil
                    self.showingAddGroupSheet = true
                } label: {
                    SwiftUI.Label(
                        String(localized: "Add Group...", comment: "Menu item to add group"),
                        systemImage: "folder.badge.gearshape"
                    )
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .padding(8)
            Spacer()
        }
        .background(.bar)
    }
}

#Preview {
    ProjectSidebar()
        .environment(AppState())
}
