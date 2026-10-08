import SwiftUI

struct ProfileChooserView: View {
    let url: URL
    let browser: Browser
    let profiles: [BrowserProfile]
    let onSelect: (BrowserProfile) -> Void
    let onCopy: () -> Void
    let onBack: () -> Void

    @State private var hoveredProfileID: String?

    private var destinationLabel: String {
        url.host ?? url.absoluteString
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .background(Color.primary.opacity(0.08), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Choose a \(browser.name) profile")
                        .font(.system(size: 13, weight: .semibold))
                    Text(destinationLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("Esc · Back")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 10) {
                CopyLinkButton(height: 112, onCopy: onCopy)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                            profileChoice(profile, at: index)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThickMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.14))
                }
        }
        .onExitCommand(perform: onBack)
    }

    private func profileButton(_ profile: BrowserProfile, shortcut: Int?) -> some View {
        VStack(spacing: 7) {
            ZStack(alignment: .topTrailing) {
                ProfileAvatarView(
                    profile: profile,
                    browserIcon: browser.icon,
                    size: 48,
                    showsBrowserBadge: true
                )

                if let shortcut {
                    Text("\(shortcut)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color.accentColor))
                        .offset(x: 6, y: -6)
                }
            }

            Text(profile.name)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)

            if let email = profile.email {
                Text(email)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 94, height: 112)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(hoveredProfileID == profile.id ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.055))
        )
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func profileChoice(_ profile: BrowserProfile, at index: Int) -> some View {
        Button {
            onSelect(profile)
        } label: {
            profileButton(profile, shortcut: index < 9 ? index + 1 : nil)
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            hoveredProfileID = isHovering ? profile.id : nil
        }
    }
}
