//
//  Label.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 31/01/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import Foundation

struct Label: Identifiable, Hashable {
    var id: String { self.name }
    let name: String
    var itemCount: Int

    init(name: String, itemCount: Int = 0) {
        self.name = name
        self.itemCount = itemCount
    }
}
