//
//  Tabs.swift
//

import Foundation

public enum TabsStyle {
    case tabs
    case pills
    case underline
}

extension TabsStyle {
    var cssClass: String {
        switch self {
        case .tabs: "nav-tabs"
        case .pills: "nav-pills"
        case .underline: "nav-underline"
        }
    }
}

public class Tabs {
    private struct Tab {
        let key: String
        let title: String
        let icon: Icon?
        let content: String
        let lazyPath: String?
        let active: Bool
        let disabled: Bool
    }

    private let id: String
    private let style: TabsStyle
    private let fill: Bool
    private let vertical: Bool
    private var tabs: [Tab] = []

    // `id` must be unique on the page; tab panes get the ids `<id>-1`, `<id>-2`, ... unless given.
    public init(id: String, style: TabsStyle = .tabs, fill: Bool = false, vertical: Bool = false) {
        self.id = id
        self.style = style
        self.fill = fill
        self.vertical = vertical
    }

    // `content` is inserted as is (a Form, a Table, HTML...); the title is escaped.
    @discardableResult
    public func addTab(_ title: String,
                       icon: Icon? = nil,
                       id: String? = nil,
                       content: CustomStringConvertible,
                       active: Bool = false,
                       disabled: Bool = false) -> Tabs {
        self.append(title, icon, id, content.description, nil, active, disabled)
    }

    // The content is fetched from `path` the first time the tab is shown.
    @discardableResult
    public func addLazyTab(_ title: String,
                           icon: Icon? = nil,
                           id: String? = nil,
                           path: String,
                           active: Bool = false,
                           disabled: Bool = false) -> Tabs {
        let spinner = "<div class=\"text-center text-muted py-4\"><div class=\"spinner-border spinner-border-sm\" role=\"status\"><span class=\"visually-hidden\">Loading...</span></div></div>"
        return self.append(title, icon, id, spinner, path, active, disabled)
    }

    private func append(_ title: String, _ icon: Icon?, _ id: String?, _ content: String,
                        _ lazyPath: String?, _ active: Bool, _ disabled: Bool) -> Tabs {
        let key = id ?? "\(self.id)-\(self.tabs.count + 1)"
        self.tabs.append(Tab(key: key, title: title, icon: icon, content: content,
                             lazyPath: lazyPath, active: active, disabled: disabled))
        return self
    }

    private var activeIndex: Int? {
        self.tabs.firstIndex { $0.active && !$0.disabled } ?? self.tabs.firstIndex { !$0.disabled }
    }

    public var output: String {
        guard !self.tabs.isEmpty else { return "" }
        let activeIndex = self.activeIndex

        var navClasses = ["nav", self.style.cssClass]
        if self.fill {
            navClasses.append("nav-fill")
        }
        if self.vertical {
            navClasses.append("flex-column me-3")
        }
        let orientation = self.vertical ? " aria-orientation=\"vertical\"" : ""

        var html = self.vertical ? "<div class=\"d-flex align-items-start\">\n" : ""
        html.append("<ul class=\"\(navClasses.joined(separator: " "))\" id=\"\(self.id.htmlEscaped)\" role=\"tablist\"\(orientation)>\n")
        for (index, tab) in self.tabs.enumerated() {
            let key = tab.key.htmlEscaped
            let isActive = index == activeIndex
            var classes = "nav-link"
            if isActive { classes.append(" active") }
            if tab.disabled { classes.append(" disabled") }
            let state = tab.disabled ? " disabled aria-disabled=\"true\"" : ""
            let title = tab.icon.map { "\($0.output) \(tab.title.htmlEscaped)" } ?? tab.title.htmlEscaped
            html.append("<li class=\"nav-item\" role=\"presentation\"><button class=\"\(classes)\" id=\"\(key)-tab\" data-bs-toggle=\"tab\" data-bs-target=\"#\(key)\" type=\"button\" role=\"tab\" aria-controls=\"\(key)\" aria-selected=\"\(isActive)\"\(state)>\(title)</button></li>\n")
        }
        html.append("</ul>\n")

        html.append("<div class=\"tab-content\(self.vertical ? " flex-grow-1" : "")\">\n")
        for (index, tab) in self.tabs.enumerated() {
            let key = tab.key.htmlEscaped
            let paneClasses = index == activeIndex ? "tab-pane fade show active" : "tab-pane fade"
            let lazy = tab.lazyPath.map { " data-lazy-path=\"\($0.htmlEscaped)\"" } ?? ""
            html.append("<div class=\"\(paneClasses)\" id=\"\(key)\" role=\"tabpanel\" aria-labelledby=\"\(key)-tab\" tabindex=\"0\"\(lazy)>\n\(tab.content)\n</div>\n")
        }
        html.append("</div>")
        if self.vertical {
            html.append("\n</div>")
        }
        return html
    }
}

extension Tabs: CustomStringConvertible {
    public var description: String {
        self.output
    }
}
