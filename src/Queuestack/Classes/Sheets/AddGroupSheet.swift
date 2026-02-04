//
//  AddGroupSheet.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct AddGroupSheet: View {
    @Environment(WindowState.self) private var windowState
    @Environment(\.dismiss) private var dismiss

    let targetGroupID: UUID?

    @State private var groupName = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text(String(localized: "New Group", comment: "New group sheet title"))
                .font(.headline)

            TextField(
                String(localized: "Group Name", comment: "Group name text field placeholder"),
                text: self.$groupName
            )
            .textFieldStyle(.roundedBorder)
            .focused(self.$isNameFocused)

            HStack {
                Button(String(localized: "Cancel", comment: "Cancel button")) {
                    self.dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(String(localized: "Create", comment: "Create button")) {
                    self.createGroup()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(self.groupName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            self.isNameFocused = true
        }
    }

    private func createGroup() {
        let name = self.groupName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        self.windowState.services.projects.addGroup(name: name, toGroupWithID: self.targetGroupID)
        self.dismiss()
    }
}
