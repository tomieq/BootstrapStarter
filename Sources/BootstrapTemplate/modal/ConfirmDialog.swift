//
//  ConfirmDialog.swift
//

import Foundation

// A client-side Bootstrap confirmation dialog; renders the JavaScript call that opens it.
public struct ConfirmDialog {
    private let message: String
    private let title: String
    private let confirmLabel: String
    private let cancelLabel: String
    private let confirmStyle: ButtonStyle
    private let onConfirm: String

    // `message` and labels are shown as plain text. `onConfirm` is JavaScript (a `JSCode` or `JSResponse`) run after the dialog closes.
    public init(_ message: String,
                title: String = "Confirm",
                confirmLabel: String = "OK",
                cancelLabel: String = "Cancel",
                confirmStyle: ButtonStyle = .primary,
                onConfirm: CustomStringConvertible) {
        self.message = message
        self.title = title
        self.confirmLabel = confirmLabel
        self.cancelLabel = cancelLabel
        self.confirmStyle = confirmStyle
        self.onConfirm = onConfirm.description
    }

    public var output: String {
        let fields = [
            "title: '\(self.title.jsEscaped)'",
            "message: '\(self.message.jsEscaped)'",
            "confirmLabel: '\(self.confirmLabel.jsEscaped)'",
            "cancelLabel: '\(self.cancelLabel.jsEscaped)'",
            "confirmClass: '\(self.confirmStyle.cssClass)'",
            "onConfirm: function () { \(self.onConfirm) }"
        ]
        return "confirmDialog({\(fields.joined(separator: ", "))});"
    }
}

extension ConfirmDialog: CustomStringConvertible {
    public var description: String {
        self.output
    }
}
