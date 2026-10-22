import XCTest
@testable import BootstrapTemplate

final class ModalTests: XCTestCase {
    func testStructure() {
        let html = Modal(id: "confirm", title: "Sure?", body: "<p>Text</p>").output

        XCTAssertTrue(html.contains("<div class=\"modal fade\" id=\"confirm\" tabindex=\"-1\" aria-labelledby=\"confirm-title\" aria-hidden=\"true\">"))
        XCTAssertTrue(html.contains("<h5 class=\"modal-title\" id=\"confirm-title\">Sure?</h5>"))
        XCTAssertTrue(html.contains("data-bs-dismiss=\"modal\" aria-label=\"Close\""))
        XCTAssertTrue(html.contains("<div class=\"modal-body\">\n<p>Text</p>\n</div>"))
        XCTAssertTrue(html.contains("<div class=\"modal-dialog\">"))
        XCTAssertFalse(html.contains("modal-footer"))
    }

    func testTitleAndIdAreEscaped() {
        let html = Modal(id: "a\"b", title: "<b>x</b>", body: "").output

        XCTAssertTrue(html.contains("id=\"a&quot;b\""))
        XCTAssertTrue(html.contains("&lt;b&gt;x&lt;/b&gt;"))
    }

    func testOptions() {
        let html = Modal(id: "m", title: "T", body: "", footer: [Button("OK", onClick: .hideModal)],
                         size: .large, centered: true, scrollable: true, staticBackdrop: true, closeButton: false).output

        XCTAssertTrue(html.contains("<div class=\"modal-dialog modal-dialog-centered modal-dialog-scrollable modal-lg\">"))
        XCTAssertTrue(html.contains("data-bs-backdrop=\"static\" data-bs-keyboard=\"false\""))
        XCTAssertFalse(html.contains("btn-close"))
        XCTAssertTrue(html.contains("<div class=\"modal-footer\">\n<button type=\"button\" class=\"btn btn-primary\" onclick=\"hideModals();\">OK</button>\n</div>"))
    }

    func testBodyCanBeAnotherWidget() {
        let form = Form(url: "/x", method: "POST").addInputText(name: "n", label: "N", id: "n")
        XCTAssertTrue(Modal(id: "m", title: "T", body: form).output.contains("<form"))
    }

    func testJSCodeModalCommands() {
        XCTAssertEqual(JSCode.loadModal(path: "/users/1/edit").description, "loadModal('/users/1/edit');")
        XCTAssertEqual(JSCode.loadModal(path: "/a'b").description, "loadModal('/a\\'b');")
        XCTAssertEqual(JSCode.showModal(domID: "#confirm").description, "showModal('#confirm');")
        XCTAssertEqual(JSCode.hideModal.description, "hideModals();")
    }

    func testModalScriptIsBundledAndLoaded() {
        XCTAssertNotNil(BootstrapTemplate.absolutePath(for: "modal.js"))
        XCTAssertTrue(BootstrapTemplate().description.contains("<script src=\"/modal.js\"></script>"))
    }
}
