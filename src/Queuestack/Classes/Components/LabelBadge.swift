//
//  LabelBadge.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct LabelBadge: View {
    let label: String

    var body: some View {
        Text(self.label)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(self.backgroundColor)
            .foregroundStyle(self.foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var backgroundColor: Color {
        self.colorForLabel.opacity(0.2)
    }

    private var foregroundColor: Color {
        self.colorForLabel
    }

    private var colorForLabel: Color {
        // Generate consistent color from label string
        let hash = self.label.lowercased().hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
}

#Preview {
    HStack {
        LabelBadge(label: "bug")
        LabelBadge(label: "feature")
        LabelBadge(label: "urgent")
        LabelBadge(label: "documentation")
    }
    .padding()
}
