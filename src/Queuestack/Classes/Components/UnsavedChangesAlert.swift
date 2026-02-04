//
//  UnsavedChangesAlert.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 04/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

/// Actions available when there are unsaved changes
enum UnsavedChangesAction {
    case save
    case discard
    case cancel
}

/// A view modifier that presents an alert for unsaved changes
struct UnsavedChangesAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onAction: (UnsavedChangesAction) -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                String(localized: "Unsaved Changes", comment: "Unsaved changes alert title"),
                isPresented: self.$isPresented
            ) {
                Button(String(localized: "Save", comment: "Save button")) {
                    self.onAction(.save)
                }
                Button(String(localized: "Discard", comment: "Discard button"), role: .destructive) {
                    self.onAction(.discard)
                }
                Button(String(localized: "Cancel", comment: "Cancel button"), role: .cancel) {
                    self.onAction(.cancel)
                }
            } message: {
                Text(String(
                    localized: "Do you want to save your changes?",
                    comment: "Unsaved changes alert message"
                ))
            }
    }
}

extension View {
    /// Presents an alert when there are unsaved changes
    func unsavedChangesAlert(
        isPresented: Binding<Bool>,
        onAction: @escaping (UnsavedChangesAction) -> Void
    )
        -> some View
    {
        self.modifier(UnsavedChangesAlertModifier(isPresented: isPresented, onAction: onAction))
    }
}
