//
//  QueuestackApp.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import AppKit
import SwiftUI

@main
struct QueuestackApp: App {
    @State private var services = AppServices()
    @FocusedValue(\.windowState) private var focusedWindowState
    @Environment(\.openWindow) private var openWindow

    init() {
        // Disable window tabbing - app uses separate windows, not tabs
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(self.services)
        }
        .defaultSize(width: 1100, height: 700)
        .commands {
            // Replace default "New Window" (⌘N) with ⇧⌘N
            CommandGroup(replacing: .newItem) {
                Button(String(localized: "New Item...", comment: "Menu item to create item")) {
                    NotificationCenter.default.post(name: .createNewItem, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                .disabled(self.focusedWindowState?.selectedProject == nil)

                Button(String(localized: "New Template...", comment: "Menu item to create template")) {
                    NotificationCenter.default.post(name: .createNewTemplate, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                .disabled(self.focusedWindowState?.selectedProject == nil)

                Divider()

                Button(String(localized: "New Window", comment: "Menu item to create new window")) {
                    self.openWindow(id: "main")
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}
