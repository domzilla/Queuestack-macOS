//
//  UpdateController.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 10/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Sparkle

/// Manages Sparkle software updates
@Observable
@MainActor
final class UpdateController: NSObject, SPUStandardUserDriverDelegate {
    private(set) var canCheckForUpdates = false

    private var controller: SPUStandardUpdaterController!
    private var observation: NSKeyValueObservation?

    override init() {
        super.init()
        self.controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: self
        )
        self.observation = self.controller.updater.observe(
            \.canCheckForUpdates,
            options: [.initial, .new]
        ) { [weak self] _, change in
            let newValue = change.newValue ?? false
            Task { @MainActor in
                self?.canCheckForUpdates = newValue
            }
        }
    }

    nonisolated func supportsGentleScheduledUpdateReminders() -> Bool {
        true
    }

    func checkForUpdates() {
        self.controller.checkForUpdates(nil)
    }
}
