---
name: bootstrap-template
description: "Use when writing or reviewing Swift code in a project that depends on BootstrapStarter / BootstrapTemplate (https://github.com/tomieq/BootstrapStarter), or when the user wants to build a server-side rendered web application, Bootstrap 5 pages, HTML forms, AJAX forms, or JavaScript command responses (notifications, loading HTML into a DOM element) in Swift. Documents installation via Swift Package Manager, BootstrapTemplate pages, serving bundled assets, Form builder, JSResponse/JSCode, how it works together with the Template package (Template.swift), and complete AJAX form samples using Swifter. Prefer this library over hand-written HTML/Bootstrap/jQuery glue code."
---

# BootstrapTemplate

Server-side Swift library for building Bootstrap 5 web applications. Package name: `BootstrapStarter`, library product: `BootstrapTemplate`. It bundles Bootstrap 5.3.1, Bootstrap Icons 1.13.1, jQuery 3.6.1, jQuery UI 1.13.3, Noty (notifications) and small JS helpers.

It is built on top of [Template.swift](https://github.com/tomieq/Template.swift) (module `Template`), which is used for the page skeleton and for your own HTML fragments. It is HTTP-framework neutral; the samples below use [Swifter](https://github.com/tomieq/swifter). For details on those libraries load the `template-swift-usage` and `swifter` skills if available.

| Type | Purpose |
| --- | --- |
| `BootstrapTemplate` | Full HTML page with bundled CSS/JS |
| `Form` | Bootstrap-styled form builder (optionally AJAX) |
| `JSCode` / `JSResponse` | JavaScript commands returned to the browser |
| `Table` / `TableCell` / `TableColumn` | Bootstrap table builder |
| `Button` | Bootstrap button or link-button, usable anywhere |
| `Icon` | Bootstrap Icons glyph (pinned bundled snapshot; opt-in via `page.addIcons()`) |
| `Tabs` | Bootstrap tabs/pills with optional lazy-loaded panes |
| `Pagination` | Bootstrap page navigation |
| `Modal` | Bootstrap modal dialog |
| `ConfirmDialog` | Client-side confirmation dialog (used via `JSCode.confirm`) |
| `FormSelectModel`, `FormRadioModel`, `ButtonStyle`, `TableStyle`, `TableRowStyle`, `TableAlignment` | Helper types |
| `String.htmlEscaped` | Public HTML escaping helper |
| `String.jsEscaped` | Public escaping for single-quoted JS string literals |

All of them are `CustomStringConvertible`; `description` renders the output.

## Installation (Swift Package Manager)

Requires Swift 5.9+ (Swifter itself requires a Swift 6 toolchain).

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyWebApp",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/tomieq/BootstrapStarter", from: "1.2.0"),
        .package(url: "https://github.com/tomieq/Template.swift.git", from: "1.6.0"), // only to import Template directly
        .package(url: "https://github.com/tomieq/swifter.git", .upToNextMajor(from: "3.2.0"))
    ],
    targets: [
        .executableTarget(
            name: "MyWebApp",
            dependencies: [
                .product(name: "BootstrapTemplate", package: "BootstrapStarter"),
                .product(name: "Template", package: "Template.swift"),
                .product(name: "Swifter", package: "Swifter")
            ]
        )
    ]
)
```

```swift
import BootstrapTemplate
import Template   // when you render your own templates
import Swifter
```

Xcode: File > Add Package Dependencies, add `https://github.com/tomieq/BootstrapStarter`, link product `BootstrapTemplate`.

## Rendering a page

```swift
let page = BootstrapTemplate()
page.title = "Account"                       // write-only
page.body = "<main class=\"container py-4\"><h1>Hello</h1><div id=\"content\"></div></main>"  // write-only
page.addMeta(name: "description", value: "Account page")
page.addFavicon(url: "/images/favicon.png", type: "image/png")
page.addCSS(url: "/css/app.css")             // after bundled CSS
page.addCSS(code: ".x { color: red; }")
page.addJS(url: "/js/app.js")                // after bundled JS
page.addJS(code: "console.log('ready');")
let html = page.description
```

