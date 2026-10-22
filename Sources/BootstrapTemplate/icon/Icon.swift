//
//  Icon.swift
//

import Foundation

// A Bootstrap Icons glyph (bundled snapshot v1.13.1). Any icon name from icons.getbootstrap.com works.
public struct Icon {
    public let name: String
    private let cssClass: String?
    private let label: String?

    // `cssClass` adds utility classes such as "fs-4 text-danger"; a `label` makes the icon accessible, otherwise it is decorative.
    public init(_ name: String, cssClass: String? = nil, label: String? = nil) {
        self.name = name
        self.cssClass = cssClass
        self.label = label
    }

    public var output: String {
        var classes = "bi bi-\(self.name.htmlEscaped)"
        if let cssClass, !cssClass.isEmpty {
            classes.append(" \(cssClass.htmlEscaped)")
        }
        let accessibility = self.label.map { "role=\"img\" aria-label=\"\($0.htmlEscaped)\"" } ?? "aria-hidden=\"true\""
        return "<i class=\"\(classes)\" \(accessibility)></i>"
    }
}

extension Icon: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension Icon: CustomStringConvertible {
    public var description: String {
        self.output
    }
}

// Common icons under semantic names.
extension Icon {
    // actions
    public static let plus = Icon("plus-lg")
    public static let minus = Icon("dash-lg")
    public static let close = Icon("x-lg")
    public static let check = Icon("check-lg")
    public static let edit = Icon("pencil")
    public static let editSquare = Icon("pencil-square")
    public static let trash = Icon("trash")
    public static let search = Icon("search")
    public static let filter = Icon("funnel")
    public static let refresh = Icon("arrow-clockwise")
    public static let copy = Icon("copy")
    public static let share = Icon("share")
    public static let print = Icon("printer")
    public static let download = Icon("download")
    public static let upload = Icon("upload")
    public static let view = Icon("eye")
    public static let hide = Icon("eye-slash")
    public static let settings = Icon("gear")

    // navigation
    public static let home = Icon("house")
    public static let menu = Icon("list")
    public static let more = Icon("three-dots")
    public static let moreVertical = Icon("three-dots-vertical")
    public static let arrowLeft = Icon("arrow-left")
    public static let arrowRight = Icon("arrow-right")
    public static let arrowUp = Icon("arrow-up")
    public static let arrowDown = Icon("arrow-down")
    public static let chevronLeft = Icon("chevron-left")
    public static let chevronRight = Icon("chevron-right")
    public static let chevronUp = Icon("chevron-up")
    public static let chevronDown = Icon("chevron-down")
    public static let link = Icon("link-45deg")
    public static let externalLink = Icon("box-arrow-up-right")
    public static let login = Icon("box-arrow-in-right")
    public static let logout = Icon("box-arrow-right")

    // status
    public static let info = Icon("info-circle")
    public static let warning = Icon("exclamation-triangle")
    public static let error = Icon("x-circle")
    public static let success = Icon("check-circle")
    public static let question = Icon("question-circle")

    // objects
    public static let person = Icon("person")
    public static let people = Icon("people")
    public static let personAdd = Icon("person-plus")
    public static let mail = Icon("envelope")
    public static let bell = Icon("bell")
    public static let calendar = Icon("calendar")
    public static let clock = Icon("clock")
    public static let star = Icon("star")
    public static let starFill = Icon("star-fill")
    public static let heart = Icon("heart")
    public static let bookmark = Icon("bookmark")
    public static let tag = Icon("tag")
    public static let folder = Icon("folder")
    public static let file = Icon("file-earmark")
    public static let document = Icon("file-earmark-text")
    public static let image = Icon("image")
    public static let lock = Icon("lock")
    public static let unlock = Icon("unlock")
    public static let key = Icon("key")
    public static let shield = Icon("shield-check")
    public static let cart = Icon("cart")
    public static let chart = Icon("graph-up")
    public static let moon = Icon("moon")
    public static let sun = Icon("sun")

    static let curated: [Icon] = [
        .plus, .minus, .close, .check, .edit, .editSquare, .trash, .search, .filter, .refresh, .copy, .share,
        .print, .download, .upload, .view, .hide, .settings,
        .home, .menu, .more, .moreVertical, .arrowLeft, .arrowRight, .arrowUp, .arrowDown,
        .chevronLeft, .chevronRight, .chevronUp, .chevronDown, .link, .externalLink, .login, .logout,
        .info, .warning, .error, .success, .question,
        .person, .people, .personAdd, .mail, .bell, .calendar, .clock, .star, .starFill, .heart, .bookmark,
        .tag, .folder, .file, .document, .image, .lock, .unlock, .key, .shield, .cart, .chart, .moon, .sun
    ]
}
