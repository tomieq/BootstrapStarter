# BootstrapStarter

`BootstrapStarter` is a server-side Swift library for producing Bootstrap-backed HTML pages, Bootstrap-styled forms, and JavaScript command responses. Its library product is named `BootstrapTemplate`.

It bundles Bootstrap 5.3.1, Bootstrap Icons 1.13.1, jQuery 3.6.1, jQuery UI 1.13.3, Noty, and small browser-side helpers. The package itself depends on [Template.swift](https://github.com/tomieq/Template.swift) 1.6.0 or later.

## Contents

- [Install](#install)
- [How the library fits together](#how-the-library-fits-together)
- [Render a page](#render-a-page)
- [Serve bundled browser assets](#serve-bundled-browser-assets)
- [Build forms](#build-forms)
- [Buttons](#buttons)
- [Build tables](#build-tables)
- [Paginate](#paginate)
- [Modals](#modals)
- [Tabs](#tabs)
- [Icons](#icons)
- [Escape HTML and JavaScript](#escape-html-and-javascript)
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
| `Button` | Bootstrap button or link-button | `CustomStringConvertible` |
| `Tabs` | Bootstrap tabs or pills, with lazy-loaded panes | `CustomStringConvertible` |
| `Icon` | Bootstrap Icons glyph | `CustomStringConvertible` |
| `Table` | Bootstrap table builder | `CustomStringConvertible` |
| `Pagination` | Bootstrap page navigation | `CustomStringConvertible` |
| `Modal` | Bootstrap modal dialog | `CustomStringConvertible` |
| `ConfirmDialog` | Client-side confirmation dialog | `CustomStringConvertible` (JavaScript) |
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
| `theme: BootstrapTheme?` | Default color theme (`.light`, `.dark`, `.auto`); see [Themes](#themes). Write-only like `title`. |
| `addFavicon(url:type:)` | Adds a favicon `<link>`. Call with a URL and MIME type such as `image/svg+xml`. |
| `addCSS(url:)` / `addJS(url:)` | Adds a stylesheet or script URL to the generated document. |
| `addCSS(code:)` / `addJS(code:)` | Adds inline CSS or JavaScript. Each accepts any `CustomStringConvertible`. |

External style sheets are inserted after the bundled style sheets. External scripts and inline JavaScript run after the bundled scripts, near the end of `<body>`.

### Themes

Bootstrap 5.3 color modes are controlled through `data-bs-theme`. Set the default for a page and let users override it:

```swift
page.theme = .auto            // .light, .dark, or .auto (follows the operating system)

Button("Toggle dark mode", onClick: .toggleTheme, style: .secondary, .small)
Button("Dark", onClick: .setTheme(.dark))
```

`.setTheme(_:)` and `.toggleTheme` store the choice in the browser's `localStorage` (key `theme`). A stored choice wins over `page.theme`, and a small script in `<head>` applies it before the first paint, so there is no flash. `theme` must be assigned before the page is rendered, and only the first assignment has effect.

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
| `addSubmit(name:label:icon:style:)` | Adds a submit button, optionally with an [`Icon`](#icons) before the label. Omitting `style` uses `.primary`. |
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

## Buttons

`Button` is a value type. Label, URL, `onClick` code and attribute values are HTML-escaped. `style:` is variadic and last; `.primary` is added when no color style is given.

```swift
Button("Delete", onClick: .loadHtml(path: "/users/1/delete", domID: "#modal"), style: .danger, .small)
Button("Open", url: "/users/1", attributes: ["title": "Details"], style: .success) // <a class="btn ..." role="button">
```

A button renders with `type="button"`; use `Form.addSubmit` for submit buttons. Pass it to `Form.addRaw(html:)`, a page body, or `TableCell(_:)`. `icon:` puts an [`Icon`](#icons) before the label; with an empty label the button is icon-only, so add `attributes: ["aria-label": "Delete"]`.

## Build tables

`Table` accumulates rows in the order added; every setter returns the same table.

```swift
let table = Table(id: "users",
                  columns: ["Name", TableColumn("Age", alignment: .right), ""],
                  styles: [.striped, .hover],
                  responsive: true)
    .setCaption("Users")
    .setEmptyMessage("No users")

table.addRows(users) { user in
    [TableCell(user.name),
     TableCell(user.age),
     TableCell(Button("Delete", onClick: .loadHtml(path: "/users/\(user.id)/delete", domID: "#modal"),
                      style: .danger, .small))]
}
table.addRow(["Total", "42", .link("Report", url: "/report")], style: .warning)
```

| API | Behavior |
| --- | --- |
| `TableCell(_:)`, string literal | Text, HTML-escaped. |
| `TableCell(_ button:)` | Inserts the rendered `Button`. |
| `TableCell.raw(_:)` | Inserts HTML as is. Never use with untrusted content. |
| `TableCell.link(_:url:)` | Escaped `<a>` link. |
| `TableColumn(_:alignment:)` | Header title and default alignment for the column's cells; a cell's own `alignment:` overrides it. |
| `setCaption(_:)`, `setEmptyMessage(_:)` | Caption; placeholder row shown when there are no rows. |

`TableStyle` cases are `.striped`, `.hover`, `.bordered`, `.borderless`, `.small`, `.dark` (default `[.striped, .hover]`). `TableRowStyle` cases are `.primary`, `.secondary`, `.success`, `.danger`, `.warning`, `.info`, `.light`, `.dark`, `.active`. With `responsive: true` (default) the table is wrapped in `div.table-responsive`.

## Paginate

`Pagination` renders Bootstrap page navigation: previous/next, first and last page, a window of pages around the current one, and ellipses for gaps. The current page is clamped to the valid range.

```swift
let pagination = Pagination(page: page, pageSize: 20, totalItems: store.count,
                            alignment: .center,
                            href: { "/users?page=\($0)" },
                            onClick: { .loadHtml(path: "/users/table?page=\($0)", domID: "#usersTable") })
```

- Use `Pagination(page:totalPages:)` when the page count is already known.
- `href` is always rendered, so the links work without JavaScript. With `onClick`, the browser runs the returned `JSCode` and cancels the navigation (`return false`), which allows partial reloads of a table container.
- `window` (default 2) is the number of pages shown on each side of the current page. `size` is `.small` or `.large`; `alignment` is `.left`, `.center` or `.right`.
- With a single page the output is empty, unless `hideWhenSinglePage: false`.
- Returned HTML is not wrapped in a container; place it next to the `Table` inside the element that `loadHtml` replaces.

## Modals

`Modal` renders a Bootstrap modal dialog. `body` and `footer` entries are inserted as is, so they can be a `Form`, a `Table`, a `Button` or HTML; the title is escaped.

```swift
let modal = Modal(id: "editUser",
                  title: "Edit user",
                  body: form,
                  footer: [Button("Cancel", onClick: .hideModal, style: .secondary)],
                  size: .large,
                  centered: true)
```

Options: `size` (`.small`, `.large`, `.extraLarge`, `.fullscreen`), `centered`, `scrollable`, `staticBackdrop` (no close on outside click or Esc) and `closeButton` (header X, default `true`).

Open it from the page with `JSCode`:

| Case | Behavior |
| --- | --- |
| `.loadModal(path:)` | Fetches the modal HTML from `path`, puts it in a `#modalContainer` element (created on demand), shows the first `.modal` in it, and removes it when closed. Any modal already loaded this way is replaced. |
| `.showModal(domID:)` | Shows a modal already present in the page. Pass a selector such as `"#confirm"`. |
| `.hideModal` | Hides every open modal. |

```swift
// Table row action
Button("Edit", onClick: .loadModal(path: "/users/1/edit"), style: .primary, .small)

// GET /users/1/edit returns the modal fragment
server.get["users/1/edit"] = { _, _ in .ok(.html(modal)) }

// AJAX form submit inside the modal: close it and refresh the table
JSResponse(.hideModal,
           .showSuccess("Saved"),
           .loadHtml(path: "/users/table", domID: "#usersTable"))
```

- Put the `Form` (with `ajax: true` and its own submit button) in the modal body. Footer buttons render with `type="button"` and cannot submit a form.
- The bundled `modal.js` is loaded by every `BootstrapTemplate` page and needs the bundled Bootstrap bundle; it is served together with the other assets.

### Confirmation dialogs

`ConfirmDialog` is a client-side Bootstrap dialog with no server round trip. It renders the JavaScript call that opens it, so use it through `JSCode.confirm(_:)` or in a `JSResponse`.

```swift
Button("Delete",
       onClick: .confirm(ConfirmDialog("Delete user Ada?",
                                       title: "Delete user",
                                       confirmLabel: "Delete",
                                       confirmStyle: .danger,
                                       onConfirm: JSResponse(.loadHtml(path: "/users/1/delete", domID: "#usersTable"),
                                                             .showSuccess("Deleted")))),
       style: .danger, .small)
```

- `message`, `title` and the button labels are shown as plain text (line breaks are kept) and are escaped for JavaScript; they need no HTML escaping.
- `onConfirm` is any `CustomStringConvertible` JavaScript, such as a `JSCode` or a `JSResponse` with several commands. It runs after the dialog has closed, so it can open another modal. Cancelling, the X button and Esc run nothing.
- `confirmStyle` defaults to `.primary`; pass a color style such as `.danger`.
- Defaults: title `"Confirm"`, labels `"OK"` and `"Cancel"`.
- Opening a new confirmation replaces a pending one.

## Tabs

`Tabs` renders Bootstrap tabs (or pills) with their panes. Every `add...` returns the same `Tabs`.

```swift
let tabs = Tabs(id: "account", style: .pills)
    .addTab("Profile", icon: .person, content: profileForm)
    .addTab("Security", icon: .lock, content: securityForm, active: true)
    .addLazyTab("Activity", icon: .clock, path: "/account/activity")
    .addTab("Billing", content: "<p>Not available</p>", disabled: true)

page.body = tabs
```

- `id` is required and must be unique on the page. Panes get the ids `account-1`, `account-2`, ... in order, or the `id:` you pass to a tab. Use simple ids (letters, digits, `-`, `_`).
- `content` is inserted as is (a `Form`, a `Table`, HTML); titles are escaped. The first enabled tab is active unless a tab passes `active: true`. Disabled tabs cannot be selected.
- `addLazyTab(_:path:)` shows a spinner and fetches its HTML from `path` the first time the tab is shown; the result stays until the page is reloaded. If the request fails, an error toast appears and the next time the tab is shown it retries. A lazy tab that is active from the start is loaded when the page or fragment appears.
- To reload a lazy pane, use `.refreshHtml(path: "/account/activity", domID: "#account-3")`. To select a tab from JavaScript responses, use `.showTab(domID: "#account-2")`.
- Options: `style` is `.tabs`, `.pills` or `.underline`; `fill: true` spreads the tabs over the full width; `vertical: true` puts the tab list on the left.
- The lazy loader runs on every `BootstrapTemplate` page (`tabs.js`) and also picks up tabs inside modals and fragments loaded with `loadHtml`.

## Icons

`Icon` renders a [Bootstrap Icons](https://icons.getbootstrap.com/) glyph as `<i class="bi bi-trash" aria-hidden="true"></i>`. The library bundles a pinned snapshot (v1.13.1: stylesheet, `woff2`/`woff` fonts and the MIT license) under `bootstrap-icons-1.13.1/`, so it does not change when upstream does. Icons are opt-in: call `addIcons()` on the page to load the stylesheet, and keep serving the bundled assets (the fonts are requested relative to the stylesheet).

```swift
page.addIcons()

Icon.trash                                          // curated, typed
Icon("airplane-fill")                               // any icon of the snapshot by name
Icon("star-fill", cssClass: "fs-4 text-warning", label: "Favorite")

Button("Delete", icon: .trash, onClick: .loadModal(path: "/users/1/delete"), style: .danger, .small)
Button("", icon: .edit, attributes: ["aria-label": "Edit"], style: .secondary, .small)
TableCell(Icon.check, alignment: .center)
```

- Curated constants (64): `.plus .minus .close .check .edit .editSquare .trash .search .filter .refresh .copy .share .print .download .upload .view .hide .settings`, navigation (`.home .menu .more .moreVertical .arrowLeft/.arrowRight/.arrowUp/.arrowDown .chevronLeft/.chevronRight/.chevronUp/.chevronDown .link .externalLink .login .logout`), status (`.info .warning .error .success .question`) and objects (`.person .people .personAdd .mail .bell .calendar .clock .star .starFill .heart .bookmark .tag .folder .file .document .image .lock .unlock .key .shield .cart .chart .moon .sun`).
- Any other name from the snapshot works through `Icon("name")` or a string literal. Names are not checked at runtime; an unknown name renders an empty glyph. Add your own constants with `extension Icon { static let logo = Icon("airplane") }`.
- `cssClass` adds utility classes (`fs-4`, `text-danger`). Without `label` the icon is decorative (`aria-hidden`); with `label` it gets `role="img"` and `aria-label`.
- `TableCell(Icon)` inserts the icon; `TableCell(_ text:)` would escape its markup.

## Escape HTML and JavaScript

`String.htmlEscaped` is public. It replaces `&`, `<`, `>`, `"` and `'`, making a value safe in HTML text and quoted attribute values. Use it for any untrusted value placed into templates, `Form.addRaw(html:)` or `TableCell.raw(_:)`.

`String.jsEscaped` is public too. It escapes `\`, `'`, newlines and `</` so a value can be placed inside a single-quoted JavaScript string literal, for example in `JSCode.custom(code:)`. Every `JSCode` case that takes a string already applies it, so do not escape those arguments again. Notification text is rendered as HTML by Noty, so pass `.showSuccess(name.htmlEscaped)`. Neither helper escapes for CSS contexts.

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

`add` returns the response, so commands can also be chained:

```swift
return .ok(.js(JSResponse()
    .add(.showSuccess("Saved"))
    .add(.hideModal)
    .add(.refreshHtml(path: "/users/table", domID: "#usersTable"))))
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
| `.refreshHtml(path:domID:)` | Like `.loadHtml`, but keeps the old content visible until the new HTML arrives (no flicker). |
| `.poll(path:domID:interval:)`, `.stopPolling(domID:)` | Reloads the selector's HTML every `interval` seconds (minimum 0.25) until stopped or the element disappears. Request errors during polling are ignored. A selector has one poller; starting again replaces it. |
| `.loadJS(path:)` | Loads and runs one script. |
| `.loadMultipleJS(paths:)` | Loads and runs several scripts. |
| `.loadHtmlAndJS(htmlPath:htmlDomID:jsPath:)` | Loads HTML into a selector, then loads one script. |
| `.loadModal(path:)`, `.showModal(domID:)`, `.hideModal` | Modal commands; see [Modals](#modals). |
| `.confirm(_:)` | Opens a `ConfirmDialog`; see [Confirmation dialogs](#confirmation-dialogs). |
| `.showTab(domID:)` | Selects the tab whose pane has this selector (for example `"#account-2"`); see [Tabs](#tabs). |
| `.showSuccess(_:icon:)`, `.showError(_:icon:)`, `.showWarning(_:icon:)`, `.showInfo(_:icon:)` | Shows a Noty notification using the bundled notification helpers. The text is rendered as HTML. The optional [`Icon`](#icons) is placed before the text (the page needs `addIcons()`), for example `.showSuccess("Saved", icon: .check)`. |
| `.redirect(path:)`, `.reload` | Navigates to a URL or reloads the page. Never pass an untrusted URL to `.redirect`. |
| `.scrollTo(domID:)` | Smooth-scrolls the selector's first element into view. |
| `.copyToClipboard(_)` | Copies text to the clipboard (uses the Clipboard API on secure contexts, a fallback otherwise). |
| `.setTheme(_:)`, `.toggleTheme` | Changes and stores the color theme; see [Themes](#themes). |
| `.setHtml(domID:html:)`, `.appendHtml(domID:html:)` | Replaces or appends the selector's HTML. `html` is inserted as is and its scripts run. |
| `.remove(domID:)` | Removes the selected elements. |
| `.addClass(domID:name:)`, `.removeClass(domID:name:)` | Adds or removes a CSS class. |
| `.setDisabled(domID:disabled:)` | Sets the `disabled` property, for example on a submit button during a long operation. |
| `.custom(code:)` | Emits the supplied JavaScript unchanged. |
| `.submitForm(path:domID:)` | Posts the form selected by `domID` in the background through the bundled helper. |

`JSResponse` has both variadic and result-builder constructors, plus matching `add` overloads. The result builder accepts a sequence of `CustomStringConvertible` expressions; it does not support control-flow expressions such as `if` inside the builder.

### JavaScript compatibility notes

- The bundled dynamic loaders add a cache-busting query parameter and depend on jQuery.
- The page template loads the required jQuery, Noty, and helper scripts automatically, provided their static URLs are served.
- Every string argument of a `JSCode` case is escaped for a single-quoted JavaScript string literal (`String.jsEscaped`), so it cannot break out of the literal. Do not escape it yourself first, or it will be doubled. `html` arguments and `.custom(code:)` are not sanitized for HTML or script content.
- `.submitForm(path:domID:)` expects a selector for the form element; selectors must be passed with their prefix, such as `"#contactForm"`.

## Public API reference

The stable public surface in this package is:

```swift
public class BootstrapTemplate: CustomStringConvertible {
    public let template: Template
    public init()
    public var title: String? { get set }
    public var body: CustomStringConvertible? { get set }
    public var theme: BootstrapTheme? { get set }
    public func addJS(code: CustomStringConvertible)
    public func addJS(url: String)
    public func addCSS(code: CustomStringConvertible)
    public func addCSS(url: String)
    public func addMeta(name: String, value: String)
    public func addFavicon(url: String, type: String)
    public func addIcons()
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
        icon: Icon? = nil,
        style: ButtonStyle...) -> Form
    public var output: String { get }
}

public enum JSCode: CustomStringConvertible {
    case submitForm(path: String, domID: String)
    case loadHtml(path: String, domID: String)
    case refreshHtml(path: String, domID: String)
    case loadJS(path: String)
    case loadMultipleJS(paths: [String])
    case loadHtmlAndJS(htmlPath: String, htmlDomID: String, jsPath: String)
    case loadModal(path: String), showModal(domID: String), hideModal
    case confirm(ConfirmDialog)
    case showTab(domID: String)
    case showSuccess(String, icon: Icon? = nil), showError(String, icon: Icon? = nil)
    case showWarning(String, icon: Icon? = nil), showInfo(String, icon: Icon? = nil)
    case redirect(path: String), reload, scrollTo(domID: String), copyToClipboard(String)
    case setTheme(BootstrapTheme), toggleTheme
    case setHtml(domID: String, html: String), appendHtml(domID: String, html: String)
    case remove(domID: String)
    case addClass(domID: String, name: String), removeClass(domID: String, name: String)
    case setDisabled(domID: String, disabled: Bool)
    case poll(path: String, domID: String, interval: TimeInterval), stopPolling(domID: String)
    case custom(code: String)
}

public enum BootstrapTheme: String { case light, dark, auto }

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

public struct Button: CustomStringConvertible {
    public init(_ label: String, icon: Icon? = nil, onClick: JSCode? = nil,
                attributes: [String: String] = [:], style: ButtonStyle...)
    public init(_ label: String, icon: Icon? = nil, url: String,
                attributes: [String: String] = [:], style: ButtonStyle...)
    public var output: String { get }
}

public struct Icon: ExpressibleByStringLiteral, CustomStringConvertible {
    public let name: String
    public init(_ name: String, cssClass: String? = nil, label: String? = nil)
    public var output: String { get }
    // static constants: .plus, .trash, .edit, ... (see Icons)
}

public class Table: CustomStringConvertible {
    public init(id: String? = nil, columns: [TableColumn],
                styles: [TableStyle] = [.striped, .hover], responsive: Bool = true)
    @discardableResult public func addRow(_ cells: [TableCell], style: TableRowStyle? = nil) -> Table
    @discardableResult public func addRows<T>(_ items: [T], cells: (T) -> [TableCell]) -> Table
    @discardableResult public func setCaption(_ caption: String) -> Table
    @discardableResult public func setEmptyMessage(_ message: String) -> Table
    public var output: String { get }
}

public struct TableColumn: ExpressibleByStringLiteral {
    public init(_ title: String, alignment: TableAlignment? = nil)
}
public struct TableCell: ExpressibleByStringLiteral {
    public init(_ text: CustomStringConvertible, alignment: TableAlignment? = nil)
    public init(_ button: Button, alignment: TableAlignment? = nil)
    public init(_ icon: Icon, alignment: TableAlignment? = nil)
    public static func raw(_ html: CustomStringConvertible, alignment: TableAlignment? = nil) -> TableCell
    public static func link(_ label: String, url: String, alignment: TableAlignment? = nil) -> TableCell
}
public enum TableStyle { case striped, hover, bordered, borderless, small, dark }
public enum TableRowStyle { case primary, secondary, success, danger, warning, info, light, dark, active }
public enum TableAlignment { case left, center, right }

public struct Pagination: CustomStringConvertible {
    public init(page: Int, totalPages: Int, window: Int = 2,
                size: PaginationSize? = nil, alignment: PaginationAlignment? = nil,
                hideWhenSinglePage: Bool = true,
                href: @escaping (Int) -> String = { _ in "#" },
                onClick: ((Int) -> JSCode)? = nil)
    public init(page: Int, pageSize: Int, totalItems: Int, window: Int = 2,
                size: PaginationSize? = nil, alignment: PaginationAlignment? = nil,
                hideWhenSinglePage: Bool = true,
                href: @escaping (Int) -> String = { _ in "#" },
                onClick: ((Int) -> JSCode)? = nil)
    public var output: String { get }
}
public enum PaginationSize { case small, large }
public enum PaginationAlignment { case left, center, right }

public struct Modal: CustomStringConvertible {
    public init(id: String, title: String, body: CustomStringConvertible,
                footer: [CustomStringConvertible] = [], size: ModalSize? = nil,
                centered: Bool = false, scrollable: Bool = false,
                staticBackdrop: Bool = false, closeButton: Bool = true)
    public var output: String { get }
}
public enum ModalSize { case small, large, extraLarge, fullscreen }

public class Tabs: CustomStringConvertible {
    public init(id: String, style: TabsStyle = .tabs, fill: Bool = false, vertical: Bool = false)
    @discardableResult public func addTab(_ title: String, icon: Icon? = nil, id: String? = nil,
        content: CustomStringConvertible, active: Bool = false, disabled: Bool = false) -> Tabs
    @discardableResult public func addLazyTab(_ title: String, icon: Icon? = nil, id: String? = nil,
        path: String, active: Bool = false, disabled: Bool = false) -> Tabs
    public var output: String { get }
}
public enum TabsStyle { case tabs, pills, underline }

public struct ConfirmDialog: CustomStringConvertible {
    public init(_ message: String, title: String = "Confirm", confirmLabel: String = "OK",
                cancelLabel: String = "Cancel", confirmStyle: ButtonStyle = .primary,
                onConfirm: CustomStringConvertible)
    public var output: String { get }
}

extension String {
    public var htmlEscaped: String { get }
    public var jsEscaped: String { get }
}
```

Properties not shown as public in this list are implementation details. In particular, option models expose construction but not public `label` or `value` properties.

## Security and operating notes

- **Escape at the boundary.** Page bodies, form labels, values, attributes, raw form HTML, metadata, CSS, JavaScript, and `JSCode` arguments are interpolated into templates or scripts. `Table` and `Button` escape their text, URLs and attribute values, `JSCode` escapes its string arguments for JavaScript, and `String.htmlEscaped` is available for the rest, but the library does not escape CSS. Encode untrusted data for its exact output context before passing it in.
- **Validate server requests normally.** Form generation does not add CSRF protection, authentication, authorization, validation, or rate limiting.
- **Set a content-security policy deliberately.** Inline scripts and styles are generated by `addJS(code:)` and `addCSS(code:)`; a restrictive CSP needs nonces, hashes, or a policy that permits those blocks.
- **Serve resources in deployment.** The package uses `Bundle.module` to locate copied resources. In a Linux container, ensure the SwiftPM-generated resource bundle (typically a `.resources` directory beside the executable) is copied into the runtime image along with the executable.
- **Use an appropriate response MIME type.** HTML pages should be returned as `text/html`; JavaScript command responses should be returned as JavaScript, as required by the HTTP framework and client.

## Guidance for AI agents

When modifying an application that uses this package:

1. Import `BootstrapTemplate`, not the repository name.
2. Treat `BootstrapTemplate`, `Form`, `Button`, `Icon`, `Table`, `TableCell`, `TableColumn`, `Pagination`, `Modal`, `ConfirmDialog`, `Tabs`, `JSCode`, `JSResponse`, `FormRadioModel`, `FormSelectModel`, `ButtonStyle`, `String.htmlEscaped`, and `String.jsEscaped` as the public API. Do not rely on package-internal template structures or helper implementation details unless the application explicitly owns that integration. Do not redefine `htmlEscaped` or `jsEscaped` in the application.
3. Preserve static serving for `BootstrapTemplate.absolutePath(for:)`; without it, every generated page is missing its bundled CSS and JavaScript.
4. Use a CSS selector such as `"#content"` for `JSCode.loadHtml` and `JSCode.loadHtmlAndJS` target arguments.
5. Prefer explicit form IDs when any client code needs to select fields. Generated IDs are intentionally non-deterministic.
6. For AJAX forms, return executable JavaScript commands, usually `JSResponse`; remember that the bundled helper posts with `POST`.
7. Encode dynamic or user-controlled strings for their HTML, attribute or CSS context before sending them to this library (`JSCode` string arguments are JavaScript-escaped automatically). Never use `addRaw(html:)` with untrusted content.
8. `.submitForm(path:domID:)` takes a selector (`"#contactForm"`); prefer `Form(ajax: true)` when the form is generated by this library.
9. Do not escape `JSCode` string arguments yourself; they are escaped already. HTML-escape text shown in notifications with `htmlEscaped`.
10. When containerizing, retain the SwiftPM resource bundle and verify the static asset fallback against a deployed build.
