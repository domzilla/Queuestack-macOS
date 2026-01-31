//
//  ItemHeader.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct ItemHeader: View {
    let item: Item
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.item.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .textSelection(.enabled)

                    HStack(spacing: 8) {
                        Text(self.item.id)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Text("·")
                            .foregroundStyle(.quaternary)

                        Text(self.item.author)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("·")
                            .foregroundStyle(.quaternary)

                        Text(self.item.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    self.onEdit()
                } label: {
                    SwiftUI.Label(
                        String(localized: "Edit", comment: "Edit button label"),
                        systemImage: "pencil"
                    )
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    ItemHeader(item: Item.placeholder(), onEdit: {})
        .padding()
}
