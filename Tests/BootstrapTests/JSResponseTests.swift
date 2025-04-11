//
//  JSResponseTests.swift
//  BootstrapStarter
//
//  Created by Tomasz on 11/04/2025.
//

import XCTest
@testable import BootstrapTemplate

final class JSResponseTests: XCTestCase {
    
    func testInitWithJSCode() throws {
        let js = JSResponse(
            .showSuccess("OK")
        )
        XCTAssertEqual(js.description, "showSuccess('OK');")
    }
    
    func testInitWithMultipleJSCode() throws {
        let js = JSResponse(
            .showSuccess("OK"),
            .showError("Failed")
        )
        XCTAssertEqual(js.description, "showSuccess('OK');\nshowError('Failed');")
    }
    
    func testInitWithCustomJSCodeGenerator() throws {
        enum CustomCodeGenerator: String, CustomStringConvertible {
            case firstCode
            case secondCode
            var description: String { self.rawValue }
        }
        let js = JSResponse(
            CustomCodeGenerator.firstCode,
            CustomCodeGenerator.secondCode,
            "rawCall();"
        )
        XCTAssertEqual(js.description, "firstCode\nsecondCode\nrawCall();")
    }
    
    func testComposeWithJSCode() throws {
        let js = JSResponse {
            JSCode.showSuccess("OK")
        }
        XCTAssertEqual(js.description, "showSuccess('OK');")
    }

    func testComposeWithMultipleJSCode() throws {
        let js = JSResponse {
            JSCode.showSuccess("OK")
            JSCode.showError("Failed")
        }
        XCTAssertEqual(js.description, "showSuccess('OK');\nshowError('Failed');")
    }

    func testComposeWithRawString() throws {
        let js = JSResponse {
            JSCode.showSuccess("OK")
            "reloadUI();"
        }
        XCTAssertEqual(js.description, "showSuccess('OK');\nreloadUI();")
    }
    
    func testAddWithJSCode() throws {
        let js = JSResponse()
        js.add (
            .showSuccess("OK"),
            .loadJS(path: "/script.js")
        )
        XCTAssertEqual(js.description, "showSuccess('OK');\nrunScripts(['/script.js']);")
    }
    
    func testAddCustomStringConvertible() throws {
        enum CustomCodeGenerator: String, CustomStringConvertible {
            case firstCode
            var description: String { self.rawValue }
        }
        let js = JSResponse()
        js.add (
            "roll(5);",
            JSCode.showSuccess("OK"),
            CustomCodeGenerator.firstCode
        )
        XCTAssertEqual(js.description, "roll(5);\nshowSuccess('OK');\nfirstCode")
    }
    
    func testAddResultBuilder() throws {
        enum CustomCodeGenerator: String, CustomStringConvertible {
            case firstCode
            var description: String { self.rawValue }
        }
        let js = JSResponse()
        js.add {
            "roll(5);"
            JSCode.showSuccess("OK")
            CustomCodeGenerator.firstCode
        }
        XCTAssertEqual(js.description, "roll(5);\nshowSuccess('OK');\nfirstCode")
    }
}
