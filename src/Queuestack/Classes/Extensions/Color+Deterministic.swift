//
//  Color+Deterministic.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 01/03/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

extension Color {
    /// Derives a stable color from a string using DJB2 hash → hue mapping.
    /// Hue offset calibrated so "bug" lands on red (hue 0).
    static func deterministic(from text: String) -> Color {
        var hash: UInt64 = 5381
        for byte in text.utf8 {
            hash = hash &* 33 &+ UInt64(byte)
        }
        let hue = Double((hash % 360 + 77) % 360) / 360.0
        return Color(hue: hue, saturation: 0.75, brightness: 0.9)
    }
}
