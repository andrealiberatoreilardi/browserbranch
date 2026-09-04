import AppKit
import Foundation

@MainActor
final class AppCoordinator {
    private let store: SettingsStore
    private let browserService: BrowserService
    private lazy var chooser = ChooserPanelController()

    private(set) var hasHandledIncomingURL = false

    init(store: SettingsStore, browserService: BrowserService) {
        self.store = store
        self.browserService = browserService
    }

    func handle(_ urls: [URL]) {
        guard let incomingURL = urls.first, let targetURL = targetURL(from: incomingURL) else { return }
        hasHandledIncomingURL = true
        route(targetURL)
    }

    func showTestChooser() {
        guard let url = URL(string: "https://example.com/browserbranch") else { return }
        store.refreshBrowsers()
        prompt(for: url)
    }

    private func targetURL(from incomingURL: URL) -> URL? {
        guard incomingURL.scheme?.lowercased() == "browserbranch" else {
            return ["http", "https"].contains(incomingURL.scheme?.lowercased() ?? "") ? incomingURL : nil
        }

        guard
            let components = URLComponents(url: incomingURL, resolvingAgainstBaseURL: false),
            let rawURL = components.queryItems?.first(where: { $0.name == "url" })?.value,
            let targetURL = URL(string: rawURL),
            ["http", "https"].contains(targetURL.scheme?.lowercased() ?? "")
        else {
            return nil
        }

        return targetURL
    }

    private func route(_ url: URL) {
        store.refreshBrowsers()
        let decision = RoutingEngine.decision(
            for: url,
            rules: store.rules,
            defaultAction: store.defaultAction
        )

        switch decision.action.type {
        case .prompt:
            prompt(for: url)
        case .favorite:
            select(store.enabledBrowsers.first, for: url)
        case .bestRunning:
            let browser = store.enabledBrowsers.first(where: \.isRunning)
                ?? store.enabledBrowsers.first
            select(browser, for: url)
        case .browser:
            let browser = store.enabledBrowsers.first {
                $0.id == decision.action.browserIdentifier
            }
            select(
                browser,
                for: url,
                requestedProfileDirectory: decision.action.profileDirectory
            )
        }
    }

    private func prompt(for url: URL) {
        let browsers = store.enabledBrowsers
        guard !browsers.isEmpty else {
            showNoBrowsersAlert()
            return
        }

        chooser.show(url: url, browsers: browsers) { [weak self] browser in
            self?.select(browser, for: url)
        }
    }

    private func select(
        _ browser: Browser?,
        for url: URL,
        requestedProfileDirectory: String? = nil
    ) {
        guard let browser else {
            prompt(for: url)
            return
        }

        let profiles = store.enabledProfiles(for: browser)
        if
            let requestedProfileDirectory,
            let profile = profiles.first(where: { $0.directoryName == requestedProfileDirectory })
        {
            open(url, with: browser, profile: profile)
            return
        }

        guard store.isProfileManagementEnabled(for: browser), !profiles.isEmpty else {
            open(url, with: browser)
            return
        }

        chooser.showProfiles(
            url: url,
            browser: browser,
            profiles: profiles
        ) { [weak self] profile in
            self?.open(url, with: browser, profile: profile)
        } onBack: { [weak self] in
            self?.prompt(for: url)
        }
    }

    private func open(_ url: URL, with browser: Browser, profile: BrowserProfile? = nil) {
        browserService.open(
            url,
            with: browser,
            profile: profile,
            lastUsedProfileDirectory: store.lastUsedProfileDirectory(for: browser)
        ) { error in
            guard let error else { return }
            let alert = NSAlert(error: error)
            alert.messageText = "BrowserBranch couldn’t open this link"
            alert.runModal()
        }
    }

    private func showNoBrowsersAlert() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "No browsers are available"
        alert.informativeText = "Enable at least one installed browser in BrowserBranch settings."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