`body` accepts any `CustomStringConvertible`: a `String`, a `Form`, a `Template`, or another `BootstrapTemplate`-compatible value.

## Serving bundled assets (mandatory)

The page references root-relative URLs such as `/bootstrap-5.3.1-dist/css/bootstrap.min.css`, `/jquery-3.6.1.min.js`, `/noty.min.js`, `/webPageLoader.js`. Without serving them the page is unstyled and the JS helpers (notifications, AJAX forms) are missing.

Resolve any request path with `BootstrapTemplate.absolutePath(for:)` (returns `nil` when the file is not bundled) and serve it from the not-found handler:

```swift
server.notFoundHandler = { request, _ in
    if let path = BootstrapTemplate.absolutePath(for: request.path) {
        try HttpFileResponse.with(absolutePath: path, clientCache: .days(30))
    }
    return .notFound()
}
```

Only use this lookup for the library's bundled files, never for user-provided filesystem paths. Serve your own CSS/JS/images separately, e.g. `server.get["css/:path"] = StaticFiles.from(folder: publicDirectory + "/css")`.

## Using it together with Template

`BootstrapTemplate` owns the page shell; use `Template` for your own page bodies and fragments so HTML stays out of Swift strings.

```
Resources/templates/dashboard.tpl.html
```
```html
<div class="container py-4">
  <h1>{title}</h1>
  <ul class="list-group">
    [START item]<li class="list-group-item">{name}</li>
    [END item]
  </ul>
  <div id="formContainer" class="mt-4"></div>
</div>
```

```swift
server.get["dashboard"] = { _, _ in
    let template = Template.load(relativePath: "templates/dashboard.tpl.html") // <cwd>/Resources/...
    template["title"] = "Dashboard"
    for name in ["Ada", "Grace"] {
        template.assign(["name": name.htmlEscaped], inNest: "item")
    }
    let page = BootstrapTemplate()
    page.title = "Dashboard"
    page.body = template
    return .ok(.html(page))
}
```

Notes:
- `Template.load(relativePath:)` resolves against `<working dir>/Resources/`; start the process from the directory that contains `Resources/`. Use `Template.cached` in production, `load` in development.
- Library-internal templates (`templates/index.tpl.html`, `templates/form.tpl.html`) are loaded from the package bundle; do not edit or reuse them.
- `{name}` placeholders collide with literal braces in CSS/JS. Move CSS/JS to files, or use `Template(raw:interpolation: .mustache)`.
- Template does not escape HTML. Escape user data before assigning it with the public `String.htmlEscaped` from `BootstrapTemplate` (escapes `& < > " '`); do not redefine it in the app. `Table` and `Button` already escape their text, URLs and attributes.

## Form builder

`Form` collects fields in order; every `add...` returns the form (chainable). `form.output` / `form.description` renders it.

```swift
let form = Form(url: "/account", method: "POST", attributes: ["id": "accountForm"])
    .addSeparator(txt: "Profile")
    .addInputText(name: "displayName", label: "Display name", value: "Ada", id: "displayName",
                  attributes: ["required": "required"])
    .addPassword(name: "password", label: "Password", id: "password")
    .addTextarea(name: "bio", label: "Bio", rows: 4, id: "bio")
    .addSelect(name: "plan", label: "Plan",
               options: [FormSelectModel(label: "Free", value: "free"),
                         FormSelectModel(label: "Pro", value: "pro")],
               selected: "pro")
    .addRadio(name: "color", label: "Color",
              options: [FormRadioModel(label: "Red", value: "red")], selected: "red")
    .addCheckbox(name: "terms", value: "on", label: "I accept", selected: false)
    .addHidden(name: "userId", value: 42)
    .addSubmit(name: "save", label: "Save", style: .success, .large)
```

