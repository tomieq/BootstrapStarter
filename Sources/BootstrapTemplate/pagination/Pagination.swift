//
//  Pagination.swift
//

import Foundation

public enum PaginationSize {
    case small
    case large
}

public enum PaginationAlignment {
    case left
    case center
    case right
}

public struct Pagination {
    private let page: Int
    private let totalPages: Int
    private let window: Int
    private let size: PaginationSize?
    private let alignment: PaginationAlignment?
    private let hideWhenSinglePage: Bool
    private let href: (Int) -> String
    private let onClick: ((Int) -> JSCode)?

    // `href` is always rendered; with `onClick` the browser runs the code instead of following it.
    public init(page: Int,
                totalPages: Int,
                window: Int = 2,
                size: PaginationSize? = nil,
                alignment: PaginationAlignment? = nil,
                hideWhenSinglePage: Bool = true,
                href: @escaping (Int) -> String = { _ in "#" },
                onClick: ((Int) -> JSCode)? = nil) {
        self.totalPages = max(totalPages, 1)
        self.page = min(max(page, 1), self.totalPages)
        self.window = max(window, 0)
        self.size = size
        self.alignment = alignment
        self.hideWhenSinglePage = hideWhenSinglePage
        self.href = href
        self.onClick = onClick
    }

    public init(page: Int,
                pageSize: Int,
                totalItems: Int,
                window: Int = 2,
                size: PaginationSize? = nil,
                alignment: PaginationAlignment? = nil,
                hideWhenSinglePage: Bool = true,
                href: @escaping (Int) -> String = { _ in "#" },
                onClick: ((Int) -> JSCode)? = nil) {
        let pageSize = max(pageSize, 1)
        self.init(page: page,
                  totalPages: (max(totalItems, 0) + pageSize - 1) / pageSize,
                  window: window,
                  size: size,
                  alignment: alignment,
                  hideWhenSinglePage: hideWhenSinglePage,
                  href: href,
                  onClick: onClick)
    }

    // Empty when there is a single page and `hideWhenSinglePage` is set.
    public var output: String {
        if self.hideWhenSinglePage && self.totalPages <= 1 {
            return ""
        }
        var classes = ["pagination"]
        switch self.size {
        case .small: classes.append("pagination-sm")
        case .large: classes.append("pagination-lg")
        case nil: break
        }
        switch self.alignment {
        case .center: classes.append("justify-content-center")
        case .right: classes.append("justify-content-end")
        case .left, nil: break
        }

        var items: [String] = []
        items.append(self.page > 1
                     ? self.item(self.link("&laquo;", page: self.page - 1, ariaLabel: "Previous"))
                     : self.item("<span class=\"page-link\" aria-hidden=\"true\">&laquo;</span>", disabled: true))
        var previous = 0
        for number in self.visiblePages {
            if number - previous > 1 {
                items.append(self.item("<span class=\"page-link\">&hellip;</span>", disabled: true))
            }
            items.append(number == self.page
                         ? self.item("<span class=\"page-link\">\(number)</span>", active: true)
                         : self.item(self.link("\(number)", page: number)))
            previous = number
        }
        items.append(self.page < self.totalPages
                     ? self.item(self.link("&raquo;", page: self.page + 1, ariaLabel: "Next"))
                     : self.item("<span class=\"page-link\" aria-hidden=\"true\">&raquo;</span>", disabled: true))

        return "<nav aria-label=\"Pagination\">\n<ul class=\"\(classes.joined(separator: " "))\">\n\(items.joined(separator: "\n"))\n</ul>\n</nav>"
    }

    // First, last and the pages around the current one; a single skipped page is shown instead of an ellipsis.
    private var visiblePages: [Int] {
        var pages = Set([1, self.totalPages])
        let lower = max(1, self.page - self.window)
        let upper = min(self.totalPages, self.page + self.window)
        pages.formUnion(lower...upper)
        var result: [Int] = []
        for number in pages.sorted() {
            if let last = result.last, number - last == 2 {
                result.append(last + 1)
            }
            result.append(number)
        }
        return result
    }

    private func item(_ content: String, active: Bool = false, disabled: Bool = false) -> String {
        var classes = "page-item"
        var attributes = ""
        if active {
            classes.append(" active")
            attributes = " aria-current=\"page\""
        }
        if disabled {
            classes.append(" disabled")
        }
        return "<li class=\"\(classes)\"\(attributes)>\(content)</li>"
    }

    private func link(_ label: String, page: Int, ariaLabel: String? = nil) -> String {
        let aria = ariaLabel.map { " aria-label=\"\($0)\"" } ?? ""
        let handler = self.onClick.map { makeCode -> String in
            let code = makeCode(page).description.trimmingCharacters(in: .whitespacesAndNewlines)
            let statement = code.hasSuffix(";") ? code : code + ";"
            return " onclick=\"\("\(statement) return false;".htmlEscaped)\""
        } ?? ""
        return "<a class=\"page-link\" href=\"\(self.href(page).htmlEscaped)\"\(aria)\(handler)>\(label)</a>"
    }
}

extension Pagination: CustomStringConvertible {
    public var description: String {
        self.output
    }
}
