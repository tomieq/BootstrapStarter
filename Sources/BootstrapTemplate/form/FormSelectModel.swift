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
}
