//
//  AppState.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import Foundation

/// Main application state
@Observable
@MainActor
final class AppState {
    // MARK: - Dependencies

    let settings: SettingsManager
    let projectManager: ProjectStateManager
    private let service: Service

    // MARK: - Selection State

    var selectedProjectID: UUID?
    var selectedItemID: String?

    /// Call this when project selection changes (use .onChange in views)
    func handleProjectSelectionChange() {
        self.onProjectSelectionChanged()
    }

    // MARK: - Filter State

    var filter = ItemFilter()

    // MARK: - Global Search

    var globalSearchQuery = ""
    var globalSearchResults: [GlobalSearchResult] = []
    var isGlobalSearching = false

    struct GlobalSearchResult: Identifiable {
        let id = UUID()
        let project: Project
        let items: [Item]
    }

    // MARK: - Initialization

    init() {
        self.settings = SettingsManager()
        self.service = Service(binaryPath: self.settings.cliBinaryPath)
        self.projectManager = ProjectStateManager(service: self.service)
    }

    // MARK: - Computed Properties

    var selectedProject: Project? {
        guard let id = self.selectedProjectID else { return nil }
        return self.settings.sidebarTree.findProject(id: id)
    }

    var currentProjectState: ProjectState? {
        guard let project = self.selectedProject else { return nil }
        return self.projectManager.state(for: project)
    }

    var selectedItem: Item? {
        guard
            let itemID = self.selectedItemID,
            let projectState = self.currentProjectState else { return nil }
        return projectState.item(withID: itemID)
    }

    var filteredItems: [Item] {
        guard let projectState = self.currentProjectState else { return [] }

        let items: [Item] = switch self.filter.mode {
        case .open:
            projectState.openItems
        case .closed:
            projectState.closedItems
        case .templates:
            projectState.templateItems
        }

        let filtered = items.filter { self.filter.matches($0) }
        return self.filter.sorted(filtered)
    }

    var allProjects: [Project] {
        self.settings.sidebarTree.allProjects
    }

    // MARK: - Project Management

    func selectProject(_ project: Project) {
        self.selectedProjectID = project.id
    }

    func selectItem(_ item: Item) {
        self.selectedItemID = item.id
    }

    func clearItemSelection() {
        self.selectedItemID = nil
    }

    private func onProjectSelectionChanged() {
        DZLog("onProjectSelectionChanged: selectedProjectID=\(String(describing: self.selectedProjectID))")

        // Clear item selection when project changes
        self.selectedItemID = nil

        // Start watching new project
        if let project = self.selectedProject {
            DZLog("Selected project: \(project.name) at \(project.path.path)")
            self.projectManager.startWatching(project: project)

            // Load items if not already loaded
            let state = self.projectManager.state(for: project)
            DZLog("State openItems.isEmpty=\(state.openItems.isEmpty), isLoading=\(state.isLoading)")
            if state.openItems.isEmpty, !state.isLoading {
                DZLog("Starting loadItems task")
                Task {
                    await state.loadItems()
                }
            }
        } else {
            DZLog("No project selected")
            self.projectManager.stopWatching()
        }
    }

    // MARK: - Global Search

    func performGlobalSearch() async {
        let query = self.globalSearchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            self.globalSearchResults = []
            return
        }

        self.isGlobalSearching = true
        var results: [GlobalSearchResult] = []

        for project in self.allProjects {
            do {
                let items = try await self.service.search(query: query, in: project, fullText: true)
                if !items.isEmpty {
                    results.append(GlobalSearchResult(project: project, items: items))
                }
            } catch {
                DZErrorLog(error)
            }
        }

        self.globalSearchResults = results
        self.isGlobalSearching = false
    }

    func clearGlobalSearch() {
        self.globalSearchQuery = ""
        self.globalSearchResults = []
    }

    // MARK: - Item Operations

    func createItem(title: String, labels: [String] = [], category: String? = nil) async throws -> Item? {
        guard let projectState = self.currentProjectState else { return nil }
        let item = try await projectState.createItem(title: title, labels: labels, category: category)
        self.selectedItemID = item.id
        return item
    }

    func createTemplate(title: String, labels: [String] = []) async throws -> Item? {
        guard let projectState = self.currentProjectState else { return nil }
        let item = try await projectState.createTemplate(title: title, labels: labels)
        self.filter.mode = .templates
        self.selectedItemID = item.id
        return item
    }

    func closeSelectedItem() async throws {
        guard
            let item = self.selectedItem,
            let projectState = self.currentProjectState else { return }
        try await projectState.closeItem(item)
        self.selectedItemID = nil
    }

    func reopenSelectedItem() async throws {
        guard
            let item = self.selectedItem,
            let projectState = self.currentProjectState else { return }
        try await projectState.reopenItem(item)
        self.selectedItemID = nil
    }
}
