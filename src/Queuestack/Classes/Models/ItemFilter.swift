//
//  ItemFilter.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation

struct ItemFilter: Equatable {
    var mode: FilterMode
    var searchQuery: String
    var sortOrder: SortOrder
    var category: String?

    init(
        mode: FilterMode = .open,
        searchQuery: String = "",
        sortOrder: SortOrder = .id,
        category: String? = nil
    ) {
        self.mode = mode
        self.searchQuery = searchQuery
        self.sortOrder = sortOrder
        self.category = category
    }

    enum FilterMode: String, CaseIterable {
        case open
        case closed
        case templates
    }

    enum SortOrder: String, CaseIterable {
        case id
        case date
        case title
        case category

        var displayName: String {
            switch self {
            case .id: String(localized: "ID", comment: "Sort by ID")
            case .date: String(localized: "Date", comment: "Sort by date")
            case .title: String(localized: "Title", comment: "Sort by title")
            case .category: String(localized: "Category", comment: "Sort by category")
            }
        }
    }
}

extension ItemFilter {
    func matches(_ item: Item) -> Bool {
        // Mode filter
        switch self.mode {
        case .open:
            if item.status != .open || item.isTemplate { return false }
        case .closed:
            if item.status != .closed { return false }
        case .templates:
            if !item.isTemplate { return false }
        }

        // Category filter
        if let filterCategory = self.category {
            if item.category != filterCategory {
                return false
            }
        }

        // Search filter
        if !self.searchQuery.isEmpty {
            let query = self.searchQuery.lowercased()
            let matchesTitle = item.title.lowercased().contains(query)
            let matchesID = item.id.lowercased().contains(query)
            let matchesLabels = item.labels.contains { $0.lowercased().contains(query) }
            let matchesCategory = item.category?.lowercased().contains(query) ?? false
            if !matchesTitle, !matchesID, !matchesLabels, !matchesCategory {
                return false
            }
        }

        return true
    }

    func sorted(_ items: [Item]) -> [Item] {
        items.sorted { lhs, rhs in
            switch self.sortOrder {
            case .id:
                return lhs.id < rhs.id
            case .date:
                return lhs.createdAt > rhs.createdAt
            case .title:
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            case .category:
                let lhsCat = lhs.category ?? ""
                let rhsCat = rhs.category ?? ""
                if lhsCat != rhsCat {
                    return lhsCat.localizedCaseInsensitiveCompare(rhsCat) == .orderedAscending
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        }
    }
}
