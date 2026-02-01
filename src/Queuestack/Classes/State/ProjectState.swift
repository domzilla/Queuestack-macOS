//
//  ProjectState.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import Foundation

/// State for a single project's items
@Observable
@MainActor
final class ProjectState {
    let project: Project

    private(set) var openItems: [Item] = []
    private(set) var closedItems: [Item] = []
    private(set) var templateItems: [Item] = []
    private(set) var labels: [Label] = []
    private(set) var categories: [Category] = []

    private(set) var isLoading = false
    private(set) var error: (any Error)?

    private let service: Service

    /// Per-item serial queues for refresh operations.
    /// Ensures same item isn't refreshed concurrently, but different items can refresh in parallel.
    private var itemRefreshQueues: [String: AsyncStream<Void>.Continuation] = [:]

    /// Tracks last processed modification date per path to skip stale refreshes.
    private var lastProcessedModificationDates: [String: Date] = [:]

    init(project: Project, service: Service) {
        self.project = project
        self.service = service
    }

    /// Records modification dates for loaded items to enable stale refresh detection.
    private func recordModificationDates(for items: [Item]) {
        for item in items {
            let path = item.filePath.path
            if
                let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                let modDate = attrs[.modificationDate] as? Date
            {
                self.lastProcessedModificationDates[path] = modDate
            }
        }
    }

    /// Gets or creates a serial refresh queue for a specific item path.
    private func refreshQueue(for path: String) -> AsyncStream<Void>.Continuation {
        if let existing = self.itemRefreshQueues[path] {
            return existing
        }

        let stream = AsyncStream<Void> { continuation in
            self.itemRefreshQueues[path] = continuation
        }

        // Start consumer task for this item
        Task { [weak self] in
            for await _ in stream {
                guard let self else { break }
                await self.processRefresh(path: path)
            }
            // Clean up when stream ends
            self?.itemRefreshQueues.removeValue(forKey: path)
        }

        return self.itemRefreshQueues[path]!
    }

    // MARK: - All Items

    var allItems: [Item] {
        self.openItems + self.closedItems + self.templateItems
    }

    func item(withID id: String) -> Item? {
        self.allItems.first { $0.id == id }
    }

    // MARK: - Loading

    func loadItems() async {
        DZLog("loadItems() starting for project: \(self.project.name)")
        self.isLoading = true
        self.error = nil

        do {
            let (open, closed, templates) = try await self.service.loadAllItems(in: self.project)
            DZLog("Loaded: \(open.count) open, \(closed.count) closed, \(templates.count) templates")
            self.openItems = open
            self.closedItems = closed
            self.templateItems = templates

            // Record modification dates to skip stale FSEvents refreshes
            self.recordModificationDates(for: open + closed + templates)

            // Compute labels and categories from loaded items
            self.computeLabelsAndCategories()
        } catch {
            self.error = error
            DZLog("loadItems error: \(error)")
            DZErrorLog(error)
        }

        self.isLoading = false
        DZLog("loadItems() finished, isLoading=\(self.isLoading)")
    }

    func refresh() async {
        await self.loadItems()
    }

    /// Refresh only specific items that changed (incremental update).
    /// Each item has its own serial queue - different items refresh in parallel, same item serialized.
    func refreshItems(at paths: [String]) {
        for path in paths {
            DZLog("refreshItems(at:) queuing: \(path)")
            self.refreshQueue(for: path).yield()
        }
    }

    /// Processes a refresh for a single item (called serially per-item from queue consumer).
    private func processRefresh(path: String) async {
        let fileURL = URL(filePath: path)

        // Check if file still exists
        if FileManager.default.fileExists(atPath: path) {
            // Check modification date to skip stale refreshes
            if
                let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                let modDate = attrs[.modificationDate] as? Date
            {
                if
                    let lastProcessed = self.lastProcessedModificationDates[path],
                    modDate <= lastProcessed
                {
                    DZLog("processRefresh() skipping stale: \(path)")
                    return
                }
                self.lastProcessedModificationDates[path] = modDate
            }

            // File exists - read and update/add
            do {
                let updatedItem = try self.service.readItem(at: fileURL, in: self.project)
                self.updateOrAddItem(updatedItem)
                DZLog("processRefresh() updated: \(updatedItem.id)")
            } catch {
                DZLog("processRefresh() failed: \(path) - \(error)")
            }
        } else {
            // File was deleted - remove from arrays and tracking
            self.removeItem(at: fileURL)
            self.lastProcessedModificationDates.removeValue(forKey: path)
            DZLog("processRefresh() removed: \(path)")
        }

        // Recompute labels and categories
        self.computeLabelsAndCategories()
    }

