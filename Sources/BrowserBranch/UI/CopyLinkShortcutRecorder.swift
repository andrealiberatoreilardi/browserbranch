import AppKit
import SwiftUI

struct CopyLinkShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: CopyLinkShortcut
    @Binding var validationMessage: String?

    func makeNSView(context: Context) -> ShortcutRecordingButton {
        let button = ShortcutRecordingButton()
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        button.font = .systemFont(ofSize: 13, weight: .medium)
        button.target = button
        button.action = #selector(ShortcutRecordingButton.beginRecording)
        button.setAccessibilityLabel("Scorciatoia Copia link")
        return button
    }

    func updateNSView(_ button: ShortcutRecordingButton, context: Context) {
        button.shortcut = shortcut
        button.onRecord = { shortcut = $0 }
        button.onValidation = { validationMessage = $0 }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: ShortcutRecordingButton, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 150, height: 28)
    }

    static func dismantleNSView(_ button: ShortcutRecordingButton, coordinator: ()) {
        button.stopRecording()
    }
}

final class ShortcutRecordingButton: NSButton {
    var shortcut = CopyLinkShortcut.defaultShortcut {
        didSet { updateTitle() }
    }
    var onRecord: ((CopyLinkShortcut) -> Void)?
    var onValidation: ((String?) -> Void)?
    private var eventMonitor: Any?
    private var resignKeyObserver: NSObjectProtocol?

    override var acceptsFirstResponder: Bool { true }

    @objc func beginRecording() {
        if eventMonitor != nil {
            stopRecording()
            return
        }
        window?.makeFirstResponder(self)
        onValidation?(nil)
        resignKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.stopRecording()
        }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, self.window?.isKeyWindow == true else { return event }
            if event.type != .keyDown {
                if event.window !== self.window || !self.bounds.contains(self.convert(event.locationInWindow, from: nil)) {
                    self.stopRecording()
                }
                return event
            }
            if event.keyCode == 53 {
                self.stopRecording()
                self.onValidation?(nil)
                return nil
            }
            if event.keyCode == 48 {
                self.stopRecording()
                return event
            }
            guard let shortcut = CopyLinkShortcut(event: event) else {
                self.onValidation?("Use a letter or symbol, optionally with modifiers. Keys 1–9 are reserved for browsers.")
                return nil
            }
            self.stopRecording()
            self.onValidation?(nil)
            self.onRecord?(shortcut)
            return nil
        }
        updateTitle()
    }

    func stopRecording() {
        if let resignKeyObserver {
            NotificationCenter.default.removeObserver(resignKeyObserver)
            self.resignKeyObserver = nil
        }
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        updateTitle()
    }

    override func resignFirstResponder() -> Bool {
        stopRecording()
        return super.resignFirstResponder()
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil { stopRecording() }
        super.viewWillMove(toWindow: newWindow)
    }

    private func updateTitle() {
        let newTitle = eventMonitor == nil ? shortcut.displayLabel : "Press shortcut…"
        if title != newTitle {
            title = newTitle
            setAccessibilityValue(newTitle)
        }
    }
}
