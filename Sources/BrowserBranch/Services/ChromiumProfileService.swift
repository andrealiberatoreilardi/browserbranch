import Foundation

struct ChromiumProfileService {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func profiles(for browser: Browser) -> [BrowserProfile] {
        guard let userDataDirectory = browser.profileDataDirectory else { return [] }
        let localStateURL = userDataDirectory.appendingPathComponent("Local State")
        guard let data = try? Data(contentsOf: localStateURL) else { return [] }

        return Self.parseProfiles(
            from: data,
            browserIdentifier: browser.id,
            userDataDirectory: userDataDirectory,
            fileManager: fileManager
        )
    }

    static func parseProfiles(
        from data: Data,
        browserIdentifier: String,
        userDataDirectory: URL,
        fileManager: FileManager = .default
    ) -> [BrowserProfile] {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let profile = root["profile"] as? [String: Any],
            let infoCache = profile["info_cache"] as? [String: [String: Any]]
        else {
            return []
        }

        let configuredOrder = profile["profiles_order"] as? [String] ?? []
        let order = Dictionary(uniqueKeysWithValues: configuredOrder.enumerated().map { ($1, $0) })

        return infoCache.compactMap { directoryName, metadata -> BrowserProfile? in
            guard
                !directoryName.isEmpty,
                URL(fileURLWithPath: directoryName).lastPathComponent == directoryName
            else {
                return nil
            }

            let rawName = metadata["name"] as? String
            let name = rawName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let displayName = name.flatMap { $0.isEmpty ? nil : $0 } ?? directoryName
            let rawEmail = metadata["user_name"] as? String
            let email = rawEmail?.trimmingCharacters(in: .whitespacesAndNewlines)
            let profileDirectory = userDataDirectory.appendingPathComponent(
                directoryName,
                isDirectory: true
            )

            return BrowserProfile(
                browserIdentifier: browserIdentifier,
                directoryName: directoryName,
                name: displayName,
                email: email?.isEmpty == false ? email : nil,
                avatarImageURL: avatarURL(
                    metadata: metadata,
                    profileDirectory: profileDirectory,
                    fileManager: fileManager
                )
            )
        }
        .sorted { lhs, rhs in
            let leftPosition = order[lhs.directoryName] ?? .max
            let rightPosition = order[rhs.directoryName] ?? .max
            if leftPosition != rightPosition { return leftPosition < rightPosition }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    private static func avatarURL(
        metadata: [String: Any],
        profileDirectory: URL,
        fileManager: FileManager
    ) -> URL? {
        let configuredName = (metadata["gaia_picture_file_name"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = [configuredName, "Google Profile Picture.png", "Avatar.png"]
            .compactMap { $0 }
            .filter { !$0.isEmpty && URL(fileURLWithPath: $0).lastPathComponent == $0 }

        return candidates
            .map { profileDirectory.appendingPathComponent($0) }
            .first { fileManager.fileExists(atPath: $0.path) }
    }
}
