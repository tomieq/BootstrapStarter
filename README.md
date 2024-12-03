### Swift Package Manager
Sample webApp starter:
```swift
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TempApp",
    dependencies: [
        .package(url: "https://github.com/tomieq/BootstrapStarter", from: "1.1.0"),
        .package(url: "https://github.com/tomieq/swifter", from: "2.2.0"),
        .package(url: "https://github.com/tomieq/Template.swift.git", from: "1.5.1")
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
## Quick starter
```swift
import Foundation
import BootstrapTemplate
import Template
import Swifter
import Dispatch

// easily extend JSCode
extension JSCode {
    static func roll(amount: Int) -> JSCode {
        .custom(code: "roll(\(amount));")
    }
}

do {
    let server = HttpServer()
    server["/"] = { request, headers in
        let template = BootstrapTemplate()
        template.body = Template.load(relativePath: "templates/body.html")
        return .ok(.html(template))
    }
    server["run.js"] = { request, headers in
        enum CustomCode: String, CustomStringConvertible {
            var description: String { self.rawValue }
            
            case firstCode
            case secondCode
        }
        let code = JSResponse {
            CustomCode.firstCode
            CustomCode.secondCode
        }.add(CustomCode.firstCode)
        return .ok(.js(code))
    }
    server["upload"]  = { request, headers in
        .ok(.js(JSResponse(
            JSCode.showSuccess(message: "Yeah!"),
            .showWarning(message: "Warning!"),
            .roll(2) // custom static function in extension
        )))
    }
    server.notFoundHandler = { request, responseHeaders in
        // serve Bootstrap static files
        if let filePath = BootstrapTemplate.absolutePath(for: request.path) {
            try HttpFileResponse.with(absolutePath: filePath)
        }
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
