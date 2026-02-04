//
//  SettingsManager.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation
import SwiftUI

/// Persists app settings and sidebar tree structure
@Observable
@MainActor
final class SettingsManager {
    // MARK: - Stored Settings

    var cliBinaryPath: String {
        didSet {
            UserDefaults.standard.set(self.cliBinaryPath, forKey: Keys.cliBinaryPath)
        }
    }

    var sidebarTree: [SidebarNode] {
        didSet {
            self.saveSidebarTree()
        }
    }

    // MARK: - Initialization

    init() {
        self.cliBinaryPath = UserDefaults.standard.string(forKey: Keys.cliBinaryPath) ?? "/opt/homebrew/bin/qs"
        self.sidebarTree = []
        self.loadSidebarTree()
    }

    // MARK: - Sidebar Persistence

    private func loadSidebarTree() {
        guard let data = UserDefaults.standard.data(forKey: Keys.sidebarTree) else {
            self.sidebarTree = []
            return
        }

        do {
            let decoder = JSONDecoder()
            self.sidebarTree = try decoder.decode([SidebarNode].self, from: data)

            // Validate projects still exist
            self.validateProjects()
        } catch {
            self.sidebarTree = []
        }
    }

    private func saveSidebarTree() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.sidebarTree)
            UserDefaults.standard.set(data, forKey: Keys.sidebarTree)
        } catch {
            // Silently fail
        }
    }

    private func validateProjects() {
        // Remove projects whose folders no longer exist
        self.sidebarTree = self.removeInvalidProjects(from: self.sidebarTree)
    }

    private func removeInvalidProjects(from nodes: [SidebarNode]) -> [SidebarNode] {
        nodes.compactMap { node -> SidebarNode? in
            switch node {
            case let .project(project):
                if project.isValid {
                    return node
                }
                return nil
            case var .group(group):
                group.children = self.removeInvalidProjects(from: group.children)
                return .group(group)
            }
        }
    }

    // MARK: - Sidebar Operations

    func addProject(_ project: Project, toGroupWithID groupID: UUID? = nil) {
        let node = SidebarNode.project(project)
        self.sidebarTree.insertNode(node, inGroupWithID: groupID)
    }

    func addGroup(name: String, toGroupWithID groupID: UUID? = nil) {
        let group = Group(name: name)
        let node = SidebarNode.group(group)
        self.sidebarTree.insertNode(node, inGroupWithID: groupID)
    }

    func removeNode(id: UUID) {
        _ = self.sidebarTree.removeNode(id: id)
    }

    func renameNode(id: UUID, to newName: String) {
        self.updateNode(id: id) { node in
            switch node {
            case var .group(group):
                group.name = newName
                return .group(group)
            case var .project(project):
                project.name = newName
                return .project(project)
            }
        }
    }

    func setGroupExpanded(_ expanded: Bool, forGroupWithID groupID: UUID) {
        self.sidebarTree.setExpanded(expanded, forGroupWithID: groupID)
    }

    /// Move a node to a new location (handles circular group prevention)
    /// Returns true if the move was successful
    @discardableResult
    func moveNode(id: UUID, toGroupWithID targetGroupID: UUID?, at index: Int) -> Bool {
        // Prevent circular drops: can't drop a group into itself or its descendants
        if let targetGroupID, self.sidebarTree.isAncestor(id, of: targetGroupID) {
            return false
        }
        if id == targetGroupID {
            return false
        }

        // Check if it's a no-op (same position)
        let currentParentID = self.sidebarTree.findParentID(of: id)
        if currentParentID == targetGroupID {
            // Same parent - check if same index
            let nodes: [SidebarNode]
            if
                let parentID = currentParentID,
                let parent = self.sidebarTree.findNode(id: parentID),
                case let .group(group) = parent
            {
                nodes = group.children
            } else if currentParentID == nil {
                nodes = self.sidebarTree
            } else {
                return false
            }

            if let currentIndex = nodes.indexOfNode(id: id) {
                // Account for removal shifting indices
                let effectiveIndex = index > currentIndex ? index - 1 : index
                if currentIndex == effectiveIndex {
                    return false // No-op
                }
            }
        }

        // Remove from current location
        guard let node = self.sidebarTree.removeNode(id: id) else {
            return false
        }

        // Insert at new location
        self.sidebarTree.insertNode(node, inGroupWithID: targetGroupID, at: index)
        return true
    }

    /// Check if a project with the given path already exists in the tree
    func containsProject(at path: URL) -> Bool {
        self.sidebarTree.containsProject(at: path)
    }

    /// Validates and adds a project from a URL, checking for duplicates and valid queuestack config
    /// - Parameters:
    ///   - url: The folder URL to add as a project
    ///   - groupID: Optional parent group ID to add the project into
    /// - Returns: The created Project
    /// - Throws: `ProjectAdditionError` if validation fails
    @discardableResult
    func validateAndAddProject(from url: URL, toGroupWithID groupID: UUID?) throws -> Project {
        // Check for .queuestack file
        let configPath = url.appendingPathComponent(".queuestack")
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            throw ProjectAdditionError.notQueuestackProject(name: url.lastPathComponent)
        }

        // Check for duplicates
        guard !self.containsProject(at: url) else {
            throw ProjectAdditionError.alreadyAdded(name: url.lastPathComponent)
        }

        // Create and add project
        let project = try Project.from(url: url)
        self.addProject(project, toGroupWithID: groupID)
        return project
    }

    private func updateNode(id: UUID, transform: (SidebarNode) -> SidebarNode) {
        self.sidebarTree = self.updateNodeRecursive(in: self.sidebarTree, id: id, transform: transform)
    }

    private func updateNodeRecursive(
        in nodes: [SidebarNode],
        id: UUID,
        transform: (SidebarNode) -> SidebarNode
    )
        -> [SidebarNode]
    {
        nodes.map { node in
            if node.id == id {
                return transform(node)
            }
            if case var .group(group) = node {
                group.children = self.updateNodeRecursive(in: group.children, id: id, transform: transform)
                return .group(group)
            }
            return node
        }
    }

    // MARK: - Keys

    private enum Keys {
        static let cliBinaryPath = "cliBinaryPath"
        static let sidebarTree = "sidebarTree"
    }
}
