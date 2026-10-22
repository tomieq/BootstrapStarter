//
//  Button.swift
//

import Foundation

public struct Button {
    private enum Kind {
        case button(onClick: JSCode?)
        case link(url: String)
    }

    private let label: String
    private let icon: Icon?
    private let kind: Kind
    private let styles: [ButtonStyle]
    private let attributes: [String: String]

    // Without a label the button is icon-only; give it `attributes: ["aria-label": ...]`.
    public init(_ label: String,
                icon: Icon? = nil,
                onClick: JSCode? = nil,
                attributes: [String: String] = [:],
                style: ButtonStyle...) {
        self.label = label
        self.icon = icon
        self.kind = .button(onClick: onClick)
        self.styles = style
        self.attributes = attributes
    }

    // Renders an <a> element styled as a button.
    public init(_ label: String,
                icon: Icon? = nil,
                url: String,
                attributes: [String: String] = [:],
                style: ButtonStyle...) {
        self.label = label
        self.icon = icon
        self.kind = .link(url: url)
        self.styles = style
        self.attributes = attributes
    }

    private var content: String {
        let text = self.label.htmlEscaped
        guard let icon else { return text }
        return text.isEmpty ? icon.output : "\(icon.output) \(text)"
    }

    private var cssClass: String {
        var styles = self.styles
        if !styles.contains(where: { $0 != .large && $0 != .small }) {
            styles.insert(.primary, at: 0)
        }
        return (["btn"] + styles.map { $0.cssClass }).joined(separator: " ")
    }

    private var extraAttributes: String {
        self.attributes.sorted { $0.key < $1.key }
            .map { " \($0.key)=\"\($0.value.htmlEscaped)\"" }
            .joined()
    }

    public var output: String {
        switch self.kind {
        case .button(let onClick):
            let handler = onClick.map { " onclick=\"\($0.description.htmlEscaped)\"" } ?? ""
            return "<button type=\"button\" class=\"\(self.cssClass)\"\(handler)\(self.extraAttributes)>\(self.content)</button>"
        case .link(let url):
            return "<a href=\"\(url.htmlEscaped)\" class=\"\(self.cssClass)\" role=\"button\"\(self.extraAttributes)>\(self.content)</a>"
        }
    }
}

extension Button: CustomStringConvertible {
    public var description: String {
        self.output
    }
}
