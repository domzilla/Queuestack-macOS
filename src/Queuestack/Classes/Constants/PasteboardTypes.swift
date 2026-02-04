//
//  PasteboardTypes.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 01/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import AppKit

extension NSPasteboard.PasteboardType {
    /// Custom pasteboard type for sidebar node drag & drop.
    static let sidebarNode = NSPasteboard.PasteboardType("com.dominicrodemer.queuestack.sidebarnode")
}
