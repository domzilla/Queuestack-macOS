//
//  Service.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import Foundation

/// High-level API for queuestack operations
@MainActor
final class Service {
    private let runner: CLIRunner
    private let fileReader = FileReader()
    private let fileWriter = FileWriter()

    init(binaryPath: String = CLIConstants.defaultBinaryPath) {
        self.runner = CLIRunner(binaryPath: binaryPath)
    }

    // MARK: - Single Item Read

    /// Read a single item from a file path
    func readItem(at path: URL, in project: Project) throws -> Item {
        try self.fileReader.readItem(at: path, project: project)
    }

    // MARK: - List Operations

    /// List open items in a project
    func listOpenItems(in project: Project) async throws -> [Item] {
        DZLog("listOpenItems in project: \(project.path.path)")
        let args = [
            CLIConstants.List.command,
            CLIConstants.List.Flag.open,
            CLIConstants.List.Flag.noInteractive,
        ]
        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        DZLog("CLI stdout: \(result.stdout)")
        DZLog("CLI stderr: \(result.stderr)")
        DZLog("CLI exit: \(result.exitCode)")

        if let error = result.error {
            DZLog("CLI error: \(error)")
            throw error
        }

        // Filter to only actual file paths (must end with .md)
        let paths = result.lines
            .filter { $0.hasSuffix(CLIConstants.FileConventions.markdownExtensionWithDot) }
            .map { project.path.appendingPathComponent($0) }
        DZLog("Parsed paths: \(paths)")
        return try self.fileReader.readItems(at: paths, project: project)
    }

    /// List closed items in a project
    func listClosedItems(in project: Project) async throws -> [Item] {
        let args = [
            CLIConstants.List.command,
            CLIConstants.List.Flag.closed,
            CLIConstants.List.Flag.noInteractive,
        ]
        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }

