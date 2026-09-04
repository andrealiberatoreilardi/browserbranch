import AppKit
import Foundation

struct BrowserProfile: Identifiable, Hashable {
    let browserIdentifier: String
    let directoryName: String
    let name: String
    let email: String?
    let avatarImageURL: URL?

    var id: String {
        "\(browserIdentifier)::\(directoryName)"
    }

    var avatarImage: NSImage? {
        guard let avatarImageURL else { return nil }
        return NSImage(contentsOf: avatarImageURL)
    }
}

struct BrowserProfilePreferences: Codable, Equatable {
    var isEnabled = false
    var profileOrder: [String] = []
    var disabledProfileDirectories: Set<String> = []
}
