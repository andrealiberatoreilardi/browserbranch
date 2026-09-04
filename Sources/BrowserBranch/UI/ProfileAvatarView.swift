import AppKit
import SwiftUI

struct ProfileAvatarView: View {
    let profile: BrowserProfile
    let browserIcon: NSImage
    var size: CGFloat = 44
    var showsBrowserBadge = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let avatar = profile.avatarImage {
                    Image(nsImage: avatar)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Text(initials)
                                .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay {
                Circle().strokeBorder(.white.opacity(0.2), lineWidth: 1)
            }

            if showsBrowserBadge {
                Image(nsImage: browserIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.38, height: size * 0.38)
                    .padding(2)
                    .background(.regularMaterial, in: Circle())
                    .offset(x: 3, y: 3)
            }
        }
        .frame(width: size + (showsBrowserBadge ? 4 : 0), height: size + (showsBrowserBadge ? 4 : 0))
    }

    private var initials: String {
        let words = profile.name.split(separator: " ")
        let characters = words.prefix(2).compactMap(\.first)
        return characters.isEmpty ? "?" : String(characters).uppercased()
    }
}
