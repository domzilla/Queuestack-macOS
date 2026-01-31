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
    @State private var isSaving = false
    @FocusState private var isFocused: Bool

    private let debounceInterval: TimeInterval = 0.5
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "Body", comment: "Body section header"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if self.isSaving {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.small)
                        Text(String(localized: "Saving...", comment: "Saving indicator"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            TextEditor(text: self.$bodyText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(maxHeight: .infinity)
                .focused(self.$isFocused)
                .onChange(of: self.bodyText) { _, newValue in
                    self.scheduleAutoSave(newValue)
                }
        }
        .frame(maxHeight: .infinity)
        .onAppear {
            self.bodyText = self.item.body
        }
        .onChange(of: self.item.id) { _, _ in
            self.bodyText = self.item.body
        }
    }

    private func scheduleAutoSave(_ newBody: String) {
        // Cancel any pending save
        self.saveTask?.cancel()

        // Don't save if content hasn't actually changed from the item
        guard newBody != self.item.body else { return }

        // Schedule new save after debounce interval
        self.saveTask = Task {
            try? await Task.sleep(for: .seconds(self.debounceInterval))

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.performSave(newBody)
            }
        }
    }

    private func performSave(_ newBody: String) {
        self.isSaving = true

        do {
            try self.appState.currentProjectState?.updateBody(of: self.item, to: newBody)
        } catch {
            DZErrorLog(error)
        }

        self.isSaving = false
    }
}

#Preview {
    ItemBody(item: Item.placeholder())
        .environment(AppState())
        .padding()
}
