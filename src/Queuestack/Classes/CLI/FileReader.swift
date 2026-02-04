//
//  FileReader.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation

/// Reads queuestack item markdown files
struct FileReader {
    private let parser = Parser()

    /// Read a single item from its file path
    func readItem(at path: URL, project: Project) throws -> Item {
        let content = try String(contentsOf: path, encoding: .utf8)

        let parsed = try self.parser.parseMarkdownFile(content: content, filePath: path)
        let category = self.parser.extractCategory(from: path, project: project)
        let isTemplate = path.pathComponents.contains(CLIConstants.FileConventions.DefaultDirectories.templates)

        return Item(
            id: parsed.id,
            title: parsed.title,
            author: parsed.author,
            createdAt: parsed.createdAt,
            status: parsed.status,
            labels: parsed.labels,
            attachments: parsed.attachments,
            category: category,
            body: parsed.body,
            filePath: path,
            isTemplate: isTemplate
        )
    }

    /// Read multiple items from file paths
    func readItems(at paths: [URL], project: Project) throws -> [Item] {
        try paths.compactMap { path in
            try self.readItem(at: path, project: project)
        }
    }

    /// Scan all items in a project directory
    func scanAllItems(in project: Project) throws -> [Item] {
        try self.scanItems(
            in: project.stackURL,
            project: project,
            excluding: "/\(project.archiveDir)/"
        )
    }

    /// Scan archived items
    func scanArchivedItems(in project: Project) throws -> [Item] {
        try self.scanItems(in: project.archiveURL, project: project)
    }

    /// Scan template items
    func scanTemplates(in project: Project) throws -> [Item] {
        try self.scanItems(in: project.templateURL, project: project)
    }

    /// Shared helper for scanning items in a directory
    private func scanItems(
        in directory: URL,
        project: Project,
        excluding pathSubstring: String? = nil
    ) throws
        -> [Item]
    {
        let fileManager = FileManager.default
        var items: [Item] = []

        guard fileManager.fileExists(atPath: directory.path) else {
            return []
        }

        let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        while let url = enumerator?.nextObject() as? URL {
            if let excludePath = pathSubstring, url.path.contains(excludePath) {
                continue
            }

            guard url.pathExtension == CLIConstants.FileConventions.markdownExtension else { continue }

            do {
                let item = try self.readItem(at: url, project: project)
                items.append(item)
            } catch {
                continue
            }
        }

        return items
    }
}
