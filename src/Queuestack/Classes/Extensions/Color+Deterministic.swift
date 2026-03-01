//
//  Color+Deterministic.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 01/03/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import SwiftUI

extension Color {
    /// Derives a stable color from a string using DJB2 hash + murmur3 finalizer → hue mapping.
    /// Hue offset calibrated so "bug" lands on red (hue 0).
    static func deterministic(from text: String) -> Color {
        // DJB2 hash
        var hash: UInt64 = 5381
        for byte in text.utf8 {
            hash = hash &* 33 &+ UInt64(byte)
        }
        // Murmur3 64-bit finalizer for even distribution
        hash ^= hash >> 33
        hash = hash &* 0xFF51_AFD7_ED55_8CCD
        hash ^= hash >> 33
        hash = hash &* 0xC4CE_B9FE_1A85_EC53
        hash ^= hash >> 33
        let hue = Double((hash % 360 + 332) % 360) / 360.0
        return Color(hue: hue, saturation: 0.75, brightness: 0.9)
    }
}
