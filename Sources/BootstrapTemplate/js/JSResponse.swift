//
//  JSResponse.swift
//
//
//  Created by Tomasz on 01/07/2024.
//

import Foundation

public class JSResponse {
    private var code: [CustomStringConvertible] = []
    
    public init() {}

    @discardableResult
    public func add(_ code: CustomStringConvertible...) -> JSResponse {
        self.code.append(contentsOf: code)
        return self
    }
}

extension JSResponse: CustomStringConvertible {
    public var description: String {
        self.code.map{ $0.description }.joined(separator: "\n")
    }
}