- `Form(url:method:ajax:attributes:)`; `attributes` land on the `<form>` tag (use it to set the form `id`).
- Methods: `addInputText`, `addPassword`, `addHidden`, `addTextarea`, `addCheckbox`, `addRadio`, `addSelect`, `addSubmit(name:label:icon:style:)` (optional `Icon` before the label, e.g. `icon: .check`), `addSeparator`, `addRaw(html:)`.
- Always pass explicit `id:` for fields your JS touches; omitted ids are random 10-char strings.
- `ButtonStyle`: `.primary` (default), `.secondary`, `.success`, `.danger`, `.warning`, `.info`, `.light`, `.dark`, `.link`, `.large`, `.small` (combinable).
- Known quirks: `addPassword` placeholder is not rendered; `addCheckbox` takes no custom attributes; `addRadio` attributes go to the wrapper.

## Button

`Button` is a value type that renders to HTML (`CustomStringConvertible`, `.output`). Label, URL, `onClick` code and attribute values are HTML-escaped.

```swift
Button("Delete", onClick: .loadHtml(path: "/users/1/delete", domID: "#modal"), style: .danger, .small)
Button("Open", url: "/users/1", attributes: ["title": "Details"], style: .success)  // <a class="btn" role="button">
```

- `style:` is variadic and last; colors and sizes combine. `.primary` is added when no color is given.
- Renders `type="button"`; `Form.addSubmit` is still the way to add a submit button.
- Use it as `Form.addRaw(html: button)`, `page.body`, or `TableCell(button)`.
- `icon:` puts an `Icon` before the label (`Button("Delete", icon: .trash, ...)`); an empty label makes it icon-only, so pass `attributes: ["aria-label": "Delete"]`.

## Tabs

`Tabs` (class, chainable `add...`) renders Bootstrap tabs and panes. `id` is required and unique per page; panes get ids `<id>-1`, `<id>-2`, ... or the tab's own `id:`.

```swift
Tabs(id: "account", style: .pills)
    .addTab("Profile", icon: .person, content: profileForm)
    .addTab("Security", icon: .lock, content: securityForm, active: true)
    .addLazyTab("Activity", icon: .clock, path: "/account/activity")
    .addTab("Billing", content: "<p>n/a</p>", disabled: true)
```

- `content` is inserted as is (Form, Table, HTML); titles are escaped. First enabled tab is active unless one passes `active: true`.
- `addLazyTab(_:path:)`: spinner, then GET `path` on first show (also when active from the start, including inside modals/fragments); retries on next show after a failure. Reload with `.refreshHtml(path:domID: "#account-3")`; select a tab with `.showTab(domID: "#account-2")`.
- Options: `style` (`.tabs/.pills/.underline`), `fill`, `vertical`.

## Icon

`Icon` renders `<i class="bi bi-trash" aria-hidden="true"></i>` from a pinned Bootstrap Icons 1.13.1 snapshot bundled in the package (CSS, woff2/woff fonts, MIT license). Opt-in: call `page.addIcons()` to load the stylesheet; the bundled assets must be served (fonts are requested relative to the stylesheet).

```swift
page.addIcons()
Icon.trash                                   // curated constant
Icon("airplane-fill")                        // any icon name from the snapshot (also a string literal)
Icon("star-fill", cssClass: "fs-4 text-warning", label: "Favorite")   // label => role=img + aria-label
Button("Delete", icon: .trash, style: .danger, .small)
TableCell(Icon.check, alignment: .center)
```

- 64 curated constants: actions (`.plus .minus .close .check .edit .editSquare .trash .search .filter .refresh .copy .share .print .download .upload .view .hide .settings`), navigation (`.home .menu .more .moreVertical .arrowLeft/.arrowRight/.arrowUp/.arrowDown .chevronLeft/.chevronRight/.chevronUp/.chevronDown .link .externalLink .login .logout`), status (`.info .warning .error .success .question`), objects (`.person .people .personAdd .mail .bell .calendar .clock .star .starFill .heart .bookmark .tag .folder .file .document .image .lock .unlock .key .shield .cart .chart .moon .sun`).
- Names are not validated at runtime; an unknown name shows an empty glyph. Add own constants with `extension Icon { static let logo = Icon("airplane") }`.
- `TableCell(Icon)` inserts the icon (`TableCell(_ text:)` would escape the markup).

