//
//  AddProjectSheet.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct AddProjectSheet: View {
    @Environment(WindowState.self) private var windowState
    @Environment(\.dismiss) private var dismiss

    let targetGroupID: UUID?

    @State private var selectedURL: URL?
    @State private var errorMessage: String?
    @State private var showingFilePicker = true

    var body: some View {
        VStack(spacing: 16) {
            Text(String(localized: "Add Project", comment: "Add project sheet title"))
                .font(.headline)

            if let url = self.selectedURL {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.secondary)
                    Text(url.lastPathComponent)
                    Spacer()
                    Button(String(localized: "Change", comment: "Button to change selected folder")) {
                        self.showingFilePicker = true
                    }
                    .buttonStyle(.link)
                }
                .padding()
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if let errorMessage = self.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Button(String(localized: "Cancel", comment: "Cancel button")) {
                    self.dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(String(localized: "Add", comment: "Add button")) {
                    self.addProject()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(self.selectedURL == nil)
            }
        }
        .padding()
        .frame(width: 400)
        .fileImporter(
            isPresented: self.$showingFilePicker,
            allowedContentTypes: [.folder]
        ) { result in
            switch result {
            case let .success(url):
                self.validateAndSelect(url)
            case .failure:
                if self.selectedURL == nil {
                    self.dismiss()
                }
            }
        }
    }

    private func validateAndSelect(_ url: URL) {
        let configPath = url.appendingPathComponent(".queuestack")
        if FileManager.default.fileExists(atPath: configPath.path) {
            self.selectedURL = url
            self.errorMessage = nil
        } else {
            self.errorMessage = String(
                localized: "Not a queuestack project (no .queuestack file found)",
                comment: "Error when folder is not a queuestack project"
            )
            self.selectedURL = nil
        }
    }

    private func addProject() {
        guard let url = self.selectedURL else { return }

        do {
            let project = try Project.from(url: url)
            self.windowState.services.settings.addProject(project, toGroupWithID: self.targetGroupID)
            self.windowState.selectProject(project)
            self.dismiss()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
