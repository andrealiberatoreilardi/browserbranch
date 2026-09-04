import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var browsers: [Browser] = []
    @Published var rules: [RoutingRule] {
        didSet { persist(rules, key: Keys.rules) }
    }
    @Published var defaultAction: RoutingAction {
        didSet { persist(defaultAction, key: Keys.defaultAction) }
    }
    @Published private(set) var profilesByBrowserIdentifier: [String: [BrowserProfile]] = [:]
    @Published private(set) var profilePreferences: [String: BrowserProfilePreferences] {
        didSet { persist(profilePreferences, key: Keys.profilePreferences) }
    }

    private var browserOrder: [String] {
        didSet { defaults.set(browserOrder, forKey: Keys.browserOrder) }
    }
    private var disabledBrowserIdentifiers: Set<String> {
        didSet { defaults.set(Array(disabledBrowserIdentifiers), forKey: Keys.disabledBrowsers) }
    }

    private let defaults: UserDefaults
    private let browserService: BrowserService
    private let profileService: ChromiumProfileService
    private var lastUsedProfileDirectories: [String: String] = [:]

    private enum Keys {
        static let browserOrder = "browserOrder"
        static let disabledBrowsers = "disabledBrowsers"
        static let rules = "rules"
        static let defaultAction = "defaultAction"
        static let profilePreferences = "profilePreferences"
        static let hasCompletedFirstLaunch = "hasCompletedFirstLaunch"
    }

    init(
        defaults: UserDefaults = .standard,
        browserService: BrowserService,
        profileService: ChromiumProfileService = ChromiumProfileService()
    ) {
        self.defaults = defaults
        self.browserService = browserService
        self.profileService = profileService
        self.browserOrder = defaults.stringArray(forKey: Keys.browserOrder) ?? []
        self.disabledBrowserIdentifiers = Set(defaults.stringArray(forKey: Keys.disabledBrowsers) ?? [])
        self.rules = Self.decode([RoutingRule].self, from: defaults.data(forKey: Keys.rules)) ?? []
        self.defaultAction = Self.decode(
            RoutingAction.self,
            from: defaults.data(forKey: Keys.defaultAction)
        ) ?? .prompt
        self.profilePreferences = Self.decode(
            [String: BrowserProfilePreferences].self,
            from: defaults.data(forKey: Keys.profilePreferences)
        ) ?? [:]
        refreshBrowsers()
    }

    var enabledBrowsers: [Browser] {
        browsers.filter { !disabledBrowserIdentifiers.contains($0.id) }
    }

    var isFirstLaunch: Bool {
        !defaults.bool(forKey: Keys.hasCompletedFirstLaunch)
    }

    func completeFirstLaunch() {
        defaults.set(true, forKey: Keys.hasCompletedFirstLaunch)
    }

    func refreshBrowsers() {
        let discovered = browserService.discoverBrowsers(
            excludingBundleIdentifier: Bundle.main.bundleIdentifier
        )

        let identifiers = Set(discovered.map(\.id))
        var updatedOrder = browserOrder.filter { identifiers.contains($0) }
        for browser in discovered where !updatedOrder.contains(browser.id) {
            updatedOrder.append(browser.id)
        }
        if updatedOrder != browserOrder {
            browserOrder = updatedOrder
        }

        let position = Dictionary(uniqueKeysWithValues: browserOrder.enumerated().map { ($1, $0) })
        browsers = discovered.sorted {
            (position[$0.id] ?? .max) < (position[$1.id] ?? .max)
        }
        refreshProfiles()
    }

    func isBrowserEnabled(_ browser: Browser) -> Bool {
        !disabledBrowserIdentifiers.contains(browser.id)
    }

    func setBrowser(_ browser: Browser, enabled: Bool) {
        if enabled {
            disabledBrowserIdentifiers.remove(browser.id)
        } else {
            disabledBrowserIdentifiers.insert(browser.id)
        }
        objectWillChange.send()
    }

    func moveBrowsers(fromOffsets: IndexSet, toOffset: Int) {
        browsers.move(fromOffsets: fromOffsets, toOffset: toOffset)
        browserOrder = browsers.map(\.id)
    }

    func profiles(for browser: Browser) -> [BrowserProfile] {
        profilesByBrowserIdentifier[browser.id] ?? []
    }

    func enabledProfiles(for browser: Browser) -> [BrowserProfile] {
        let preferences = profilePreferences[browser.id] ?? BrowserProfilePreferences()
        return profiles(for: browser).filter {
            !preferences.disabledProfileDirectories.contains($0.directoryName)
        }
    }

    func lastUsedProfileDirectory(for browser: Browser) -> String? {
        lastUsedProfileDirectories[browser.id]
    }

    func isProfileManagementEnabled(for browser: Browser) -> Bool {
        profilePreferences[browser.id]?.isEnabled == true
    }

    func setProfileManagement(for browser: Browser, enabled: Bool) {
        var preferences = profilePreferences[browser.id] ?? BrowserProfilePreferences()
        preferences.isEnabled = enabled
        profilePreferences[browser.id] = preferences
    }

    func isProfileEnabled(_ profile: BrowserProfile, for browser: Browser) -> Bool {
        let preferences = profilePreferences[browser.id] ?? BrowserProfilePreferences()
        return !preferences.disabledProfileDirectories.contains(profile.directoryName)
    }

    func setProfile(_ profile: BrowserProfile, for browser: Browser, enabled: Bool) {
        var preferences = profilePreferences[browser.id] ?? BrowserProfilePreferences()
        if enabled {
            preferences.disabledProfileDirectories.remove(profile.directoryName)
        } else {
            preferences.disabledProfileDirectories.insert(profile.directoryName)
        }
        profilePreferences[browser.id] = preferences
    }

    func moveProfiles(for browser: Browser, fromOffsets: IndexSet, toOffset: Int) {
        var orderedProfiles = profiles(for: browser)
        orderedProfiles.move(fromOffsets: fromOffsets, toOffset: toOffset)
        var preferences = profilePreferences[browser.id] ?? BrowserProfilePreferences()
        preferences.profileOrder = orderedProfiles.map(\.directoryName)
        profilePreferences[browser.id] = preferences
        profilesByBrowserIdentifier[browser.id] = orderedProfiles
    }

    func upsert(_ rule: RoutingRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }
    }

    func deleteRule(id: UUID) {
        rules.removeAll { $0.id == id }
    }

    func moveRules(fromOffsets: IndexSet, toOffset: Int) {
        rules.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }

    private func refreshProfiles() {
        var discoveredByBrowser: [String: [BrowserProfile]] = [:]
        var discoveredLastUsedDirectories: [String: String] = [:]
        var updatedPreferences = profilePreferences

        for browser in browsers where browser.supportsProfiles {
            let snapshot = profileService.snapshot(for: browser)
            let discovered = snapshot.profiles
            if let lastUsedProfileDirectory = snapshot.lastUsedProfileDirectory {
                discoveredLastUsedDirectories[browser.id] = lastUsedProfileDirectory
            }
            let availableDirectories = Set(discovered.map(\.directoryName))
            var preferences = updatedPreferences[browser.id] ?? BrowserProfilePreferences()

            preferences.profileOrder = preferences.profileOrder.filter {
                availableDirectories.contains($0)
            }
            for profile in discovered where !preferences.profileOrder.contains(profile.directoryName) {
                preferences.profileOrder.append(profile.directoryName)
            }
            preferences.disabledProfileDirectories = preferences.disabledProfileDirectories
                .intersection(availableDirectories)

            let position = Dictionary(
                uniqueKeysWithValues: preferences.profileOrder.enumerated().map { ($1, $0) }
            )
            discoveredByBrowser[browser.id] = discovered.sorted {
                (position[$0.directoryName] ?? .max) < (position[$1.directoryName] ?? .max)
            }
            updatedPreferences[browser.id] = preferences
        }

        profilesByBrowserIdentifier = discoveredByBrowser
        lastUsedProfileDirectories = discoveredLastUsedDirectories
        if updatedPreferences != profilePreferences {
            profilePreferences = updatedPreferences
        }
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
