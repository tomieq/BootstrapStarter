//
//  Table.swift
//

import Foundation

public class Table {
    private struct Row {
        let cells: [TableCell]
        let style: TableRowStyle?
    }

    private let id: String?
    private let columns: [TableColumn]
    private let styles: [TableStyle]
    private let responsive: Bool
    private var rows: [Row] = []
    private var caption: String?
    private var emptyMessage: String?

    public init(id: String? = nil,
                columns: [TableColumn],
                styles: [TableStyle] = [.striped, .hover],
                responsive: Bool = true) {
        self.id = id
        self.columns = columns
        self.styles = styles
        self.responsive = responsive
    }

    @discardableResult
    public func addRow(_ cells: [TableCell], style: TableRowStyle? = nil) -> Table {
        self.rows.append(Row(cells: cells, style: style))
        return self
    }

    @discardableResult
    public func addRows<T>(_ items: [T], cells: (T) -> [TableCell]) -> Table {
        items.forEach { self.addRow(cells($0)) }
        return self
    }

    @discardableResult
    public func setCaption(_ caption: String) -> Table {
        self.caption = caption
        return self
    }

    // Shown in place of the body when there are no rows.
    @discardableResult
    public func setEmptyMessage(_ message: String) -> Table {
        self.emptyMessage = message
        return self
    }

    public var output: String {
        var html = ""
        if self.responsive {
            html.append("<div class=\"table-responsive\">\n")
        }
        var classes = ["table"]
        classes.append(contentsOf: self.styles.map { $0.cssClass })
        let idAttribute = self.id.map { " id=\"\($0.htmlEscaped)\"" } ?? ""
        html.append("<table\(idAttribute) class=\"\(classes.joined(separator: " "))\">\n")
        if let caption {
            html.append("<caption>\(caption.htmlEscaped)</caption>\n")
        }
        if !self.columns.isEmpty {
            html.append("<thead><tr>")
            for column in self.columns {
                html.append("<th scope=\"col\"\(classAttribute([column.alignment?.cssClass]))>\(column.title.htmlEscaped)</th>")
            }
            html.append("</tr></thead>\n")
        }
        html.append("<tbody>\n")
        if self.rows.isEmpty, let emptyMessage {
            let span = max(self.columns.count, 1)
            html.append("<tr><td colspan=\"\(span)\" class=\"text-center text-muted\">\(emptyMessage.htmlEscaped)</td></tr>\n")
        }
        for row in self.rows {
            html.append("<tr\(classAttribute([row.style?.cssClass]))>")
            for (index, cell) in row.cells.enumerated() {
                let alignment = cell.alignment ?? (index < self.columns.count ? self.columns[index].alignment : nil)
                html.append("<td\(classAttribute([alignment?.cssClass]))>\(cell.html)</td>")
            }
            html.append("</tr>\n")
        }
        html.append("</tbody>\n</table>")
        if self.responsive {
            html.append("\n</div>")
        }
        return html
    }

    private func classAttribute(_ classes: [String?]) -> String {
        let value = classes.compactMap { $0 }.joined(separator: " ")
        return value.isEmpty ? "" : " class=\"\(value)\""
    }
}

extension Table: CustomStringConvertible {
    public var description: String {
        self.output
    }
}
