//
//  ProjectSidebar.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import SwiftUI

struct ProjectSidebar: View {
    @Environment(WindowState.self) private var windowState

    @State private var showingAddProjectSheet = false
    @State private var showingAddGroupSheet = false
    @State private var targetGroupID: UUID?
    @State private var showingUnsavedAlert = false
    @State private var pendingProjectID: UUID?

    private var showSearchResults: Bool {
        !self.windowState.globalSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        @Bindable var windowState = self.windowState

        self.sidebarContent
            .navigationTitle(String(localized: "Projects", comment: "Sidebar title"))
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

    @ViewBuilder
    private var sidebarContent: some View {
        if self.showSearchResults {
            GlobalSearchResultsList()
        } else {
            @Bindable var windowState = self.windowState
            SidebarOutlineView(
                settings: self.windowState.services.settings,
                selectedProjectID: $windowState.selectedProjectID,
                onAddProject: { groupID in
                    self.targetGroupID = groupID
                    self.showingAddProjectSheet = true
                },
                onAddGroup: { groupID in
                    self.targetGroupID = groupID
                    self.showingAddGroupSheet = true
                }
            )
            .safeAreaInset(edge: .bottom) {
                self.bottomBar
            }
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
    }
}

#Preview {
    ProjectSidebar()
        .environment(WindowState(services: AppServices()))
}
