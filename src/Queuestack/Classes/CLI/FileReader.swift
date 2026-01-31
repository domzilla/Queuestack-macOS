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

        return Item(
            id: parsed.id,
            title: parsed.title,
            author: parsed.author,
            createdAt: parsed.createdAt,
            status: parsed.status,
            labels: parsed.labels,
            category: category,
            body: parsed.body,
            filePath: path
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
        let fileManager = FileManager.default
        var items: [Item] = []

        guard fileManager.fileExists(atPath: project.stackURL.path) else {
            return []
        }

        let enumerator = fileManager.enumerator(
            at: project.stackURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        while let url = enumerator?.nextObject() as? URL {
            // Skip archive directory (handled separately)
            if url.path.contains("/\(project.archiveDir)/") {
                continue
            }

            // Only process markdown files
            guard url.pathExtension == "md" else { continue }

            do {
                let item = try self.readItem(at: url, project: project)
                items.append(item)
            } catch {
                // Skip files that can't be parsed
                continue
            }
        }

        return items
    }

    /// Scan archived items
    func scanArchivedItems(in project: Project) throws -> [Item] {
        let fileManager = FileManager.default
        var items: [Item] = []

        guard fileManager.fileExists(atPath: project.archiveURL.path) else {
            return []
        }

        let enumerator = fileManager.enumerator(
            at: project.archiveURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "md" else { continue }

            do {
                let item = try self.readItem(at: url, project: project)
                items.append(item)
            } catch {
                continue
            }
        }

        return items
    }

    /// Scan template items
    func scanTemplates(in project: Project) throws -> [Item] {
        let fileManager = FileManager.default
        var items: [Item] = []

        guard fileManager.fileExists(atPath: project.templateURL.path) else {
            return []
        }

        let enumerator = fileManager.enumerator(
            at: project.templateURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "md" else { continue }

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
