import XCTest
@testable import BootstrapTemplate

final class FormUploadTests: XCTestCase {
    func testFileFieldOutput() {
        let html = Form(url: "/upload", method: "POST")
            .addFile(name: "photo", label: "Photo", accept: "image/*", multiple: true, maxSize: 5_242_880, id: "photo")
            .output

        XCTAssertTrue(html.contains("<input type=\"file\" class=\"form-control\" id=\"photo\" name=\"photo\" accept=\"image/*\" data-max-size=\"5242880\" multiple=\"multiple\">"))
        XCTAssertTrue(html.contains("<label for=\"photo\" class=\"form-label\">Photo</label>"))
    }

    func testFormBecomesMultipart() {
        let withFile = Form(url: "/u", method: "POST").addFile(name: "f", label: "F").output
        let without = Form(url: "/u", method: "POST").addInputText(name: "n", label: "N").output
        let custom = Form(url: "/u", method: "POST", attributes: ["enctype": "text/plain"]).addFile(name: "f", label: "F").output

        XCTAssertTrue(withFile.contains("enctype=\"multipart/form-data\""))
        XCTAssertFalse(without.contains("enctype"))
        XCTAssertTrue(custom.contains("enctype=\"text/plain\""))
        XCTAssertFalse(custom.contains("multipart/form-data"))
    }

    func testAjaxFormWithFileUsesUploadHandler() {
        let upload = Form(url: "/u'x", method: "POST", ajax: true).addFile(name: "f", label: "F").output
        let plain = Form(url: "/u", method: "POST", ajax: true).addInputText(name: "n", label: "N").output

        XCTAssertTrue(upload.contains("onsubmit=\"event.preventDefault(); uploadFormInBackground(&#39;/u\\&#39;x&#39;, this);\""))
        XCTAssertTrue(plain.contains("onsubmit=\"event.preventDefault(); submitFormInBackground(&#39;/u&#39;, this);\""))
    }

    func testNonAjaxFormWithFileHasNoHandler() {
        XCTAssertFalse(Form(url: "/u", method: "POST").addFile(name: "f", label: "F").output.contains("onsubmit"))
    }

    func testProgressBarIsRenderedOnlyUnderFirstFileField() {
        let html = Form(url: "/u", method: "POST", ajax: true)
            .addFile(name: "a", label: "A")
            .addFile(name: "b", label: "B")
            .output

        XCTAssertEqual(html.components(separatedBy: "data-upload-progress").count - 1, 1)
        XCTAssertTrue(html.contains("<div class=\"progress mt-2 d-none\" data-upload-progress role=\"progressbar\""))
    }

    func testUploadHelperIsBundled() throws {
        let path = try XCTUnwrap(BootstrapTemplate.absolutePath(for: "form.js"))
        let js = try String(contentsOfFile: path, encoding: .utf8)

        XCTAssertTrue(js.contains("function uploadFormInBackground("))
        XCTAssertTrue(js.contains("new FormData(element)"))
        XCTAssertTrue(js.contains("xhr.upload.addEventListener('progress'"))
    }
}
