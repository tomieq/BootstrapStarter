//
//  BootstrapTemplate.swift
//
//
//  Created by Tomasz Kucharski on 26/07/2024.
//

import Foundation
import Template

public class BootstrapTemplate {
    public let template: Template
    
    public init() {
        self.template = Template.cached(absolutePath: BootstrapTemplate.absolutePath(for: "templates/index.tpl.html")!)
    }

    public var title: String? {
        set {
            guard let title = newValue else { return }
            self.template["title"] = title
        }
        get {
            nil
        }
    }
    
    public var body: CustomStringConvertible? {
        set {
            guard let body = newValue else { return }
            self.template["body"] = body
        }
        get {
            nil
        }
    }
    
    public func addJS(code: CustomStringConvertible) {
        self.template.assign(["code":code.description], inNest: "script")
    }
    
    public func addJS(url: String) {
        self.template.assign(["url":url], inNest: "jsFile")
    }
    
    public func addCSS(code: CustomStringConvertible) {
        self.template.assign(["code":code.description], inNest: "csscode")
    }
    
    public func addCSS(url: String) {
        self.template.assign(["url":url], inNest: "css")
    }

    public func addMeta(name: String, value: String) {
        self.template.assign(["name":name, "value": value], inNest: "meta")
    }
    
    public func addFavicon(url: String, type: String) {
        self.template.assign(["url": url, "type": type], inNest: "favicon")
    }
}

extension BootstrapTemplate: CustomStringConvertible {
    public var description: String {
        self.template.description
    }
}
