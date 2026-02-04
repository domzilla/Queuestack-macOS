//
//  LabelToggleButton.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 04/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

/// A toggle button for selecting/deselecting a label
struct LabelToggleButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: 4) {
                Image(systemName: self.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(self.isSelected ? Color.accentColor : Color.secondary)
                Text(self.label)
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(self.isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        LabelToggleButton(label: "bug", isSelected: true) {}
        LabelToggleButton(label: "feature", isSelected: false) {}
    }
    .padding()
}
