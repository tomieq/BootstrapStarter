//
//  Modal.swift
//

import Foundation

public enum ModalSize {
    case small
    case large
    case extraLarge
    case fullscreen
}

extension ModalSize {
    var cssClass: String {
        switch self {
        case .small: "modal-sm"
        case .large: "modal-lg"
        case .extraLarge: "modal-xl"
        case .fullscreen: "modal-fullscreen"
        }
    }
}

public struct Modal {
    private let id: String
    private let title: String
    private let body: CustomStringConvertible
    private let footer: [CustomStringConvertible]
    private let size: ModalSize?
    private let centered: Bool
    private let scrollable: Bool
    private let staticBackdrop: Bool
    private let closeButton: Bool

    // `body` and `footer` are inserted as is (a Form, a Table, a Button...); the title is escaped.
    public init(id: String,
                title: String,
                body: CustomStringConvertible,
                footer: [CustomStringConvertible] = [],
                size: ModalSize? = nil,
                centered: Bool = false,
                scrollable: Bool = false,
                staticBackdrop: Bool = false,
                closeButton: Bool = true) {
        self.id = id
        self.title = title
        self.body = body
        self.footer = footer
        self.size = size
        self.centered = centered
        self.scrollable = scrollable
        self.staticBackdrop = staticBackdrop
        self.closeButton = closeButton
    }

    public var output: String {
        let id = self.id.htmlEscaped
        var modalAttributes = ""
        if self.staticBackdrop {
            modalAttributes = " data-bs-backdrop=\"static\" data-bs-keyboard=\"false\""
        }
        var dialogClasses = ["modal-dialog"]
        if self.centered {
            dialogClasses.append("modal-dialog-centered")
        }
        if self.scrollable {
            dialogClasses.append("modal-dialog-scrollable")
        }
        if let size = self.size {
            dialogClasses.append(size.cssClass)
        }
        var html = "<div class=\"modal fade\" id=\"\(id)\" tabindex=\"-1\" aria-labelledby=\"\(id)-title\" aria-hidden=\"true\"\(modalAttributes)>\n"
        html.append("<div class=\"\(dialogClasses.joined(separator: " "))\">\n<div class=\"modal-content\">\n")
        html.append("<div class=\"modal-header\">\n<h5 class=\"modal-title\" id=\"\(id)-title\">\(self.title.htmlEscaped)</h5>\n")
        if self.closeButton {
            html.append("<button type=\"button\" class=\"btn-close\" data-bs-dismiss=\"modal\" aria-label=\"Close\"></button>\n")
        }
        html.append("</div>\n")
        html.append("<div class=\"modal-body\">\n\(self.body.description)\n</div>\n")
        if !self.footer.isEmpty {
            html.append("<div class=\"modal-footer\">\n\(self.footer.map { $0.description }.joined(separator: "\n"))\n</div>\n")
        }
        html.append("</div>\n</div>\n</div>")
        return html
    }
}

extension Modal: CustomStringConvertible {
    public var description: String {
        self.output
    }
}
