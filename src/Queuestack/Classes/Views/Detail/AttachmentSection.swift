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
    @State private var showingAttachmentError = false
    @State private var attachmentErrorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            self.headerView

            if self.item.attachments.isEmpty {
                Text(String(localized: "No attachments", comment: "Empty attachments placeholder"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                AttachmentTableView(
                    attachments: self.item.attachments,
                    attachmentsDirectoryURL: self.attachmentsDirectoryURL,
                    onOpen: { self.openAttachment(at: $0) },
                    onDelete: { self.deleteAttachments(at: $0) },
                    onRevealInFinder: { self.revealInFinder(at: $0) },
                    onCopyPath: { self.copyPath(at: $0) },
                    onFilesDropped: { self.addFiles($0) }
                )
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
        .alert(
            String(localized: "Cannot Add Attachment", comment: "Attachment error alert title"),
            isPresented: self.$showingAttachmentError
        ) {
            Button(String(localized: "OK", comment: "OK button"), role: .cancel) {}
        } message: {
            Text(self.attachmentErrorMessage)
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

    // MARK: - Helpers

    private func isURL(_ attachment: String) -> Bool {
        attachment.hasPrefix(CLIConstants.FileConventions.URLScheme.http) || attachment
            .hasPrefix(CLIConstants.FileConventions.URLScheme.https)
    }

    /// Returns the URL of the attachments directory for the current item.
    /// Format: `{item-stem}.attachments/` as sibling to the item file.
    private var attachmentsDirectoryURL: URL {
        let itemURL = self.item.filePath
        let stem = itemURL.deletingPathExtension().lastPathComponent
        return itemURL.deletingLastPathComponent()
            .appendingPathComponent(stem + CLIConstants.FileConventions.attachmentDirectorySuffix, isDirectory: true)
    }

    /// Resolves an attachment filename to its full file URL.
    private func attachmentURL(for attachment: String) -> URL {
        self.attachmentsDirectoryURL.appendingPathComponent(attachment)
    }

    // MARK: - Actions

    private func openAttachment(at index: Int) {
        let attachment = self.item.attachments[index]
        if self.isURL(attachment) {
            if let url = URL(string: attachment) {
                NSWorkspace.shared.open(url)
            }
        } else {
            let fileURL = self.attachmentURL(for: attachment)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                NSWorkspace.shared.open(fileURL)
            } else {
                DZLog("Attachment file not found: \(fileURL.path)")
            }
        }
    }

    private func revealInFinder(at index: Int) {
        let attachment = self.item.attachments[index]
        let fileURL = self.attachmentURL(for: attachment)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }

    private func copyPath(at index: Int) {
        let attachment = self.item.attachments[index]
        let textToCopy: String = if self.isURL(attachment) {
            attachment
        } else {
            self.attachmentURL(for: attachment).path
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToCopy, forType: .string)
    }

    private func deleteAttachments(at indices: Set<Int>) {
        guard !indices.isEmpty, !self.isProcessing else { return }

        self.isProcessing = true
        Task {
            do {
                try await self.windowState.currentProjectState?.removeAttachments(at: Array(indices), from: self.item)
            } catch {
                DZErrorLog(error)
            }
            self.isProcessing = false
        }
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, !panel.urls.isEmpty else { return }

        self.addFiles(panel.urls)
    }

    private func addFiles(_ urls: [URL]) {
        self.isProcessing = true
        Task {
            do {
                let paths = urls.map(\.path)
                try await self.windowState.currentProjectState?.addAttachments(paths, to: self.item)
            } catch {
                DZErrorLog(error)
            }
            self.isProcessing = false
        }
    }

    private func addURL() {
        let urlString = self.urlText.trimmingCharacters(in: .whitespaces)
        self.urlText = ""

        guard !urlString.isEmpty else { return }

        // Validate URL format
        guard
            let url = URL(string: urlString),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme) else
        {
            self.attachmentErrorMessage = String(
                localized: "Invalid URL format",
                comment: "Error when URL format is invalid"
            )
            self.showingAttachmentError = true
            return
        }

        self.isProcessing = true
        Task {
            do {
                try await self.windowState.currentProjectState?.addAttachment(urlString, to: self.item)
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
