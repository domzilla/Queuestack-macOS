//
//  FSEventWatcher.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import CoreServices
import DZFoundation
import Foundation

/// Watches a directory tree for changes using FSEvents
final class FSEventWatcher: @unchecked Sendable {
    // All mutable state is protected by the lock
    private nonisolated(unsafe) var streamRef: FSEventStreamRef?
    private nonisolated(unsafe) var watchedPath: URL?
    private nonisolated(unsafe) var onChange: (@MainActor () -> Void)?
    private let lock = NSLock()

    private let latency: CFTimeInterval = 0.3

    deinit {
        // Direct cleanup in deinit - must be synchronous and not call any isolated methods
        self.lock.withLock {
            if let stream = self.streamRef {
                FSEventStreamStop(stream)
                FSEventStreamInvalidate(stream)
                FSEventStreamRelease(stream)
            }
            self.streamRef = nil
            self.watchedPath = nil
            self.onChange = nil
        }
    }

    /// Start watching a directory for changes
    @MainActor
    func start(path: URL, onChange: @escaping @MainActor () -> Void) {
        // Stop any existing watcher
        self.stopStreamSync()

        self.lock.withLock {
            self.watchedPath = path
            self.onChange = onChange
        }

        let pathString = path.path as CFString
        let pathsToWatch = [pathString] as CFArray

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes |
                kFSEventStreamCreateFlagFileEvents |
                kFSEventStreamCreateFlagNoDefer
        )

        guard
            let stream = FSEventStreamCreate(
                kCFAllocatorDefault,
                Self.eventCallback,
                &context,
                pathsToWatch,
                FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                self.latency,
                flags
            ) else
        {
            DZLog("Failed to create FSEvent stream for \(path.path)")
            return
        }

        self.lock.withLock {
            self.streamRef = stream
        }

        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)

        DZLog("Started watching: \(path.path)")
    }

    /// Stop watching
    @MainActor
    func stop() {
        self.stopStreamSync()
    }

    private nonisolated func stopStreamSync() {
        var stream: FSEventStreamRef?
        var path: URL?

        self.lock.withLock {
            stream = self.streamRef
            path = self.watchedPath
            self.streamRef = nil
            self.watchedPath = nil
            self.onChange = nil
        }

        guard let stream else { return }

        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)

        if let path {
            DZLog("Stopped watching: \(path.path)")
        }
    }

    /// Check if currently watching a path
    @MainActor
    var isWatching: Bool {
        self.lock.withLock {
            self.streamRef != nil
        }
    }

    // MARK: - FSEvents Callback

    private static let eventCallback: FSEventStreamCallback = { _, info, numEvents, eventPaths, eventFlags, _ in
        guard let info else { return }

        let watcher = Unmanaged<FSEventWatcher>.fromOpaque(info).takeUnretainedValue()

        // Filter to only relevant events (created, removed, renamed, modified)
        guard let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else { return }

        var hasRelevantChange = false

        for i in 0..<numEvents {
            let path = paths[i]
            let flags = eventFlags[i]

            // Skip if it's just an access or stat change
            let isRelevant =
                (flags & UInt32(kFSEventStreamEventFlagItemCreated)) != 0 ||
                (flags & UInt32(kFSEventStreamEventFlagItemRemoved)) != 0 ||
                (flags & UInt32(kFSEventStreamEventFlagItemRenamed)) != 0 ||
                (flags & UInt32(kFSEventStreamEventFlagItemModified)) != 0

            // Only care about markdown files
            if isRelevant, path.hasSuffix(".md") {
                hasRelevantChange = true
                DZLog("File changed: \(path)")
                break
            }
        }

        if hasRelevantChange {
            let callback = watcher.lock.withLock {
                watcher.onChange
            }

            Task { @MainActor in
                callback?()
            }
        }
    }
}
