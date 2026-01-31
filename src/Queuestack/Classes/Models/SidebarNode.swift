//
//  SidebarNode.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation

/// Represents either a group or a project in the sidebar tree
enum SidebarNode: Identifiable, Hashable, Codable {
    case group(Group)
    case project(Project)

    var id: UUID {
        switch self {
        case let .group(group):
            group.id
        case let .project(project):
            project.id
        }
    }

    var name: String {
        switch self {
        case let .group(group):
            group.name
        case let .project(project):
            project.name
        }
    }

    var isGroup: Bool {
        if case .group = self { return true }
        return false
    }

    var isProject: Bool {
        if case .project = self { return true }
        return false
    }

    var group: Group? {
        if case let .group(g) = self { return g }
        return nil
    }

    var project: Project? {
        if case let .project(p) = self { return p }
        return nil
    }

    var children: [SidebarNode] {
        switch self {
        case let .group(group):
            group.children
        case .project:
            []
        }
    }
}

// MARK: - Tree Operations

extension [SidebarNode] {
    /// Find a node by ID anywhere in the tree
    func findNode(id: UUID) -> SidebarNode? {
        for node in self {
            if node.id == id { return node }
            if let found = node.children.findNode(id: id) {
                return found
            }
        }
        return nil
    }

    /// Find a project by ID anywhere in the tree
    func findProject(id: UUID) -> Project? {
        self.findNode(id: id)?.project
    }

    /// Get all projects in the tree (flattened)
    var allProjects: [Project] {
        self.flatMap { node -> [Project] in
            switch node {
            case let .group(group):
                return group.children.allProjects
            case let .project(project):
                return [project]
            }
        }
    }

    /// Remove a node by ID from anywhere in the tree
    mutating func removeNode(id: UUID) -> SidebarNode? {
        for i in self.indices {
            if self[i].id == id {
                return self.remove(at: i)
            }
            if case var .group(group) = self[i] {
                if let removed = group.children.removeNode(id: id) {
                    self[i] = .group(group)
                    return removed
                }
            }
        }
        return nil
    }

    /// Insert a node into a group (or at root if groupID is nil)
    mutating func insertNode(_ node: SidebarNode, inGroupWithID groupID: UUID?) {
        guard let groupID else {
            self.append(node)
            return
        }

        for i in self.indices {
            if case var .group(group) = self[i], group.id == groupID {
                group.children.append(node)
                self[i] = .group(group)
                return
            }
            if case var .group(group) = self[i] {
                group.children.insertNode(node, inGroupWithID: groupID)
                self[i] = .group(group)
            }
        }
    }

    /// Update expansion state of a group
    mutating func setExpanded(_ expanded: Bool, forGroupWithID groupID: UUID) {
        for i in self.indices {
            if case var .group(group) = self[i] {
                if group.id == groupID {
                    group.isExpanded = expanded
                    self[i] = .group(group)
                    return
                }
                group.children.setExpanded(expanded, forGroupWithID: groupID)
                self[i] = .group(group)
            }
        }
    }
}
