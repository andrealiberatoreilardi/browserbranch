import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let browserService: BrowserService
    private let store: SettingsStore
    private let coordinator: AppCoordinator
    private let settingsWindowController: SettingsWindowController
    private var statusItem: NSStatusItem?

    override init() {
        let browserService = BrowserService()
        let store = SettingsStore(browserService: browserService)

        self.browserService = browserService
        self.store = store
        self.coordinator = AppCoordinator(store: store, browserService: browserService)
        self.settingsWindowController = SettingsWindowController(
            store: store,
            browserService: browserService
        )
        super.init()

        settingsWindowController.onHide = { [weak self] in
            self?.settingsWindowDidHide()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if
            let iconURL = Bundle.main.url(forResource: "BrowserBranch", withExtension: "icns"),
            let icon = NSImage(contentsOf: iconURL)
        {
            NSApplication.shared.applicationIconImage = icon
        }

        installStatusItem()

        if store.isFirstLaunch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self, !self.coordinator.hasHandledIncomingURL else { return }
                self.showSettings()
                self.store.completeFirstLaunch()
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        coordinator.handle(urls)
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        showSettings()
        return true
    }

    @objc private func showSettings() {
        store.refreshBrowsers()
        browserService.refreshDefaultStatus()
        NSApplication.shared.setActivationPolicy(.regular)
        settingsWindowController.showWindow()
    }

    private func settingsWindowDidHide() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    @objc private func showTestChooser() {
        coordinator.showTestChooser()
    }

    @objc private func makeDefault() {
        browserService.makeDefault { [weak self] in
            if self?.browserService.isDefaultBrowser == false {
                self?.showSettings()
            }
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "arrow.triangle.branch",
            accessibilityDescription: "BrowserBranch"
        )
        item.button?.toolTip = "BrowserBranch"

        let menu = NSMenu()
        menu.addItem(withTitle: "Open Settings…", action: #selector(showSettings), keyEquivalent: ",")
        menu.addItem(withTitle: "Try the Chooser…", action: #selector(showTestChooser), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Make BrowserBranch Default", action: #selector(makeDefault), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit BrowserBranch", action: #selector(quit), keyEquivalent: "q")

        for menuItem in menu.items {
            menuItem.target = self
        }

        item.menu = menu
        statusItem = item
    }
}