    private func updateOrAddItem(_ item: Item) {
        // Determine which array the item belongs to
        if item.isTemplate {
            if let index = self.templateItems.firstIndex(where: { $0.id == item.id }) {
                self.templateItems[index] = item
            } else {
                self.templateItems.append(item)
            }
        } else if item.status == .closed {
            // Remove from open if it was there (status changed)
            self.openItems.removeAll { $0.id == item.id }
            if let index = self.closedItems.firstIndex(where: { $0.id == item.id }) {
                self.closedItems[index] = item
            } else {
                self.closedItems.append(item)
            }
        } else {
            // Remove from closed if it was there (status changed)
            self.closedItems.removeAll { $0.id == item.id }
            if let index = self.openItems.firstIndex(where: { $0.id == item.id }) {
                self.openItems[index] = item
            } else {
                self.openItems.append(item)
            }
        }
    }

    private func removeItem(at fileURL: URL) {
        self.openItems.removeAll { $0.filePath == fileURL }
        self.closedItems.removeAll { $0.filePath == fileURL }
        self.templateItems.removeAll { $0.filePath == fileURL }
    }

    private func computeLabelsAndCategories() {
        // Compute labels
        var labelCounts: [String: Int] = [:]
        for item in self.allItems {
            for label in item.labels {
                labelCounts[label, default: 0] += 1
            }
        }
        self.labels = labelCounts.map { Label(name: $0.key, itemCount: $0.value) }
            .sorted { $0.name < $1.name }

        // Compute categories
        var categoryCounts: [String: Int] = [:]
        for item in self.allItems {
            if let category = item.category {
                categoryCounts[category, default: 0] += 1
            }
        }
        self.categories = categoryCounts.map { Category(name: $0.key, itemCount: $0.value) }
            .sorted { $0.name < $1.name }
    }

    // MARK: - Item Operations

    func createItem(title: String, labels: [String], category: String?) async throws -> Item {
        let item = try await self.service.createItem(
            title: title,
            labels: labels,
            category: category,
            in: self.project
        )
        await self.refresh()
        return item
    }

    func createTemplate(title: String, labels: [String]) async throws -> Item {
        let item = try await self.service.createTemplate(
            title: title,
            labels: labels,
            in: self.project
        )
        await self.refresh()
        return item
    }

    func updateBody(of item: Item, to newBody: String) throws {
        try self.service.updateBody(of: item, to: newBody)

        // Update the in-memory item immediately
        var updatedItem = item
        updatedItem.body = newBody
        self.updateOrAddItem(updatedItem)
    }

    func closeItem(_ item: Item) async throws {
        try await self.service.close(item: item, in: self.project)
        self.refreshItems(at: [item.filePath.path])
    }

    func reopenItem(_ item: Item) async throws {
        try await self.service.reopen(item: item, in: self.project)
        self.refreshItems(at: [item.filePath.path])
    }

    func addLabels(_ labels: [String], to item: Item) async throws {
        try await self.service.addLabels(labels, to: item, in: self.project)
        self.refreshItems(at: [item.filePath.path])
    }

    func removeLabels(_ labels: [String], from item: Item) async throws {
        try await self.service.removeLabels(labels, from: item, in: self.project)
        self.refreshItems(at: [item.filePath.path])
    }

    func updateCategory(of item: Item, to category: String?) async throws {
        try await self.service.updateCategory(of: item, to: category, in: self.project)
        self.refreshItems(at: [item.filePath.path])
    }

    func updateTitle(of item: Item, to newTitle: String) async throws -> Item {
        let updated = try await self.service.updateTitle(of: item, to: newTitle, in: self.project)
        await self.refresh()
        return updated
    }

    // MARK: - Attachments

    func addAttachment(_ attachment: String, to item: Item) async throws {
        try await self.service.addAttachment(attachment, to: item, in: self.project)
        self.refreshItems(at: [item.filePath.path])
    }

    func addAttachments(_ attachments: [String], to item: Item) async throws {
        for attachment in attachments {
            try await self.service.addAttachment(attachment, to: item, in: self.project)
        }
        self.refreshItems(at: [item.filePath.path])
    }

    func removeAttachment(at index: Int, from item: Item) async throws {
        try await self.service.removeAttachment(at: index, from: item, in: self.project)
        self.refreshItems(at: [item.filePath.path])
    }

    func removeAttachments(at indices: [Int], from item: Item) async throws {
        // Delete in reverse order to maintain correct indices
        for index in indices.sorted(by: >) {
            try await self.service.removeAttachment(at: index, from: item, in: self.project)
        }
        self.refreshItems(at: [item.filePath.path])
    }

    // MARK: - Search

    func search(query: String, fullText: Bool = false, closed: Bool = false) async throws -> [Item] {
        try await self.service.search(query: query, in: self.project, fullText: fullText, closed: closed)
    }
}
