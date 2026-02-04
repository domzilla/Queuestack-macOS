//
//  CategoryPicker.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 04/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

/// A picker for selecting or creating a category
struct CategoryPicker: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    @Binding var newCategoryText: String

    /// If true, shows an "Add" button next to the text field.
    /// If false, typing in the text field clears the selection and the text is used directly.
    var showAddButton: Bool = false

    /// Called when the Add button is tapped (only when showAddButton is true)
    var onAddCategory: (() -> Void)?

    var body: some View {
        // None option
        self.categoryOption(nil)

        // Existing categories
        ForEach(self.categories, id: \.self) { category in
            self.categoryOption(category)
        }

        // New category input
        if self.showAddButton {
            HStack {
                TextField(
                    String(localized: "New category...", comment: "New category placeholder"),
                    text: self.$newCategoryText
                )
                .textFieldStyle(.roundedBorder)

                Button(String(localized: "Add", comment: "Add category button")) {
                    self.onAddCategory?()
                }
                .disabled(self.newCategoryText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } else {
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
    }

    @ViewBuilder
    private func categoryOption(_ category: String?) -> some View {
        let isSelected = self.selectedCategory == category && (category != nil || self.newCategoryText.isEmpty)
        let displayLabel = category ?? String(localized: "None", comment: "No category option")

        Button {
            self.selectedCategory = category
            self.newCategoryText = ""
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                Text(displayLabel)
                    .foregroundStyle(category == nil ? Color.secondary : Color.primary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        CategoryPicker(
            categories: ["Bug", "Feature", "Enhancement"],
            selectedCategory: .constant("Bug"),
            newCategoryText: .constant("")
        )
    }
    .padding()
    .frame(width: 300)
}