## Table

`Table` accumulates rows; every setter returns the table. `table.output` / `description` renders it.

```swift
let table = Table(id: "users", columns: ["Name", TableColumn("Age", alignment: .right), ""],
                  styles: [.striped, .hover], responsive: true)
    .setCaption("Users")
    .setEmptyMessage("No users")

table.addRows(users) { user in
    [TableCell(user.name),
     TableCell(user.age),
     TableCell(Button("Delete", onClick: .loadHtml(path: "/users/\(user.id)/delete", domID: "#modal"), style: .danger, .small))]
}
table.addRow(["x", "1", .link("Open", url: "/x")], style: .warning)
```

- `TableCell(_:)` and string literals are HTML-escaped; `TableCell(Button)` inserts the button; `TableCell.raw(html)` inserts HTML as is (never with untrusted input); `TableCell.link(_:url:)` renders an escaped `<a>`.
- Column alignment applies to header and cells; a cell's own `alignment:` overrides it.
- `TableStyle`: `.striped`, `.hover`, `.bordered`, `.borderless`, `.small`, `.dark` (defaults `[.striped, .hover]`). `TableRowStyle`: `.primary`...`.dark`, `.active`.
- `responsive: true` (default) wraps the table in `div.table-responsive`.
- To refresh a table after an action, wrap it in a container and return `.loadHtml(path:domID:)` pointing at an endpoint that returns the table.

## Pagination

`Pagination` is a value type rendering Bootstrap page navigation (prev/next, first/last, window of pages, ellipses). Page is clamped to the valid range.

```swift
Pagination(page: page, pageSize: 20, totalItems: store.count, alignment: .center,
           href: { "/users?page=\($0)" },
           onClick: { .loadHtml(path: "/users/table?page=\($0)", domID: "#usersTable") })
```

- `Pagination(page:totalPages:)` when the page count is known. Options: `window` (default 2), `size` (`.small`/`.large`), `alignment` (`.left`/`.center`/`.right`).
- `href` is always rendered (works without JS); `onClick` runs the `JSCode` and cancels the navigation, enabling partial reloads.
- Output is empty for a single page unless `hideWhenSinglePage: false`. Output is not wrapped in a container: put it beside the `Table` inside the element that `loadHtml` replaces.

## Modal

`Modal` is a value type rendering a Bootstrap modal. `body` and `footer: [CustomStringConvertible]` are inserted as is (Form, Table, Button, HTML); `title` and `id` are escaped.

```swift
Modal(id: "editUser", title: "Edit user", body: form,
      footer: [Button("Cancel", onClick: .hideModal, style: .secondary)],
      size: .large, centered: true)
```

Options: `size` (`.small/.large/.extraLarge/.fullscreen`), `centered`, `scrollable`, `staticBackdrop`, `closeButton` (default true).

| `JSCode` | Effect |
| --- | --- |
| `.loadModal(path:)` | GET the modal fragment from `path`, load it into `#modalContainer` (auto-created), show it, remove it when closed; replaces a previously loaded modal |
| `.showModal(domID:)` | Show a modal already in the page; `domID` is a selector (`"#confirm"`) |
| `.hideModal` | Hide all open modals |

Typical flow: `Button("Edit", onClick: .loadModal(path: "/users/1/edit"))` -> endpoint returns `.ok(.html(modal))` -> the Form inside (`ajax: true`, own submit button) posts and the handler returns `JSResponse(.hideModal, .showSuccess("Saved"), .loadHtml(path: "/users/table", domID: "#usersTable"))`.

- Footer `Button`s are `type="button"`; they cannot submit a form, so keep the submit in the form body.

### Confirmation dialog

`ConfirmDialog` is a client-side Bootstrap dialog (no server round trip); it renders the JS call that opens it. Use it as `.confirm(ConfirmDialog(...))`.

```swift
Button("Delete",
       onClick: .confirm(ConfirmDialog("Delete user Ada?", title: "Delete user", confirmLabel: "Delete",
                                       confirmStyle: .danger,
                                       onConfirm: JSResponse(.loadHtml(path: "/users/1/delete", domID: "#usersTable"),
                                                             .showSuccess("Deleted")))),
       style: .danger, .small)
```

