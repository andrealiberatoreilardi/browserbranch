import AppKit
import Foundation

struct Browser: Identifiable {
    let bundleIdentifier: String
    let name: String
    let applicationURL: URL
    let profileDataDirectory: URL?
    let executableURL: URL?
    let icon: NSImage
    let isRunning: Bool

    init(
        bundleIdentifier: String,
        name: String,
        applicationURL: URL,
        profileDataDirectory: URL? = nil,
        executableURL: URL? = nil,
        icon: NSImage,
        isRunning: Bool
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.applicationURL = applicationURL
        self.profileDataDirectory = profileDataDirectory
        self.executableURL = executableURL
        self.icon = icon
        self.isRunning = isRunning
    }

    var id: String { bundleIdentifier }

    var supportsProfiles: Bool {
        profileDataDirectory != nil
    }
}
