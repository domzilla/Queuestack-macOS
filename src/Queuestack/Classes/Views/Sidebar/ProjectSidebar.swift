//
//  ProjectSidebar.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import SwiftUI
import UniformTypeIdentifiers

struct ProjectSidebar: View {
    @Environment(AppState.self) private var appState

    @State private var showingAddMenu = false
    @State private var showingAddProjectSheet = false
    @State private var showingAddGroupSheet = false
    @State private var targetGroupID: UUID?
    @State private var isDropTargeted = false

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
        .dropDestination(for: URL.self) { urls, _ in
            self.handleDroppedURLs(urls)
        } isTargeted: { targeted in
            self.isDropTargeted = targeted
        }
        .overlay {
            if self.isDropTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: 2)
                    .padding(4)
            }
        }
        .sheet(isPresented: self.$showingAddProjectSheet) {
            AddProjectSheet(targetGroupID: self.targetGroupID)
        }
        .sheet(isPresented: self.$showingAddGroupSheet) {
            AddGroupSheet(targetGroupID: self.targetGroupID)
        }
        .onChange(of: self.appState.selectedProjectID) { oldValue, newValue in
            DZLog("ProjectSidebar onChange: \(String(describing: oldValue)) -> \(String(describing: newValue))")
            self.appState.handleProjectSelectionChange()
        }
    }

    private func handleDroppedURLs(_ urls: [URL]) -> Bool {
        var addedAny = false

        for url in urls {
            // Check if it's a directory
            var isDirectory: ObjCBool = false
            guard
                FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                isDirectory.boolValue else { continue }

            // Try to create a project from the URL
            do {
                let project = try Project.from(url: url)
                self.appState.settings.addProject(project)
                addedAny = true
            } catch {
                // Not a valid queuestack project, skip
                continue
            }
        }

        return addedAny
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
