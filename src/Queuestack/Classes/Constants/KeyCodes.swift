//
//  KeyCodes.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 04/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

/// macOS virtual key codes for keyboard event handling
nonisolated(unsafe) enum KeyCode {
    /// Space bar
    static let space: UInt16 = 49

    /// Delete (Backspace)
    static let delete: UInt16 = 51

    /// Down arrow
    static let downArrow: UInt16 = 125

    /// Up arrow
    static let upArrow: UInt16 = 126
}
