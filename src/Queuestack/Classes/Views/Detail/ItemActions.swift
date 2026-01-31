//
//  ItemActions.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import SwiftUI

struct ItemActions: View {
    @Environment(AppState.self) private var appState

    let item: Item

    @State private var isProcessing = false

    var body: some View {
        HStack {
            Spacer()

            if self.item.status == .open {
                Button {
                    self.closeItem()
                } label: {
                    SwiftUI.Label(
                        String(localized: "Close Item", comment: "Close item button"),
                        systemImage: "archivebox"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.isProcessing)
            } else {
                Button {
                    self.reopenItem()
                } label: {
                    SwiftUI.Label(
                        String(localized: "Reopen Item", comment: "Reopen item button"),
                        systemImage: "arrow.uturn.backward"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.isProcessing)
            }
        }
        .padding()
        .background(.bar)
    }

    private func closeItem() {
        self.isProcessing = true
        Task {
            do {
                try await self.appState.closeSelectedItem()
            } catch {
                DZErrorLog(error)
            }
            self.isProcessing = false
        }
    }

    private func reopenItem() {
        self.isProcessing = true
        Task {
            do {
                try await self.appState.reopenSelectedItem()
            } catch {
                DZErrorLog(error)
            }
            self.isProcessing = false
        }
    }
}

#Preview {
    ItemActions(item: Item.placeholder())
        .environment(AppState())
}
