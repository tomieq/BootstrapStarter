//
//  JSResponse.swift
//
//
//  Created by Tomasz on 01/07/2024.
//

import Foundation

public class JSResponse {
    public private(set) var code: [CustomStringConvertible] = []

    @discardableResult
    public func add(code: CustomStringConvertible...) -> JSResponse {
        self.code.append(contentsOf: code)
        return self
    }
}
