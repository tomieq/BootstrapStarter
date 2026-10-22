import XCTest
@testable import BootstrapTemplate

final class TableTests: XCTestCase {
    func testHeaderAndRows() {
        let html = Table(id: "users", columns: ["Name", TableColumn("Age", alignment: .right)])
            .addRow(["Anna", "30"])
            .output

        XCTAssertTrue(html.contains("<table id=\"users\" class=\"table table-striped table-hover\">"))
        XCTAssertTrue(html.contains("<th scope=\"col\">Name</th>"))
        XCTAssertTrue(html.contains("<th scope=\"col\" class=\"text-end\">Age</th>"))
        XCTAssertTrue(html.contains("<td>Anna</td>"))
        XCTAssertTrue(html.contains("<td class=\"text-end\">30</td>"))
        XCTAssertTrue(html.hasPrefix("<div class=\"table-responsive\">"))
    }

    func testTextIsEscapedButRawIsNot() {
        let html = Table(columns: ["A"], responsive: false)
            .addRow([TableCell("<b>x</b>")])
            .addRow([.raw("<b>y</b>")])
            .output

        XCTAssertTrue(html.contains("<td>&lt;b&gt;x&lt;/b&gt;</td>"))
        XCTAssertTrue(html.contains("<td><b>y</b></td>"))
        XCTAssertFalse(html.contains("table-responsive"))
    }

    func testEmptyMessageAndRowStyle() {
        let empty = Table(columns: ["A", "B"]).setEmptyMessage("No data").output
        XCTAssertTrue(empty.contains("<td colspan=\"2\" class=\"text-center text-muted\">No data</td>"))

        let styled = Table(columns: ["A"]).addRow(["x"], style: .danger).output
        XCTAssertTrue(styled.contains("<tr class=\"table-danger\">"))
    }

    func testButtonCellIsNotEscaped() {
        let cell = TableCell(Button("Del", onClick: .showInfo("ok"), style: .danger, .small))
        let html = Table(columns: ["A"]).addRow([cell]).output

        XCTAssertTrue(html.contains("<td><button type=\"button\" class=\"btn btn-danger btn-sm\""))
    }

    func testAddRowsFromModels() {
        let html = Table(columns: ["N"])
            .addRows([1, 2, 3]) { [TableCell($0)] }
            .output

        XCTAssertEqual(html.components(separatedBy: "<td>").count - 1, 3)
    }
}
