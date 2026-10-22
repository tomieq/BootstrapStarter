//
//  TableCell.swift
//

import Foundation

public struct TableColumn {
    public let title: String
    public let alignment: TableAlignment?

    public init(_ title: String, alignment: TableAlignment? = nil) {
        self.title = title
        self.alignment = alignment
    }
}

extension TableColumn: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

public struct TableCell {
    let html: String
    let alignment: TableAlignment?

    // Text is HTML-escaped.
    public init(_ text: CustomStringConvertible, alignment: TableAlignment? = nil) {
        self.html = text.description.htmlEscaped
        self.alignment = alignment
    }

    public init(_ button: Button, alignment: TableAlignment? = nil) {
        self.html = button.output
        self.alignment = alignment
    }

    public init(_ icon: Icon, alignment: TableAlignment? = nil) {
        self.html = icon.output
        self.alignment = alignment
    }

    public init(_ badge: Badge, alignment: TableAlignment? = nil) {
        self.html = badge.output
        self.alignment = alignment
    }

    private init(html: String, alignment: TableAlignment?) {
        self.html = html
        self.alignment = alignment
    }

    // HTML is inserted as is; the caller is responsible for escaping.
    public static func raw(_ html: CustomStringConvertible, alignment: TableAlignment? = nil) -> TableCell {
        TableCell(html: html.description, alignment: alignment)
    }

    public static func link(_ label: String, url: String, alignment: TableAlignment? = nil) -> TableCell {
        TableCell(html: "<a href=\"\(url.htmlEscaped)\">\(label.htmlEscaped)</a>", alignment: alignment)
    }
}

extension TableCell: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}
