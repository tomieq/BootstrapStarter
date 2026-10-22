import XCTest
@testable import BootstrapTemplate

final class ButtonTests: XCTestCase {
    func testDefaultsToPrimary() {
        XCTAssertEqual(Button("Go").output, "<button type=\"button\" class=\"btn btn-primary\">Go</button>")
    }

    func testSizeOnlyKeepsPrimaryColor() {
        XCTAssertTrue(Button("Go", style: .small).output.contains("class=\"btn btn-primary btn-sm\""))
    }

    func testOnClickIsEscaped() {
        let html = Button("Del", onClick: .showInfo("it's \"x\""), style: .danger).output

        XCTAssertTrue(html.contains("class=\"btn btn-danger\""))
        XCTAssertTrue(html.contains("onclick=\"showInfo(&#39;it\\&#39;s &quot;x&quot;&#39;);\""))
    }

    func testLinkButton() {
        let html = Button("Open", url: "/a?x=1&y=2", attributes: ["title": "T"], style: .success).output

        XCTAssertEqual(html, "<a href=\"/a?x=1&amp;y=2\" class=\"btn btn-success\" role=\"button\" title=\"T\">Open</a>")
    }

    func testLabelIsEscaped() {
        XCTAssertTrue(Button("<b>").output.contains(">&lt;b&gt;</button>"))
    }
}
