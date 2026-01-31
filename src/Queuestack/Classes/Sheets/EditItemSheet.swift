//
//  EditItemSheet.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import SwiftUI

struct EditItemSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let item: Item

    @State private var title: String
    @State private var selectedLabels: Set<String>
    @State private var selectedCategory: String?
    @State private var newLabelText = ""
    @State private var newCategoryText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(item: Item) {
        self.item = item
        self._title = State(initialValue: item.title)
        self._selectedLabels = State(initialValue: Set(item.labels))
        self._selectedCategory = State(initialValue: item.category)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(String(localized: "Edit Item", comment: "Edit item sheet title"))
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
            }

            // Labels section
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Labels", comment: "Labels section header"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                self.labelsContent
            }

            // Category section (only for non-templates)
            if !self.item.isTemplate {
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

                Button(String(localized: "Save", comment: "Save button")) {
                    self.saveChanges()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(self.title.trimmingCharacters(in: .whitespaces).isEmpty || self.isSaving)
            }
        }
        .padding()
        .frame(width: 400)
    }

    @ViewBuilder
    private var labelsContent: some View {
        // Combine existing project labels with item's labels
        let projectLabels = Set((self.appState.currentProjectState?.labels ?? []).map(\.name))
        let allLabels = projectLabels.union(self.selectedLabels).sorted()

        if allLabels.isEmpty, self.newLabelText.isEmpty {
            Text(String(localized: "No labels yet", comment: "No labels placeholder"))
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            FlowLayout(spacing: 4) {
                ForEach(allLabels, id: \.self) { label in
                    self.labelToggle(label)
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

    @ViewBuilder
    private var categoryContent: some View {
        let sortedCategories = self.allCategoryNames

        // None option
        self.categoryOption(nil, label: String(localized: "None", comment: "No category option"))

        // All categories
        ForEach(sortedCategories, id: \.self) { category in
            self.categoryOption(category, label: category)
        }

        // New category input
        HStack {
            TextField(
                String(localized: "New category...", comment: "New category placeholder"),
                text: self.$newCategoryText
            )
            .textFieldStyle(.roundedBorder)

            Button(String(localized: "Add", comment: "Add category button")) {
                self.addNewCategory()
            }
            .disabled(self.newCategoryText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var allCategoryNames: [String] {
        var categories = Set((self.appState.currentProjectState?.categories ?? []).map(\.name))
        if let current = self.selectedCategory {
            categories.insert(current)
        }
        return categories.sorted()
    }

    @ViewBuilder
    private func categoryOption(_ category: String?, label: String) -> some View {
        let isSelected = self.selectedCategory == category

        Button {
            self.selectedCategory = category
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                Text(label)
                    .foregroundStyle(category == nil ? Color.secondary : Color.primary)
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

    private func addNewCategory() {
        let category = self.newCategoryText.trimmingCharacters(in: .whitespaces)
        guard !category.isEmpty else { return }
        self.selectedCategory = category
        self.newCategoryText = ""
    }

    private func saveChanges() {
        guard let projectState = self.appState.currentProjectState else { return }

        self.isSaving = true
        self.errorMessage = nil

        Task {
            do {
                // Update title if changed
                let newTitle = self.title.trimmingCharacters(in: .whitespaces)
                if newTitle != self.item.title {
                    _ = try await projectState.updateTitle(of: self.item, to: newTitle)
                }

                // Update labels
                let currentLabels = Set(self.item.labels)
                let labelsToAdd = Array(self.selectedLabels.subtracting(currentLabels))
                let labelsToRemove = Array(currentLabels.subtracting(self.selectedLabels))

                if !labelsToAdd.isEmpty {
                    try await projectState.addLabels(labelsToAdd, to: self.item)
                }
                if !labelsToRemove.isEmpty {
                    try await projectState.removeLabels(labelsToRemove, from: self.item)
                }

                // Update category if changed
                if self.selectedCategory != self.item.category {
                    try await projectState.updateCategory(of: self.item, to: self.selectedCategory)
                }

                self.dismiss()
            } catch {
                self.errorMessage = error.localizedDescription
                DZErrorLog(error)
            }
            self.isSaving = false
        }
    }
}

#Preview {
    EditItemSheet(item: Item.placeholder())
        .environment(AppState())
}