        // Filter to only actual file paths (must end with .md)
        let paths = result.lines
            .filter { $0.hasSuffix(CLIConstants.FileConventions.markdownExtensionWithDot) }
            .map { project.path.appendingPathComponent($0) }
        return try self.fileReader.readItems(at: paths, project: project)
    }

    /// List templates in a project
    func listTemplates(in project: Project) async throws -> [Item] {
        let args = [
            CLIConstants.List.command,
            CLIConstants.List.Flag.templates,
            CLIConstants.List.Flag.noInteractive,
        ]
        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }

        // Filter to only actual file paths (must end with .md)
        let paths = result.lines
            .filter { $0.hasSuffix(CLIConstants.FileConventions.markdownExtensionWithDot) }
            .map { project.path.appendingPathComponent($0) }
        return try self.fileReader.readItems(at: paths, project: project)
    }

    /// List all unique labels in a project
    func listLabels(in project: Project) async throws -> [Label] {
        let args = [
            CLIConstants.List.command,
            CLIConstants.List.Flag.labels,
            CLIConstants.List.Flag.noInteractive,
        ]
        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }

        return result.lines.map { Label(name: $0) }
    }

    /// List all unique categories in a project
    func listCategories(in project: Project) async throws -> [Category] {
        let args = [
            CLIConstants.List.command,
            CLIConstants.List.Flag.categories,
            CLIConstants.List.Flag.noInteractive,
        ]
        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }

        return result.lines.map { Category(name: $0) }
    }

    // MARK: - Search

    /// Search items by query
    func search(
        query: String,
        in project: Project,
        fullText: Bool = false,
        closed: Bool = false
    ) async throws
        -> [Item]
    {
        var args = [
            CLIConstants.Search.command,
            query,
            CLIConstants.Search.Flag.noInteractive,
        ]
        if fullText {
            args.append(CLIConstants.Search.Flag.fullText)
        }
        if closed {
            args.append(CLIConstants.Search.Flag.closed)
        }

        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        // Search returns exit code 1 when no matches
        if result.exitCode == CLIConstants.Search.ExitCode.noMatches, result.stderr.contains("No matches") {
            return []
        }

        if let error = result.error {
            throw error
        }

        let paths = result.lines.map { project.path.appendingPathComponent($0) }
        return try self.fileReader.readItems(at: paths, project: project)
    }

    // MARK: - Create

    /// Create a new item
    func createItem(
        title: String,
        labels: [String] = [],
        category: String? = nil,
        in project: Project
    ) async throws
        -> Item
    {
        var args = [
            CLIConstants.New.command,
            title,
            CLIConstants.New.Flag.noInteractive,
        ]

        for label in labels {
            args.append(contentsOf: [CLIConstants.New.Flag.label, label])
        }

        if let category {
            args.append(contentsOf: [CLIConstants.New.Flag.category, category])
        }

        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }

        // CLI outputs the created file path
        guard let relativePath = result.lines.first else {
            throw CLIRunner.Error(message: "No file path returned from create")
        }

        let filePath = project.path.appendingPathComponent(relativePath)
        return try self.fileReader.readItem(at: filePath, project: project)
    }

    /// Create a new template
    func createTemplate(
        title: String,
        labels: [String] = [],
        in project: Project
    ) async throws
        -> Item
    {
        var args = [
            CLIConstants.New.command,
            title,
            CLIConstants.New.Flag.asTemplate,
            CLIConstants.New.Flag.noInteractive,
        ]

        for label in labels {
            args.append(contentsOf: [CLIConstants.New.Flag.label, label])
        }

        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }

        guard let relativePath = result.lines.first else {
            throw CLIRunner.Error(message: "No file path returned from create template")
        }

        let filePath = project.path.appendingPathComponent(relativePath)
        return try self.fileReader.readItem(at: filePath, project: project)
    }

    // MARK: - Update

    /// Update an item's title
    func updateTitle(of item: Item, to newTitle: String, in project: Project) async throws -> Item {
        let args = [
            CLIConstants.Update.command,
            CLIConstants.Update.Flag.id, item.id,
            CLIConstants.Update.Flag.title, newTitle,
        ]
        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }

        // CLI outputs "✓ Updated item: <path>" - extract the path portion
        // Find first line containing ".md" and extract path after last ": "
        let newPath: URL
        if
            let outputLine = result.lines
                .first(where: { $0.contains(CLIConstants.FileConventions.markdownExtensionWithDot) }),
            let pathStart = outputLine.range(of: ": ", options: .backwards)
        {
            let relativePath = String(outputLine[pathStart.upperBound...])
            newPath = project.path.appendingPathComponent(relativePath)
        } else {
            newPath = item.filePath
        }

        return try self.fileReader.readItem(at: newPath, project: project)
    }

    /// Add labels to an item
    func addLabels(_ labels: [String], to item: Item, in project: Project) async throws {
        var args = [CLIConstants.Update.command, CLIConstants.Update.Flag.id, item.id]
        for label in labels {
            args.append(contentsOf: [CLIConstants.Update.Flag.label, label])
        }

        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }
    }

    /// Remove labels from an item
    func removeLabels(_ labels: [String], from item: Item, in project: Project) async throws {
        var args = [CLIConstants.Update.command, CLIConstants.Update.Flag.id, item.id]
        for label in labels {
            args.append(contentsOf: [CLIConstants.Update.Flag.removeLabel, label])
        }

        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }
    }

    /// Update item's category
    func updateCategory(of item: Item, to category: String?, in project: Project) async throws {
        var args = [CLIConstants.Update.command, CLIConstants.Update.Flag.id, item.id]

        if let category {
            args.append(contentsOf: [CLIConstants.Update.Flag.category, category])
        } else {
            args.append(CLIConstants.Update.Flag.removeCategory)
        }

        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }
    }

    /// Update item body (direct file write, not via CLI)
    func updateBody(of item: Item, to newBody: String) throws {
        try self.fileWriter.updateBody(of: item, newBody: newBody)
    }

    // MARK: - Close / Reopen

    /// Close an item (move to archive)
    func close(item: Item, in project: Project) async throws {
        let args = [CLIConstants.Close.command, CLIConstants.Close.Flag.id, item.id]
        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }
    }

    /// Reopen an item (move from archive)
    func reopen(item: Item, in project: Project) async throws {
        let args = [CLIConstants.Reopen.command, CLIConstants.Reopen.Flag.id, item.id]
        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }
    }

    // MARK: - Attachments

    /// Add an attachment to an item
    func addAttachment(_ attachment: String, to item: Item, in project: Project) async throws {
        let args = [
            CLIConstants.Attachments.command,
            CLIConstants.Attachments.Add.subcommand,
            CLIConstants.Attachments.Add.Flag.id, item.id,
            attachment,
        ]
        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }
    }

    /// Remove an attachment from an item by index (1-based)
    func removeAttachment(at index: Int, from item: Item, in project: Project) async throws {
        let args = [
            CLIConstants.Attachments.command,
            CLIConstants.Attachments.Remove.subcommand,
            CLIConstants.Attachments.Remove.Flag.id, item.id,
            String(index),
        ]
        let result = try await self.runner.run(arguments: args, workingDirectory: project.path)

        if let error = result.error {
            throw error
        }
    }

    // MARK: - Bulk Operations

    /// Load all items (open, closed, templates) for a project
    func loadAllItems(in project: Project) async throws -> (open: [Item], closed: [Item], templates: [Item]) {
        async let openItems = self.listOpenItems(in: project)
        async let closedItems = self.listClosedItems(in: project)
        async let templateItems = self.listTemplates(in: project)

        return try await (openItems, closedItems, templateItems)
    }
}
