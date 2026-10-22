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
    // Like loadHtml, but keeps the old content until the new one arrives.
    case refreshHtml(path: String, domID: String)
    case loadJS(path: String)
    case loadMultipleJS(paths: [String])
    case loadHtmlAndJS(htmlPath: String, htmlDomID: String, jsPath: String)
    
    // modals
    case loadModal(path: String)
    case showModal(domID: String)
    case hideModal
    case confirm(ConfirmDialog)    
    // notifications; the optional icon needs `BootstrapTemplate.addIcons()`
    case showSuccess(String, icon: Icon? = nil)
    case showError(String, icon: Icon? = nil)
    case showWarning(String, icon: Icon? = nil)
    case showInfo(String, icon: Icon? = nil)
    
    // page
    case redirect(path: String)
    case reload
    case scrollTo(domID: String)
    case copyToClipboard(String)
    case setTheme(BootstrapTheme)
    case toggleTheme
    
    // DOM; `html` is inserted as is
    case setHtml(domID: String, html: String)
    case appendHtml(domID: String, html: String)
    case remove(domID: String)
    case addClass(domID: String, name: String)
    case removeClass(domID: String, name: String)
    case setDisabled(domID: String, disabled: Bool)
    
    // Reloads the HTML of domID every `interval` seconds (at least 0.25) until stopPolling or the element is gone.
    case poll(path: String, domID: String, interval: TimeInterval)
    case stopPolling(domID: String)
    
    case custom(code: String)
}

extension JSCode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .submitForm(let path, let domID):
            "submitFormInBackground('\(path.jsEscaped)', '\(domID.jsEscaped)');"
        case .loadHtml(let path, let domID):
            "loadHtmlThenRunScripts('\(path.jsEscaped)', '\(domID.jsEscaped)', []);"
        case .refreshHtml(let path, let domID):
            "refreshHtml('\(path.jsEscaped)', '\(domID.jsEscaped)');"
        case .loadJS(let path):
            "runScripts(['\(path.jsEscaped)']);"
        case .loadMultipleJS(let paths):
            "runScripts(['\(paths.map { $0.jsEscaped }.joined(separator: "', '"))']);"
        case .loadHtmlAndJS(let htmlPath, let htmlDomID, let jsPath):
            "loadHtmlThenRunScripts('\(htmlPath.jsEscaped)', '\(htmlDomID.jsEscaped)', ['\(jsPath.jsEscaped)']);"
        case .loadModal(let path):
            "loadModal('\(path.jsEscaped)');"
        case .showModal(let domID):
            "showModal('\(domID.jsEscaped)');"
        case .hideModal:
            "hideModals();"
        case .confirm(let dialog):
            dialog.output
        case .showSuccess(let message, let icon):
            Self.notification("showSuccess", message, icon)
        case .showError(let message, let icon):
            Self.notification("showError", message, icon)
        case .showWarning(let message, let icon):
            Self.notification("showWarning", message, icon)
        case .showInfo(let message, let icon):
            Self.notification("showInfo", message, icon)
        case .redirect(let path):
            "window.location.href = '\(path.jsEscaped)';"
        case .reload:
            "window.location.reload();"
        case .scrollTo(let domID):
            "scrollToElement('\(domID.jsEscaped)');"
        case .copyToClipboard(let text):
            "copyToClipboard('\(text.jsEscaped)');"
        case .setTheme(let theme):
            "setTheme('\(theme.rawValue)');"
        case .toggleTheme:
            "toggleTheme();"
        case .setHtml(let domID, let html):
            "$('\(domID.jsEscaped)').html('\(html.jsEscaped)');"
        case .appendHtml(let domID, let html):
            "$('\(domID.jsEscaped)').append('\(html.jsEscaped)');"
        case .remove(let domID):
            "$('\(domID.jsEscaped)').remove();"
        case .addClass(let domID, let name):
            "$('\(domID.jsEscaped)').addClass('\(name.jsEscaped)');"
        case .removeClass(let domID, let name):
            "$('\(domID.jsEscaped)').removeClass('\(name.jsEscaped)');"
        case .setDisabled(let domID, let disabled):
            "$('\(domID.jsEscaped)').prop('disabled', \(disabled));"
        case .poll(let path, let domID, let interval):
            "startPolling('\(path.jsEscaped)', '\(domID.jsEscaped)', \(max(Int(interval * 1000), 250)));"
        case .stopPolling(let domID):
            "stopPolling('\(domID.jsEscaped)');"
        case .custom(let code):
            code
        }
    }

    private static func notification(_ function: String, _ message: String, _ icon: Icon?) -> String {
        let text = icon.map { "\($0.output) \(message)" } ?? message
        return "\(function)('\(text.jsEscaped)');"
    }
}
