//
//  StatusBadge.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct StatusBadge: View {
    let status: Item.Status

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(self.statusColor)
                .frame(width: 8, height: 8)
            Text(self.statusText)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(self.statusColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var statusColor: Color {
        switch self.status {
        case .open:
            .green
        case .closed:
            .secondary
        }
    }

    private var statusText: String {
        switch self.status {
        case .open:
            String(localized: "Open", comment: "Status badge open")
        case .closed:
            String(localized: "Closed", comment: "Status badge closed")
        }
    }
}

#Preview {
    VStack {
        StatusBadge(status: .open)
        StatusBadge(status: .closed)
    }
    .padding()
}
