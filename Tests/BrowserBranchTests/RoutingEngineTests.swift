import Foundation
import XCTest
@testable import BrowserBranch

final class RoutingEngineTests: XCTestCase {
    func testExactHostIgnoresCaseAndAcceptsHostInput() throws {
        let rule = makeRule(kind: .hostEquals, pattern: "GitHub.COM")
        let url = try XCTUnwrap(URL(string: "https://github.com/openai"))

        XCTAssertTrue(rule.matches(url))
    }

    func testHostSuffixMatchesSubdomainsButNotLookalikes() throws {
        let rule = makeRule(kind: .hostSuffix, pattern: "example.com")

        XCTAssertTrue(rule.matches(try XCTUnwrap(URL(string: "https://docs.example.com/page"))))
        XCTAssertTrue(rule.matches(try XCTUnwrap(URL(string: "https://example.com/page"))))
        XCTAssertFalse(rule.matches(try XCTUnwrap(URL(string: "https://notexample.com/page"))))
    }

    func testFirstMatchingEnabledRuleWins() throws {
        let first = makeRule(
            name: "First",
            kind: .urlContains,
            pattern: "docs",
            action: RoutingAction(type: .favorite, browserIdentifier: nil)
        )
        let second = makeRule(
            name: "Second",
            kind: .hostSuffix,
            pattern: "example.com",
            action: RoutingAction(type: .bestRunning, browserIdentifier: nil)
        )
        let url = try XCTUnwrap(URL(string: "https://docs.example.com"))

        let decision = RoutingEngine.decision(
            for: url,
            rules: [first, second],
            defaultAction: .prompt
        )

        XCTAssertEqual(decision.matchingRuleID, first.id)
        XCTAssertEqual(decision.action.type, .favorite)
    }

    func testDefaultActionWhenNothingMatches() throws {
        let url = try XCTUnwrap(URL(string: "https://example.net"))
        let fallback = RoutingAction(type: .bestRunning, browserIdentifier: nil)

        let decision = RoutingEngine.decision(
            for: url,
            rules: [makeRule(kind: .hostEquals, pattern: "example.com")],
            defaultAction: fallback
        )

        XCTAssertNil(decision.matchingRuleID)
        XCTAssertEqual(decision.action, fallback)
    }

    func testInvalidRegexDoesNotMatch() throws {
        let rule = makeRule(kind: .regularExpression, pattern: "[")
        let url = try XCTUnwrap(URL(string: "https://example.com"))

        XCTAssertFalse(rule.matches(url))
    }

    private func makeRule(
        name: String = "Test",
        kind: URLMatchKind,
        pattern: String,
        action: RoutingAction = .prompt
    ) -> RoutingRule {
        RoutingRule(name: name, matchKind: kind, pattern: pattern, action: action)
    }
}