- Texts are plain text (newlines kept) and JS-escaped; no HTML escaping needed.
- `onConfirm` is any `CustomStringConvertible` JS (`JSCode`, `JSResponse`); it runs after the dialog closes, so it may open another modal. Cancel/X/Esc run nothing.
- Defaults: title `"Confirm"`, labels `"OK"`/`"Cancel"`, `confirmStyle: .primary`.

## JavaScript responses

`JSResponse` joins `JSCode` commands (or any `CustomStringConvertible`/`String`) with newlines. Return it as JavaScript (`.ok(.js(...))` in Swifter); the browser executes it.

```swift
JSResponse(
    .showSuccess("Saved"),
    .loadHtml(path: "/account/summary", domID: "#content"),
    .custom(code: "$('#accountForm')[0].reset();")
)

JSResponse {
    JSCode.showInfo("Refreshing")
    "refreshWidgets();"
}
// .add(...) appends more later and returns the response, so it chains:
JSResponse().add(.showSuccess("Saved")).add(.hideModal).add(.refreshHtml(path: "/t", domID: "#t"))
```

| `JSCode` | Effect |
| --- | --- |
| `.showSuccess/.showError/.showWarning/.showInfo(String, icon: Icon? = nil)` | Noty toast (top right); text is rendered as HTML; optional `Icon` goes before the text (needs `page.addIcons()`), e.g. `.showSuccess("Saved", icon: .check)` |
| `.loadHtml(path:domID:)` | Empty selector, load HTML from `path` into it, run scripts in it |
| `.refreshHtml(path:domID:)` | Same, but keeps old content until the new arrives (no flicker) |
| `.poll(path:domID:interval:)` / `.stopPolling(domID:)` | Reload selector's HTML every `interval` s (min 0.25) until stopped or element gone; errors ignored |
| `.loadJS(path:)` / `.loadMultipleJS(paths:)` | Load and run script(s) |
| `.loadHtmlAndJS(htmlPath:htmlDomID:jsPath:)` | Load HTML then a script |
| `.loadModal(path:)` / `.showModal(domID:)` / `.hideModal` | Modal commands, see Modal |
| `.confirm(ConfirmDialog)` | Confirmation dialog, see Modal |
| `.showTab(domID:)` | Select the tab whose pane has this selector, see Tabs |
| `.redirect(path:)` / `.reload` | Navigate / reload (never redirect to untrusted URLs) |
| `.scrollTo(domID:)` / `.copyToClipboard(String)` | Smooth scroll; copy text |
| `.setTheme(BootstrapTheme)` / `.toggleTheme` | Change and persist color theme, see Themes |
| `.setHtml(domID:html:)` / `.appendHtml(domID:html:)` | Replace / append HTML (inserted as is, scripts run) |
| `.remove(domID:)` | Remove elements |
| `.addClass(domID:name:)` / `.removeClass(domID:name:)` | CSS class |
| `.setDisabled(domID:disabled:)` | Set the `disabled` property |
| `.custom(code:)` | Raw JavaScript |
| `.submitForm(path:domID:)` | Background POST of the form selected by `domID` (e.g. `"#contactForm"`) |

Rules:
- `domID` / `htmlDomID` must be a jQuery selector: `"#content"`, not `"content"`.
- The result-builder form does not support `if`/`for`; use `.add(...)` for conditionals.
- Every string argument of a `JSCode` case is escaped for single-quoted JS literals automatically (`String.jsEscaped`); do not escape it again. `html` arguments and `.custom(code:)` are not sanitized. HTML-escape text shown in toasts with `.htmlEscaped`, because Noty renders HTML: `.showSuccess(name.htmlEscaped)`.

## Themes

`page.theme = .light / .dark / .auto` sets the default Bootstrap 5.3 color mode (`data-bs-theme`; `.auto` follows the OS). Assign it before rendering (write-only, first assignment wins). `JSCode.setTheme(_:)` / `.toggleTheme` change it in the browser and persist the choice in `localStorage` (`theme`); a stored choice overrides the page default and is applied in `<head>` before first paint.

