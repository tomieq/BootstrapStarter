import BootstrapTemplate
import Foundation
import Swifter
import Template

/// Serves Resources/public/** (own CSS, JS, images, 3rd party files) at the URL root,
/// then the static files bundled with BootstrapTemplate.
final class AssetsFlow: Flow {
    private let resource: Resource

    init(resource: Resource = Resource()) {
        self.resource = resource
    }

    func register(on server: HttpServer) {
        server.notFoundHandler = { [self] request, _ in
            guard request.method == .GET else { return .notFound() }
            let path = resource.existingFilePath(for: request.path, inside: "public")
                ?? BootstrapTemplate.absolutePath(for: request.path)
            if let path {
                try HttpFileResponse.with(absolutePath: path, clientCache: .days(1))
            }
            return .notFound()
        }
    }
}
