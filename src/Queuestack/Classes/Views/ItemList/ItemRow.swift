//
//  ItemRow.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 01/03/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct ItemRow: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            self.titleLine
            if !self.item.labels.isEmpty {
                self.labelsLine
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Title Line

    private var titleLine: some View {
        HStack(spacing: 6) {
            if let category = self.item.category {
                self.categoryPill(category)
            }
            Text(self.item.title)
                .lineLimit(1)
            Spacer(minLength: 0)
            if !self.item.attachments.isEmpty {
                Image(systemName: "paperclip")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    // MARK: - Labels Line

    private var labelsLine: some View {
        FlowLayout(spacing: 4) {
            ForEach(self.item.labels, id: \.self) { label in
                self.labelPill(label)
            }
        }
    }

    // MARK: - Pills

    private func categoryPill(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(.secondary.opacity(0.5))
            )
    }

    private func labelPill(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.deterministic(from: text).opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    List {
        // With category + labels
        ItemRow(item: Item(
            id: "1",
            title: "Fix the heartbeat skip when disconnected",
            author: "dom",
            createdAt: .now,
            status: .open,
            labels: ["bug", "feature"],
            attachments: [],
            category: "backend",
            body: "",
            filePath: URL(fileURLWithPath: "/tmp/1.md"),
            isTemplate: false
        ))

        // Without category, with label
        ItemRow(item: Item(
            id: "2",
            title: "Upgrade @slack/bolt to 4.7.0",
            author: "dom",
            createdAt: .now,
            status: .open,
            labels: ["task"],
            attachments: ["file.png"],
            category: nil,
            body: "",
            filePath: URL(fileURLWithPath: "/tmp/2.md"),
            isTemplate: false
        ))

        // Without category, without labels
        ItemRow(item: Item(
            id: "3",
            title: "Upgrade @slack/bolt to 4.7.0",
            author: "dom",
            createdAt: .now,
            status: .open,
            labels: [],
            attachments: [],
            category: nil,
            body: "",
            filePath: URL(fileURLWithPath: "/tmp/3.md"),
            isTemplate: false
        ))

        // With category + many labels
        ItemRow(item: Item(
            id: "4",
            title: "Fix the heartbeat skip when disconnected",
            author: "dom",
            createdAt: .now,
            status: .open,
            labels: ["bug", "P0", "regression", "v2.1", "needs-review", "security"],
            attachments: [],
            category: "backend",
            body: "",
            filePath: URL(fileURLWithPath: "/tmp/4.md"),
            isTemplate: false
        ))
    }
    .listStyle(.inset)
}
