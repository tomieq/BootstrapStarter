import XCTest
@testable import BootstrapTemplate

final class BootstrapTests: XCTestCase {
    func testCutFilepath() throws {
        var (directory, filename, fileExtension) = BootstrapTemplate.cut("/res/bootstrap/css/file.js")
        XCTAssertEqual(directory, "shared/res/bootstrap/css")
        XCTAssertEqual(filename, "file")
        XCTAssertEqual(fileExtension, "js")
        (directory, filename, fileExtension) = BootstrapTemplate.cut("res/bootstrap/css/file.js")
        XCTAssertEqual(directory, "shared/res/bootstrap/css")
        (directory, filename, fileExtension) = BootstrapTemplate.cut("ile")
        XCTAssertEqual(directory, "shared")
        XCTAssertEqual(filename, "ile")
        XCTAssertNil(fileExtension)
        (directory, filename, fileExtension) = BootstrapTemplate.cut("/script.js")
        XCTAssertEqual(directory, "shared")
        XCTAssertEqual(filename, "script")
        XCTAssertEqual(fileExtension, "js")
    }
    
    func testBuildingJSResponse() throws {
        enum CustomCode: String, CustomStringConvertible {
            var description: String { self.rawValue }
            
            case firstCode
            case secondCode
        }
        let js = JSResponse(CustomCode.firstCode, CustomCode.secondCode).add {
            CustomCode.firstCode
            CustomCode.secondCode
        }.add(CustomCode.firstCode)
        
        XCTAssertEqual(js.description, "firstCode\nsecondCode\nfirstCode\nsecondCode\nfirstCode")

        let code = JSResponse {
            CustomCode.firstCode
            CustomCode.secondCode
        }.add(CustomCode.firstCode)
        XCTAssertEqual(code.description, "firstCode\nsecondCode\nfirstCode")
    }
    
    func testBuildingJSResponseFromJSCode() throws {

        let js = JSResponse(
            .showInfo("ok"),
            .roll()
        )
            .add(.loadJS(path: ""), .loadHtml(path: "", domID: ""))
    }
}

fileprivate extension JSCode {
    static func roll() -> JSCode {
        .custom(code: "roll();")
    }
}
