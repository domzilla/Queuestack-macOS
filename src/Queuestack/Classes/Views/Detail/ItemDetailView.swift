//
//  ItemDetailView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

struct ItemDetailView: View {
    @Environment(AppState.self) private var appState

    @State private var showingEditSheet = false

    var body: some View {
        SwiftUI.Group {
            if let item = self.appState.selectedItem {
                self.detailContent(item)
            } else {
                self.noSelectionView
            }
        }
    }

    private var noSelectionView: some View {
        ContentUnavailableView {
            SwiftUI.Label(
                String(localized: "No Item Selected", comment: "Detail empty state title"),
                systemImage: "doc.text"
            )
        } description: {
            Text(String(
                localized: "Select an item from the list to view its details.",
                comment: "Detail empty state description"
            ))
        }
    }

    @ViewBuilder
    private func detailContent(_ item: Item) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ItemHeader(item: item, onEdit: { self.showingEditSheet = true })

                Divider()

                ItemMetadata(item: item)

                Divider()

                ItemBody(item: item)
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            ItemActions(item: item)
        }
        .sheet(isPresented: self.$showingEditSheet) {
            EditItemSheet(item: item)
        }
    }
}

#Preview {
    ItemDetailView()
        .environment(AppState())
}
