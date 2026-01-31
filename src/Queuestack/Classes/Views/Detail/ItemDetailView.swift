//
//  ItemDetailView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import SwiftUI

struct ItemDetailView: View {
    @Environment(AppState.self) private var appState

    @State private var showingEditSheet = false
    @State private var isProcessing = false

    var body: some View {
        SwiftUI.Group {
            if let item = self.appState.selectedItem {
                self.detailContent(item)
            } else {
                Color.clear
            }
        }
    }

    @ViewBuilder
    private func detailContent(_ item: Item) -> some View {
        VStack(spacing: 0) {
            // Fixed header
            self.headerSection(item)

            Divider()

            // Resizable split between body and attachments
            VSplitView {
                // Body section (TextEditor is already scrollable)
                ItemBody(item: item)
                    .padding()

                // Attachments section
                VStack(spacing: 0) {
                    Divider()

                    ScrollView {
                        AttachmentSection(item: item)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(minHeight: 80)
            }
        }
        .sheet(isPresented: self.$showingEditSheet) {
            EditItemSheet(item: item)
        }
    }

    private func headerSection(_ item: Item) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row with Close button
            HStack(alignment: .top) {
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .textSelection(.enabled)

                Spacer()

                self.actionButton(item)
            }

            // Id and Created at row
            HStack {
                HStack(spacing: 4) {
                    Text(String(localized: "Id:", comment: "Item ID label"))
                        .foregroundStyle(.secondary)
                    Text(item.id)
                        .textSelection(.enabled)
                }
                .font(.caption)

                Spacer()

                HStack(spacing: 4) {
                    Text(String(localized: "Created at:", comment: "Created date label"))
                        .foregroundStyle(.secondary)
                    Text(item.createdAt, style: .date)
                }
                .font(.caption)
            }

            // Author and Labels row
            HStack {
                HStack(spacing: 4) {
                    Text(String(localized: "Author:", comment: "Author label"))
                        .foregroundStyle(.secondary)
                    Text(item.author)
                }
                .font(.caption)

                Spacer()

                HStack(spacing: 4) {
                    Text(String(localized: "Labels:", comment: "Labels label"))
                        .foregroundStyle(.secondary)
                    if item.labels.isEmpty {
                        Text("—")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(item.labels.joined(separator: ", "))
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .background(.bar)
    }

    @ViewBuilder
    private func actionButton(_ item: Item) -> some View {
        if item.status == .open {
            Button {
                self.closeItem()
            } label: {
                Text(String(localized: "Close", comment: "Close item button"))
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(self.isProcessing)
        } else {
            Button {
                self.reopenItem()
            } label: {
                Text(String(localized: "Reopen", comment: "Reopen item button"))
            }
            .buttonStyle(.borderedProminent)
            .disabled(self.isProcessing)
        }
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
    ItemDetailView()
        .environment(AppState())
}
