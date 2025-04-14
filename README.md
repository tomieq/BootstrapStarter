# Installation
### Swift Package Manager
Sample webApp starter:
```swift
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TempApp",
    dependencies: [
        .package(url: "https://github.com/tomieq/BootstrapStarter", from: "1.2.0"),
        .package(url: "https://github.com/tomieq/swifter", from: "3.0.0"),
        .package(url: "https://github.com/tomieq/Template.swift.git", from: "1.6.0")
    ],
    targets: [
        .executableTarget(
            name: "TempApp",
            dependencies: [
                .product(name: "BootstrapTemplate", package: "BootstrapStarter"),
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "Template", package: "Template.swift")
            ]),
    ]
)
```
# Structured JavaScript
## Provided bootstrap functions
Generating webpages and flow that manages UI via JavaScript can get messy. To make it more structured, you can use `JSResponse` and `JSCode` objects.
### Basic `JSCode`
BootstrapStarter comes with a set of inbuild `JSCode` functions:

`JSCode.showSuccess(String)` - show on UI success popup message

`JSCode.showError(String)` - show on UI error popup message

`JSCode.showWarning(String)` - show on UI warning popup message

`JSCode.showInfo(String)` - show on UI info popup message

`JSCode.loadJS(path: String)` - load into browser's memory javascript code by another web request to specified path (might be 3rd party absolute url or own relative served by Swifter)

`JSCode.loadMultipleJS(paths: [String])` - same as above, but allows setting multiple paths as String array

`JSCode.loadHtml(path: String, domID: String)` - loads HTML code from given path into webpage's given DOM's id

`JSCode.loadHtmlAndJS(htmlPath: String, htmlDomID: String, jsPath: String)` - combo function that loads HTML and then JavaScript from given paths.

Sample Swifter code:
```swift
server.post["/process"] = { request, _ in
    .ok(.js(JSResponse(
        .showSuccess("File processed"),
        .loadJS(path: "/reloader.js")
    )))
}
```
### Extending `JSCode`
You can extend `JSCode` with your own javascript function calls:
```Swift
extension JSCode {
    static func roll(amount: Int) -> JSCode {
        .custom(code: "rollJSImplementation(\(amount));")
    }
}
```
Then you can generate raw JavaSctipt code with:
```
JSCode.roll(2)
```
## Composing JavaScript code in Swifter
### `JSResponse.init()` usage with `JSCode`
```swift
server.get["process"]  = { request, headers in
    .ok(.js(JSResponse(
        .showSuccess(message: "Yeah!"),
        .showWarning(message: "Warning!"),
        .roll(2) // custom static function from extension
    )))
}
```
### `JSResponse.init()` usage with custom JS objects
You can create your own domain specific JS generators and use them with `JSResponse`. The only condition is that your generator implements `CustomStringConvertible`:
```swift
enum CustomCode: String, CustomStringConvertible {
    case firstCode
    case secondCode
    var description: String { self.rawValue }
}
let js = JSResponse(
    CustomCode.firstCode,
    CustomCode.secondCode,
    "rawCall();"
)
```
### `JSResponse.init()` with `@resultBuilder`
JSResponse implement `@resultBuilder` with `CustomStringConvertible` objects:
```swift
let js = JSResponse {
    JSCode.showSuccess("OK")
    JSCode.showError("Failed")
}
```
Usage with your own code generators:
```swift
let js = JSResponse {
    CustomCode.firstCode
    "reloadUI();"
}
```
### `JSResponse.add()` with `JSCode`, `CustomStringConvertible` and `@resultBuilder`
Sometimes you don't 'know at the beginning which JavaScript code should be returned, 
but rather you need to check for some conditions and build response in steps.
For this purpose `JSResponse` offers `add()` function that can be used in multiple ways.
#### `JSCode`
```swift
let js = JSResponse()
js.add (
    .showSuccess("OK"),
    .loadJS(path: "/script.js")
)
```
#### `CustomStringConvertible`
```swift
enum CustomCodeGenerator: String, CustomStringConvertible {
    case firstCode
    var description: String { self.rawValue }
}
let js = JSResponse()
js.add (
    "roll(5);",
    JSCode.showSuccess("OK"),
    CustomCodeGenerator.firstCode
)
```
#### `@resultBuilder`
Very similar as above, but use `{}` instead of `()` and omit commas (`,`)
```swift
enum CustomCodeGenerator: String, CustomStringConvertible {
    case firstCode
    var description: String { self.rawValue }
}
let js = JSResponse()
js.add {
    "roll(5);"
    JSCode.showSuccess("OK")
    CustomCodeGenerator.firstCode
}
```

### Form generation
Library has `Form` object that allows building HTML forms.

#### `<input>` text
```swift
let form = Form(url: "go.html", method: "POST")
form.addInputText(name: "name", label: "Your name")
form.addSubmit(name: "go", label: "Upload", style: .danger)
```
You can also provide default value, `id` or any custom attributes you want.

