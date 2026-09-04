import AppKit
import Foundation

struct Browser: Identifiable, Hashable {
    let bundleIdentifier: String
    let name: String
    let applicationURL: URL
    let profileDataDirectory: URL?

    init(
        bundleIdentifier: String,
        name: String,
        applicationURL: URL,
        profileDataDirectory: URL? = nil
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.applicationURL = applicationURL
        self.profileDataDirectory = profileDataDirectory
    }

    var id: String { bundleIdentifier }

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: applicationURL.path)
    }

    var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
    }

    var supportsProfiles: Bool {
        profileDataDirectory != nil
    }
}
