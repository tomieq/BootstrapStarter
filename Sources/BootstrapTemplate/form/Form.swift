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
                            label: String,
                            id: String? = nil,
                            selected: Bool = false) -> Form {
        var variables = TemplateVariables()
        variables["name"] = name
        variables["label"] = label
        variables["value"] = value
        variables["id"] = id ?? self.randomString(length: 10)
        if selected {
            variables["checked"] = "checked"
        }
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
        
        var variables = TemplateVariables()
        variables["label"] = label
        variables["name"] = name
        variables["id"] = id ?? self.randomString(length: 10)
        variables["attributes"] = makeAttributes(attributes)
        variables["options"] = FormSelectModel.optionsHTML(options, selected: selected)
        self.template.assign(variables, inNest: "select")
        self.html.append(self.template.output)
        self.template.reset()
        return self
    }
    
    // The select's options are reloaded from `optionsPath` whenever the field with id `dependsOn` changes.
    // The endpoint receives the parent's `name=value` as a query parameter and returns `FormSelectModel.optionsHTML(...)`.
    // Give this select an explicit `id` if other fields depend on it.
    @discardableResult
    public func addDependentSelect(name: String,
                                   label: String,
                                   dependsOn parentID: String,
                                   optionsPath: String,
                                   options: [FormSelectModel] = [],
                                   selected: CustomStringConvertible? = nil,
                                   id: String? = nil,
                                   attributes: [String:String] = [:]) -> Form {
        var attributes = attributes
        attributes["data-depends-on"] = parentID.htmlEscaped
        attributes["data-options-path"] = optionsPath.htmlEscaped
        return self.addSelect(name: name, label: label, options: options, selected: selected, id: id, attributes: attributes)
    }
    
    // Native date input; `value`, `min` and `max` use the format yyyy-MM-dd.
    @discardableResult
    public func addDate(name: String,
                        label: String,
                        value: String = "",
                        min: String? = nil,
                        max: String? = nil,
                        id: String? = nil,
                        attributes: [String:String] = [:]) -> Form {
        self.addTemporalInput(type: "date", name: name, label: label, value: value, min: min, max: max, id: id, attributes: attributes)
    }
    
    // Native time input; `value`, `min` and `max` use the format HH:mm (or HH:mm:ss).
    @discardableResult
    public func addTime(name: String,
                        label: String,
                        value: String = "",
                        min: String? = nil,
                        max: String? = nil,
                        id: String? = nil,
                        attributes: [String:String] = [:]) -> Form {
        self.addTemporalInput(type: "time", name: name, label: label, value: value, min: min, max: max, id: id, attributes: attributes)
    }
    
    // Native date and time input (`datetime-local`); `value`, `min` and `max` use the format yyyy-MM-dd'T'HH:mm.
    @discardableResult
    public func addDateTime(name: String,
                            label: String,
                            value: String = "",
                            min: String? = nil,
                            max: String? = nil,
                            id: String? = nil,
                            attributes: [String:String] = [:]) -> Form {
        self.addTemporalInput(type: "datetime-local", name: name, label: label, value: value, min: min, max: max, id: id, attributes: attributes)
    }
    
    private func addTemporalInput(type: String,
                                  name: String,
                                  label: String,
                                  value: String,
                                  min: String?,
                                  max: String?,
                                  id: String?,
                                  attributes: [String:String]) -> Form {
        var attributes = attributes
        attributes["min"] = min?.htmlEscaped
        attributes["max"] = max?.htmlEscaped
        var variables = TemplateVariables()
        variables["type"] = type
        variables["label"] = label
        variables["id"] = id ?? self.randomString(length: 10)
        variables["name"] = name
        variables["value"] = value
        variables["attributes"] = makeAttributes(attributes)
        self.template.assign(variables, inNest: "input")
        self.html.append(self.template.output)
        self.template.reset()
        return self
    }
    
    // Text input with suggestions (jQuery UI autocomplete). `source` is queried with `?term=<text>` and must
    // return a JSON array of strings or of objects with `label` and `value`.
    @discardableResult
    public func addAutocomplete(name: String,
                                label: String,
                                source: String,
                                value: String = "",
                                minLength: Int = 2,
                                id: String? = nil,
                                attributes: [String:String] = [:]) -> Form {
        var attributes = attributes
        attributes["data-autocomplete-source"] = source.htmlEscaped
        attributes["data-autocomplete-min-length"] = "\(Swift.max(minLength, 0))"
        attributes["autocomplete"] = "off"
        return self.addInputText(name: name, label: label, value: value, id: id, attributes: attributes)
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
                          icon: Icon? = nil,
                          style: ButtonStyle...) -> Form {
        var variables = TemplateVariables()
        variables["label"] = icon.map { label.isEmpty ? $0.output : "\($0.output) \(label)" } ?? label
        variables["name"] = name
        variables["cssClass"] = style.isEmpty ? ButtonStyle.primary : style.map { $0.cssClass }.joined(separator: " ")
        self.template.assign(variables, inNest: "submit")
        self.html.append(self.template.output)
        self.template.reset()
        return self
    }
    
    private func makeAttributes(_ attributes: [String:String]) -> String {
        attributes.sorted { $0.key < $1.key }.map { "\($0.key)=\"\($0.value)\"" }.joined(separator: " ")
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
