//
//  ProjectAdditionError.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation

/// Error type for project addition validation failures.
enum ProjectAdditionError: LocalizedError {
    case notQueuestackProject(name: String)
    case alreadyAdded(name: String)

    var errorDescription: String? {
        switch self {
        case let .notQueuestackProject(name):
            String(
                localized: "Not a queuestack project: \(name)",
                comment: "Error when folder is not a queuestack project"
            )
        case let .alreadyAdded(name):
            String(localized: "Project already added: \(name)", comment: "Error when project is already in sidebar")
        }
    }
}
