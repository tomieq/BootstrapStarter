import Foundation

public enum BootstrapTemplate {
    public static func absolutePath(for filepath: String) -> String? {
        let (directory, filename, fileExtension) = Self.cut(filepath)
        return Bundle.module.path(forResource: filename, ofType: fileExtension, inDirectory: directory)
    }
    
    static func cut(_ filepath: String) -> (subdirectory: String, filename: String, fileExtension: String?) {
        var directory = "shared"
        var filename = filepath
        var fileExtension: String?
        if filepath.contains("/") {
            let folderParts = filepath.components(separatedBy: "/")
            directory.append("/")
            directory.append(folderParts.dropLast().joined(separator: "/").trimmingCharacters(in: CharacterSet(arrayLiteral: "/")))
            filename = folderParts.last!
        }
        let parts = filename.components(separatedBy: ".")
        if parts.count > 1 {
            filename = parts.dropLast().joined(separator: ".")
            fileExtension = parts.last!
        }
        directory = directory.trimmingCharacters(in: CharacterSet(arrayLiteral: "/"))
        return (directory, filename, fileExtension)
    }
}
