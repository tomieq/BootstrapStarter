//
//  ButtonStyle.swift
//
//
//  Created by Tomasz on 01/07/2024.
//

import Foundation

public enum ButtonStyle: String {
    // color
    case primary
    case secondary
    case success
    case danger
    case warning
    case info
    case light
    case dark
    case link
    // size
    case large
    case small
}

extension ButtonStyle {
    public var cssClass: String {
        switch self {
        case .large:
            "btn-lg"
        case .small:
            "btn-sm"
        default:
            "btn-\(self.rawValue)"
        }
    }
}

extension ButtonStyle: CustomStringConvertible {
    public var description: String {
        self.cssClass
    }
}
