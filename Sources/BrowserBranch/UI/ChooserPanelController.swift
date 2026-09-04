import AppKit
import SwiftUI

@MainActor
final class ChooserPanelController {
    private var panel: ChooserPanel?

    func show(url: URL, browsers: [Browser], onSelect: @escaping (Browser) -> Void) {
        panel?.close()

        let width = min(max(CGFloat(browsers.count) * 112 + 56, 360), 760)
        let size = NSSize(width: width, height: 196)
        let panel = makePanel(size: size)

        let rootView = ChooserView(
            url: url,
            browsers: browsers,
            onSelect: { [weak panel] browser in
                panel?.close()
                onSelect(browser)
            },
            onCancel: { [weak panel] in panel?.close() }
        )

        present(
            panel,
            size: size,
            rootView: rootView,
            onEscape: { [weak panel] in panel?.close() }
        )
    }

    func showProfiles(
        url: URL,
        browser: Browser,
        profiles: [BrowserProfile],
        onSelect: @escaping (BrowserProfile) -> Void,
        onBack: @escaping () -> Void
    ) {
        panel?.close()

        let width = min(max(CGFloat(profiles.count) * 112 + 56, 380), 760)
        let size = NSSize(width: width, height: 216)
        let panel = makePanel(size: size)
        let goBack = { [weak panel] in
            panel?.close()
            onBack()
        }
        let rootView = ProfileChooserView(
            url: url,
            browser: browser,
            profiles: profiles,
            onSelect: { [weak panel] profile in
                panel?.close()
                onSelect(profile)
            },
            onBack: goBack
        )

        present(panel, size: size, rootView: rootView, onEscape: goBack)
    }

    private func makePanel(size: NSSize) -> ChooserPanel {
        ChooserPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
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
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
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

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onEscape?()
            return
        }
        super.keyDown(with: event)
    }
}
