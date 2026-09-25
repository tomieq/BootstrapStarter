# BootstrapStarter

`BootstrapStarter` is a server-side Swift library for producing Bootstrap-backed HTML pages, Bootstrap-styled forms, and JavaScript command responses. Its library product is named `BootstrapTemplate`.

It bundles Bootstrap 5.3.1, jQuery 3.6.1, jQuery UI 1.13.3, Noty, and small browser-side helpers. The package itself depends on [Template.swift](https://github.com/tomieq/Template.swift) 1.6.0 or later.

## Contents

- [Install](#install)
- [How the library fits together](#how-the-library-fits-together)
- [Render a page](#render-a-page)
- [Serve bundled browser assets](#serve-bundled-browser-assets)
- [Build forms](#build-forms)
- [Compose JavaScript responses](#compose-javascript-responses)
- [Public API reference](#public-api-reference)
- [Security and operating notes](#security-and-operating-notes)
- [Guidance for AI agents](#guidance-for-ai-agents)

## Install

The package requires Swift 5.9 or later. Add the dependency and link the `BootstrapTemplate` product:

```swift
// Package.swift
import PackageDescription

let package = Package(
    name: "MyWebApp",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/tomieq/BootstrapStarter", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "MyWebApp",
            dependencies: [
                .product(name: "BootstrapTemplate", package: "BootstrapStarter")
            ]
        )
    ]
)
```

Then import the module:

```swift
import BootstrapTemplate
```

The package does not require a specific HTTP framework. The examples use Swifter only to illustrate response handling; add and configure that framework separately if needed.

## How the library fits together

| Type | Purpose | Output |
| --- | --- | --- |
| `BootstrapTemplate` | Full HTML document with bundled CSS and scripts | `CustomStringConvertible` |
| `Form` | Bootstrap-styled HTML form builder | `CustomStringConvertible` |
| `JSCode` | One browser-side JavaScript command | `CustomStringConvertible` |
| `JSResponse` | Ordered, newline-separated JavaScript commands | `CustomStringConvertible` |

All rendered values are obtained through `description`, so instances can be supplied to APIs that accept `CustomStringConvertible`, or rendered explicitly with `String(describing: value)`.

## Render a page

`BootstrapTemplate` loads the package's `index.tpl.html` template and produces a complete HTML document. The generated page references the bundled assets at root-relative URLs, so configure your server to serve those files before returning a page.

```swift
import BootstrapTemplate

let page = BootstrapTemplate()
page.title = "Account"
page.body = """
<main class="container py-4">
  <h1>Welcome</h1>
  <div id="content"></div>
</main>
"""
page.addMeta(name: "description", value: "Account home page")
page.addFavicon(url: "/images/favicon.png", type: "image/png")
page.addCSS(url: "/app.css")
page.addCSS(code: ".welcome { color: rebeccapurple; }")
page.addJS(url: "/app.js")
page.addJS(code: "console.log('page ready');")

let html = page.description
```

### Head and body customization

| API | Effect |
| --- | --- |
| `title: String?` | Adds the document title when assigned a non-`nil` value. The getter intentionally returns `nil`; treat this as write-only. |
| `body: CustomStringConvertible?` | Inserts page body HTML when assigned a non-`nil` value. The getter intentionally returns `nil`; treat this as write-only. |
| `addMeta(name:value:)` | Adds `<meta name="…" content="…">`. Call repeatedly for multiple tags. |
| `addFavicon(url:type:)` | Adds a favicon `<link>`. Call with a URL and MIME type such as `image/svg+xml`. |
| `addCSS(url:)` / `addJS(url:)` | Adds a stylesheet or script URL to the generated document. |
| `addCSS(code:)` / `addJS(code:)` | Adds inline CSS or JavaScript. Each accepts any `CustomStringConvertible`. |

External style sheets are inserted after the bundled style sheets. External scripts and inline JavaScript run after the bundled scripts, near the end of `<body>`.

## Serve bundled browser assets

The generated page requests these root-relative URLs:

- `/bootstrap-5.3.1-dist/css/bootstrap.min.css`
- `/bootstrap-5.3.1-dist/js/bootstrap.bundle.min.js`
- `/jquery-3.6.1.min.js`
- `/jquery-ui-1.13.3/jquery-ui.min.css` and `/jquery-ui-1.13.3/jquery-ui.min.js`
- `/noty.css`, `/noty.min.js`, and `/notifications.js`
- `/webPageUtils.js` and `/webPageLoader.js`

Resolve a request path against the package bundle with `BootstrapTemplate.absolutePath(for:)`. The function returns `nil` when the resource is not bundled. Keep the request path relative to the bundled `shared` directory; a leading slash is accepted.

The following is framework-neutral pseudocode for a static-file fallback:

```swift
if let filePath = BootstrapTemplate.absolutePath(for: request.path) {
    return serveFile(at: filePath)
}
return notFound()
```

Do not expose arbitrary filesystem paths through this fallback. `absolutePath(for:)` is intended for the package's known static resources, not for application uploads or user-provided paths.

### Swifter outline

When using Swifter, convert the page or JavaScript response to the response type expected by your Swifter version and serve bundle paths in its static-file fallback. The exact route and response APIs are owned by Swifter, not this package.

```swift
server["/"] = { _, _ in
    let page = BootstrapTemplate()
    page.title = "Home"
    page.body = "<main class=\"container py-4\"><h1>Home</h1></main>"
    return .ok(.html(page))
}

server.notFoundHandler = { request, _ in
    guard let path = BootstrapTemplate.absolutePath(for: request.path) else {
        return .notFound()
    }
    return try HttpFileResponse.with(absolutePath: path)
}
```

## Build forms

`Form` accumulates fields in the order added. Every `add…` method returns the same form, allowing fluent construction. Use `form.output` or `form.description` only after the required fields have been added.

```swift
let form = Form(
    url: "/account",
    method: "POST",
    attributes: ["class": "needs-validation"]
)
    .addSeparator(txt: "Profile")
    .addInputText(
        name: "displayName",
        label: "Display name",
        value: "Ada",
        attributes: ["required": "required", "autocomplete": "name"]
    )
    .addPassword(
        name: "password",
        label: "Password",
        attributes: ["required": "required", "autocomplete": "new-password"]
    )
    .addSelect(
        name: "plan",
        label: "Plan",
        options: [
            FormSelectModel(label: "Free", value: "free"),
            FormSelectModel(label: "Pro", value: "pro")
        ],
        selected: "pro"
    )
    .addCheckbox(name: "terms", value: "accepted", label: "I accept the terms", selected: true)
    .addSubmit(name: "save", label: "Save", style: .primary, .large)

let formHTML = form.output
```

Set `page.body = form` to put it in a `BootstrapTemplate` page.

### Form initializer

```swift
Form(url: String, method: String, ajax: Bool = false, attributes: [String: String] = [:])
```

- `url` becomes the form `action`.
- `method` becomes the HTML form `method`.
- `attributes` are appended to the opening `<form>` tag.
- With `ajax: true`, an `onsubmit` handler prevents the browser's native submit and calls the bundled `submitFormInBackground` helper. That helper always sends a `POST` request and expects a JavaScript response (`dataType: "script"`), regardless of `method`.

### Field API

| Method | Key behavior |
| --- | --- |
| `addInputText(name:label:value:id:attributes:)` | Adds a Bootstrap text input. `value` defaults to `""`. |
| `addPassword(name:label:id:placeholder:attributes:)` | Adds a password input. `placeholder` defaults to `""`. |
| `addHidden(name:value:id:attributes:)` | Adds a hidden input; `value` accepts any `CustomStringConvertible`. |
| `addTextarea(name:label:rows:value:id:attributes:)` | Adds a textarea; `rows` defaults to `3`. |
| `addCheckbox(name:value:label:id:selected:)` | Adds a checkbox. Set `selected: true` to render it checked. This method has no custom-attributes parameter. |
| `addRadio(name:label:options:selected:attributes:)` | Adds a labelled radio group. `selected` is matched by its `description`. |
| `addSelect(name:label:options:selected:id:attributes:)` | Adds a select element. `selected` is matched by its `description`. |
| `addSubmit(name:label:style:)` | Adds a submit button. Omitting `style` uses `.primary`. |
| `addSeparator(txt:)` | Adds a labelled section wrapper. |
| `addRaw(html:)` | Appends HTML verbatim. |

When an `id` is omitted, the library generates a random 10-character alphanumeric ID. Supply explicit IDs whenever application JavaScript, tests, labels outside the form, or accessibility tooling needs stable identifiers.

### Form compatibility notes

- `addPassword` accepts a `placeholder` argument, but the current template variables do not render it. Use a custom attribute or `addRaw(html:)` if a visible password placeholder is required.
- `addRadio` accepts `attributes`, but they are applied to the radio group's wrapper rather than to each radio input.
- `addCheckbox` does not accept custom attributes.

`FormRadioModel` and `FormSelectModel` both use this initializer:

```swift
FormRadioModel(label: CustomStringConvertible, value: CustomStringConvertible)
FormSelectModel(label: CustomStringConvertible, value: CustomStringConvertible)
```

Available `ButtonStyle` cases are `.primary`, `.secondary`, `.success`, `.danger`, `.warning`, `.info`, `.light`, `.dark`, `.link`, `.large`, and `.small`. Multiple styles are allowed, for example `.addSubmit(name: "save", label: "Save", style: .success, .large)`.

## Compose JavaScript responses

Use `JSCode` to generate a supported browser command, and `JSResponse` to join commands with newlines. This is useful for endpoints that return JavaScript to a page that has loaded the bundled browser helpers.

```swift
let response = JSResponse(
    .showSuccess("Saved"),
    .loadHtml(path: "/account/summary", domID: "#content"),
    .loadJS(path: "/account.js")
)

let script = response.description
```

For conditional construction, use `add` or the result-builder initializer:

```swift
let response = JSResponse {
    JSCode.showInfo("Refreshing…")
    "refreshWidgets();"
}

if shouldLoadReports {
    response.add(.loadMultipleJS(paths: ["/charts.js", "/reports.js"]))
}
```

Any `CustomStringConvertible`, including `String`, can be passed to `JSResponse` or `add`. This enables application-specific command types:

```swift
enum AppCommand: CustomStringConvertible {
    case refresh

    var description: String {
        switch self {
        case .refresh: "refreshWidgets();"
        }
    }
}

let response = JSResponse(.showSuccess("Saved"), AppCommand.refresh)
```

### `JSCode` cases

| Case | Generated browser action |
| --- | --- |
| `.loadHtml(path:domID:)` | Replaces the supplied jQuery selector's contents with HTML loaded from `path`, then runs any scripts in that HTML response. Pass a selector such as `"#content"`, not an unprefixed DOM ID. |
| `.loadJS(path:)` | Loads and runs one script. |
| `.loadMultipleJS(paths:)` | Loads and runs several scripts. |
| `.loadHtmlAndJS(htmlPath:htmlDomID:jsPath:)` | Loads HTML into a selector, then loads one script. |
| `.showSuccess(_)`, `.showError(_)`, `.showWarning(_)`, `.showInfo(_)` | Shows a Noty notification using the bundled notification helpers. |
| `.custom(code:)` | Emits the supplied JavaScript unchanged. |
| `.submitForm(path:domID:)` | Intended to call the bundled form helper; see the compatibility note below. |

`JSResponse` has both variadic and result-builder constructors, plus matching `add` overloads. The result builder accepts a sequence of `CustomStringConvertible` expressions; it does not support control-flow expressions such as `if` inside the builder.

### JavaScript compatibility notes

- The bundled dynamic loaders add a cache-busting query parameter and depend on jQuery.
- The page template loads the required jQuery, Noty, and helper scripts automatically, provided their static URLs are served.
- `JSCode` interpolates paths and notification text directly into JavaScript string literals. Do not pass untrusted values without JavaScript-string escaping.
- In the current implementation, `.submitForm(path:domID:)` emits a malformed JavaScript string. Use `Form(ajax: true)` or `.custom(code:)` with correctly escaped JavaScript until that API is corrected.

## Public API reference

The stable public surface in this package is:

```swift
public class BootstrapTemplate: CustomStringConvertible {
    public let template: Template
    public init()
    public var title: String? { get set }
    public var body: CustomStringConvertible? { get set }
    public func addJS(code: CustomStringConvertible)
    public func addJS(url: String)
    public func addCSS(code: CustomStringConvertible)
    public func addCSS(url: String)
    public func addMeta(name: String, value: String)
    public func addFavicon(url: String, type: String)
    public static func absolutePath(for filepath: String) -> String?
}

public class Form: CustomStringConvertible {
    public init(url: String, method: String, ajax: Bool = false,
                attributes: [String: String] = [:])
    @discardableResult public func addPassword(name: String, label: String,
        id: String? = nil, placeholder: String = "",
        attributes: [String: String] = [:]) -> Form
    @discardableResult public func addInputText(name: String, label: String,
        value: String = "", id: String? = nil,
        attributes: [String: String] = [:]) -> Form
    @discardableResult public func addSeparator(txt: CustomStringConvertible) -> Form
    @discardableResult public func addRaw(html: CustomStringConvertible) -> Form
    @discardableResult public func addHidden(name: String,
        value: CustomStringConvertible, id: String? = nil,
        attributes: [String: String] = [:]) -> Form
    @discardableResult public func addCheckbox(name: String,
        value: CustomStringConvertible, label: String, id: String? = nil) -> Form
    @discardableResult public func addRadio(name: String, label: String,
        options: [FormRadioModel], selected: CustomStringConvertible? = nil,
        attributes: [String: String] = [:]) -> Form
    @discardableResult public func addSelect(name: String, label: String,
        options: [FormSelectModel], selected: CustomStringConvertible? = nil,
        id: String? = nil, attributes: [String: String] = [:]) -> Form
    @discardableResult public func addTextarea(name: String, label: String,
        rows: Int = 3, value: CustomStringConvertible? = nil, id: String? = nil,
        attributes: [String: String] = [:]) -> Form
    @discardableResult public func addSubmit(name: String, label: String,
        style: ButtonStyle...) -> Form
    public var output: String { get }
}

public enum JSCode: CustomStringConvertible {
    case submitForm(path: String, domID: String)
    case loadHtml(path: String, domID: String)
    case loadJS(path: String)
    case loadMultipleJS(paths: [String])
    case loadHtmlAndJS(htmlPath: String, htmlDomID: String, jsPath: String)
    case showSuccess(String), showError(String), showWarning(String), showInfo(String)
    case custom(code: String)
}

public class JSResponse: CustomStringConvertible {
    public init(_ code: CustomStringConvertible...)
    public init(_ code: JSCode...)
    public init(@SimpleStringBuilder makeCode: () -> [CustomStringConvertible])
    @discardableResult public func add(_ code: CustomStringConvertible...) -> JSResponse
    @discardableResult public func add(_ code: JSCode...) -> JSResponse
    @discardableResult public func add(
        @SimpleStringBuilder makeCode: () -> [CustomStringConvertible]
    ) -> JSResponse
}

public struct FormRadioModel { public init(label: CustomStringConvertible, value: CustomStringConvertible) }
public struct FormSelectModel { public init(label: CustomStringConvertible, value: CustomStringConvertible) }
public enum ButtonStyle: String, CustomStringConvertible {
    case primary, secondary, success, danger, warning, info, light, dark, link
    case large, small
    public var cssClass: String { get }
}
```

Properties not shown as public in this list are implementation details. In particular, option models expose construction but not public `label` or `value` properties.

## Security and operating notes

- **Escape at the boundary.** Page bodies, form labels, values, attributes, raw form HTML, metadata, CSS, JavaScript, and `JSCode` arguments are interpolated into templates or scripts. This library does not promise HTML, attribute, CSS, or JavaScript escaping. Encode untrusted data for its exact output context before passing it in.
- **Validate server requests normally.** Form generation does not add CSRF protection, authentication, authorization, validation, or rate limiting.
- **Set a content-security policy deliberately.** Inline scripts and styles are generated by `addJS(code:)` and `addCSS(code:)`; a restrictive CSP needs nonces, hashes, or a policy that permits those blocks.
- **Serve resources in deployment.** The package uses `Bundle.module` to locate copied resources. In a Linux container, ensure the SwiftPM-generated resource bundle (typically a `.resources` directory beside the executable) is copied into the runtime image along with the executable.
- **Use an appropriate response MIME type.** HTML pages should be returned as `text/html`; JavaScript command responses should be returned as JavaScript, as required by the HTTP framework and client.

## Guidance for AI agents

When modifying an application that uses this package:

1. Import `BootstrapTemplate`, not the repository name.
2. Treat `BootstrapTemplate`, `Form`, `JSCode`, `JSResponse`, `FormRadioModel`, `FormSelectModel`, and `ButtonStyle` as the public API. Do not rely on package-internal template structures or helper implementation details unless the application explicitly owns that integration.
3. Preserve static serving for `BootstrapTemplate.absolutePath(for:)`; without it, every generated page is missing its bundled CSS and JavaScript.
4. Use a CSS selector such as `"#content"` for `JSCode.loadHtml` and `JSCode.loadHtmlAndJS` target arguments.
5. Prefer explicit form IDs when any client code needs to select fields. Generated IDs are intentionally non-deterministic.
6. For AJAX forms, return executable JavaScript commands, usually `JSResponse`; remember that the bundled helper posts with `POST`.
7. Encode all dynamic or user-controlled strings for their HTML, attribute, CSS, or JavaScript context before sending them to this library. Never use `addRaw(html:)` with untrusted content.
8. Do not generate calls to `.submitForm(path:domID:)` until its malformed output has been fixed; use `Form(ajax: true)` or escaped `.custom(code:)` instead.
9. When containerizing, retain the SwiftPM resource bundle and verify the static asset fallback against a deployed build.
