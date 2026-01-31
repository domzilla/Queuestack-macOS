//
//  SidebarTreeView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct SidebarTreeView: View {
    let nodes: [SidebarNode]
    let onAddProject: (UUID?) -> Void
    let onAddGroup: (UUID?) -> Void

    var body: some View {
        ForEach(self.nodes) { node in
            SidebarNodeRow(
                node: node,
                onAddProject: self.onAddProject,
                onAddGroup: self.onAddGroup
            )
        }
    }
}

struct SidebarNodeRow: View {
    @Environment(WindowState.self) private var windowState

    let node: SidebarNode
    let onAddProject: (UUID?) -> Void
    let onAddGroup: (UUID?) -> Void

    @State private var isExpanded = true
    @State private var isTargeted = false

    var body: some View {
        switch self.node {
        case let .group(group):
            self.groupView(group)
        case let .project(project):
            self.projectView(project)
        }
    }

    @ViewBuilder
    private func groupView(_ group: Group) -> some View {
        DisclosureGroup(isExpanded: self.$isExpanded) {
            SidebarTreeView(
                nodes: group.children,
                onAddProject: self.onAddProject,
                onAddGroup: self.onAddGroup
            )
        } label: {
            SwiftUI.Label(group.name, systemImage: "folder")
                .contextMenu {
                    self.groupContextMenu(group)
                }
        }
        .onAppear {
            self.isExpanded = group.isExpanded
        }
        .onChange(of: self.isExpanded) { _, newValue in
            self.windowState.services.settings.setGroupExpanded(newValue, forGroupWithID: group.id)
        }
    }

    @ViewBuilder
    private func projectView(_ project: Project) -> some View {
        SwiftUI.Label(project.name, systemImage: "doc.text")
            .tag(project.id)
            .contextMenu {
                self.projectContextMenu(project)
            }
    }

    @ViewBuilder
    private func groupContextMenu(_ group: Group) -> some View {
        Button {
            self.onAddProject(group.id)
        } label: {
            SwiftUI.Label(
                String(localized: "Add Project...", comment: "Context menu add project"),
                systemImage: "folder.badge.plus"
            )
        }

        Button {
            self.onAddGroup(group.id)
        } label: {
            SwiftUI.Label(
                String(localized: "Add Group...", comment: "Context menu add group"),
                systemImage: "folder.badge.gearshape"
            )
        }

        Divider()

        Button(role: .destructive) {
            self.windowState.services.settings.removeNode(id: group.id)
        } label: {
            SwiftUI.Label(
                String(localized: "Remove Group", comment: "Context menu remove group"),
                systemImage: "trash"
            )
        }
    }

    @ViewBuilder
    private func projectContextMenu(_ project: Project) -> some View {
        Button {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.path.path)
        } label: {
            SwiftUI.Label(
                String(localized: "Show in Finder", comment: "Context menu show in Finder"),
                systemImage: "folder"
            )
        }

        Divider()

        Button(role: .destructive) {
            self.windowState.services.settings.removeNode(id: project.id)
            if self.windowState.selectedProjectID == project.id {
                self.windowState.selectedProjectID = nil
            }
        } label: {
            SwiftUI.Label(
                String(localized: "Remove from Sidebar", comment: "Context menu remove project"),
                systemImage: "trash"
            )
        }
    }
}
