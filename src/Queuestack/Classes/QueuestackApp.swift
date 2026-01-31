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
            // Replace default "New Window" (⌘N) with ⇧⌘N
            CommandGroup(replacing: .newItem) {
                Button(String(localized: "New Item...", comment: "Menu item to create item")) {
                    NotificationCenter.default.post(name: .createNewItem, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                .disabled(self.appState.selectedProject == nil)

                Button(String(localized: "New Template...", comment: "Menu item to create template")) {
                    NotificationCenter.default.post(name: .createNewTemplate, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                .disabled(self.appState.selectedProject == nil)

                Divider()

                Button(String(localized: "New Window", comment: "Menu item to create new window")) {
                    NSApp.sendAction(#selector(NSDocumentController.newDocument(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}

extension Notification.Name {
    static let createNewItem = Notification.Name("createNewItem")
    static let createNewTemplate = Notification.Name("createNewTemplate")
}
