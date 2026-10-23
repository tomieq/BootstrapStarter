//
//  MenuItem.swift
//

import Foundation

// One entry of a `Navbar` or `Sidebar`.
public struct MenuItem {
    enum Kind {
        case link(url: String, matchPrefix: Bool)
        case action(JSCode)
        case dropdown([MenuItem])
        case divider
        case header
        case raw
    }

    let kind: Kind
    let title: String
    let html: String
    let icon: Icon?
    let badge: Badge?
    let active: Bool
    let disabled: Bool
    let end: Bool

    private init(kind: Kind,
                 title: String = "",
                 html: String = "",
                 icon: Icon? = nil,
                 badge: Badge? = nil,
                 active: Bool = false,
                 disabled: Bool = false,
                 end: Bool = false) {
        self.kind = kind
        self.title = title
        self.html = html
        self.icon = icon
        self.badge = badge
        self.active = active
        self.disabled = disabled
        self.end = end
    }

    // The item is active when `active` is set, when its URL equals the menu's `currentPath` (query and trailing slash
    // ignored), or, with `matchPrefix`, when `currentPath` is below it (`/users` matches `/users/5`).
    public static func link(_ title: String,
                            url: String,
                            icon: Icon? = nil,
                            badge: Badge? = nil,
                            active: Bool = false,
                            disabled: Bool = false,
                            matchPrefix: Bool = false) -> MenuItem {
        MenuItem(kind: .link(url: url, matchPrefix: matchPrefix), title: title, icon: icon, badge: badge, active: active, disabled: disabled)
    }

    // A button that runs `onClick`.
    public static func action(_ title: String,
                              onClick: JSCode,
                              icon: Icon? = nil,
                              badge: Badge? = nil,
                              active: Bool = false,
                              disabled: Bool = false) -> MenuItem {
        MenuItem(kind: .action(onClick), title: title, icon: icon, badge: badge, active: active, disabled: disabled)
    }

    // A dropdown in a navbar, a collapsible group in a sidebar. Inside another dropdown it is flattened to a header and its items.
    public static func dropdown(_ title: String,
                                icon: Icon? = nil,
                                items: [MenuItem],
                                disabled: Bool = false) -> MenuItem {
        MenuItem(kind: .dropdown(items), title: title, icon: icon, disabled: disabled)
    }

    // Separator inside dropdowns and sidebars; ignored at the top level of a navbar.
    public static var divider: MenuItem {
        MenuItem(kind: .divider)
    }

    // A small caption: a dropdown header, a sidebar section title or plain text in a navbar.
    public static func header(_ title: String) -> MenuItem {
        MenuItem(kind: .header, title: title)
    }

    // HTML inserted as is, for example a search form; the caller is responsible for escaping.
    public static func raw(_ html: CustomStringConvertible) -> MenuItem {
        MenuItem(kind: .raw, html: html.description)
    }

    // Right-aligned in a navbar, pinned to the bottom of a sidebar. Ignored inside dropdowns.
    public func atEnd() -> MenuItem {
        MenuItem(kind: self.kind, title: self.title, html: self.html, icon: self.icon, badge: self.badge,
                 active: self.active, disabled: self.disabled, end: true)
    }

    func isActive(_ currentPath: String?) -> Bool {
        if self.active {
            return true
        }
        switch self.kind {
        case .link(let url, let matchPrefix):
            guard let currentPath else { return false }
            let current = MenuItem.normalized(currentPath)
            let target = MenuItem.normalized(url)
            if current == target {
                return true
            }
            return matchPrefix && target != "/" && current.hasPrefix(target + "/")
        case .dropdown(let items):
            return items.contains { $0.isActive(currentPath) }
        default:
            return false
        }
    }

    private static func normalized(_ path: String) -> String {
        var result = path
        if let index = result.firstIndex(where: { $0 == "?" || $0 == "#" }) {
            result = String(result[..<index])
        }
        while result.count > 1 && result.hasSuffix("/") {
            result.removeLast()
        }
        return result.isEmpty ? "/" : result
    }

    // Icon, title and badge; with `badgeAtEnd` the badge is pushed to the far side and the element needs a flex container.
    func inner(badgeAtEnd: Bool) -> String {
        var text = self.title.htmlEscaped
        if let icon {
            text = "\(icon.output) \(text)"
        }
        guard let badge else { return text }
        return badgeAtEnd ? "\(text)<span class=\"ms-auto ps-3\">\(badge.output)</span>" : "\(text) \(badge.output)"
    }

    var flexClasses: String {
        self.badge == nil ? "" : " d-flex align-items-center"
    }

    // <li> elements for a Bootstrap dropdown menu.
    func dropdownEntries(_ currentPath: String?) -> [String] {
        let active = self.isActive(currentPath)
        var classes = "dropdown-item" + self.flexClasses
        if active { classes.append(" active") }
        if self.disabled { classes.append(" disabled") }
        let inner = self.inner(badgeAtEnd: true)

        switch self.kind {
        case .link(let url, _):
            var attributes = ""
            if active { attributes.append(" aria-current=\"page\"") }
            if self.disabled { attributes.append(" tabindex=\"-1\" aria-disabled=\"true\"") }
            return ["<li><a class=\"\(classes)\" href=\"\(url.htmlEscaped)\"\(attributes)>\(inner)</a></li>"]
        case .action(let code):
            let attributes = self.disabled ? " disabled" : ""
            return ["<li><button type=\"button\" class=\"\(classes)\" onclick=\"\(code.description.htmlEscaped)\"\(attributes)>\(inner)</button></li>"]
        case .dropdown(let items):
            return [self.headerEntry] + items.flatMap { $0.dropdownEntries(currentPath) }
        case .divider:
            return ["<li><hr class=\"dropdown-divider\"></li>"]
        case .header:
            return [self.headerEntry]
        case .raw:
            return ["<li>\(self.html)</li>"]
        }
    }

    private var headerEntry: String {
        "<li><h6 class=\"dropdown-header\">\(self.title.htmlEscaped)</h6></li>"
    }
}
