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

    init(project: Project, service: Service) {
        self.project = project
        self.service = service
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
    }

    func closeItem(_ item: Item) async throws {
        try await self.service.close(item: item, in: self.project)
        await self.refresh()
    }

    func reopenItem(_ item: Item) async throws {
        try await self.service.reopen(item: item, in: self.project)
        await self.refresh()
    }

    func addLabels(_ labels: [String], to item: Item) async throws {
        try await self.service.addLabels(labels, to: item, in: self.project)
        await self.refresh()
    }

    func removeLabels(_ labels: [String], from item: Item) async throws {
        try await self.service.removeLabels(labels, from: item, in: self.project)
        await self.refresh()
    }

    func updateCategory(of item: Item, to category: String?) async throws {
        try await self.service.updateCategory(of: item, to: category, in: self.project)
        await self.refresh()
    }

    func updateTitle(of item: Item, to newTitle: String) async throws -> Item {
        let updated = try await self.service.updateTitle(of: item, to: newTitle, in: self.project)
        await self.refresh()
        return updated
    }

    // MARK: - Attachments

    func addAttachment(_ attachment: String, to item: Item) async throws {
        try await self.service.addAttachment(attachment, to: item, in: self.project)
        await self.refresh()
    }

    func removeAttachment(at index: Int, from item: Item) async throws {
        try await self.service.removeAttachment(at: index, from: item, in: self.project)
        await self.refresh()
    }

    // MARK: - Search

    func search(query: String, fullText: Bool = false, closed: Bool = false) async throws -> [Item] {
        try await self.service.search(query: query, in: self.project, fullText: fullText, closed: closed)
    }
}
