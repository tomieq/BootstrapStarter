//
//  JSResponse.swift
//
//
//  Created by Tomasz on 01/07/2024.
//

import Foundation

public class JSResponse {
    private var code: [CustomStringConvertible]
    
    public init(_ code: CustomStringConvertible...) {
        self.code = code
    }

    init(list: [CustomStringConvertible]) {
        self.code = list
    }

    public init(@SimpleStringBuilder makeCode: () -> [CustomStringConvertible]) {
        self.code = makeCode()
    }

    @discardableResult
    public func add(_ code: CustomStringConvertible...) -> JSResponse {
        self.code.append(contentsOf: code)
        return self
    }

    @discardableResult
    public func add(@SimpleStringBuilder makeCode: () -> [CustomStringConvertible]) -> JSResponse {
        self.code.append(contentsOf: makeCode())
        return self
    }
}

extension JSResponse: CustomStringConvertible {
    public var description: String {
        self.code.map{ $0.description }.joined(separator: "\n")
    }
}

@resultBuilder
struct SimpleStringBuilder {
    static func buildBlock(_ parts: CustomStringConvertible...) -> [CustomStringConvertible] {
        parts
    }
    static func buildArray(_ components: [CustomStringConvertible]) -> [CustomStringConvertible] {
        components
    }
}

extension JSResponse {
    public convenience init(_ code: JSCode...) {
        self.init(list: code)
    }
    
    @discardableResult
    public func add(_ code: JSCode...) -> JSResponse {
        self.code.append(contentsOf: code)
        return self
    }
}
