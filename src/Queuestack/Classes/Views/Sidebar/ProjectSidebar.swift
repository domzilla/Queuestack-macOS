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
    @Environment(WindowState.self) private var windowState

    @State private var showingAddMenu = false
    @State private var showingAddProjectSheet = false
    @State private var showingAddGroupSheet = false
    @State private var targetGroupID: UUID?
    @State private var isDropTargeted = false
    @State private var showingUnsavedAlert = false
    @State private var pendingProjectID: UUID?

    var body: some View {
        @Bindable var windowState = self.windowState

        List(selection: $windowState.selectedProjectID) {
            SidebarTreeView(
                nodes: self.windowState.services.settings.sidebarTree,
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
        .onChange(of: self.windowState.selectedProjectID) { oldValue, newValue in
            DZLog("ProjectSidebar onChange: \(String(describing: oldValue)) -> \(String(describing: newValue))")
            self.handleProjectSelectionChange(from: oldValue, to: newValue)
        }
        .alert(
            String(localized: "Unsaved Changes", comment: "Unsaved changes alert title"),
            isPresented: self.$showingUnsavedAlert
        ) {
            Button(String(localized: "Save", comment: "Save button")) {
                self.windowState.saveBodyChanges()
                self.commitPendingProjectSelection()
            }
            Button(String(localized: "Discard", comment: "Discard button"), role: .destructive) {
                self.windowState.discardBodyChanges()
                self.commitPendingProjectSelection()
            }
            Button(String(localized: "Cancel", comment: "Cancel button"), role: .cancel) {
                self.revertProjectSelection()
            }
        } message: {
            Text(String(
                localized: "Do you want to save your changes?",
                comment: "Unsaved changes alert message"
            ))
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
                self.windowState.services.settings.addProject(project)
                addedAny = true
            } catch {
                // Not a valid queuestack project, skip
                continue
            }
        }

        return addedAny
    }

    private func handleProjectSelectionChange(from oldID: UUID?, to newID: UUID?) {
        // If selecting the same project, do nothing
        if newID == oldID {
            return
        }

        // If we're in the middle of handling unsaved changes, ignore further changes
        if self.pendingProjectID != nil {
            return
        }

        // If there are unsaved changes, show dialog
        if self.windowState.hasUnsavedBodyChanges {
            self.pendingProjectID = newID
            // Revert selection immediately to prevent project loading
            self.windowState.selectedProjectID = oldID
            self.showingUnsavedAlert = true
        } else {
            // No unsaved changes, proceed with project change
            self.windowState.handleProjectSelectionChange()
        }
    }

    private func commitPendingProjectSelection() {
        guard let pendingID = self.pendingProjectID else { return }
        // Clear first to allow onChange to proceed normally
        self.pendingProjectID = nil
        self.windowState.clearBodyEditing()
        self.windowState.selectedProjectID = pendingID
    }

    private func revertProjectSelection() {
        // Selection was already reverted, just clear pending
        self.pendingProjectID = nil
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
    }
}

#Preview {
    ProjectSidebar()
        .environment(WindowState(services: AppServices()))
}
