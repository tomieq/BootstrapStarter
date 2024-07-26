//
//  Bootstrap.swift
//
//
//  Created by Tomasz Kucharski on 26/07/2024.
//

import Foundation
import Template

public class Bootstrap {
    public let template: Template
    
    public init() {
        self.template = Template.cached(absolutePath: BootstrapTemplate.absolutePath(for: "templates/index.tpl.html")!)
    }

    public var title: String? {
        set {
            guard let title = newValue else { return }
            self.template.assign("title", title)
        }
        get {
            nil
        }
    }
    
    public func addJS(code: String) {
        self.template.assign(["code":code], inNest: "script")
    }
    
    public func addJS(url: String) {
        self.template.assign(["url":url], inNest: "jsFile")
    }
    
    public func addCSS(code: String) {
        self.template.assign(["code":code], inNest: "csscode")
    }
    
    public func addCSS(url: String) {
        self.template.assign(["url":url], inNest: "css")
    }

    public func addMeta(name: String, value: String) {
        self.template.assign(["name":name, "value": value], inNest: "meta")
    }
}
