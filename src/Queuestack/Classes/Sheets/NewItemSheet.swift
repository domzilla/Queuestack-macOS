//
//  NewItemSheet.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import SwiftUI

struct NewItemSheet: View {
    @Environment(WindowState.self) private var windowState
    @Environment(\.dismiss) private var dismiss

    let isTemplate: Bool

    @State private var title = ""
    @State private var selectedLabels: Set<String> = []
    @State private var selectedCategory: String?
    @State private var newCategoryText = ""
    @State private var newLabelText = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text(self.sheetTitle)
                .font(.headline)

            // Title field
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Title", comment: "Title field label"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(
                    String(localized: "Enter title...", comment: "Title placeholder"),
                    text: self.$title
                )
                .textFieldStyle(.roundedBorder)
                .focused(self.$isTitleFocused)
            }

            // Labels section
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Labels", comment: "Labels section header"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                self.labelsContent
            }

            // Category section (only for non-templates)
            if !self.isTemplate {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Category", comment: "Category section header"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    self.categoryContent
                }
            }

            if let errorMessage = self.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Button(String(localized: "Cancel", comment: "Cancel button")) {
                    self.dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(String(localized: "Create", comment: "Create button")) {
                    self.createItem()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(self.title.trimmingCharacters(in: .whitespaces).isEmpty || self.isCreating)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            self.isTitleFocused = true
        }
    }

    private var sheetTitle: String {
        if self.isTemplate {
            return String(localized: "New Template", comment: "New template sheet title")
        }
        return String(localized: "New Item", comment: "New item sheet title")
    }

    @ViewBuilder
    private var labelsContent: some View {
        let existingLabels = self.windowState.currentProjectState?.labels ?? []

        if existingLabels.isEmpty, self.newLabelText.isEmpty {
            Text(String(localized: "No labels yet", comment: "No labels placeholder"))
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            FlowLayout(spacing: 4) {
                ForEach(existingLabels) { label in
                    self.labelToggle(label.name)
                }
            }
        }

        HStack {
            TextField(
                String(localized: "New label...", comment: "New label placeholder"),
                text: self.$newLabelText
            )
            .textFieldStyle(.roundedBorder)

            Button(String(localized: "Add", comment: "Add label button")) {
                self.addNewLabel()
            }
            .disabled(self.newLabelText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    @ViewBuilder
    private func labelToggle(_ label: String) -> some View {
        let isSelected = self.selectedLabels.contains(label)
        Button {
            if isSelected {
                self.selectedLabels.remove(label)
            } else {
                self.selectedLabels.insert(label)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                Text(label)
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    // NOTE: Using custom radio buttons instead of Picker with .radioGroup style
    // because we need mutual exclusion between radio selection and text field:
    // - Typing in text field clears radio selection
    // - Selecting a radio option clears text field
    // Native Picker doesn't support this interaction pattern.
    @ViewBuilder
    private var categoryContent: some View {
        let existingCategories = self.windowState.currentProjectState?.categories ?? []

        // None option
        self.noneOption

        // Existing categories as radio buttons
        ForEach(existingCategories) { category in
            self.categoryOption(category.name)
        }

        // New category text field
        TextField(
            String(localized: "New category...", comment: "New category placeholder"),
            text: self.$newCategoryText
        )
        .textFieldStyle(.roundedBorder)
        .onChange(of: self.newCategoryText) { _, newValue in
            if !newValue.isEmpty {
                self.selectedCategory = nil
            }
        }
    }

    private var noneOption: some View {
        let isSelected = self.selectedCategory == nil && self.newCategoryText.isEmpty

        return Button {
            self.selectedCategory = nil
            self.newCategoryText = ""
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                Text(String(localized: "None", comment: "No category option"))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func categoryOption(_ category: String) -> some View {
        let isSelected = self.selectedCategory == category

        Button {
            self.selectedCategory = category
            self.newCategoryText = ""
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                Text(category)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func addNewLabel() {
        let label = self.newLabelText.trimmingCharacters(in: .whitespaces)
        guard !label.isEmpty else { return }
        self.selectedLabels.insert(label)
        self.newLabelText = ""
    }

    private func createItem() {
        let itemTitle = self.title.trimmingCharacters(in: .whitespaces)
        guard !itemTitle.isEmpty else { return }

        self.isCreating = true
        self.errorMessage = nil

        Task {
            do {
                if self.isTemplate {
                    _ = try await self.windowState.createTemplate(
                        title: itemTitle,
                        labels: Array(self.selectedLabels)
                    )
                } else {
                    let trimmedNew = self.newCategoryText.trimmingCharacters(in: .whitespaces)
                    let category = self.selectedCategory ?? (trimmedNew.isEmpty ? nil : trimmedNew)
                    _ = try await self.windowState.createItem(
                        title: itemTitle,
                        labels: Array(self.selectedLabels),
                        category: category
                    )
                }
                self.dismiss()
            } catch {
                self.errorMessage = error.localizedDescription
                DZErrorLog(error)
            }
            self.isCreating = false
        }
    }
}

#Preview {
    NewItemSheet(isTemplate: false)
        .environment(WindowState(services: AppServices()))
}
