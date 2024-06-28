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
    }
}