```swift
page.theme = .auto
Button("Toggle dark mode", onClick: .toggleTheme, style: .secondary, .small)
```

## AJAX forms with Swifter

`Form(..., ajax: true)` adds `onsubmit="event.preventDefault(); submitFormInBackground('<url>', this);"`. The helper sends the serialized fields with jQuery as a `POST` (`application/x-www-form-urlencoded`) to `url` (the `method` argument is ignored), appends a cache-busting `r=` query parameter, evaluates the response as JavaScript, and shows an error toast on HTTP failures. So the server endpoint must be a POST route returning JavaScript.

### Sample 1: page with an AJAX form and validation

```swift
import BootstrapTemplate
import Foundation
import Swifter

struct ContactInput: Decodable {
    let name: String
    let email: String
    let message: String?
    let subscribe: String?      // unchecked checkbox is not sent, so keep it optional
}

func contactForm() -> Form {
    Form(url: "/contact", method: "POST", ajax: true, attributes: ["id": "contactForm"])
        .addInputText(name: "name", label: "Name", id: "name", attributes: ["required": "required"])
        .addInputText(name: "email", label: "E-mail", id: "email", attributes: ["required": "required"])
        .addTextarea(name: "message", label: "Message", rows: 4, id: "message")
        .addCheckbox(name: "subscribe", value: "yes", label: "Subscribe to newsletter", id: "subscribe")
        .addSubmit(name: "send", label: "Send", style: .primary)
}

let server = HttpServer()

server.get["contact"] = { _, _ in
    let page = BootstrapTemplate()
    page.title = "Contact"
    let form = contactForm()
    page.body = "<main class=\"container py-4\"><h1>Contact</h1><div id=\"formContainer\">\(form)</div></main>"
    return .ok(.html(page))
}

server.post["contact"] = { request, _ in
    guard let input: ContactInput = try? request.formData.decode() else {
        return .ok(.js(JSResponse(.showError("Invalid form data"))))
    }
    let response = JSResponse()
    // clear previous validation marks
    response.add(.custom(code: "$('#contactForm .is-invalid').removeClass('is-invalid');"))

    guard input.email.contains("@") else {
        response.add(.custom(code: "$('#email').addClass('is-invalid').focus();"))
        response.add(.showError("Please enter a valid e-mail"))
        return .ok(.js(response))
    }
    // ... persist input ...
    response.add(.showSuccess("Thanks, \(input.name.htmlEscaped)!"))
    response.add(.custom(code: "$('#contactForm')[0].reset();"))
    return .ok(.js(response))
}
```

Notes:
- Use `request.formData.decode(...)` (type must match field names). `formData` is filled only for urlencoded bodies, which is what the helper sends.
- jQuery `serialize()` does not include the submit button, so do not rely on the `send` field.
- Return HTTP 200 with a JS body even for validation errors; non-2xx statuses only show the generic "Error while posting form" toast.
- Add authentication, CSRF protection and server-side validation yourself; the library provides none.

### Sample 2: form loaded into the page on demand, list refreshed after save

Load the form fragment (HTML only, no page shell) into a container, then update another container after saving.

