import XCTest
@testable import BootstrapTemplate

final class BootstrapTests: XCTestCase {
    func testCheckboxSelectedState() {
        let selectedCheckbox = Form(url: "/", method: "POST")
            .addCheckbox(name: "terms", value: "accepted", label: "Terms", id: "terms", selected: true)
        let unselectedCheckbox = Form(url: "/", method: "POST")
            .addCheckbox(name: "terms", value: "accepted", label: "Terms", id: "terms")

        XCTAssertTrue(selectedCheckbox.output.contains("id=\"terms\" checked>"))
        XCTAssertFalse(unselectedCheckbox.output.contains("id=\"terms\" checked>"))
    }

    func testEscapingHelpers() {
        XCTAssertEqual("<a href=\"x\">&'</a>".htmlEscaped, "&lt;a href=&quot;x&quot;&gt;&amp;&#39;&lt;/a&gt;")
        XCTAssertEqual("it's\n\\ </script>".jsEscaped, "it\\'s\\n\\\\ <\\/script>")
    }

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
}

fileprivate extension JSCode {
    static func roll() -> JSCode {
        .custom(code: "roll();")
    }
}
