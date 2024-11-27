//
//  Form.swift
//
//
//  Created by Tomasz on 01/07/2024.
//

import Foundation
import Template

public class Form {
    let template: Template
    var html: String
    let method: String
    let url: String
    let ajax: Bool
    let formAttributes: [String:String]
    
    public init(url: String, method: String, ajax: Bool = false, attributes: [String:String] = [:]) {
        self.method = method
        self.url = url
        self.ajax = ajax
        self.formAttributes = attributes
        self.template = Template.cached(absolutePath: BootstrapTemplate.absolutePath(for: "templates/form.tpl.html")!)
        self.html = ""
    }
    
    @discardableResult
    public func addPassword(name: String,
                            label: String,
                            id: String? = nil,
                            placeholder: String = "",
                            attributes: [String:String] = [:]) -> Form {
        var variables = TemplateVariables()
        variables["label"] = label
        variables["id"] = id ?? self.randomString(length: 10)
        variables["name"] = name
        variables["attributes"] = makeAttributes(attributes)
        self.template.assign(variables, inNest: "password")
        self.html.append(self.template.output)
        self.template.reset()
        return self
    }
    
    @discardableResult
    public func addInputText(name: String,
                             label: String,
                             value: String = "",
                             id: String? = nil,
                             attributes: [String:String] = [:]) -> Form {
        var variables = TemplateVariables()
        variables["label"] = label
        variables["id"] = id ?? self.randomString(length: 10)
        variables["name"] = name
        variables["value"] = value
        variables["attributes"] = makeAttributes(attributes)

        self.template.assign(variables, inNest: "text")
        self.html.append(self.template.output)
        self.template.reset()
        return self
    }
    
    @discardableResult
    public func addSeparator(txt: CustomStringConvertible) -> Form {
        var variables = TemplateVariables()
        variables["label"] = txt
        variables["id"] = self.randomString(length: 10)
        self.template.assign(variables, inNest: "label")
        self.html.append(self.template.output)
        self.template.reset()
        return self
    }
    
    @discardableResult
    public func addRaw(html: CustomStringConvertible) -> Form {
        self.html.append(html.description)
        return self
    }
    
    @discardableResult
    public func addHidden(name: String,
                          value: CustomStringConvertible,
                          id: String? = nil,
                          attributes: [String:String] = [:]) -> Form {
        var variables = TemplateVariables()
        variables["name"] = name
        variables["value"] = value
        variables["id"] = id ?? self.randomString(length: 10)
        variables["attributes"] = makeAttributes(attributes)
        self.template.assign(variables, inNest: "hidden")
        self.html.append(self.template.output)
        self.template.reset()
        return self
    }
    
    @discardableResult
    public func addCheckbox(name: String,
                            value: CustomStringConvertible,
                            label: String) -> Form {
        var variables = TemplateVariables()
        variables["name"] = name
        variables["label"] = label
        variables["value"] = value
        variables["id"] = self.randomString(length: 10)
        self.template.assign(variables, inNest: "checkbox")
        self.html.append(self.template.output)
        self.template.reset()
        return self
    }
    
    @discardableResult
    public func addRadio(name: String,
                         label: String,
                         options: [FormRadioModel],
                         selected: CustomStringConvertible? = nil,
                         attributes: [String:String] = [:]) -> Form {
        
        var radioHTML = ""
        options.forEach { option in
            var variables = TemplateVariables()
            variables["label"] = option.label
            variables["id"] = self.randomString(length: 10)
            variables["name"] = name
            variables["value"] = option.value
            if selected?.description == option.value.description {
                variables["checked"] = "checked"
            }
            self.template.assign(variables, inNest: "radio")
            radioHTML.append(self.template.output)
            self.template.reset()
        }
        var variables = TemplateVariables()
        variables["label"] = label
        variables["id"] = self.randomString(length: 10)
        variables["attributes"] = makeAttributes(attributes)
        variables["inputHTML"] = radioHTML
        self.template.assign(variables, inNest: "label")
        self.html.append(self.template.output)
        self.template.reset()
        return self
    }
    
    
    @discardableResult
    public func addSelect(name: String,
                          label: String,
                          options: [FormSelectModel],
                          selected: CustomStringConvertible? = nil,
                          id: String? = nil,
                          attributes: [String:String] = [:]) -> Form {
        
        var optionsHTML = ""
        options.forEach { option in
            var attr: [String:String] = [:]
            attr["value"] = option.value.description
            attr["id"] = id ?? self.randomString(length: 10)
            if selected?.description == option.value.description {
                attr["selected"] = "selected"
            }
            let option = "<option \(makeAttributes(attr))>\(option.label.description)</option>\n"
            optionsHTML.append(option)
        }
        var variables = TemplateVariables()
        variables["label"] = label
        variables["id"] = id ?? self.randomString(length: 10)
        variables["attributes"] = makeAttributes(attributes)
        variables["options"] = optionsHTML
        self.template.assign(variables, inNest: "select")
        self.html.append(self.template.output)
        self.template.reset()
        return self
    }
    
    @discardableResult
    public func addTextarea(name: String,
                            label: String,
                            rows: Int = 3,
                            value: CustomStringConvertible? = nil,
                            id: String? = nil,
                            attributes: [String:String] = [:]) -> Form {
        var variables = TemplateVariables()
        variables["label"] = label
        variables["id"] = id ?? self.randomString(length: 10)
        variables["rows"] = "\(rows)"
        variables["name"] = name
        variables["value"] = value ?? ""
        variables["attributes"] = makeAttributes(attributes)
        self.template.assign(variables, inNest: "textarea")
        self.html.append(self.template.output)
        self.template.reset()
        return self
    }
    
    @discardableResult
    public func addSubmit(name: String,
                          label: String,
                          style: ButtonStyle...) -> Form {
        var variables = TemplateVariables()
        variables["label"] = label
        variables["name"] = name
        variables["cssClass"] = style.isEmpty ? ButtonStyle.primary : style.map { $0.cssClass }.joined(separator: " ")
        self.template.assign(variables, inNest: "submit")
        self.html.append(self.template.output)
        self.template.reset()
        return self
    }
    
    private func makeAttributes(_ attributes: [String:String]) -> String {
        attributes.map{ "\($0.key)=\"\($0.value)\"" }.joined(separator: " ")
    }
    
    public var output: String {
        var variables = TemplateVariables()
        variables["html"] = self.html
        variables["method"] = self.method
        variables["url"] = self.url
        
        var attributes = self.formAttributes
        if self.ajax {
            attributes["onsubmit"] = "event.preventDefault(); submitFormInBackground('\(url)', this);"
        }
        variables["attributes"] = makeAttributes(attributes)
        self.template.assign(variables, inNest: "form")
        return self.template.output
    }
    
    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
