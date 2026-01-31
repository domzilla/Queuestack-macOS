//
//  CLIRunner.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import DZFoundation
import Foundation

/// Actor-based CLI execution wrapper
actor CLIRunner {
    private let binaryPath: String

    init(binaryPath: String = "/opt/homebrew/bin/qs") {
        self.binaryPath = binaryPath
    }

    struct Result {
        let stdout: String
        let stderr: String
        let exitCode: Int32

        var isSuccess: Bool {
            self.exitCode == 0
        }

        var lines: [String] {
            self.stdout
                .components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
        }

        var error: Error? {
            guard !self.isSuccess else { return nil }
            return Error(message: self.stderr.isEmpty ? "Command failed with exit code \(self.exitCode)" : self.stderr)
        }
    }

    struct Error: LocalizedError {
        let message: String
        var errorDescription: String? { self.message }
    }

    func run(
        arguments: [String],
        workingDirectory: URL? = nil
    ) async throws
        -> Result
    {
        guard FileManager.default.fileExists(atPath: self.binaryPath) else {
            throw Error(message: "CLI tool not found at \(self.binaryPath)")
        }

        let process = Process()
        process.executableURL = URL(filePath: self.binaryPath)
        process.arguments = arguments

        if let workingDirectory {
            process.currentDirectoryURL = workingDirectory
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        DZLog("Running: qs \(arguments.joined(separator: " "))")

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        let result = Result(
            stdout: stdout.trimmingCharacters(in: .whitespacesAndNewlines),
            stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines),
            exitCode: process.terminationStatus
        )

        if !result.isSuccess {
            DZLog("CLI failed: \(result.stderr)")
        }

        return result
    }
}
