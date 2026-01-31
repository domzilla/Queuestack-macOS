//
//  ProjectStateManager.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import Foundation

/// Manages ProjectState instances for multiple projects
@Observable
@MainActor
final class ProjectStateManager {
    private var states: [UUID: ProjectState] = [:]
    private let service: Service
    private let watcher = FSEventWatcher()

    private var watchedProjectID: UUID?

    init(service: Service) {
        self.service = service
    }

    /// Get or create state for a project
    func state(for project: Project) -> ProjectState {
        if let existing = self.states[project.id] {
            return existing
        }

        let state = ProjectState(project: project, service: self.service)
        self.states[project.id] = state
        return state
    }

    /// Remove cached state for a project
    func removeState(for projectID: UUID) {
        self.states.removeValue(forKey: projectID)
        if self.watchedProjectID == projectID {
            self.watcher.stop()
            self.watchedProjectID = nil
        }
    }

    /// Start watching a project for file changes
    func startWatching(project: Project) {
        // Don't restart if already watching this project
        if self.watchedProjectID == project.id, self.watcher.isWatching {
            return
        }

        self.watchedProjectID = project.id

        self.watcher.start(path: project.stackURL) { [weak self] changedPaths in
            guard let self else { return }
            Task { @MainActor in
                DZLog("File change detected for \(changedPaths.count) file(s)")
                if let state = self.states[project.id] {
                    await state.refreshItems(at: changedPaths)
                }
            }
        }
    }

    /// Stop watching current project
    func stopWatching() {
        self.watcher.stop()
        self.watchedProjectID = nil
    }
}
