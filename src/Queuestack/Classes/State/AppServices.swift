//
//  AppServices.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation

/// Shared services and dependencies available to all windows
@Observable
@MainActor
final class AppServices {
    let projects: ProjectManager
    let service: Service
    let projectState: ProjectStateManager

    init() {
        self.projects = ProjectManager()
        self.service = Service(binaryPath: CLIConstants.defaultBinaryPath)
        self.projectState = ProjectStateManager(service: self.service)
    }

    var allProjects: [Project] {
        self.projects.sidebarTree.allProjects
    }
}
