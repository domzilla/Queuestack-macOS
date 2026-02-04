//
//  AttachmentCellView.swift
//  Queuestack
//
//  Created by Dominic Rodemer on 03/02/2026.
//  Copyright © 2026 Dominic Rodemer. All rights reserved.
//

import AppKit

/// Custom cell view with text field and eye button for Quick Look.
final class AttachmentCellView: NSTableCellView {
    let eyeButton: NSButton

    override init(frame frameRect: NSRect) {
        self.eyeButton = NSButton(frame: .zero)
        super.init(frame: frameRect)
        self.setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let textField = NSTextField(labelWithString: "")
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.lineBreakMode = .byTruncatingMiddle
        textField.cell?.truncatesLastVisibleLine = true
        self.addSubview(textField)
        self.textField = textField

        self.eyeButton.translatesAutoresizingMaskIntoConstraints = false
        self.eyeButton.bezelStyle = .accessoryBarAction
        self.eyeButton.setButtonType(.momentaryPushIn)
        self.eyeButton.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Quick Look")
        self.eyeButton.imagePosition = .imageOnly
        self.eyeButton.contentTintColor = .secondaryLabelColor
        self.eyeButton.toolTip = String(localized: "Quick Look", comment: "Quick Look button tooltip")
        self.addSubview(self.eyeButton)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8),
            textField.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: self.eyeButton.leadingAnchor, constant: -4),

            self.eyeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
            self.eyeButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.eyeButton.widthAnchor.constraint(equalToConstant: 20),
            self.eyeButton.heightAnchor.constraint(equalToConstant: 20),
        ])
    }
}
