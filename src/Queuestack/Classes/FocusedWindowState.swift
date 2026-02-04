//
//  FocusedWindowState.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

/// FocusedValue key for passing WindowState through the environment.
struct FocusedWindowStateKey: FocusedValueKey {
    typealias Value = WindowState
}

extension FocusedValues {
    var windowState: WindowState? {
        get { self[FocusedWindowStateKey.self] }
        set { self[FocusedWindowStateKey.self] = newValue }
    }
}