#### `<input>` password
```swift
let form = Form(url: "go.html", method: "POST")
form.addPassword(name: "password", label: "Password")
form.addSubmit(name: "go", label: "Log in", style: .danger)
```
You can also provide placeholder, `id` or any custom attributes you want.

#### `<textarea>`
```swift
let form = Form(url: "go.html", method: "POST")
form.addTextarea(name: "content", label: "Your opinion")
form.addSubmit(name: "go", label: "Upload", style: .danger)
```
You can also provide default value, `id`, number of rows or any oher custom attributes you want.

#### `<select>`
```swift
let form = Form(url: "go.html", method: "POST")
form.addSelect(name: "meal", label: "Did you like the meal?", options: [
    FormSelectModel(label: "Yes", value: "yes"),
    FormSelectModel(label: "No", value: "no")
], selected: "no")
form.addSubmit(name: "go", label: "Upload", style: .danger)
```
You can also provide default selected value, `id` or any custom attributes you want.

#### `<radio>`
```swift
let form = Form(url: "go.html", method: "POST")
form.addRadio(name: "transactionType",
              label: "Type of transaction",
              options: [
                FormRadioModel(label: "Visa", value: 0),
                FormRadioModel(label: "MasterCard", value: 1)
              ])
form.addSubmit(name: "go", label: "Upload", style: .danger)
```

#### Checkbox
```swift
let form = Form(url: "go.html", method: "POST")
form.addCheckbox(name: "privacyPolicy", value: 1, label: "I have read Privacy Policy")
form.addSubmit(name: "go", label: "Upload", style: .danger)
```
You can specify custom `id`.

#### `<input>` hidden
```swift
let form = Form(url: "go.html", method: "POST")
form.addHidden(name: "productID", value: 7829643)
form.addSubmit(name: "go", label: "Upload", style: .danger)
```
You can also set `id` or any custom attributes you want.

#### Separator
You can organise form with sections:
```swift
let form = Form(url: "go.html", method: "POST")
form.addSeparator(txt: "Personal information")
form.addSubmit(name: "go", label: "Upload", style: .danger)
```
You can also set `id` or any custom attributes you want.

### BootstrapTemplate
`BootstrapTemplate` objects is the main page template that adds all needed styles and js files for using Bootstrap framework.

It has a few properties that allows setting, body, title etc.
```swift
let template = BootstrapTemplate()
// load yours app main template:
template.body = Template.load(relativePath: "templates/body.html")
// page's title
template.title = "My awesome page"
// shorthand for adding javascript file to load at launch
template.addJS(url: "/logic.js")
// shorthand for adding javascript code to execute at launch
template.addJS(code: "someJSFunction();")
// shorthand for adding css file to load at launch
template.addCSS(url: "/style.css")
// shorthand for adding css code to load at launch
template.addCSS(code: ".button { color: #FF0022; }")
// function for adding meta code to the main template
template.addMeta(name: "keywords", value: "banking,payment")
// function for setting favicon to the main template
template.addFavicon(url: "/images/favicon.png", type: "image/png")
```

## Quick starter
```swift
import Foundation
import BootstrapTemplate
import Template
import Swifter
import Dispatch


do {
    let server = HttpServer()
    server["/"] = { request, headers in
        let template = BootstrapTemplate()
        template.body = Template.load(relativePath: "templates/body.html")
        return .ok(.html(template))
    }
    server["upload"]  = { request, headers in
        .ok(.js(JSResponse(
            .showSuccess(message: "Yeah!"),
            .showWarning(message: "Warning!"),
            .roll(2) // custom static function in extension
        )))
    }
    server.notFoundHandler = { request, responseHeaders in
        // serve Bootstrap static files
        if let filePath = BootstrapTemplate.absolutePath(for: request.path) {
            try HttpFileResponse.with(absolutePath: filePath)
        }
        // serve App's static files
        let resourcePath = Resource().absolutePath(for: request.path)
        try HttpFileResponse.with(absolutePath: resourcePath)
        return .notFound()
    }
    try server.start(8080)
    dispatchMain()
} catch {
    print(error)
}
```
## Dockerize Swift app that uses SPM library with resources
On macOS/iOS systems the resources are distributes as `bundle`. On linux sustems they are packed as `resources`.
If you want dockerize your app, you need to copy the `resources`, which is tricky.
```Dockerfile
FROM swift:5.9 as builder
WORKDIR /app
COPY . .
RUN swift build -c release 
RUN echo $(ls -la .build/x86_64-unknown-linux-gnu/release)


FROM swift:5.9-slim
RUN apt-get update -y
RUN apt-get install -y file
WORKDIR /app
# first copy everything to temp directory
COPY --from=builder /app/.build/x86_64-unknown-linux-gnu/release/ ./tmp/
# move resources only(linux bundles) to destination
RUN cp -R ./tmp/*.resources .
# remove tmp
RUN rm -rf ./tmp
# now copy your app
COPY --from=builder /app/.build/x86_64-unknown-linux-gnu/release/TempApp .
# and app's own resources (if any)
COPY Resources /app/Resources
CMD ["./TempApp"]

```
