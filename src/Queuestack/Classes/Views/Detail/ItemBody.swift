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
    @FocusState private var isFocused: Bool

    var body: some View {
        @Bindable var appState = self.appState

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Text(String(localized: "Body", comment: "Body section header"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if self.appState.hasUnsavedBodyChanges {
                        Circle()
                            .fill(.orange)
                            .frame(width: 6, height: 6)

                        Button {
                            self.appState.discardBodyChanges()
                        } label: {
                            Text(String(localized: "Discard", comment: "Discard changes button"))
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.orange)
                    }
                }

                Spacer()
            }

            TextEditor(text: $appState.editingBodyText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(maxHeight: .infinity)
                .focused(self.$isFocused)
        }
        .frame(maxHeight: .infinity)
        .onKeyPress(phases: .down) { press in
            if press.key == "s", press.modifiers.contains(.command) {
                self.appState.saveBodyChanges()
                return .handled
            }
            return .ignored
        }
    }
}

#Preview {
    ItemBody()
        .environment(AppState())
        .padding()
}
