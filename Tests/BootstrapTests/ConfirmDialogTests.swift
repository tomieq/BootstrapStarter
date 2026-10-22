import XCTest
@testable import BootstrapTemplate

final class ConfirmDialogTests: XCTestCase {
    func testOutput() {
        let dialog = ConfirmDialog("Delete user?",
                                   title: "Delete",
                                   confirmLabel: "Yes",
                                   cancelLabel: "No",
                                   confirmStyle: .danger,
                                   onConfirm: JSCode.loadHtml(path: "/users/1/delete", domID: "#list"))

        XCTAssertEqual(dialog.output,
                       "confirmDialog({title: 'Delete', message: 'Delete user?', confirmLabel: 'Yes', cancelLabel: 'No', confirmClass: 'btn-danger', onConfirm: function () { loadHtmlThenRunScripts('/users/1/delete', '#list', []); }});")
    }

    func testDefaults() {
        let output = ConfirmDialog("Sure?", onConfirm: JSCode.hideModal).output

        XCTAssertTrue(output.contains("title: 'Confirm'"))
        XCTAssertTrue(output.contains("confirmLabel: 'OK', cancelLabel: 'Cancel', confirmClass: 'btn-primary'"))
    }

    func testTextIsEscapedForJavaScript() {
        let output = ConfirmDialog("it's\n</script>", onConfirm: "x();").output

        XCTAssertTrue(output.contains("message: 'it\\'s\\n<\\/script>'"))
    }

    func testOnConfirmAcceptsResponseWithSeveralCommands() {
        let response = JSResponse(.showSuccess("Done"), .hideModal)
        let output = ConfirmDialog("Sure?", onConfirm: response).output

        XCTAssertTrue(output.contains("onConfirm: function () { showSuccess('Done');\nhideModals(); }"))
    }

    func testAsButtonHandler() {
        let button = Button("Delete", onClick: .confirm(ConfirmDialog("Sure?", onConfirm: "go();")), style: .danger)

        XCTAssertTrue(button.output.contains("onclick=\"confirmDialog({title: &#39;Confirm&#39;"))
    }

    func testHelperIsBundled() throws {
        let path = try XCTUnwrap(BootstrapTemplate.absolutePath(for: "modal.js"))
        XCTAssertTrue(try String(contentsOfFile: path, encoding: .utf8).contains("function confirmDialog("))
    }
}
