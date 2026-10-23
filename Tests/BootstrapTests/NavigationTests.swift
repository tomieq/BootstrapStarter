import XCTest
@testable import BootstrapTemplate

final class NavigationTests: XCTestCase {
    private let items: [MenuItem] = [
        .link("Home", url: "/", icon: .home),
        .link("Users", url: "/users", badge: Badge(3, color: .danger, pill: true), matchPrefix: true),
        .dropdown("Reports", items: [
            .header("Sales"),
            .link("Daily", url: "/reports/daily"),
            .divider,
            .action("Export", onClick: .showInfo("it's")),
            .link("Off", url: "/off", disabled: true)
        ]),
        .link("Docs", url: "/docs", disabled: true),
        .link("Profile", url: "/profile").atEnd(),
        .dropdown("Account", items: [.link("Logout", url: "/logout")]).atEnd()
    ]

    // MARK: MenuItem

    func testActiveMatching() {
        XCTAssertTrue(MenuItem.link("A", url: "/users").isActive("/users"))
        XCTAssertTrue(MenuItem.link("A", url: "/users/").isActive("/users?page=2"))
        XCTAssertFalse(MenuItem.link("A", url: "/users").isActive("/users/5"))
        XCTAssertTrue(MenuItem.link("A", url: "/users", matchPrefix: true).isActive("/users/5"))
        XCTAssertFalse(MenuItem.link("A", url: "/users", matchPrefix: true).isActive("/usersx"))
        XCTAssertFalse(MenuItem.link("A", url: "/", matchPrefix: true).isActive("/users"))
        XCTAssertTrue(MenuItem.link("A", url: "/x", active: true).isActive(nil))
        XCTAssertTrue(MenuItem.dropdown("D", items: [.link("A", url: "/a")]).isActive("/a#top"))
        XCTAssertFalse(MenuItem.divider.isActive("/"))
    }

    // MARK: Navbar

    func testNavbarStructure() {
        let html = Navbar(brand: "Acme", brandIcon: .home, items: items, currentPath: "/users/7").output

        XCTAssertTrue(html.hasPrefix("<nav class=\"navbar navbar-expand-lg bg-body-tertiary\" id=\"navbar\">"))
        XCTAssertTrue(html.contains("<div class=\"container-fluid\">"))
        XCTAssertTrue(html.contains("<a class=\"navbar-brand\" href=\"/\">" + Icon.home.output + " Acme</a>"))
        XCTAssertTrue(html.contains("data-bs-target=\"#navbar-collapse\" aria-controls=\"navbar-collapse\" aria-expanded=\"false\" aria-label=\"Toggle navigation\""))
        XCTAssertTrue(html.contains("<div class=\"collapse navbar-collapse\" id=\"navbar-collapse\">"))
        XCTAssertTrue(html.contains("<ul class=\"navbar-nav me-auto mb-2 mb-lg-0\">"))
        XCTAssertTrue(html.hasSuffix("</ul>\n</div>\n</div>\n</nav>"))
    }

    func testNavbarLinksActiveDisabledAndBadge() {
        let html = Navbar(items: items, currentPath: "/users/7").output

        XCTAssertTrue(html.contains("<li class=\"nav-item\"><a class=\"nav-link\" href=\"/\">" + Icon.home.output + " Home</a></li>"))
        XCTAssertTrue(html.contains("<a class=\"nav-link active\" href=\"/users\" aria-current=\"page\">Users <span class=\"badge text-bg-danger rounded-pill\">3</span></a>"))
        XCTAssertTrue(html.contains("<a class=\"nav-link disabled\" href=\"/docs\" tabindex=\"-1\" aria-disabled=\"true\">Docs</a>"))
    }

    func testNavbarDropdown() {
        let html = Navbar(items: items, currentPath: "/reports/daily").output

        XCTAssertTrue(html.contains("<li class=\"nav-item dropdown\"><button type=\"button\" class=\"nav-link active dropdown-toggle\" data-bs-toggle=\"dropdown\" aria-expanded=\"false\">Reports</button>"))
        XCTAssertTrue(html.contains("<ul class=\"dropdown-menu\">"))
        XCTAssertTrue(html.contains("<li><h6 class=\"dropdown-header\">Sales</h6></li>"))
        XCTAssertTrue(html.contains("<li><a class=\"dropdown-item active\" href=\"/reports/daily\" aria-current=\"page\">Daily</a></li>"))
        XCTAssertTrue(html.contains("<li><hr class=\"dropdown-divider\"></li>"))
        XCTAssertTrue(html.contains("<li><button type=\"button\" class=\"dropdown-item\" onclick=\"showInfo(&#39;it\\&#39;s&#39;);\">Export</button></li>"))
        XCTAssertTrue(html.contains("<li><a class=\"dropdown-item disabled\" href=\"/off\" tabindex=\"-1\" aria-disabled=\"true\">Off</a></li>"))
    }

