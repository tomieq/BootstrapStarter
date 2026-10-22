//
//  ListGroup.swift
//

import Foundation

public struct ListGroupItem {
    enum Kind {
        case plain
        case link(url: String)
        case action(onClick: JSCode)
    }

    let kind: Kind
    let html: String
    let badge: Badge?
    let color: ContextColor?
    let active: Bool
    let disabled: Bool

    private init(kind: Kind, html: String, icon: Icon?, badge: Badge?, color: ContextColor?, active: Bool, disabled: Bool) {
        self.kind = kind
        self.html = icon.map { "\($0.output) \(html)" } ?? html
        self.badge = badge
        self.color = color
        self.active = active
        self.disabled = disabled
    }

    // A plain item; the text is HTML-escaped.
    public init(_ text: String,
                icon: Icon? = nil,
                badge: Badge? = nil,
                color: ContextColor? = nil,
                active: Bool = false,
                disabled: Bool = false) {
        self.init(kind: .plain, html: text.htmlEscaped, icon: icon, badge: badge, color: color, active: active, disabled: disabled)
    }

    // A link item.
    public init(_ text: String,
                url: String,
                icon: Icon? = nil,
                badge: Badge? = nil,
                color: ContextColor? = nil,
                active: Bool = false,
                disabled: Bool = false) {
        self.init(kind: .link(url: url), html: text.htmlEscaped, icon: icon, badge: badge, color: color, active: active, disabled: disabled)
    }

    // A button item that runs `onClick`.
    public init(_ text: String,
                onClick: JSCode,
                icon: Icon? = nil,
                badge: Badge? = nil,
                color: ContextColor? = nil,
                active: Bool = false,
                disabled: Bool = false) {
        self.init(kind: .action(onClick: onClick), html: text.htmlEscaped, icon: icon, badge: badge, color: color, active: active, disabled: disabled)
    }

    // Content is inserted as is; the caller is responsible for escaping. Plain unless `url` or `onClick` is given.
    public static func raw(_ html: CustomStringConvertible,
                           url: String? = nil,
                           onClick: JSCode? = nil,
                           badge: Badge? = nil,
                           color: ContextColor? = nil,
                           active: Bool = false,
                           disabled: Bool = false) -> ListGroupItem {
        let kind: Kind = url.map { .link(url: $0) } ?? onClick.map { .action(onClick: $0) } ?? .plain
        return ListGroupItem(kind: kind, html: html.description, icon: nil, badge: badge, color: color, active: active, disabled: disabled)
    }

    var isActionable: Bool {
        if case .plain = self.kind { return false }
        return true
    }
}

extension ListGroupItem: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

public class ListGroup {
    private let id: String?
    private let flush: Bool
    private let numbered: Bool
    private let horizontal: Bool
    private var items: [ListGroupItem] = []
    private var emptyMessage: String?

    public init(id: String? = nil, flush: Bool = false, numbered: Bool = false, horizontal: Bool = false) {
        self.id = id
        self.flush = flush
        self.numbered = numbered
        self.horizontal = horizontal
    }

    @discardableResult
    public func addItem(_ item: ListGroupItem) -> ListGroup {
        self.items.append(item)
        return self
    }

    @discardableResult
    public func addItems<T>(_ models: [T], item: (T) -> ListGroupItem) -> ListGroup {
        models.forEach { self.items.append(item($0)) }
        return self
    }

    // Shown as a disabled item when there are no items.
    @discardableResult
    public func setEmptyMessage(_ message: String) -> ListGroup {
        self.emptyMessage = message
        return self
    }

    public var output: String {
        var items = self.items
        if items.isEmpty, let emptyMessage {
            items.append(ListGroupItem(emptyMessage, disabled: true))
        }
        // Links and buttons need a <div> container; a plain list uses <ul> or <ol>.
        let useDiv = items.contains { $0.isActionable }
        let container = useDiv ? "div" : (self.numbered ? "ol" : "ul")

        var classes = ["list-group"]
        if self.flush { classes.append("list-group-flush") }
        if self.numbered { classes.append("list-group-numbered") }
        if self.horizontal { classes.append("list-group-horizontal") }
        let idAttribute = self.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""

        var html = "<\(container)\(idAttribute) class=\"\(classes.joined(separator: " "))\">\n"
        for item in items {
            html.append(self.render(item, useDiv: useDiv))
            html.append("\n")
        }
        html.append("</\(container)>")
        return html
    }

    private func render(_ item: ListGroupItem, useDiv: Bool) -> String {
        var classes = ["list-group-item"]
        if item.isActionable { classes.append("list-group-item-action") }
        if let color = item.color { classes.append("list-group-item-\(color.rawValue)") }
        if item.active { classes.append("active") }
        if item.disabled { classes.append("disabled") }

        var content = item.html
        if let badge = item.badge {
            classes.append("d-flex justify-content-between align-items-center")
            content = "<div>\(item.html)</div>\(badge.output)"
        }

        var attributes = " class=\"\(classes.joined(separator: " "))\""
        if item.active { attributes.append(" aria-current=\"true\"") }

        switch item.kind {
        case .plain:
            let tag = useDiv ? "div" : "li"
            if item.disabled && !useDiv { attributes.append(" aria-disabled=\"true\"") }
            return "<\(tag)\(attributes)>\(content)</\(tag)>"
        case .link(let url):
            attributes.append(" href=\"\(url.htmlEscaped)\"")
            if item.disabled { attributes.append(" tabindex=\"-1\" aria-disabled=\"true\"") }
            return "<a\(attributes)>\(content)</a>"
        case .action(let onClick):
            attributes.append(" type=\"button\" onclick=\"\(onClick.description.htmlEscaped)\"")
            if item.disabled { attributes.append(" disabled") }
            return "<button\(attributes)>\(content)</button>"
        }
    }
}

extension ListGroup: CustomStringConvertible {
    public var description: String {
        self.output
    }
}
