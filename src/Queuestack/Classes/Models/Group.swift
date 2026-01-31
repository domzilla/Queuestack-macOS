//
//  Group.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation

/// A UI-only container for organizing projects in the sidebar.
/// Groups can contain other groups and projects (nested hierarchy).
/// They have no filesystem representation.
struct Group: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var children: [SidebarNode]
    var isExpanded: Bool

    init(
        id: UUID = UUID(),
        name: String,
        children: [SidebarNode] = [],
        isExpanded: Bool = true
    ) {
        self.id = id
        self.name = name
        self.children = children
        self.isExpanded = isExpanded
    }
}
