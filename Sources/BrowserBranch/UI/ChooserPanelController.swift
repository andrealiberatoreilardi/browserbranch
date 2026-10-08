import AppKit
import SwiftUI

@MainActor
final class ChooserPanelController {
    private var panel: ChooserPanel?

    func show(url: URL, browsers: [Browser], onSelect: @escaping (Browser) -> Void) {
        retire(panel)

        let width = min(max(CGFloat(browsers.count + 1) * 112 + 56, 360), 760)
        let size = NSSize(width: width, height: 196)
        let panel = makePanel(size: size, url: url)
        panel.onNumberKey = { [weak self, weak panel] index in
            guard browsers.indices.contains(index) else { return }
            self?.retire(panel) {
                onSelect(browsers[index])
            }
        }

        let rootView = ChooserView(
            url: url,
            browsers: browsers,
            onSelect: { [weak self, weak panel] browser in
                self?.retire(panel) {
                    onSelect(browser)
                }
            },
            onCopy: { [weak panel] in
                panel?.onCopy?()
            },
            onCancel: { [weak self, weak panel] in
                self?.retire(panel)
            }
        )

        present(
            panel,
            size: size,
            rootView: rootView,
            onEscape: { [weak self, weak panel] in
                self?.retire(panel)
            }
        )
    }

    func showProfiles(
        url: URL,
        browser: Browser,
        profiles: [BrowserProfile],
        onSelect: @escaping (BrowserProfile) -> Void,
        onBack: @escaping () -> Void
    ) {
        retire(panel)

        let width = min(max(CGFloat(profiles.count + 1) * 112 + 56, 380), 760)
        let size = NSSize(width: width, height: 216)
        let panel = makePanel(size: size, url: url)
        panel.onNumberKey = { [weak self, weak panel] index in
            guard profiles.indices.contains(index) else { return }
            self?.retire(panel) {
                onSelect(profiles[index])
            }
        }
        let goBack: () -> Void = { [weak self, weak panel] in
            guard let self else { return }
            self.retire(panel, then: onBack)
        }
        let rootView = ProfileChooserView(
            url: url,
            browser: browser,
            profiles: profiles,
            onSelect: { [weak self, weak panel] profile in
                self?.retire(panel) {
                    onSelect(profile)
                }
            },
            onCopy: { [weak panel] in
                panel?.onCopy?()
            },
            onBack: goBack
        )

        present(panel, size: size, rootView: rootView, onEscape: goBack)
    }

    private func retire(_ panel: ChooserPanel?, then action: (() -> Void)? = nil) {
        guard let panel else {
            action?()
            return
        }

        panel.orderOut(nil)
        if self.panel === panel {
            self.panel = nil
        }
        action?()

        DispatchQueue.main.async {
            panel.close()
        }
    }

    private func makePanel(size: NSSize, url: URL) -> ChooserPanel {
        let panel = ChooserPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.onCopy = { [weak self, weak panel] in
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            guard pasteboard.setString(url.absoluteString, forType: .string) else {
                NSSound.beep()
                return
            }
            self?.retire(panel)
        }
        return panel
    }

    private func present<Content: View>(
        _ panel: ChooserPanel,
        size: NSSize,
        rootView: Content,
        onEscape: @escaping () -> Void
    ) {
        panel.contentViewController = NSHostingController(rootView: rootView)
        panel.setContentSize(size)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = true
        panel.collectionBehavior = [.transient, .moveToActiveSpace]
        panel.isReleasedWhenClosed = false
        panel.onEscape = onEscape
        position(panel)

        self.panel = panel
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    private func position(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else {
            panel.center()
            return
        }

        var origin = NSPoint(
            x: mouse.x - panel.frame.width / 2,
            y: mouse.y - panel.frame.height - 18
        )
        origin.x = min(max(origin.x, visibleFrame.minX + 12), visibleFrame.maxX - panel.frame.width - 12)
        origin.y = min(max(origin.y, visibleFrame.minY + 12), visibleFrame.maxY - panel.frame.height - 12)
        panel.setFrameOrigin(origin)
    }
}

private final class ChooserPanel: NSPanel {
    var onEscape: (() -> Void)?
    var onNumberKey: ((Int) -> Void)?
    var onCopy: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onEscape?()
            return
        }

        let blockedModifiers: NSEvent.ModifierFlags = [.command, .control, .option]
        if
            event.modifierFlags.intersection(blockedModifiers).isEmpty,
            let characters = event.charactersIgnoringModifiers
        {
            if characters == "\\" {
                onCopy?()
                return
            }
            if let number = Int(characters), (1...9).contains(number) {
                onNumberKey?(number - 1)
                return
            }
        }

        super.keyDown(with: event)
    }
}
