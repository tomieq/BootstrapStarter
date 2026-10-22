---
name: swift-web-architecture
description: "Use when planning or extending the architecture of a server-side Swift web application built with Swifter, Template.swift and BootstrapStarter (BootstrapTemplate), with Logger and Env. Covers project layout, splitting routes into per-module Flow classes, where HTML templates live (Resources/<module>/), shared stores, startup wiring, configuration, and a checklist for adding a new module or page. Use for new web apps, adding modules/pages, or refactoring a growing routes file."
---

# Swift web app architecture (Swifter + Template + BootstrapStarter)

Conventions for server-side rendered apps using Swifter, Template.swift, BootstrapStarter, Logger and Env. For library APIs load the `swifter`, `template-swift-usage`, `bootstrap-template`, `swift-logger`, `env` and `swift-extensions` skills.

## Layout

```
Package.swift
.env.example                  # committed; .env is git-ignored
Resources/                    # templates and public files; resolved from the working directory
  public/                     # ONLY this tree is web-accessible, served at the URL root
    css/style.css             # -> /css/style.css
    js/                       # own and 3rd party scripts -> /js/...
    images/                   # -> /images/...
  <module>/page.tpl.html      # one folder per module (login, portal, navi, ...); never served
  <module>/<fragment>.tpl.html
Sources/<App>/
  main.swift                  # config, logger level, stores, flow list, server start only
  Config.swift                # Env-backed settings
  Stores/                     # shared state (UserStore, SessionStore, ...)
  Flows/
    Flow.swift                # protocol Flow { func register(on server: HttpServer) }
    <Module>Flow.swift        # one class per module
  Extensions/                 # small helpers: WebPath+URL, BootstrapTemplate+Portal (shared page shell)
```

Run from the directory containing `Resources/` (`swift run` from the project root).

## Rules

1. **One Flow per module.** Each `<Module>Flow` owns all routes, handlers and page builders of that module. Never create a single catch-all routes class.
2. **No HTML in Swift sources.** Markup goes into `Resources/<module>/*.tpl.html`, loaded with `Template.cached(relativePath:)` (use `load` while developing). The folder name is the module that owns the template; shared pieces (menu, user bar) get their own module folder such as `navi/`. Swift only assigns values. Exception: HTML produced by `Form` / `JSCode` from BootstrapStarter.
3. **Compose pages from templates.** Fragment templates are assigned into a page template placeholder (`body["userbar"] = userbar`), then set as `BootstrapTemplate.body`. Page shell, CSS and JS come from `BootstrapTemplate`.
4. **Escape dynamic values** with `htmlEscaped` (public, from `BootstrapTemplate`; do not redefine it) before assigning them into templates; `JSCode` string arguments are JS-escaped automatically (use the public `jsEscaped` only for `.custom(code:)`). `Table` and `Button` escape their own text.
5. **Dependencies are injected** through Flow initializers (stores, services). Flows never create their own shared state and never reach for globals.
6. **Shared state lives in stores** (`final class`, lock-protected or an actor) created once in `main.swift`. Start with in-memory stores behind a clear type; swap implementation later without touching Flows.
7. **Logging and config:** one `Logger(Type.self)` per Flow/store; read settings once through `Env` (and `Param` for CLI overrides) in `Config`; never log secrets.
8. **Global singletons of the server** (for example `notFoundHandler`, `globalErrorHandler`, middleware) are registered by exactly one dedicated Flow.
9. **Auth:** protect routes in the owning Flow by checking the session; redirect to `LoginFlow.Path.login.url` for pages, return JS errors for AJAX endpoints.
10. **No loose path strings.** Each Flow declares a nested `enum Path: String, WebPath` (`case home = ""` for the root). Register with `server.get[Path.x]`; build links, redirects, form actions and template hrefs from `Path.x.url` (`extension WebPath { var url: String { "/" + path.trimming("/") } }` in `Extensions/`). Other Flows may reference `OtherFlow.Path`.
11. **Public files only under `Resources/public/**`.** `AssetsFlow` is the sole owner of `notFoundHandler` and serves everything else. Copy [assets/AssetsFlow.swift](assets/AssetsFlow.swift) into `Flows/` unchanged; do not reimplement it (it relies on `Resource.existingFilePath`, Template.swift > 1.6.2, to reject traversal, hidden files, directories and symlinks leaving the folder). Never serve other `Resources/` folders (templates), never build paths from request paths by hand, and never pass untrusted input to `Resource.absolutePath(for:)`/`content(for:)`. Link to assets with root-relative URLs (`/css/style.css`).
12. **One shared page shell.** Build every page with a single helper (`BootstrapTemplate.portalPage(title:body:)`) that adds the shared stylesheet/scripts, so Flows do not repeat `addCSS`/`addJS` for common assets.

## Flow skeleton

```swift
final class OrdersFlow: Flow {
    enum Path: String, WebPath {
        case orders
    }

    private let logger = Logger(OrdersFlow.self)
    private let sessions: SessionStore

    init(sessions: SessionStore) { self.sessions = sessions }

    func register(on server: HttpServer) {
        server.get[Path.orders] = { [self] request, _ in
            guard sessions.login(for: request).notNil else { return .found(LoginFlow.Path.login.url) }
            return .ok(.html(ordersPage()))
        }
    }

    private func ordersPage() -> BootstrapTemplate {
        let body = Template.cached(relativePath: "orders/page.tpl.html")
        let page = BootstrapTemplate()
        page.title = "Orders"
        page.body = body
        return page
    }
}
```

`main.swift` wiring:

```swift
let flows: [Flow] = [
    LoginFlow(users: users, sessions: sessions),
    PortalFlow(sessions: sessions),
    OrdersFlow(sessions: sessions),
    AssetsFlow()
]
flows.forEach { $0.register(on: server) }
```

## Package.swift essentials

- `swift-tools-version: 6.0`, `platforms: [.macOS(.v13)]`, `swiftLanguageModes: [.v5]` (Logger uses unsafe globals).
- Products: `Swifter`, `SwiftExtensions`, `BootstrapTemplate` (package `BootstrapStarter`), `Template` (package `Template.swift`), `Logger`, `Env`.
- `swift build` after each change; smoke test with curl (use GET, not `curl -I`: HEAD does not match `get` routes).

## Adding a new module (checklist)

1. Create `Resources/<module>/page.tpl.html` (+ fragments). Placeholders `{name}`; avoid literal braces.
2. Create `Flows/<Module>Flow.swift` conforming to `Flow`; inject only what it needs.
3. Add the Flow to the list in `main.swift` (before `AssetsFlow`; in a new project copy `assets/AssetsFlow.swift` first, see rule 11).
4. AJAX forms: `Form(..., ajax: true)`, POST route returning `.ok(.js(JSResponse(...)))`, explicit field ids, `#` selectors.
5. If other modules need the same data, add or extend a store in `Stores/` instead of sharing state between Flows.
6. Build, then curl the new routes (signed out and signed in).

## Anti-patterns

- One growing `Routes`/`Router` class for the whole app.
- HTML in Swift string literals or `"""` blocks.
- Flows depending on other Flows (extract a store/service instead).
- Setting `notFoundHandler` or middleware from several Flows.
- Serving a whole `Resources/` folder or building file paths from request paths by hand (use `Resource.existingFilePath`, rule 11).
- Reading `ProcessInfo`/`CommandLine` directly instead of `Env`/`Param`; `print` instead of `Logger`.
- Starting the server without `RunLoop.main.run()`.
