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
    // notifications
    case showSuccess(String)
    case showError(String)
    case showWarning(String)
    case showInfo(String)
    
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
        case .showSuccess(let message):
            "showSuccess('\(message.jsEscaped)');"
        case .showError(let message):
            "showError('\(message.jsEscaped)');"
        case .showWarning(let message):
            "showWarning('\(message.jsEscaped)');"
        case .showInfo(let message):
            "showInfo('\(message.jsEscaped)');"
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
}
