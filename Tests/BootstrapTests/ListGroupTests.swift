import XCTest
@testable import BootstrapTemplate

final class ListGroupTests: XCTestCase {
    func testPlainList() {
        let html = ListGroup(id: "files")
            .addItem("One")
            .addItem(ListGroupItem("Two", active: true))
            .addItem(ListGroupItem("Three", color: .success, disabled: true))
            .output

        XCTAssertEqual(html,
            "<ul id=\"files\" class=\"list-group\">\n" +
            "<li class=\"list-group-item\">One</li>\n" +
            "<li class=\"list-group-item active\" aria-current=\"true\">Two</li>\n" +
            "<li class=\"list-group-item list-group-item-success disabled\" aria-disabled=\"true\">Three</li>\n" +
            "</ul>")
    }

    func testTextIsEscapedButRawIsNot() {
        let html = ListGroup().addItem("<b>x</b>").addItem(.raw("<b>y</b>")).output

        XCTAssertTrue(html.contains(">&lt;b&gt;x&lt;/b&gt;</li>"))
        XCTAssertTrue(html.contains("><b>y</b></li>"))
    }

    func testBadgeAndIcon() {
        let html = ListGroup()
            .addItem(ListGroupItem("Inbox", icon: .mail, badge: Badge(14, color: .primary, pill: true)))
            .output

        XCTAssertTrue(html.contains("<li class=\"list-group-item d-flex justify-content-between align-items-center\"><div>" + Icon.mail.output + " Inbox</div><span class=\"badge text-bg-primary rounded-pill\">14</span></li>"))
    }

    func testLinkAndActionItemsUseDivContainer() {
        let html = ListGroup()
            .addItem(ListGroupItem("Home", url: "/a?x=1&y=2", active: true))
            .addItem(ListGroupItem("Delete", onClick: .showInfo("it's"), color: .danger))
            .addItem(ListGroupItem("Off", url: "/off", disabled: true))
            .addItem("Plain")
            .output

        XCTAssertTrue(html.hasPrefix("<div class=\"list-group\">"))
        XCTAssertTrue(html.hasSuffix("</div>"))
        XCTAssertTrue(html.contains("<a class=\"list-group-item list-group-item-action active\" aria-current=\"true\" href=\"/a?x=1&amp;y=2\">Home</a>"))
        XCTAssertTrue(html.contains("<button class=\"list-group-item list-group-item-action list-group-item-danger\" type=\"button\" onclick=\"showInfo(&#39;it\\&#39;s&#39;);\">Delete</button>"))
        XCTAssertTrue(html.contains("<a class=\"list-group-item list-group-item-action disabled\" href=\"/off\" tabindex=\"-1\" aria-disabled=\"true\">Off</a>"))
        XCTAssertTrue(html.contains("<div class=\"list-group-item\">Plain</div>"))
    }

    func testRawLinkAndAction() {
        let html = ListGroup()
            .addItem(.raw("<i>x</i>", url: "/x"))
            .addItem(.raw("y", onClick: .reload))
            .output

        XCTAssertTrue(html.contains("href=\"/x\"><i>x</i></a>"))
        XCTAssertTrue(html.contains("onclick=\"window.location.reload();\">y</button>"))
    }

    func testLayoutOptions() {
        XCTAssertTrue(ListGroup(flush: true, horizontal: true).addItem("a").output
            .hasPrefix("<ul class=\"list-group list-group-flush list-group-horizontal\">"))
        XCTAssertTrue(ListGroup(numbered: true).addItem("a").output.hasPrefix("<ol class=\"list-group list-group-numbered\">"))
        XCTAssertTrue(ListGroup(numbered: true).addItem(ListGroupItem("a", url: "/")).output
            .hasPrefix("<div class=\"list-group list-group-numbered\">"))
    }

    func testEmptyMessageAndAddItems() {
        XCTAssertTrue(ListGroup().setEmptyMessage("Nothing").output
            .contains("<li class=\"list-group-item disabled\" aria-disabled=\"true\">Nothing</li>"))
        let html = ListGroup().addItems([1, 2, 3]) { ListGroupItem("n\($0)") }.output
        XCTAssertEqual(html.components(separatedBy: "<li ").count - 1, 3)
    }

    func testBadgeOutput() {
        XCTAssertEqual(Badge("New").output, "<span class=\"badge text-bg-primary\">New</span>")
        XCTAssertEqual(Badge("<3", color: .danger, pill: true).output,
                       "<span class=\"badge text-bg-danger rounded-pill\">&lt;3</span>")
        let table = Table(columns: ["A"]).addRow([TableCell(Badge(5))]).output
        XCTAssertTrue(table.contains("<td><span class=\"badge"))
    }
}
