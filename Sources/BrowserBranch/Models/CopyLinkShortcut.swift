import AppKit

struct CopyLinkShortcut: Codable, Equatable {
    let key: String
    let modifiers: UInt

    static let relevantModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
    static let defaultShortcut = CopyLinkShortcut(key: "\\")

    init(key: String, modifiers: NSEvent.ModifierFlags = []) {
        self.key = key.lowercased()
        self.modifiers = modifiers.intersection(Self.relevantModifiers).rawValue
    }

    init?(event: NSEvent) {
        guard let key = event.charactersIgnoringModifiers else { return nil }
        self.init(key: key, modifiers: event.modifierFlags)
        guard isValid else { return nil }
    }

    var isValid: Bool {
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        guard key.count == 1,
              modifiers == flags.intersection(Self.relevantModifiers).rawValue,
              key.unicodeScalars.allSatisfy({
                  !CharacterSet.whitespacesAndNewlines.contains($0)
                      && !CharacterSet.controlCharacters.contains($0)
                      && !CharacterSet(charactersIn: "\u{F700}"..."\u{F8FF}").contains($0)
              })
        else { return false }

        // These keys already select browsers and profiles, including with Shift.
        if let number = Int(key), (1...9).contains(number),
           flags.intersection([.command, .control, .option]).isEmpty {
            return false
        }
        return true
    }

    var displayLabel: String {
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        return (flags.contains(.control) ? "⌃" : "")
            + (flags.contains(.option) ? "⌥" : "")
            + (flags.contains(.shift) ? "⇧" : "")
            + (flags.contains(.command) ? "⌘" : "")
            + key.uppercased()
    }

    func matches(_ event: NSEvent) -> Bool {
        Self(event: event) == self
    }
}
