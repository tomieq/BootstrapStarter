//
//  FormRadioModel.swift
//
//
//  Created by Tomasz on 01/07/2024.
//

import Foundation

public struct FormRadioModel {
    let label: CustomStringConvertible
    let value: CustomStringConvertible
    
    public init(label: CustomStringConvertible, value: CustomStringConvertible) {
        self.label = label
        self.value = value
    }
}
