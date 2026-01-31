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
    let settings: SettingsManager
    let service: Service
    let projectManager: ProjectStateManager

    init() {
        self.settings = SettingsManager()
        self.service = Service(binaryPath: self.settings.cliBinaryPath)
        self.projectManager = ProjectStateManager(service: self.service)
    }

    var allProjects: [Project] {
        self.settings.sidebarTree.allProjects
    }
}
