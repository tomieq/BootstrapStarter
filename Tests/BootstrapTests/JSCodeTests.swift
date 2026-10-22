import XCTest
@testable import BootstrapTemplate

final class JSCodeTests: XCTestCase {
    func testArgumentsAreEscaped() {
        XCTAssertEqual(JSCode.showSuccess("it's <b>ok</b>\n").description, "showSuccess('it\\'s <b>ok<\\/b>\\n');")
        XCTAssertEqual(JSCode.loadHtml(path: "/a'b", domID: "#x").description, "loadHtmlThenRunScripts('/a\\'b', '#x', []);")
        XCTAssertEqual(JSCode.loadMultipleJS(paths: ["/a.js", "/b'.js"]).description, "runScripts(['/a.js', '/b\\'.js']);")
    }

    func testNotificationWithIcon() {
        XCTAssertEqual(JSCode.showSuccess("Saved", icon: .check).description,
                       "showSuccess('<i class=\"bi bi-check-lg\" aria-hidden=\"true\"><\\/i> Saved');")
        XCTAssertTrue(JSCode.showError("Failed", icon: .error).description.hasPrefix("showError('<i class=\"bi bi-x-circle\""))
        XCTAssertTrue(JSCode.showWarning("Careful", icon: Icon("bug")).description.contains("bi-bug"))
        XCTAssertTrue(JSCode.showInfo("FYI", icon: .info).description.hasSuffix("<\\/i> FYI');"))
        XCTAssertEqual(JSCode.showInfo("FYI").description, "showInfo('FYI');")
    }

    func testSubmitFormIsWellFormed() {
        XCTAssertEqual(JSCode.submitForm(path: "/save", domID: "#form").description, "submitFormInBackground('/save', '#form');")
    }

    func testPageCommands() {
        XCTAssertEqual(JSCode.redirect(path: "/home").description, "window.location.href = '/home';")
        XCTAssertEqual(JSCode.reload.description, "window.location.reload();")
        XCTAssertEqual(JSCode.scrollTo(domID: "#end").description, "scrollToElement('#end');")
        XCTAssertEqual(JSCode.copyToClipboard("a'b").description, "copyToClipboard('a\\'b');")
        XCTAssertEqual(JSCode.setTheme(.dark).description, "setTheme('dark');")
        XCTAssertEqual(JSCode.toggleTheme.description, "toggleTheme();")
        XCTAssertEqual(JSCode.refreshHtml(path: "/t", domID: "#t").description, "refreshHtml('/t', '#t');")
    }

    func testDOMCommands() {
        XCTAssertEqual(JSCode.setHtml(domID: "#a", html: "<i>x</i>").description, "$('#a').html('<i>x<\\/i>');")
        XCTAssertEqual(JSCode.appendHtml(domID: "#a", html: "x").description, "$('#a').append('x');")
        XCTAssertEqual(JSCode.remove(domID: "#a").description, "$('#a').remove();")
        XCTAssertEqual(JSCode.addClass(domID: "#a", name: "d-none").description, "$('#a').addClass('d-none');")
        XCTAssertEqual(JSCode.removeClass(domID: "#a", name: "d-none").description, "$('#a').removeClass('d-none');")
        XCTAssertEqual(JSCode.setDisabled(domID: "#a", disabled: true).description, "$('#a').prop('disabled', true);")
    }

    func testPolling() {
        XCTAssertEqual(JSCode.poll(path: "/s", domID: "#s", interval: 5).description, "startPolling('/s', '#s', 5000);")
        XCTAssertEqual(JSCode.poll(path: "/s", domID: "#s", interval: 0).description, "startPolling('/s', '#s', 250);")
        XCTAssertEqual(JSCode.stopPolling(domID: "#s").description, "stopPolling('#s');")
    }

    func testResponseChaining() {
        let response = JSResponse().add(.showSuccess("Saved")).add(.hideModal).add(.refreshHtml(path: "/t", domID: "#t"))

        XCTAssertEqual(response.description, "showSuccess('Saved');\nhideModals();\nrefreshHtml('/t', '#t');")
    }

    func testThemeDefaultsAndScriptsAreBundled() {
        let page = BootstrapTemplate()
        XCTAssertTrue(page.description.contains("data-default-theme=\"\""))
        XCTAssertTrue(page.description.contains("<script src=\"/theme.js\"></script>"))
        XCTAssertTrue(page.description.contains("<script src=\"/commands.js\"></script>"))

        let dark = BootstrapTemplate()
        dark.theme = .dark
        XCTAssertTrue(dark.description.contains("data-default-theme=\"dark\""))

        XCTAssertNotNil(BootstrapTemplate.absolutePath(for: "theme.js"))
        XCTAssertNotNil(BootstrapTemplate.absolutePath(for: "commands.js"))
    }
}
