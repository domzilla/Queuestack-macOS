//
//  WindowState.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import Foundation

/// Per-window state for selection, editing, filtering, and search
@Observable
@MainActor
final class WindowState {
    // MARK: - Shared Services

    let services: AppServices

    // MARK: - Selection State

    var selectedProjectID: UUID?
    var selectedItemID: String?

    // MARK: - Body Editing State

    /// The item ID whose body is currently being edited
    private(set) var editingBodyItemID: String?
    /// The current body text being edited
    var editingBodyText: String = ""
    /// The last saved body text (to detect unsaved changes)
    private(set) var savedBodyText: String = ""

    var hasUnsavedBodyChanges: Bool {
        self.editingBodyItemID != nil && self.editingBodyText != self.savedBodyText
    }

    /// Call this when project selection changes (use .onChange in views)
    func handleProjectSelectionChange() {
        self.onProjectSelectionChanged()
    }

    // MARK: - Filter State

    var filter = ItemFilter()

    // MARK: - Global Search

    enum GlobalSearchScope: String, CaseIterable, Identifiable {
        case open
        case closed
        case template

        var id: String { self.rawValue }

        var localizedName: String {
            switch self {
            case .open:
                String(localized: "Open", comment: "Global search scope: open items")
            case .closed:
                String(localized: "Closed", comment: "Global search scope: closed items")
            case .template:
                String(localized: "Template", comment: "Global search scope: templates")
            }
        }
    }

    var globalSearchQuery = ""
    var globalSearchScope: GlobalSearchScope = .open
    var globalSearchResults: [GlobalSearchResult] = []
    var isGlobalSearching = false

    /// Item to select after project change (for navigation from global search)
    private var pendingItemID: String?

    struct GlobalSearchResult: Identifiable {
        let id = UUID()
        let project: Project
        let items: [Item]
    }

    // MARK: - Initialization

    init(services: AppServices) {
        self.services = services
    }

    // MARK: - Computed Properties

    var selectedProject: Project? {
        guard let id = self.selectedProjectID else { return nil }
        return self.services.projects.sidebarTree.findProject(id: id)
    }

    var currentProjectState: ProjectState? {
        guard let project = self.selectedProject else { return nil }
        return self.services.projectState.state(for: project)
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
        self.services.allProjects
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

    // MARK: - Body Editing

    /// Start editing an item's body
    func startEditingBody(for item: Item) {
        self.editingBodyItemID = item.id
        self.editingBodyText = item.body
        self.savedBodyText = item.body
    }

    /// Save the current body changes
    func saveBodyChanges() {
        guard
            self.hasUnsavedBodyChanges,
            let itemID = self.editingBodyItemID,
            let projectState = self.currentProjectState,
            let item = projectState.item(withID: itemID) else { return }

        do {
            try projectState.updateBody(of: item, to: self.editingBodyText)
            self.savedBodyText = self.editingBodyText
        } catch {
            DZErrorLog(error)
        }
    }

    /// Discard body changes and revert to saved state
    func discardBodyChanges() {
        self.editingBodyText = self.savedBodyText
    }

    /// Clear body editing state (when switching items after save/discard)
    func clearBodyEditing() {
        self.editingBodyItemID = nil
        self.editingBodyText = ""
        self.savedBodyText = ""
    }

    /// Sync editing state with item if there are no local unsaved changes
    /// Called when the underlying item is updated externally (e.g., from another window)
    func syncBodyWithItem(_ item: Item) {
        guard
            self.editingBodyItemID == item.id,
            !self.hasUnsavedBodyChanges else { return }

        self.editingBodyText = item.body
        self.savedBodyText = item.body
    }

    private func onProjectSelectionChanged() {
        DZLog("onProjectSelectionChanged: selectedProjectID=\(String(describing: self.selectedProjectID))")

        // Use pending item from global search navigation, or clear selection
        if let pending = self.pendingItemID {
            self.selectedItemID = pending
            self.pendingItemID = nil
        } else {
            self.selectedItemID = nil
        }

        // Start watching new project
        if let project = self.selectedProject {
            DZLog("Selected project: \(project.name) at \(project.path.path)")
            self.services.projectState.startWatching(project: project)

            // Always reload items to ensure fresh data (external tools may have modified files)
            let state = self.services.projectState.state(for: project)
            if !state.isLoading {
                Task {
                    await state.loadItems()
                }
            }
        } else {
            DZLog("No project selected")
            self.services.projectState.stopWatching()
        }
    }

    // MARK: - Global Search

    func performGlobalSearch() async {
        let query = self.globalSearchQuery.trimmingCharacters(in: .whitespaces)
        DZLog("performGlobalSearch called with query: '\(query)' scope: \(self.globalSearchScope)")
        guard !query.isEmpty else {
            self.globalSearchResults = []
            return
        }

        self.isGlobalSearching = true
        var results: [GlobalSearchResult] = []

        for project in self.allProjects {
            do {
                let items: [Item]
                switch self.globalSearchScope {
                case .open:
                    items = try await self.services.service.search(
                        query: query,
                        in: project,
                        fullText: true
                    )
                case .closed:
                    items = try await self.services.service.search(
                        query: query,
                        in: project,
                        fullText: true,
                        closed: true
                    )
                case .template:
                    // CLI doesn't support template search, filter client-side
                    let allTemplates = try await self.services.service.listTemplates(in: project)
                    let lowercasedQuery = query.lowercased()
                    items = allTemplates.filter { $0.title.lowercased().contains(lowercasedQuery) }
                }

                DZLog("Search in \(project.name): found \(items.count) items")
                if !items.isEmpty {
                    results.append(GlobalSearchResult(project: project, items: items))
                }
            } catch {
                DZErrorLog(error)
            }
        }

        DZLog("Global search complete: \(results.count) projects with results")
        self.globalSearchResults = results
        self.isGlobalSearching = false
    }

    func clearGlobalSearch() {
        self.globalSearchQuery = ""
        self.globalSearchResults = []
    }

    func navigateToSearchResult(_ item: Item, in project: Project) {
        if self.selectedProjectID == project.id {
            // Same project: directly select the item
            self.selectedItemID = item.id
        } else {
            // Different project: use pending mechanism (onChange will consume it)
            self.pendingItemID = item.id
            self.selectedProjectID = project.id
        }
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