    func testNavbarEndItemsAreRightAligned() {
        let html = Navbar(items: items, expand: .md).output
        let parts = html.components(separatedBy: "<ul class=\"navbar-nav\">")

        XCTAssertEqual(parts.count, 2)
        XCTAssertTrue(parts[1].contains("href=\"/profile\""))
        XCTAssertTrue(parts[1].contains("<ul class=\"dropdown-menu dropdown-menu-md-end\">"))
        XCTAssertFalse(parts[0].contains("href=\"/profile\""))
        XCTAssertTrue(parts[0].contains("navbar-expand-md"))
    }

    func testNavbarStylesAndPosition() {
        let dark = Navbar(items: [], style: .dark, position: .fixedTop, fluid: false).output
        XCTAssertTrue(dark.hasPrefix("<nav class=\"navbar navbar-expand-lg bg-dark fixed-top\" data-bs-theme=\"dark\" id=\"navbar\">"))
        XCTAssertTrue(dark.contains("<div class=\"container\">"))
        XCTAssertTrue(Navbar(items: [], style: .primary, position: .stickyTop).output.contains("bg-primary sticky-top\" data-bs-theme=\"dark\""))
    }

    func testNavbarActionHeaderRawAndDividerAtTopLevel() {
        let html = Navbar(items: [
            .action("Refresh", onClick: .reload, icon: .refresh),
            .header("v1.0"),
            .divider,
            .raw("<form class=\"d-flex\"></form>")
        ]).output

        XCTAssertTrue(html.contains("<li class=\"nav-item\"><button type=\"button\" class=\"nav-link\" onclick=\"window.location.reload();\">" + Icon.refresh.output + " Refresh</button></li>"))
        XCTAssertTrue(html.contains("<li class=\"nav-item\"><span class=\"navbar-text\">v1.0</span></li>"))
        XCTAssertTrue(html.contains("<li class=\"nav-item\"><form class=\"d-flex\"></form></li>"))
        XCTAssertFalse(html.contains("<hr"))
    }

    func testNavbarEscaping() {
        let html = Navbar(id: "a\"b", brand: "<Acme>", brandURL: "/?a=1&b=2", items: [.link("<x>", url: "/?q=\"1\"")]).output

        XCTAssertTrue(html.contains("id=\"a&quot;b\""))
        XCTAssertTrue(html.contains("href=\"/?a=1&amp;b=2\">&lt;Acme&gt;</a>"))
        XCTAssertTrue(html.contains("href=\"/?q=&quot;1&quot;\">&lt;x&gt;</a>"))
    }

    func testNavbarRendersWithoutBrandOrItems() {
        let html = Navbar(items: []).output

        XCTAssertFalse(html.contains("navbar-brand"))
        XCTAssertTrue(html.contains("<ul class=\"navbar-nav me-auto mb-2 mb-lg-0\">"))
    }

    // MARK: Sidebar

    func testSidebarStructure() {
        let html = Sidebar(brand: "Acme", brandIcon: .home, items: items, currentPath: "/users").output

        XCTAssertTrue(html.hasPrefix("<nav class=\"d-flex flex-column flex-shrink-0 p-3 bg-body-tertiary\" id=\"sidebar\" aria-label=\"Sidebar\" style=\"width: 280px;\">"))
        XCTAssertTrue(html.contains("<span class=\"fs-4\">" + Icon.home.output + " Acme</span>"))
        XCTAssertTrue(html.contains("<ul class=\"nav nav-pills flex-column mb-auto\">"))
        XCTAssertTrue(html.hasSuffix("</ul>\n</nav>"))
    }

    func testSidebarLinksActiveBadgeAndDisabled() {
        let html = Sidebar(items: items, currentPath: "/users").output

        XCTAssertTrue(html.contains("<a class=\"nav-link link-body-emphasis\" href=\"/\">" + Icon.home.output + " Home</a>"))
        XCTAssertTrue(html.contains("<a class=\"nav-link d-flex align-items-center active\" href=\"/users\" aria-current=\"page\">Users<span class=\"ms-auto ps-3\"><span class=\"badge text-bg-danger rounded-pill\">3</span></span></a>"))
        XCTAssertTrue(html.contains("class=\"nav-link link-body-emphasis disabled\" href=\"/docs\" tabindex=\"-1\" aria-disabled=\"true\""))
    }

