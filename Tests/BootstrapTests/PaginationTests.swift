import XCTest
@testable import BootstrapTemplate

final class PaginationTests: XCTestCase {
    private func labels(_ html: String) -> [String] {
        html.components(separatedBy: "\n")
            .filter { $0.hasPrefix("<li") }
            .map { line in
                let text = line.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                return line.contains(" active") ? "[\(text)]" : text
            }
    }

    func testWindowWithEllipsis() {
        let html = Pagination(page: 10, totalPages: 20, window: 1).output
        XCTAssertEqual(labels(html), ["&laquo;", "1", "&hellip;", "9", "[10]", "11", "&hellip;", "20", "&raquo;"])
    }

    func testSingleSkippedPageIsShownInsteadOfEllipsis() {
        let html = Pagination(page: 4, totalPages: 8, window: 1).output
        XCTAssertEqual(labels(html), ["&laquo;", "1", "2", "3", "[4]", "5", "&hellip;", "8", "&raquo;"])
    }

    func testFirstPageDisablesPrevious() {
        let html = Pagination(page: 1, totalPages: 3).output
        XCTAssertTrue(html.contains("<li class=\"page-item disabled\"><span class=\"page-link\" aria-hidden=\"true\">&laquo;</span></li>"))
        XCTAssertTrue(html.contains("<li class=\"page-item active\" aria-current=\"page\"><span class=\"page-link\">1</span></li>"))
        XCTAssertTrue(html.contains("href=\"#\" aria-label=\"Next\""))
    }

    func testLastPageDisablesNext() {
        let html = Pagination(page: 3, totalPages: 3, href: { "/u?page=\($0)" }).output
        XCTAssertTrue(html.contains("<li class=\"page-item disabled\"><span class=\"page-link\" aria-hidden=\"true\">&raquo;</span></li>"))
        XCTAssertTrue(html.contains("href=\"/u?page=2\" aria-label=\"Previous\""))
    }

    func testHrefIsEscapedAndOnClickIsAdded() {
        let html = Pagination(page: 1,
                              totalPages: 2,
                              href: { "/u?a=1&page=\($0)" },
                              onClick: { .loadHtml(path: "/u/list?page=\($0)", domID: "#list") }).output
        XCTAssertTrue(html.contains("href=\"/u?a=1&amp;page=2\""))
        XCTAssertTrue(html.contains("onclick=\"loadHtmlThenRunScripts(&#39;/u/list?page=2&#39;, &#39;#list&#39;, []); return false;\""))
    }

    func testPageIsClampedAndTotalFromItems() {
        let html = Pagination(page: 99, pageSize: 10, totalItems: 25).output
        XCTAssertEqual(labels(html), ["&laquo;", "1", "2", "[3]", "&raquo;"])
    }

    func testHiddenForSinglePageUnlessDisabled() {
        XCTAssertEqual(Pagination(page: 1, pageSize: 10, totalItems: 5).output, "")
        XCTAssertFalse(Pagination(page: 1, totalPages: 1, hideWhenSinglePage: false).output.isEmpty)
        XCTAssertEqual(Pagination(page: 1, pageSize: 10, totalItems: 0).output, "")
    }

    func testSizeAndAlignment() {
        let html = Pagination(page: 1, totalPages: 2, size: .small, alignment: .center).output
        XCTAssertTrue(html.contains("<ul class=\"pagination pagination-sm justify-content-center\">"))
    }
}