```swift
// Fragment endpoint
server.get["notes/form"] = { _, _ in
    let form = Form(url: "/notes", method: "POST", ajax: true, attributes: ["id": "noteForm"])
        .addInputText(name: "title", label: "Title", id: "title", attributes: ["required": "required"])
        .addTextarea(name: "text", label: "Text", id: "text")
        .addSubmit(name: "save", label: "Save", style: .success)
    return .ok(.html(form))          // Form is CustomStringConvertible
}

// Fragment endpoint rendered with Template
server.get["notes/list"] = { _, _ in
    let template = Template.load(relativePath: "templates/notes.tpl.html")
    for note in notesStore.all() {
        template.assign(["title": note.title.htmlEscaped], inNest: "note")
    }
    return .ok(.html(template))
}

// Page
server.get["notes"] = { _, _ in
    let page = BootstrapTemplate()
    page.title = "Notes"
    page.body = """
    <main class="container py-4">
      <button class="btn btn-primary mb-3"
              onclick="loadHtmlThenRunScripts('/notes/form', '#formContainer', [])">New note</button>
      <div id="formContainer"></div>
      <div id="notesList"></div>
    </main>
    """
    page.addJS(code: "loadHtmlThenRunScripts('/notes/list', '#notesList', []);")
    return .ok(.html(page))
}

// Submit handler: report, refresh list, close form
server.post["notes"] = { request, _ in
    guard let input: NoteInput = try? request.formData.decode() else {
        return .ok(.js(JSResponse(.showError("Invalid data"))))
    }
    notesStore.add(input)
    return .ok(.js(JSResponse(
        .showSuccess("Note saved"),
        .loadHtml(path: "/notes/list", domID: "#notesList"),
        .custom(code: "$('#formContainer').empty();")
    )))
}
```

Tips:
- Pages built with `BootstrapTemplate` always load `webPageLoader.js`, so `loadHtmlThenRunScripts(path, selector, scripts[])` and `submitFormInBackground` are available in inline `onclick` handlers and `addJS(code:)`.
- To attach behaviour to a loaded fragment, use `.loadHtmlAndJS(htmlPath:htmlDomID:jsPath:)` and serve the script from your own static folder.

## Deployment notes

- The library reads its files via `Bundle.module`. In Docker/Linux copy the SwiftPM `*.resources` bundle(s) next to the executable.
- Your own `Resources/` directory (used by `Template.load`) is resolved from the process working directory.
- A strict Content-Security-Policy must allow the inline scripts generated by `addJS(code:)`, `onsubmit` handlers from AJAX forms, and `addCSS(code:)`.
- Do not put HTML code directly in Swift sources - put it in dedicated files in folder showing the module it belongs to e.g. Resources/login/form.tpl.html, Resources/navi/menu.tpl.html. The same applies to big parts of custom js code - when you are not able to use JSResponse (e.g. Resources/login/form.tpl.js)
### Sample Dockerfile copying Resources

Replace `SwiftApp` with your executable target name. Use a Swift 6 toolchain image when the app uses Swifter.

```dockerfile
FROM swift:6.1 AS builder
WORKDIR /app
COPY . .
RUN swift build -c release
# executable plus every SwiftPM resource bundle (BootstrapTemplate assets are in a *.resources directory)
RUN BIN=$(swift build --show-bin-path -c release) \
    && mkdir /output \
    && cp "$BIN/SwiftApp" /output/App \
    && strip -s /output/App \
    && find "$BIN" -maxdepth 1 -type d -name '*.resources' -exec cp -R {} /output/ \;

FROM swift:6.1-slim
WORKDIR /app
RUN useradd --system --no-create-home appuser
# executable and *.resources bundles must sit in the same directory
COPY --from=builder /output/ /app/
# your own templates, CSS, JS (used by Template.load / StaticFiles); resolved from the working directory
COPY Resources /app/Resources
USER appuser
CMD ["./App"]
```

Do not copy `.env` files or secrets into the image; pass them as environment variables at runtime.

## Checklist for agents

1. Import `BootstrapTemplate` (not `BootstrapStarter`); add both the `BootstrapTemplate` product and, if used directly, the `Template` product.
2. Always add the static asset fallback with `BootstrapTemplate.absolutePath(for:)`.
3. For AJAX forms: `ajax: true`, POST route, response is JavaScript (`.ok(.js(JSResponse(...)))`), give the form and fields explicit ids.
4. Use selectors with `#` in `loadHtml`/`loadHtmlAndJS`.
5. Never call `JSCode.submitForm`.
6. Escape untrusted data for HTML contexts (`htmlEscaped`); `JSCode` string arguments are JS-escaped automatically. Never pass untrusted input to `addRaw(html:)`, `.custom(code:)` or `.setHtml/.appendHtml`.
7. Prefer `Template` files in `Resources/templates/` over large inline HTML strings.