    func testSidebarGroupsAreCollapsibleAndOpenWhenActive() {
        let closed = Sidebar(items: items, currentPath: "/").output
        let open = Sidebar(items: items, currentPath: "/reports/daily").output

        XCTAssertTrue(closed.contains("data-bs-toggle=\"collapse\" data-bs-target=\"#sidebar-group-1\" aria-expanded=\"false\""))
        XCTAssertTrue(closed.contains("<div class=\"collapse\" id=\"sidebar-group-1\">"))
        XCTAssertTrue(open.contains("aria-expanded=\"true\""))
        XCTAssertTrue(open.contains("<div class=\"collapse show\" id=\"sidebar-group-1\">"))
        XCTAssertTrue(open.contains("<ul class=\"nav nav-pills flex-column ps-3\">"))
        XCTAssertTrue(open.contains("class=\"nav-link active\" href=\"/reports/daily\" aria-current=\"page\""))
    }

    func testSidebarEndItemsArePinnedToBottom() {
        let html = Sidebar(items: items).output
        let parts = html.components(separatedBy: "<hr>\n<ul class=\"nav nav-pills flex-column\">")

        XCTAssertEqual(parts.count, 2)
        XCTAssertTrue(parts[1].contains("href=\"/profile\""))
        XCTAssertTrue(parts[1].contains("id=\"sidebar-group-2\""))
        XCTAssertFalse(parts[0].contains("href=\"/profile\""))
    }

    func testSidebarNestedGroupsGetUniqueIds() {
        let html = Sidebar(items: [
            .dropdown("A", items: [.dropdown("B", items: [.link("C", url: "/c")])]),
            .dropdown("D", items: [.link("E", url: "/e")])
        ], currentPath: "/c").output

        XCTAssertTrue(html.contains("id=\"sidebar-group-1\""))
        XCTAssertTrue(html.contains("id=\"sidebar-group-2\""))
        XCTAssertTrue(html.contains("id=\"sidebar-group-3\""))
        XCTAssertTrue(html.contains("<div class=\"collapse show\" id=\"sidebar-group-1\">"))
        XCTAssertTrue(html.contains("<div class=\"collapse show\" id=\"sidebar-group-2\">"))
        XCTAssertTrue(html.contains("<div class=\"collapse\" id=\"sidebar-group-3\">"))
    }

    func testSidebarHeaderDividerActionAndRaw() {
        let html = Sidebar(items: [
            .header("Admin"),
            .divider,
            .action("Reload", onClick: .reload),
            .raw("<small>x</small>")
        ]).output

        XCTAssertTrue(html.contains("<li class=\"mt-3 mb-1 px-2 text-uppercase small fw-semibold text-body-secondary\">Admin</li>"))
        XCTAssertTrue(html.contains("<li><hr class=\"my-2\"></li>"))
        XCTAssertTrue(html.contains("class=\"nav-link link-body-emphasis w-100 text-start\" onclick=\"window.location.reload();\">Reload</button>"))
        XCTAssertTrue(html.contains("<li class=\"nav-item\"><small>x</small></li>"))
    }

    func testSidebarDarkStyleAndWidth() {
        let html = Sidebar(brand: "A", items: [.link("L", url: "/l")], style: .dark, width: 220).output

        XCTAssertTrue(html.contains("bg-body-tertiary") == false)
        XCTAssertTrue(html.contains("text-bg-dark"))
        XCTAssertTrue(html.contains("style=\"width: 220px;\""))
        XCTAssertTrue(html.contains("class=\"nav-link text-white\" href=\"/l\""))
        XCTAssertTrue(html.contains("text-white text-decoration-none"))
    }

    func testDropdownInsideDropdownIsFlattened() {
        let html = Navbar(items: [
            .dropdown("Outer", items: [.dropdown("Inner", items: [.link("Leaf", url: "/leaf")])])
        ]).output

        XCTAssertTrue(html.contains("<li><h6 class=\"dropdown-header\">Inner</h6></li>"))
        XCTAssertTrue(html.contains("<a class=\"dropdown-item\" href=\"/leaf\">Leaf</a>"))
        XCTAssertEqual(html.components(separatedBy: "dropdown-toggle").count - 1, 1)
    }
}
