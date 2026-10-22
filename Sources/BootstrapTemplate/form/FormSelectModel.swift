//
//  FormSelectModel.swift
//  BootstrapStarter
//
//  Created by Tomasz on 27/11/2024.
//

import Foundation

public struct FormSelectModel {
    let label: CustomStringConvertible
    let value: CustomStringConvertible
    
    public init(label: CustomStringConvertible, value: CustomStringConvertible) {
        self.label = label
        self.value = value
    }
    
    // `<option>` elements; the label is inserted as is, the value is attribute-escaped.
    public static func optionsHTML(_ options: [FormSelectModel], selected: CustomStringConvertible? = nil) -> String {
        options.map { option in
            let value = option.value.description
            let state = selected?.description == value ? " selected=\"selected\"" : ""
            return "<option value=\"\(value.htmlEscaped)\"\(state)>\(option.label.description)</option>\n"
        }.joined()
    }
}
