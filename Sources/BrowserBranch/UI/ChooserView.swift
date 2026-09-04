import SwiftUI

struct ChooserView: View {
    let url: URL
    let browsers: [Browser]
    let onSelect: (Browser) -> Void
    let onCancel: () -> Void

    @State private var hoveredBrowserID: String?

    private var destinationLabel: String {
        url.host ?? url.absoluteString
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Open link with")
                        .font(.system(size: 13, weight: .semibold))
                    Text(destinationLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("Esc")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(browsers.enumerated()), id: \.element.id) { index, browser in
                        browserChoice(browser, at: index)
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
        .onExitCommand(perform: onCancel)
    }

    private func browserButton(_ browser: Browser, shortcut: Int?) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(nsImage: browser.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .opacity(browser.isRunning ? 1 : 0.72)

                if let shortcut {
                    Text("\(shortcut)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color.accentColor))
                        .offset(x: 6, y: -6)
                }
            }

            HStack(spacing: 5) {
                Circle()
                    .fill(browser.isRunning ? Color.green : Color.secondary.opacity(0.35))
                    .frame(width: 6, height: 6)
                Text(browser.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
        }
        .frame(width: 90, height: 98)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(hoveredBrowserID == browser.id ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.055))
        )
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func browserChoice(_ browser: Browser, at index: Int) -> some View {
        let button = Button {
            onSelect(browser)
        } label: {
            browserButton(browser, shortcut: index < 9 ? index + 1 : nil)
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            hoveredBrowserID = isHovering ? browser.id : nil
        }

        if index < 9 {
            button.keyboardShortcut(shortcut(for: index), modifiers: [])
        } else {
            button
        }
    }

    private func shortcut(for index: Int) -> KeyEquivalent {
        guard index < 9, let character = "\(index + 1)".first else { return KeyEquivalent("0") }
        return KeyEquivalent(character)
    }
}
