import Foundation
import XCTest
@testable import BrowserBranch

final class ChromiumProfileServiceTests: XCTestCase {
    func testParsesProfilesUsingChromeOrderAndMetadata() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let avatarDirectory = root.appendingPathComponent("Profile 2", isDirectory: true)
        try FileManager.default.createDirectory(at: avatarDirectory, withIntermediateDirectories: true)
        let avatarURL = avatarDirectory.appendingPathComponent("Google Profile Picture.png")
        XCTAssertTrue(FileManager.default.createFile(atPath: avatarURL.path, contents: Data()))
        defer { try? FileManager.default.removeItem(at: root) }

        let data = try XCTUnwrap(
            """
            {
              "profile": {
                "last_used": "Profile 2",
                "profiles_order": ["Profile 2", "Default"],
                "info_cache": {
                  "Default": { "name": "Personal", "user_name": "personal@example.test" },
                  "Profile 2": {
                    "name": "Work",
                    "user_name": "work@example.test",
                    "gaia_picture_file_name": "Google Profile Picture.png"
                  }
                }
              }
            }
            """.data(using: .utf8)
        )

        let snapshot = ChromiumProfileService.parseSnapshot(
            from: data,
            browserIdentifier: "com.google.Chrome",
            userDataDirectory: root
        )
        let profiles = snapshot.profiles

        XCTAssertEqual(profiles.map(\.directoryName), ["Profile 2", "Default"])
        XCTAssertEqual(profiles.first?.name, "Work")
        XCTAssertEqual(profiles.first?.email, "work@example.test")
        XCTAssertEqual(profiles.first?.avatarImageURL, avatarURL)
        XCTAssertEqual(snapshot.lastUsedProfileDirectory, "Profile 2")
    }

    func testOldRoutingActionJSONRemainsCompatible() throws {
        let data = try XCTUnwrap(
            #"{"type":"browser","browserIdentifier":"com.google.Chrome"}"#.data(using: .utf8)
        )

        let action = try JSONDecoder().decode(RoutingAction.self, from: data)

        XCTAssertEqual(action.type, .browser)
        XCTAssertEqual(action.browserIdentifier, "com.google.Chrome")
        XCTAssertNil(action.profileDirectory)
    }

    @MainActor
    func testChromiumLaunchArgumentsKeepProfileAndURLSeparate() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/path?q=hello%20world"))

        let arguments = BrowserService.chromiumLaunchArguments(
            for: url,
            profileDirectory: "Profile 3"
        )

        XCTAssertEqual(
            arguments,
            [
                "--profile-directory=Profile 3",
                "--ignore-profile-directory-if-not-exists",
                "https://example.com/path?q=hello%20world"
            ]
        )
    }

    @MainActor
    func testLastUsedProfileCanUseFastSystemOpen() {
        XCTAssertFalse(
            BrowserService.requiresExplicitProfileLaunch(
                profileDirectory: "Profile 3",
                lastUsedProfileDirectory: "Profile 3"
            )
        )
        XCTAssertTrue(
            BrowserService.requiresExplicitProfileLaunch(
                profileDirectory: "Profile 3",
                lastUsedProfileDirectory: "Profile 2"
            )
        )
        XCTAssertTrue(
            BrowserService.requiresExplicitProfileLaunch(
                profileDirectory: "Profile 3",
                lastUsedProfileDirectory: nil
            )
        )
    }
}
