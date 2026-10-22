import XCTest
@testable import BootstrapTemplate

final class TabsTests: XCTestCase {
    func testStructureAndDefaultActiveTab() {
        let html = Tabs(id: "profile")
            .addTab("Info", content: "<p>Info</p>")
            .addTab("Security", content: "<p>Sec</p>")
            .output

        XCTAssertTrue(html.contains("<ul class=\"nav nav-tabs\" id=\"profile\" role=\"tablist\">"))
        XCTAssertTrue(html.contains("<button class=\"nav-link active\" id=\"profile-1-tab\" data-bs-toggle=\"tab\" data-bs-target=\"#profile-1\" type=\"button\" role=\"tab\" aria-controls=\"profile-1\" aria-selected=\"true\">Info</button>"))
        XCTAssertTrue(html.contains("<button class=\"nav-link\" id=\"profile-2-tab\" data-bs-toggle=\"tab\" data-bs-target=\"#profile-2\" type=\"button\" role=\"tab\" aria-controls=\"profile-2\" aria-selected=\"false\">Security</button>"))
        XCTAssertTrue(html.contains("<div class=\"tab-pane fade show active\" id=\"profile-1\" role=\"tabpanel\" aria-labelledby=\"profile-1-tab\" tabindex=\"0\">\n<p>Info</p>\n</div>"))
        XCTAssertTrue(html.contains("<div class=\"tab-pane fade\" id=\"profile-2\""))
    }

    func testExplicitActiveAndDisabledTabs() {
        let html = Tabs(id: "t")
            .addTab("A", id: "a", content: "a", disabled: true)
            .addTab("B", id: "b", content: "b")
            .addTab("C", id: "c", content: "c", active: true)
            .output

        XCTAssertTrue(html.contains("class=\"nav-link disabled\" id=\"a-tab\""))
        XCTAssertTrue(html.contains("aria-selected=\"false\" disabled aria-disabled=\"true\">A</button>"))
        XCTAssertTrue(html.contains("<div class=\"tab-pane fade show active\" id=\"c\""))
        XCTAssertFalse(html.contains("<div class=\"tab-pane fade show active\" id=\"b\""))
    }

    func testFirstEnabledTabIsActiveWhenNoneSelected() {
        let html = Tabs(id: "t")
            .addTab("A", id: "a", content: "a", disabled: true)
            .addTab("B", id: "b", content: "b")
            .output

        XCTAssertTrue(html.contains("<div class=\"tab-pane fade show active\" id=\"b\""))
    }

    func testTitleIsEscapedAndIconIsRendered() {
        let html = Tabs(id: "t").addTab("<b>x</b>", icon: .person, content: "").output

        XCTAssertTrue(html.contains(">" + Icon.person.output + " &lt;b&gt;x&lt;/b&gt;</button>"))
    }

    func testLazyTab() {
        let html = Tabs(id: "t")
            .addTab("A", content: "a")
            .addLazyTab("Users", path: "/users/table?a=1&b=2")
            .output

        XCTAssertTrue(html.contains("id=\"t-2\" role=\"tabpanel\" aria-labelledby=\"t-2-tab\" tabindex=\"0\" data-lazy-path=\"/users/table?a=1&amp;b=2\""))
        XCTAssertTrue(html.contains("spinner-border"))
    }

    func testStylesFillAndVertical() {
        let html = Tabs(id: "t", style: .pills, fill: true, vertical: true).addTab("A", content: "a").output

        XCTAssertTrue(html.hasPrefix("<div class=\"d-flex align-items-start\">"))
        XCTAssertTrue(html.contains("<ul class=\"nav nav-pills nav-fill flex-column me-3\" id=\"t\" role=\"tablist\" aria-orientation=\"vertical\">"))
        XCTAssertTrue(html.contains("<div class=\"tab-content flex-grow-1\">"))
        XCTAssertTrue(html.hasSuffix("</div>\n</div>"))
        XCTAssertTrue(Tabs(id: "t", style: .underline).addTab("A", content: "a").output.contains("nav nav-underline"))
    }

    func testEmptyTabsRenderNothing() {
        XCTAssertEqual(Tabs(id: "t").output, "")
    }

    func testBodyCanBeAnotherWidget() {
        let table = Table(columns: ["A"]).addRow(["x"])
        XCTAssertTrue(Tabs(id: "t").addTab("T", content: table).output.contains("<table"))
    }

    func testShowTabCommandAndScript() throws {
        XCTAssertEqual(JSCode.showTab(domID: "#t-2").description, "showTab('#t-2');")
        XCTAssertTrue(BootstrapTemplate().description.contains("<script src=\"/tabs.js\"></script>"))
        let path = try XCTUnwrap(BootstrapTemplate.absolutePath(for: "tabs.js"))
        XCTAssertTrue(try String(contentsOfFile: path, encoding: .utf8).contains("function loadLazyTab("))
    }
}
