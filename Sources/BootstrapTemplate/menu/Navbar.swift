//
//  Navbar.swift
//

import Foundation

public enum NavStyle {
    // Follows the page's color mode.
    case `default`
    case dark
    case primary
}

public enum Breakpoint: String {
    case sm
    case md
    case lg
    case xl
    case xxl
}

public enum NavbarPosition {
    case normal
    // Needs top padding on the page body, as the bar is taken out of the document flow.
    case fixedTop
    case stickyTop
}

public struct Navbar {
    private let id: String
    private let brand: String?
    private let brandURL: String
    private let brandIcon: Icon?
    private let items: [MenuItem]
    private let currentPath: String?
    private let style: NavStyle
    private let expand: Breakpoint
    private let position: NavbarPosition
    private let fluid: Bool

    // Below the `expand` breakpoint the items collapse behind a toggle button. `id` must be unique on the page.
    public init(id: String = "navbar",
                brand: String? = nil,
                brandURL: String = "/",
                brandIcon: Icon? = nil,
                items: [MenuItem],
                currentPath: String? = nil,
                style: NavStyle = .default,
                expand: Breakpoint = .lg,
                position: NavbarPosition = .normal,
                fluid: Bool = true) {
        self.id = id
        self.brand = brand
        self.brandURL = brandURL
        self.brandIcon = brandIcon
        self.items = items
        self.currentPath = currentPath
        self.style = style
        self.expand = expand
        self.position = position
        self.fluid = fluid
    }

    public var output: String {
        let id = self.id.htmlEscaped
        let breakpoint = self.expand.rawValue
        var classes = ["navbar", "navbar-expand-\(breakpoint)"]
        var theme = ""
        switch self.style {
        case .default:
            classes.append("bg-body-tertiary")
        case .dark:
            classes.append("bg-dark")
            theme = " data-bs-theme=\"dark\""
        case .primary:
            classes.append("bg-primary")
            theme = " data-bs-theme=\"dark\""
        }
        switch self.position {
        case .normal: break
        case .fixedTop: classes.append("fixed-top")
        case .stickyTop: classes.append("sticky-top")
        }

        var html = "<nav class=\"\(classes.joined(separator: " "))\"\(theme) id=\"\(id)\">\n"
        html.append("<div class=\"\(self.fluid ? "container-fluid" : "container")\">\n")
        if self.brand != nil || self.brandIcon != nil {
            let icon = self.brandIcon.map { $0.output + (self.brand == nil ? "" : " ") } ?? ""
            let brandText = (self.brand ?? "").htmlEscaped
            html.append("<a class=\"navbar-brand\" href=\"\(self.brandURL.htmlEscaped)\">\(icon)\(brandText)</a>\n")
        }
        html.append("<button class=\"navbar-toggler\" type=\"button\" data-bs-toggle=\"collapse\" data-bs-target=\"#\(id)-collapse\" aria-controls=\"\(id)-collapse\" aria-expanded=\"false\" aria-label=\"Toggle navigation\"><span class=\"navbar-toggler-icon\"></span></button>\n")
        html.append("<div class=\"collapse navbar-collapse\" id=\"\(id)-collapse\">\n")

        let start = self.items.filter { !$0.end }
        let end = self.items.filter { $0.end }
        html.append("<ul class=\"navbar-nav me-auto mb-2 mb-\(breakpoint)-0\">\n")
        html.append(start.compactMap { self.render($0, atEnd: false) }.joined(separator: "\n"))
        html.append("\n</ul>\n")
        if !end.isEmpty {
            html.append("<ul class=\"navbar-nav\">\n")
            html.append(end.compactMap { self.render($0, atEnd: true) }.joined(separator: "\n"))
            html.append("\n</ul>\n")
        }
        html.append("</div>\n</div>\n</nav>")
        return html
    }

    private func render(_ item: MenuItem, atEnd: Bool) -> String? {
        let active = item.isActive(self.currentPath)
        var classes = "nav-link"
        if active { classes.append(" active") }
        if item.disabled { classes.append(" disabled") }
        let inner = item.inner(badgeAtEnd: false)

        switch item.kind {
        case .link(let url, _):
            var attributes = ""
            if active { attributes.append(" aria-current=\"page\"") }
            if item.disabled { attributes.append(" tabindex=\"-1\" aria-disabled=\"true\"") }
            return "<li class=\"nav-item\"><a class=\"\(classes)\" href=\"\(url.htmlEscaped)\"\(attributes)>\(inner)</a></li>"
        case .action(let code):
            let attributes = item.disabled ? " disabled" : ""
            return "<li class=\"nav-item\"><button type=\"button\" class=\"\(classes)\" onclick=\"\(code.description.htmlEscaped)\"\(attributes)>\(inner)</button></li>"
        case .dropdown(let children):
            let toggleClasses = classes + " dropdown-toggle"
            let menuClasses = "dropdown-menu" + (atEnd ? " dropdown-menu-\(self.expand.rawValue)-end" : "")
            let entries = children.flatMap { $0.dropdownEntries(self.currentPath) }.joined(separator: "\n")
            return "<li class=\"nav-item dropdown\"><button type=\"button\" class=\"\(toggleClasses)\" data-bs-toggle=\"dropdown\" aria-expanded=\"false\"\(item.disabled ? " disabled" : "")>\(inner)</button>\n<ul class=\"\(menuClasses)\">\n\(entries)\n</ul></li>"
        case .header:
            return "<li class=\"nav-item\"><span class=\"navbar-text\">\(item.title.htmlEscaped)</span></li>"
        case .raw:
            return "<li class=\"nav-item\">\(item.html)</li>"
        case .divider:
            return nil
        }
    }
}

extension Navbar: CustomStringConvertible {
    public var description: String {
        self.output
    }
}
