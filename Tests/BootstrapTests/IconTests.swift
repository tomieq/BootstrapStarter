import XCTest
@testable import BootstrapTemplate

final class IconTests: XCTestCase {
    func testOutput() {
        XCTAssertEqual(Icon.trash.output, "<i class=\"bi bi-trash\" aria-hidden=\"true\"></i>")
        XCTAssertEqual(Icon("star-fill", cssClass: "fs-4 text-warning", label: "Favorite").output,
                       "<i class=\"bi bi-star-fill fs-4 text-warning\" role=\"img\" aria-label=\"Favorite\"></i>")
    }

    func testValuesAreEscaped() {
        XCTAssertEqual(Icon("a\"b", cssClass: "<x>", label: "\"").output,
                       "<i class=\"bi bi-a&quot;b &lt;x&gt;\" role=\"img\" aria-label=\"&quot;\"></i>")
    }

    func testStringLiteral() {
        let icon: Icon = "airplane"
        XCTAssertEqual(icon.name, "airplane")
    }

    func testButtonWithIcon() {
        XCTAssertTrue(Button("Delete", icon: .trash, style: .danger).output
            .hasSuffix(">" + Icon.trash.output + " Delete</button>"))
        XCTAssertTrue(Button("", icon: .trash, attributes: ["aria-label": "Delete"]).output
            .hasSuffix(">" + Icon.trash.output + "</button>"))
        XCTAssertTrue(Button("Open", icon: .externalLink, url: "/x").output.contains(Icon.externalLink.output + " Open</a>"))
    }

    func testTableCellWithIcon() {
        let html = Table(columns: ["A"]).addRow([TableCell(Icon.check)]).output
        XCTAssertTrue(html.contains("<td><i class=\"bi bi-check-lg\""))
    }

    func testAddIconsLoadsStylesheetOnce() {
        let page = BootstrapTemplate()
        page.addIcons()
        page.addIcons()
        XCTAssertEqual(page.description.components(separatedBy: "bootstrap-icons.min.css").count - 1, 1)
    }

    func testSnapshotIsBundled() {
        XCTAssertNotNil(BootstrapTemplate.absolutePath(for: "/bootstrap-icons-1.13.1/bootstrap-icons.min.css"))
        XCTAssertNotNil(BootstrapTemplate.absolutePath(for: "/bootstrap-icons-1.13.1/fonts/bootstrap-icons.woff2"))
        XCTAssertNotNil(BootstrapTemplate.absolutePath(for: "/bootstrap-icons-1.13.1/fonts/bootstrap-icons.woff"))
        XCTAssertNotNil(BootstrapTemplate.absolutePath(for: "/bootstrap-icons-1.13.1/LICENSE"))
    }

    func testEveryCuratedIconExistsInBundledStylesheet() throws {
        let path = try XCTUnwrap(BootstrapTemplate.absolutePath(for: "/bootstrap-icons-1.13.1/bootstrap-icons.min.css"))
        let css = try String(contentsOfFile: path, encoding: .utf8)

        XCTAssertGreaterThanOrEqual(Icon.curated.count, 60)
        XCTAssertEqual(Set(Icon.curated.map { $0.name }).count, Icon.curated.count, "duplicate icon names")
        for icon in Icon.curated {
            XCTAssertTrue(css.contains(".bi-\(icon.name)::before"), "missing icon: \(icon.name)")
        }
    }
}
