import Foundation

enum URLMatchKind: String, Codable, CaseIterable, Identifiable {
    case hostEquals
    case hostSuffix
    case urlContains
    case regularExpression

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hostEquals: "Host is exactly"
        case .hostSuffix: "Host is or ends with"
        case .urlContains: "URL contains"
        case .regularExpression: "URL matches regex"
        }
    }
}

enum RoutingActionType: String, Codable, CaseIterable, Identifiable {
    case prompt
    case favorite
    case bestRunning
    case browser

    var id: String { rawValue }

    var title: String {
        switch self {
        case .prompt: "Ask me"
        case .favorite: "Use favorite browser"
        case .bestRunning: "Use best running browser"
        case .browser: "Use a specific browser"
        }
    }
}

struct RoutingAction: Codable, Equatable {
    var type: RoutingActionType
    var browserIdentifier: String?
    var profileDirectory: String? = nil

    static let prompt = RoutingAction(type: .prompt, browserIdentifier: nil)
}

struct RoutingRule: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var isEnabled: Bool
    var matchKind: URLMatchKind
    var pattern: String
    var action: RoutingAction

    init(
        id: UUID = UUID(),
        name: String,
        isEnabled: Bool = true,
        matchKind: URLMatchKind,
        pattern: String,
        action: RoutingAction
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.matchKind = matchKind
        self.pattern = pattern
        self.action = action
    }

    func matches(_ url: URL) -> Bool {
        guard isEnabled else { return false }

        let candidate = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else { return false }

        switch matchKind {
        case .hostEquals:
            return normalizedHost(url.host) == normalizedHost(candidate)
        case .hostSuffix:
            guard let host = normalizedHost(url.host) else { return false }
            guard let suffix = normalizedHost(candidate) else { return false }
            return host == suffix || host.hasSuffix("." + suffix)
        case .urlContains:
            return url.absoluteString.localizedCaseInsensitiveContains(candidate)
        case .regularExpression:
            return url.absoluteString.range(of: candidate, options: .regularExpression) != nil
        }
    }

    private func normalizedHost(_ value: String?) -> String? {
        guard var value else { return nil }
        value = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if let parsedHost = URL(string: value.contains("://") ? value : "https://\(value)")?.host {
            value = parsedHost.lowercased()
        }

        while value.hasPrefix(".") { value.removeFirst() }
        while value.hasSuffix(".") { value.removeLast() }
        return value.isEmpty ? nil : value
    }
}
