import AppKit
import Combine
import Foundation

@MainActor
final class BrowserService: ObservableObject {
    @Published private(set) var isDefaultBrowser = false
    @Published private(set) var statusMessage: String?

    private let workspace: NSWorkspace

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
        refreshDefaultStatus()
    }

    func discoverBrowsers(excludingBundleIdentifier: String?) -> [Browser] {
        guard let probeURL = URL(string: "https://example.com") else { return [] }

        var seen = Set<String>()
        return workspace.urlsForApplications(toOpen: probeURL)
            .compactMap { applicationURL -> Browser? in
                guard
                    let bundle = Bundle(url: applicationURL),
                    let identifier = bundle.bundleIdentifier,
                    identifier != excludingBundleIdentifier,
                    isLikelyWebBrowser(identifier: identifier, name: displayName(for: bundle, at: applicationURL)),
                    seen.insert(identifier).inserted
                else {
                    return nil
                }

                let displayName = displayName(for: bundle, at: applicationURL)

                return Browser(
                    bundleIdentifier: identifier,
                    name: displayName,
                    applicationURL: applicationURL,
                    profileDataDirectory: profileDataDirectory(for: identifier)
                )
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func displayName(for bundle: Bundle, at applicationURL: URL) -> String {
        (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? applicationURL.deletingPathExtension().lastPathComponent
    }

    private func isLikelyWebBrowser(identifier: String, name: String) -> Bool {
        let normalizedIdentifier = identifier.lowercased()
        let normalizedName = name.lowercased()

        let identifierFragments = [
            "com.apple.safari",
            "com.google.chrome",
            "org.chromium.chromium",
            "org.mozilla.firefox",
            "com.microsoft.edgemac",
            "com.brave.browser",
            "com.vivaldi.vivaldi",
            "com.operasoftware.opera",
            "company.thebrowser.browser",
            "company.thebrowser.dia",
            "com.kagi.kagimacos",
            "com.duckduckgo.macos.browser",
            "org.waterfoxproject.waterfox",
            "io.gitlab.librewolf-community",
            "app.zen-browser.zen",
            "org.torproject.torbrowser",
            "net.mullvad.mullvadbrowser"
        ]

        let nameFragments = [
            "arc", "brave", "chromium", "chrome", "dia", "duckduckgo", "edge",
            "firefox", "floorp", "librewolf", "mullvad browser", "opera", "orion",
            "safari", "tor browser", "vivaldi", "waterfox", "zen browser"
        ]

        return identifierFragments.contains(where: normalizedIdentifier.hasPrefix)
            || nameFragments.contains(where: normalizedName.contains)
    }

    private func profileDataDirectory(for identifier: String) -> URL? {
        guard let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }

        let normalizedIdentifier = identifier.lowercased()
        let relativePath: String?

        switch normalizedIdentifier {
        case let value where value.hasPrefix("com.google.chrome.canary"):
            relativePath = "Google/Chrome Canary"
        case let value where value.hasPrefix("com.google.chrome.beta"):
            relativePath = "Google/Chrome Beta"
        case let value where value.hasPrefix("com.google.chrome.dev"):
            relativePath = "Google/Chrome Dev"
        case let value where value.hasPrefix("com.google.chrome"):
            relativePath = "Google/Chrome"
        case let value where value.hasPrefix("com.microsoft.edgemac.beta"):
            relativePath = "Microsoft Edge Beta"
        case let value where value.hasPrefix("com.microsoft.edgemac.dev"):
            relativePath = "Microsoft Edge Dev"
        case let value where value.hasPrefix("com.microsoft.edgemac.canary"):
            relativePath = "Microsoft Edge Canary"
        case let value where value.hasPrefix("com.microsoft.edgemac"):
            relativePath = "Microsoft Edge"
        case let value where value.hasPrefix("com.brave.browser.beta"):
            relativePath = "BraveSoftware/Brave-Browser-Beta"
        case let value where value.hasPrefix("com.brave.browser.nightly"):
            relativePath = "BraveSoftware/Brave-Browser-Nightly"
        case let value where value.hasPrefix("com.brave.browser"):
            relativePath = "BraveSoftware/Brave-Browser"
        case let value where value.hasPrefix("com.vivaldi.vivaldi"):
            relativePath = "Vivaldi"
        case let value where value.hasPrefix("org.chromium.chromium"):
            relativePath = "Chromium"
        default:
            relativePath = nil
        }

        guard let relativePath else { return nil }
        let directory = applicationSupport.appendingPathComponent(relativePath, isDirectory: true)
        return FileManager.default.fileExists(atPath: directory.path) ? directory : nil
    }

    func open(
        _ url: URL,
        with browser: Browser,
        profile: BrowserProfile? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        if let profile {
            openChromium(url, with: browser, profile: profile, completion: completion)
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        workspace.open(
            [url],
            withApplicationAt: browser.applicationURL,
            configuration: configuration
        ) { _, error in
            DispatchQueue.main.async {
                completion?(error)
            }
        }
    }

    private func openChromium(
        _ url: URL,
        with browser: Browser,
        profile: BrowserProfile,
        completion: ((Error?) -> Void)?
    ) {
        guard
            profile.browserIdentifier == browser.id,
            let bundle = Bundle(url: browser.applicationURL),
            let executableName = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as? String
        else {
            completion?(ProfileLaunchError.invalidBrowserBundle)
            return
        }

        let executableURL = browser.applicationURL
            .appendingPathComponent("Contents/MacOS")
            .appendingPathComponent(executableName)
        let process = Process()
        process.executableURL = executableURL
        process.arguments = Self.chromiumLaunchArguments(
            for: url,
            profileDirectory: profile.directoryName
        )

        do {
            try process.run()
        } catch {
            completion?(error)
        }
    }

    static func chromiumLaunchArguments(for url: URL, profileDirectory: String) -> [String] {
        [
            "--profile-directory=\(profileDirectory)",
            "--ignore-profile-directory-if-not-exists",
            url.absoluteString
        ]
    }

    func refreshDefaultStatus() {
        guard let probeURL = URL(string: "https://example.com") else { return }
        let handlerURL = workspace.urlForApplication(toOpen: probeURL)
        isDefaultBrowser = handlerURL?.standardizedFileURL == Bundle.main.bundleURL.standardizedFileURL
    }

    func makeDefault(completion: (() -> Void)? = nil) {
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            statusMessage = "Build and launch BrowserBranch.app before making it the default browser."
            completion?()
            return
        }

        statusMessage = nil
        let group = DispatchGroup()
        var errors: [Error] = []

        for scheme in ["http", "https"] {
            group.enter()
            workspace.setDefaultApplication(
                at: Bundle.main.bundleURL,
                toOpenURLsWithScheme: scheme
            ) { error in
                DispatchQueue.main.async {
                    if let error { errors.append(error) }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.refreshDefaultStatus()
            self?.statusMessage = errors.first?.localizedDescription
            completion?()
        }
    }
}

private enum ProfileLaunchError: LocalizedError {
    case invalidBrowserBundle

    var errorDescription: String? {
        "The selected browser profile could not be opened."
    }
}
