//
//  JSCode.swift
//
//
//  Created by Tomasz on 01/07/2024.
//

import Foundation

public enum JSCode {
    case submitForm(path: String, domID: String)
    case loadHtml(path: String, domID: String)
    case loadJS(path: String)
    case loadMultipleJS(paths: [String])
    case loadHtmlAndJS(htmlPath: String, htmlDomID: String, jsPath: String)
    
    // notifications
    case showSuccess(String)
    case showError(String)
    case showWarning(String)
    case showInfo(String)
    
    case custom(code: String)
}

extension JSCode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .submitForm(let path, let domID):
            "submitFormInBackground(\"\(path)\", \"\(domID)');"
        case .loadHtml(let path, let domID):
            "loadHtmlThenRunScripts('\(path)', '\(domID)', []);"
        case .loadJS(let path):
            "runScripts(['\(path)']);"
        case .loadMultipleJS(let paths):
            "runScripts(['\(paths.joined(separator: "', '"))']);"
        case .loadHtmlAndJS(let htmlPath, let htmlDomID, let jsPath):
            "loadHtmlThenRunScripts('\(htmlPath)', '\(htmlDomID)', ['\(jsPath)']);"
        case .showSuccess(let message):
            "showSuccess('\(message)');"
        case .showError(let message):
            "showError('\(message)');"
        case .showWarning(let message):
            "showWarning('\(message)');"
        case .showInfo(let message):
            "showInfo('\(message)');"
        case .custom(let code):
            code
        }
    }
}
