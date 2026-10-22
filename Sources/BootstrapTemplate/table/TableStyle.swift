//
//  TableStyle.swift
//

import Foundation

public enum TableStyle: String {
    case striped
    case hover
    case bordered
    case borderless
    case small
    case dark
}

extension TableStyle {
    public var cssClass: String {
        "table-\(self.rawValue)"
    }
}

public enum TableRowStyle: String {
    case primary
    case secondary
    case success
    case danger
    case warning
    case info
    case light
    case dark
    case active
}

extension TableRowStyle {
    public var cssClass: String {
        "table-\(self.rawValue)"
    }
}

public enum TableAlignment {
    case left
    case center
    case right
}

extension TableAlignment {
    public var cssClass: String {
        switch self {
        case .left:
            "text-start"
        case .center:
            "text-center"
        case .right:
            "text-end"
        }
    }
}
