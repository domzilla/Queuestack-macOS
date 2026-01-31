//
//  ItemMetadata.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct ItemMetadata: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status
            HStack {
                Text(String(localized: "Status", comment: "Metadata label"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .leading)
                StatusBadge(status: self.item.status)
            }

            // Category
            HStack {
                Text(String(localized: "Category", comment: "Metadata label"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .leading)
                if let category = self.item.category {
                    Text(category)
                        .font(.callout)
                } else {
                    Text(String(localized: "None", comment: "No category"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            // Labels
            HStack(alignment: .top) {
                Text(String(localized: "Labels", comment: "Metadata label"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .leading)
                if self.item.labels.isEmpty {
                    Text(String(localized: "None", comment: "No labels"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    FlowLayout(spacing: 4) {
                        ForEach(self.item.labels, id: \.self) { label in
                            LabelBadge(label: label)
                        }
                    }
                }
            }
        }
    }
}

/// Simple flow layout for wrapping labels
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let result = self.layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let result = self.layout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + self.spacing
                lineHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + self.spacing
            totalHeight = max(totalHeight, currentY + lineHeight)
        }

        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}

#Preview {
    ItemMetadata(item: Item.placeholder())
        .padding()
}
