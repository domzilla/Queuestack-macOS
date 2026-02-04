//
//  NotificationNames.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation

extension Notification.Name {
    /// Posted when the user requests to create a new item.
    static let createNewItem = Notification.Name("createNewItem")

    /// Posted when the user requests to create a new template.
    static let createNewTemplate = Notification.Name("createNewTemplate")
}
