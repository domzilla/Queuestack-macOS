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
    @Environment(WindowState.self) private var windowState
    @FocusState private var isFocused: Bool

    var body: some View {
        @Bindable var windowState = self.windowState

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "Body", comment: "Body section header"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if self.windowState.hasUnsavedBodyChanges {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.orange)
                            .frame(width: 6, height: 6)

                        Button {
                            self.windowState.discardBodyChanges()
                        } label: {
                            Text(String(localized: "Discard", comment: "Discard changes button"))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.orange)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(.orange, lineWidth: 1)
                        )
                    }
                }
            }

            TextEditor(text: $windowState.editingBodyText)
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
                self.windowState.saveBodyChanges()
                return .handled
            }
            return .ignored
        }
    }
}

#Preview {
    ItemBody()
        .environment(WindowState(services: AppServices()))
        .padding()
}
