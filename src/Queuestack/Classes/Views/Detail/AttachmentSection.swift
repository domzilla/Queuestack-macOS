//
//  AttachmentSection.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import Quartz
import SwiftUI

struct AttachmentSection: View {
    @Environment(WindowState.self) private var windowState

    let item: Item

    @State private var showingURLAlert = false
    @State private var urlText = ""
    @State private var isProcessing = false
    @State private var selectedIndices: Set<Int> = []
    @State private var lastSelectedIndex: Int?
    @State private var showingQuickLook = false
    @State private var quickLookIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            self.headerView

            if self.item.attachments.isEmpty {
                Text(String(localized: "No attachments", comment: "Empty attachments placeholder"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(self.item.attachments.enumerated()), id: \.offset) { index, attachment in
                    self.attachmentRow(attachment, at: index)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            self.selectedIndices.removeAll()
            self.lastSelectedIndex = nil
        }
        .dropDestination(for: URL.self) { urls, _ in
            let fileURLs = urls.filter(\.isFileURL)
            guard !fileURLs.isEmpty else { return false }
            self.addFiles(fileURLs)
            return true
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(keys: [.delete], phases: .down) { keyPress in
            if keyPress.modifiers.contains(.command) {
                self.deleteSelectedAttachments()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(keys: [.space], phases: .down) { _ in
            if let firstSelected = self.selectedIndices.min() {
                self.showQuickLookPreview(at: firstSelected)
                return .handled
            }
            return .ignored
        }
        .quickLookPreview(
            urls: self.previewableURLs,
            selectedIndex: self.$quickLookIndex,
            isPresented: self.$showingQuickLook
        )
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

    private func attachmentRow(_ attachment: String, at index: Int) -> some View {
        let isSelected = self.selectedIndices.contains(index)
        let canPreview = self.canQuickLookPreview(attachment)

        return HStack(spacing: 8) {
            Text(self.displayName(for: attachment))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(isSelected ? Color(nsColor: .alternateSelectedControlTextColor) : .primary)

            Spacer()

            if canPreview {
                Button {
                    self.showQuickLookPreview(at: index)
                } label: {
                    Image(systemName: "eye")
                        .foregroundStyle(isSelected ? Color(nsColor: .alternateSelectedControlTextColor) : .secondary)
                }
                .buttonStyle(.plain)
                .help(String(localized: "Quick Look", comment: "Quick Look button tooltip"))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isSelected ? Color(nsColor: .selectedContentBackgroundColor) : Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .onTapGesture {
            self.handleSelection(at: index, with: NSEvent.modifierFlags)
        }
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded {
                    self.openAttachment(attachment)
                }
        )
        .contextMenu {
            if !self.isURL(attachment) {
                Button {
                    self.revealInFinder(attachment)
                } label: {
                    Text(String(localized: "Show in Finder", comment: "Context menu item to reveal file in Finder"))
                }
            }

            Button {
                self.copyPath(attachment)
            } label: {
                if self.isURL(attachment) {
                    Text(String(localized: "Copy URL", comment: "Context menu item to copy URL"))
                } else {
                    Text(String(localized: "Copy File Path", comment: "Context menu item to copy file path"))
                }
            }

            Divider()

            Button(role: .destructive) {
                if self.selectedIndices.contains(index), self.selectedIndices.count > 1 {
                    self.deleteSelectedAttachments()
                } else {
                    self.removeAttachment(at: index)
                }
            } label: {
                if self.selectedIndices.contains(index), self.selectedIndices.count > 1 {
                    Text(String(
                        localized: "Delete \(self.selectedIndices.count) Items",
                        comment: "Context menu item to delete multiple attachments"
                    ))
                } else {
                    Text(String(localized: "Delete", comment: "Context menu item to delete attachment"))
                }
            }
        }
    }

    private func handleSelection(at index: Int, with modifiers: NSEvent.ModifierFlags) {
        if modifiers.contains(.command) {
            // Cmd+Click: Toggle selection
            if self.selectedIndices.contains(index) {
                self.selectedIndices.remove(index)
            } else {
                self.selectedIndices.insert(index)
            }
            self.lastSelectedIndex = index
        } else if modifiers.contains(.shift), let lastIndex = self.lastSelectedIndex {
            // Shift+Click: Range selection
            let range = min(lastIndex, index)...max(lastIndex, index)
            for i in range {
                self.selectedIndices.insert(i)
            }
        } else {
            // Plain click: Single selection
            self.selectedIndices = [index]
            self.lastSelectedIndex = index
        }
    }

    private func revealInFinder(_ attachment: String) {
        let fileURL = self.attachmentURL(for: attachment)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }

    private func copyPath(_ attachment: String) {
        let textToCopy: String = if self.isURL(attachment) {
            attachment
        } else {
            self.attachmentURL(for: attachment).path
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToCopy, forType: .string)
    }

    private func deleteSelectedAttachments() {
        guard !self.selectedIndices.isEmpty, !self.isProcessing else { return }

        self.isProcessing = true
        Task {
            do {
                // CLI uses 1-based indices
                let indices = self.selectedIndices.map { $0 + 1 }
                try await self.windowState.currentProjectState?.removeAttachments(at: indices, from: self.item)
            } catch {
                DZErrorLog(error)
            }
            self.selectedIndices.removeAll()
            self.lastSelectedIndex = nil
            self.isProcessing = false
        }
    }

    // MARK: - Helpers

    private func isURL(_ attachment: String) -> Bool {
        attachment.hasPrefix("http://") || attachment.hasPrefix("https://")
    }

    /// Returns the URL of the attachments directory for the current item.
    /// Format: `{item-stem}.attachments/` as sibling to the item file.
    private var attachmentsDirectoryURL: URL {
        let itemURL = self.item.filePath
        let stem = itemURL.deletingPathExtension().lastPathComponent
        return itemURL.deletingLastPathComponent()
            .appendingPathComponent("\(stem).attachments", isDirectory: true)
    }

    /// Resolves an attachment filename to its full file URL.
    private func attachmentURL(for attachment: String) -> URL {
        self.attachmentsDirectoryURL.appendingPathComponent(attachment)
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
            let fileURL = self.attachmentURL(for: attachment)
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

    // MARK: - Quick Look

    /// Returns file URLs for all previewable attachments (excludes web URLs).
    private var previewableURLs: [URL] {
        self.item.attachments.compactMap { attachment in
            guard !self.isURL(attachment) else { return nil }
            let url = self.attachmentURL(for: attachment)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return url
        }
    }

    /// Returns whether the attachment can be previewed with Quick Look.
    private func canQuickLookPreview(_ attachment: String) -> Bool {
        guard !self.isURL(attachment) else { return false }
        let url = self.attachmentURL(for: attachment)
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Shows the Quick Look preview for the attachment at the specified index.
    private func showQuickLookPreview(at index: Int) {
        let attachment = self.item.attachments[index]
        guard self.canQuickLookPreview(attachment) else { return }

        // Find the index in previewable URLs
        let fileURL = self.attachmentURL(for: attachment)
        if let previewIndex = self.previewableURLs.firstIndex(of: fileURL) {
            self.quickLookIndex = previewIndex
            self.showingQuickLook = true
        }
    }
}

#Preview {
    AttachmentSection(item: Item.placeholder())
        .environment(WindowState(services: AppServices()))
        .padding()
}
