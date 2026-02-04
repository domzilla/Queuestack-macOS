//
//  Item.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation

struct Item: Identifiable, Hashable {
    let id: String
    var title: String
    var author: String
    var createdAt: Date
    var status: Status
    var labels: [String]
    var attachments: [String]
    var category: String?
    var body: String
    let filePath: URL
    let isTemplate: Bool

    enum Status: String, Codable, Hashable {
        case open
        case closed
    }
}

extension Item {
    static func placeholder(id: String = "000000-XXXXXX", isTemplate: Bool = false) -> Item {
        Item(
            id: id,
            title: "Untitled",
            author: "Unknown",
            createdAt: Date(),
            status: .open,
            labels: [],
            attachments: [],
            category: nil,
            body: "",
            filePath: URL(filePath: "/tmp/placeholder.md"),
            isTemplate: isTemplate
        )
    }
}
