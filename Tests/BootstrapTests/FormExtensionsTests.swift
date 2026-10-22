import XCTest
@testable import BootstrapTemplate

final class FormExtensionsTests: XCTestCase {
    private func form() -> Form {
        Form(url: "/", method: "POST")
    }

    func testDateTimeInputs() {
        let html = form()
            .addDate(name: "day", label: "Day", value: "2026-10-22", min: "2026-01-01", max: "2026-12-31", id: "day")
            .addTime(name: "at", label: "At", value: "09:30", id: "at")
            .addDateTime(name: "when", label: "When", id: "when", attributes: ["required": "required"])
            .output

        XCTAssertTrue(html.contains("<input type=\"date\" class=\"form-control\" id=\"day\" value=\"2026-10-22\" name=\"day\" max=\"2026-12-31\" min=\"2026-01-01\">"))
        XCTAssertTrue(html.contains("<input type=\"time\" class=\"form-control\" id=\"at\" value=\"09:30\" name=\"at\" >"))
        XCTAssertTrue(html.contains("<input type=\"datetime-local\" class=\"form-control\" id=\"when\" value=\"\" name=\"when\" required=\"required\">"))
        XCTAssertTrue(html.contains("<label for=\"day\" class=\"form-label\">Day</label>"))
    }

    func testAutocomplete() {
        let html = form()
            .addAutocomplete(name: "city", label: "City", source: "/cities?a=1&b=2", value: "Ber", minLength: 3, id: "city")
            .output

        XCTAssertTrue(html.contains("id=\"city\" value=\"Ber\" name=\"city\""))
        XCTAssertTrue(html.contains("data-autocomplete-source=\"/cities?a=1&amp;b=2\""))
        XCTAssertTrue(html.contains("data-autocomplete-min-length=\"3\""))
        XCTAssertTrue(html.contains("autocomplete=\"off\""))
    }

    func testDependentSelect() {
        let html = form()
            .addSelect(name: "country", label: "Country", options: [FormSelectModel(label: "PL", value: "pl")], id: "country")
            .addDependentSelect(name: "region", label: "Region", dependsOn: "country", optionsPath: "/regions",
                                options: [FormSelectModel(label: "Mazovia", value: "mz")], selected: "mz", id: "region")
            .output

        XCTAssertTrue(html.contains("<select class=\"form-control\" id=\"region\" name=\"region\" data-depends-on=\"country\" data-options-path=\"/regions\">"))
        XCTAssertTrue(html.contains("<option value=\"mz\" selected=\"selected\">Mazovia</option>"))
    }

    func testOptionsHTMLHasNoIdsAndEscapesValues() {
        let html = FormSelectModel.optionsHTML([FormSelectModel(label: "A", value: "a\"b"), FormSelectModel(label: "B", value: 2)],
                                               selected: 2)

        XCTAssertEqual(html, "<option value=\"a&quot;b\">A</option>\n<option value=\"2\" selected=\"selected\">B</option>\n")
    }

    func testSelectOptionsDoNotCarryIds() {
        let html = form().addSelect(name: "n", label: "N", options: [FormSelectModel(label: "A", value: "a")], id: "sel").output

        XCTAssertEqual(html.components(separatedBy: "id=\"sel\"").count - 1, 1)
    }

    func testFormScriptIsBundledAndLoaded() throws {
        XCTAssertTrue(BootstrapTemplate().description.contains("<script src=\"/form.js\"></script>"))
        let path = try XCTUnwrap(BootstrapTemplate.absolutePath(for: "form.js"))
        let js = try String(contentsOfFile: path, encoding: .utf8)
        XCTAssertTrue(js.contains("function reloadDependentOptions("))
        XCTAssertTrue(js.contains("data-autocomplete-source"))
    }
}
