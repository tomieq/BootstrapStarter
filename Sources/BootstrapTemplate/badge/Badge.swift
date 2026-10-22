//
//  Badge.swift
//

import Foundation

public struct Badge {
    private let text: String
    private let color: ContextColor
    private let pill: Bool

    // The text is HTML-escaped.
    public init(_ text: CustomStringConvertible, color: ContextColor = .primary, pill: Bool = false) {
        self.text = text.description
        self.color = color
        self.pill = pill
    }

    public var output: String {
        let pill = self.pill ? " rounded-pill" : ""
        return "<span class=\"badge text-bg-\(self.color.rawValue)\(pill)\">\(self.text.htmlEscaped)</span>"
    }
}

extension Badge: CustomStringConvertible {
    public var description: String {
        self.output
    }
}
