//
//  QueuestackApp.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

@main
struct QueuestackApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(self.appState)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button(String(localized: "New Template...", comment: "Menu item to create template")) {
                    NotificationCenter.default.post(name: .createNewTemplate, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                .disabled(self.appState.selectedProject == nil)
            }
        }
    }
}

extension Notification.Name {
    static let createNewTemplate = Notification.Name("createNewTemplate")
}
