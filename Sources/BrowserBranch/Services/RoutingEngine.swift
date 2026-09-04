import Foundation

struct RoutingDecision: Equatable {
    let action: RoutingAction
    let matchingRuleID: UUID?
}

enum RoutingEngine {
    static func decision(
        for url: URL,
        rules: [RoutingRule],
        defaultAction: RoutingAction
    ) -> RoutingDecision {
        if let rule = rules.first(where: { $0.matches(url) }) {
            return RoutingDecision(action: rule.action, matchingRuleID: rule.id)
        }

        return RoutingDecision(action: defaultAction, matchingRuleID: nil)
    }
}
