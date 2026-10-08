import AppKit
import Testing
@testable import BrowserBranch

struct CopyLinkShortcutTests {
    @Test func reservesBrowserNumbersAndNavigationKeys() throws {
        for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "\u{1B}", "\r", "\t", "\u{F700}"] {
            #expect(CopyLinkShortcut(event: try event(key)) == nil)
        }
        #expect(CopyLinkShortcut(event: try event("1", modifiers: .shift)) == nil)
        #expect(CopyLinkShortcut(event: try event("1", modifiers: .command)) != nil)
        #expect(CopyLinkShortcut(event: try event("c")) != nil)
    }

    @Test func requiresExactModifiersAndIgnoresCapsLock() throws {
        let shortcut = CopyLinkShortcut(key: "c", modifiers: [.command, .option])
        #expect(shortcut.matches(try event("C", modifiers: [.command, .option, .capsLock])))
        #expect(!shortcut.matches(try event("c", modifiers: .command)))
        #expect(!shortcut.matches(try event("c", modifiers: [.command, .option, .shift])))
        #expect(!shortcut.matches(try event("v", modifiers: [.command, .option])))
        #expect(CopyLinkShortcut.defaultShortcut.matches(try event("\\")))
        #expect(!CopyLinkShortcut.defaultShortcut.matches(try event("\\", modifiers: .command)))
    }

    @MainActor @Test func persistsShortcutAndFallsBackForInvalidPreferences() throws {
        let suite = "BrowserBranchShortcutTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = BrowserService()
        let store = SettingsStore(defaults: defaults, browserService: service)
        #expect(store.copyLinkShortcut == .defaultShortcut)

        let shortcut = CopyLinkShortcut(key: "c", modifiers: .command)
        store.copyLinkShortcut = shortcut
        let reloaded = SettingsStore(defaults: defaults, browserService: service)
        #expect(reloaded.copyLinkShortcut == shortcut)

        defaults.set(try JSONEncoder().encode(CopyLinkShortcut(key: "1")), forKey: "copyLinkShortcut")
        let invalid = SettingsStore(defaults: defaults, browserService: service)
        #expect(invalid.copyLinkShortcut == .defaultShortcut)
    }

    private func event(_ key: String, modifiers: NSEvent.ModifierFlags = []) throws -> NSEvent {
        try #require(NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: key,
            charactersIgnoringModifiers: key,
            isARepeat: false,
            keyCode: 0
        ))
    }
}
