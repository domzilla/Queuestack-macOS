//
//  AttachmentSection.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import SwiftUI

struct AttachmentSection: View {
    @Environment(WindowState.self) private var windowState

    let item: Item

    @State private var showingURLAlert = false
    @State private var urlText = ""
    @State private var isProcessing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            self.headerView

            if self.item.attachments.isEmpty {
                Text(String(localized: "No attachments", comment: "Empty attachments placeholder"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(self.item.attachments, id: \.self) { attachment in
                    self.attachmentRow(attachment)
                }
            }
        }
        .alert(
            String(localized: "Add URL", comment: "Add URL alert title"),
            isPresented: self.$showingURLAlert
        ) {
            TextField(
                String(localized: "https://example.com", comment: "URL placeholder"),
                text: self.$urlText
            )
            Button(String(localized: "Cancel", comment: "Cancel button"), role: .cancel) {
                self.urlText = ""
            }
            Button(String(localized: "Add", comment: "Add button")) {
                self.addURL()
            }
        } message: {
            Text(String(localized: "Enter a URL to attach", comment: "Add URL alert message"))
        }
    }

    private var headerView: some View {
        HStack {
            Text(String(localized: "Attachments", comment: "Attachments section header"))
                .font(.headline)

            Spacer()

            Menu {
                Button {
                    self.pickFile()
                } label: {
                    HStack {
                        Image(systemName: "doc")
                        Text(String(localized: "Add File...", comment: "Add file attachment menu item"))
                    }
                }

                Button {
                    self.showingURLAlert = true
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text(String(localized: "Add URL...", comment: "Add URL attachment menu item"))
                    }
                }
            } label: {
                Image(systemName: "plus.circle")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .disabled(self.isProcessing)
        }
    }

    private func attachmentRow(_ attachment: String) -> some View {
        let index = self.item.attachments.firstIndex(of: attachment) ?? 0

        return HStack(spacing: 8) {
            Image(systemName: self.isURL(attachment) ? "link.circle" : "doc")
                .foregroundStyle(.secondary)

            Text(self.displayName(for: attachment))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Button {
                self.removeAttachment(at: index)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(self.isProcessing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .onTapGesture {
            self.openAttachment(attachment)
        }
    }

    // MARK: - Helpers

    private func isURL(_ attachment: String) -> Bool {
        attachment.hasPrefix("http://") || attachment.hasPrefix("https://")
    }

    private func displayName(for attachment: String) -> String {
        if self.isURL(attachment) {
            return attachment
        }
        // For files, show just the filename
        return URL(filePath: attachment).lastPathComponent
    }

    private func openAttachment(_ attachment: String) {
        if self.isURL(attachment) {
            if let url = URL(string: attachment) {
                NSWorkspace.shared.open(url)
            }
        } else {
            // File attachment - resolve relative to item's directory
            let itemDirectory = self.item.filePath.deletingLastPathComponent()
            let fileURL = itemDirectory.appendingPathComponent(attachment)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                NSWorkspace.shared.open(fileURL)
            } else {
                DZLog("Attachment file not found: \(fileURL.path)")
            }
        }
    }

    // MARK: - Actions

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        self.isProcessing = true
        Task {
            do {
                try await self.windowState.currentProjectState?.addAttachment(url.path, to: self.item)
            } catch {
                DZErrorLog(error)
            }
            self.isProcessing = false
        }
    }

    private func addURL() {
        let url = self.urlText.trimmingCharacters(in: .whitespaces)
        self.urlText = ""

        guard !url.isEmpty else { return }

        self.isProcessing = true
        Task {
            do {
                try await self.windowState.currentProjectState?.addAttachment(url, to: self.item)
            } catch {
                DZErrorLog(error)
            }
            self.isProcessing = false
        }
    }

    private func removeAttachment(at index: Int) {
        self.isProcessing = true
        Task {
            do {
                // CLI uses 1-based index
                try await self.windowState.currentProjectState?.removeAttachment(at: index + 1, from: self.item)
            } catch {
                DZErrorLog(error)
            }
            self.isProcessing = false
        }
    }
}

#Preview {
    AttachmentSection(item: Item.placeholder())
        .environment(WindowState(services: AppServices()))
        .padding()
}
