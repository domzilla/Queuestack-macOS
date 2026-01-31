//
//  ItemBody.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import SwiftUI

struct ItemBody: View {
    @Environment(AppState.self) private var appState

    let item: Item

    @State private var bodyText: String = ""
    @FocusState private var isFocused: Bool

    private var hasUnsavedChanges: Bool {
        self.bodyText != self.item.body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Text(String(localized: "Body", comment: "Body section header"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if self.hasUnsavedChanges {
                        Circle()
                            .fill(.orange)
                            .frame(width: 6, height: 6)
                    }
                }

                Spacer()
            }

            TextEditor(text: self.$bodyText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(maxHeight: .infinity)
                .focused(self.$isFocused)
        }
        .frame(maxHeight: .infinity)
        .onAppear {
            self.bodyText = self.item.body
        }
        .onDisappear {
            self.saveIfNeeded()
        }
        .onChange(of: self.item.id) { oldID, newID in
            // Save previous item before switching
            if oldID != newID {
                self.saveIfNeeded()
            }
            self.bodyText = self.item.body
        }
        .onKeyPress(phases: .down) { press in
            if press.key == "s", press.modifiers.contains(.command) {
                self.saveIfNeeded()
                return .handled
            }
            return .ignored
        }
    }

    private func saveIfNeeded() {
        guard self.hasUnsavedChanges else { return }

        do {
            try self.appState.currentProjectState?.updateBody(of: self.item, to: self.bodyText)
        } catch {
            DZErrorLog(error)
        }
    }
}

#Preview {
    ItemBody(item: Item.placeholder())
        .environment(AppState())
        .padding()
}
