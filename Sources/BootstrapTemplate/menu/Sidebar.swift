//
//  Sidebar.swift
//

import Foundation

public struct Sidebar {
    private let id: String
    private let brand: String?
    private let brandURL: String
    private let brandIcon: Icon?
    private let items: [MenuItem]
    private let currentPath: String?
    private let style: NavStyle
    private let width: Int

    // A fixed-width vertical menu. Place it next to the content in a flex row; `width` is in pixels.
    // Items marked `atEnd()` are pinned to the bottom. `id` must be unique on the page.
    public init(id: String = "sidebar",
                brand: String? = nil,
                brandURL: String = "/",
                brandIcon: Icon? = nil,
                items: [MenuItem],
                currentPath: String? = nil,
                style: NavStyle = .default,
                width: Int = 280) {
        self.id = id
        self.brand = brand
        self.brandURL = brandURL
        self.brandIcon = brandIcon
        self.items = items
        self.currentPath = currentPath
        self.style = style
        self.width = width
    }

    private var isDark: Bool {
        if case .default = self.style { return false }
        return true
    }

    public var output: String {
        let id = self.id.htmlEscaped
        var classes = ["d-flex", "flex-column", "flex-shrink-0", "p-3"]
        switch self.style {
        case .default: classes.append("bg-body-tertiary")
        case .dark: classes.append("text-bg-dark")
        case .primary: classes.append("text-bg-primary")
        }

        var html = "<nav class=\"\(classes.joined(separator: " "))\" id=\"\(id)\" aria-label=\"Sidebar\" style=\"width: \(self.width)px;\">\n"
        if self.brand != nil || self.brandIcon != nil {
            let icon = self.brandIcon.map { $0.output + (self.brand == nil ? "" : " ") } ?? ""
            let color = self.isDark ? "text-white" : "link-body-emphasis"
            html.append("<a class=\"d-flex align-items-center mb-2 \(color) text-decoration-none\" href=\"\(self.brandURL.htmlEscaped)\"><span class=\"fs-4\">\(icon)\((self.brand ?? "").htmlEscaped)</span></a>\n<hr>\n")
        }

        var counter = 0
        let start = self.items.filter { !$0.end }
        let end = self.items.filter { $0.end }
        html.append("<ul class=\"nav nav-pills flex-column mb-auto\">\n")
        html.append(self.renderList(start, counter: &counter))
        html.append("</ul>\n")
        if !end.isEmpty {
            html.append("<hr>\n<ul class=\"nav nav-pills flex-column\">\n")
            html.append(self.renderList(end, counter: &counter))
            html.append("</ul>\n")
        }
        html.append("</nav>")
        return html
    }

    private func renderList(_ items: [MenuItem], counter: inout Int) -> String {
        var html = ""
        for item in items {
            html.append(self.render(item, counter: &counter))
            html.append("\n")
        }
        return html
    }

    private func render(_ item: MenuItem, counter: inout Int) -> String {
        let active = item.isActive(self.currentPath)
        var classes = "nav-link" + item.flexClasses
        if active && !item.isDropdown {
            classes.append(" active")
        } else {
            classes.append(self.isDark ? " text-white" : " link-body-emphasis")
        }
        if item.disabled { classes.append(" disabled") }
        let inner = item.inner(badgeAtEnd: true)

        switch item.kind {
        case .link(let url, _):
            var attributes = ""
            if active { attributes.append(" aria-current=\"page\"") }
            if item.disabled { attributes.append(" tabindex=\"-1\" aria-disabled=\"true\"") }
            return "<li class=\"nav-item\"><a class=\"\(classes)\" href=\"\(url.htmlEscaped)\"\(attributes)>\(inner)</a></li>"
        case .action(let code):
            let attributes = item.disabled ? " disabled" : ""
            return "<li class=\"nav-item\"><button type=\"button\" class=\"\(classes) w-100 text-start\" onclick=\"\(code.description.htmlEscaped)\"\(attributes)>\(inner)</button></li>"
        case .dropdown(let children):
            counter += 1
            let target = "\(self.id.htmlEscaped)-group-\(counter)"
            let toggleClasses = "nav-link dropdown-toggle w-100 text-start d-flex justify-content-between align-items-center"
                + (self.isDark ? " text-white" : " link-body-emphasis") + (item.disabled ? " disabled" : "")
            let list = self.renderList(children, counter: &counter)
            return "<li class=\"nav-item\"><button type=\"button\" class=\"\(toggleClasses)\" data-bs-toggle=\"collapse\" data-bs-target=\"#\(target)\" aria-expanded=\"\(active)\"\(item.disabled ? " disabled" : "")><span>\(item.inner(badgeAtEnd: false))</span></button>\n<div class=\"collapse\(active ? " show" : "")\" id=\"\(target)\">\n<ul class=\"nav nav-pills flex-column ps-3\">\n\(list)</ul>\n</div></li>"
        case .header:
            return "<li class=\"mt-3 mb-1 px-2 text-uppercase small fw-semibold \(self.isDark ? "text-white-50" : "text-body-secondary")\">\(item.title.htmlEscaped)</li>"
        case .divider:
            return "<li><hr class=\"my-2\"></li>"
        case .raw:
            return "<li class=\"nav-item\">\(item.html)</li>"
        }
    }
}

extension Sidebar: CustomStringConvertible {
    public var description: String {
        self.output
    }
}

extension MenuItem {
    var isDropdown: Bool {
        if case .dropdown = self.kind { return true }
        return false
    }
}
