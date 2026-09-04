import AppKit
import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case rules = "Rules"
    case about = "About"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .rules: "arrow.triangle.branch"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject var browserService: BrowserService
    @State private var selection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.symbol)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 220)
        } detail: {
            switch selection ?? .general {
            case .general:
                GeneralSettingsView(store: store, browserService: browserService)
            case .rules:
                RulesSettingsView(store: store)
            case .about:
                AboutView()
            }
        }
        .tint(Color(red: 0.42, green: 0.28, blue: 0.95))
    }
}

private struct GeneralSettingsView: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject var browserService: BrowserService
    @State private var profileBrowser: Browser?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsHeader("General", subtitle: "Choose how links are routed on this Mac.")

            HStack(spacing: 14) {
                Image(systemName: browserService.isDefaultBrowser ? "checkmark.seal.fill" : "circle.dashed")
                    .font(.system(size: 30))
                    .foregroundStyle(browserService.isDefaultBrowser ? .green : .secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(browserService.isDefaultBrowser ? "BrowserBranch is your default browser" : "BrowserBranch is not the default yet")
                        .font(.headline)
                    Text("macOS sends web links here first, then BrowserBranch applies your rules.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !browserService.isDefaultBrowser {
                    Button("Make Default") {
                        browserService.makeDefault()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(16)
            .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            if let message = browserService.statusMessage {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("When no rule matches")
                    .font(.headline)

                Picker("Default action", selection: $store.defaultAction.type) {
                    Text(RoutingActionType.prompt.title).tag(RoutingActionType.prompt)
                    Text(RoutingActionType.favorite.title).tag(RoutingActionType.favorite)
                    Text(RoutingActionType.bestRunning.title).tag(RoutingActionType.bestRunning)
                }
                .labelsHidden()
                .frame(maxWidth: 280)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Browsers")
                        .font(.headline)
                    Spacer()
                    Text("Drag to set preference")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if store.browsers.isEmpty {
                    ContentUnavailableView(
                        "No browsers found",
                        systemImage: "safari",
                        description: Text("Install a browser that can open HTTPS links, then reopen settings.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(minHeight: 260)
                    .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
                } else {
                    List {
                        ForEach(store.browsers) { browser in
                            BrowserSettingsRow(
                                browser: browser,
                                profileCount: store.profiles(for: browser).count,
                                isProfileManagementEnabled: store.isProfileManagementEnabled(for: browser),
                                isEnabled: Binding(
                                    get: { store.isBrowserEnabled(browser) },
                                    set: { store.setBrowser(browser, enabled: $0) }
                                ),
                                onConfigureProfiles: { profileBrowser = browser }
                            )
                        }
                        .onMove(perform: store.moveBrowsers)
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: false))
                    .frame(minHeight: 260)
                }
            }
        }
        .padding(28)
        .sheet(item: $profileBrowser) { browser in
            BrowserProfilesSettingsView(store: store, browser: browser) {
                profileBrowser = nil
            }
        }
    }
}

private struct BrowserSettingsRow: View {
    let browser: Browser
    let profileCount: Int
    let isProfileManagementEnabled: Bool
    @Binding var isEnabled: Bool
    let onConfigureProfiles: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: browser.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(browser.name)
                    .fontWeight(.medium)
                Text(browser.isRunning ? "Running" : browser.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(browser.isRunning ? .green : .secondary)
            }
            Spacer()
            if browser.supportsProfiles {
                Button(action: onConfigureProfiles) {
                    Label(
                        profileCount == 1 ? "1 Profile" : "\(profileCount) Profiles",
                        systemImage: isProfileManagementEnabled ? "person.2.fill" : "person.2"
                    )
                }
                .buttonStyle(.borderless)
                .help("Configure \(browser.name) profiles")
            }
            Toggle("Use", isOn: $isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

private struct BrowserProfilesSettingsView: View {
    @ObservedObject var store: SettingsStore
    let browser: Browser
    let onDone: () -> Void

    private var profiles: [BrowserProfile] {
        store.profiles(for: browser)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(nsImage: browser.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(browser.name) Profiles")
                        .font(.title2.bold())
                    Text("Choose which profiles appear and the order of their shortcuts.")
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(
                "Choose a profile after selecting \(browser.name)",
                isOn: Binding(
                    get: { store.isProfileManagementEnabled(for: browser) },
                    set: { store.setProfileManagement(for: browser, enabled: $0) }
                )
            )
            .toggleStyle(.switch)
            .disabled(profiles.isEmpty)

            if profiles.isEmpty {
                ContentUnavailableView(
                    "No profiles found",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("Open \(browser.name) once and create a profile, then reopen these settings.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
            } else {
                List {
                    ForEach(profiles) { profile in
                        HStack(spacing: 12) {
                            ProfileAvatarView(
                                profile: profile,
                                browserIcon: browser.icon,
                                size: 36
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name)
                                    .fontWeight(.medium)
                                Text(profile.email ?? profile.directoryName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Toggle(
                                "Use",
                                isOn: Binding(
                                    get: { store.isProfileEnabled(profile, for: browser) },
                                    set: { store.setProfile(profile, for: browser, enabled: $0) }
                                )
                            )
                            .toggleStyle(.switch)
                            .labelsHidden()
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove { offsets, destination in
                        store.moveProfiles(
                            for: browser,
                            fromOffsets: offsets,
                            toOffset: destination
                        )
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: false))
            }

            HStack {
                Label("Drag profiles to assign shortcuts 1…N.", systemImage: "command")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Done", action: onDone)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 560, height: 520)
    }
}

private struct RulesSettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var editingRule: RoutingRule?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                settingsHeader("Rules", subtitle: "The first matching rule decides where a link opens.")
                Spacer()
                Button {
                    editingRule = RoutingRule(
                        name: "",
                        matchKind: .hostSuffix,
                        pattern: "",
                        action: .prompt
                    )
                } label: {
                    Label("Add Rule", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            if store.rules.isEmpty {
                ContentUnavailableView(
                    "No rules yet",
                    systemImage: "arrow.triangle.branch",
                    description: Text("Add a rule to route work, personal, or local links automatically.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
            } else {
                List {
                    ForEach($store.rules) { $rule in
                        HStack(spacing: 12) {
                            Toggle("Enabled", isOn: $rule.isEnabled)
                                .labelsHidden()

                            VStack(alignment: .leading, spacing: 3) {
                                Text(rule.name.isEmpty ? "Untitled rule" : rule.name)
                                    .fontWeight(.semibold)
                                Text(ruleDescription(rule))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Edit") { editingRule = rule }
                                .buttonStyle(.borderless)
                            Button(role: .destructive) {
                                store.deleteRule(id: rule.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 6)
                    }
                    .onMove(perform: store.moveRules)
                }
                .listStyle(.inset(alternatesRowBackgrounds: false))
            }
        }
        .padding(28)
        .sheet(item: $editingRule) { rule in
            RuleEditorView(rule: rule, store: store) { savedRule in
                store.upsert(savedRule)
                editingRule = nil
            } onCancel: {
                editingRule = nil
            }
        }
    }

    private func ruleDescription(_ rule: RoutingRule) -> String {
        let action: String
        switch rule.action.type {
        case .prompt:
            action = "ask"
        case .favorite:
            action = "favorite browser"
        case .bestRunning:
            action = "best running browser"
        case .browser:
            guard let browser = store.browsers.first(where: { $0.id == rule.action.browserIdentifier }) else {
                action = "missing browser"
                break
            }

            if
                let directory = rule.action.profileDirectory,
                let profile = store.profiles(for: browser).first(where: { $0.directoryName == directory })
            {
                action = "\(browser.name) › \(profile.name)"
            } else if store.isProfileManagementEnabled(for: browser) {
                action = "\(browser.name) › ask profile"
            } else {
                action = browser.name
            }
        }
        return "\(rule.matchKind.title) “\(rule.pattern)”  →  \(action)"
    }
}

private struct RuleEditorView: View {
    @State private var rule: RoutingRule
    @ObservedObject var store: SettingsStore
    let onSave: (RoutingRule) -> Void
    let onCancel: () -> Void

    init(
        rule: RoutingRule,
        store: SettingsStore,
        onSave: @escaping (RoutingRule) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _rule = State(initialValue: rule)
        self.store = store
        self.onSave = onSave
        self.onCancel = onCancel
    }

    private var canSave: Bool {
        !rule.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !rule.pattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (rule.action.type != .browser || rule.action.browserIdentifier != nil)
    }

    private var selectedBrowser: Browser? {
        store.enabledBrowsers.first { $0.id == rule.action.browserIdentifier }
    }

    private var selectedBrowserProfiles: [BrowserProfile] {
        guard
            let selectedBrowser,
            store.isProfileManagementEnabled(for: selectedBrowser)
        else {
            return []
        }
        return store.enabledProfiles(for: selectedBrowser)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(rule.name.isEmpty ? "New Rule" : "Edit Rule")
                .font(.title2.bold())

            Form {
                TextField("Name", text: $rule.name, prompt: Text("Work links"))

                Picker("Match", selection: $rule.matchKind) {
                    ForEach(URLMatchKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }

                TextField("Value", text: $rule.pattern, prompt: Text("example.com"))

                Picker("Then", selection: $rule.action.type) {
                    ForEach(RoutingActionType.allCases) { action in
                        Text(action.title).tag(action)
                    }
                }

                if rule.action.type == .browser {
                    Picker(
                        "Browser",
                        selection: Binding(
                            get: { rule.action.browserIdentifier },
                            set: { identifier in
                                rule.action.browserIdentifier = identifier
                                rule.action.profileDirectory = nil
                            }
                        )
                    ) {
                        Text("Choose a browser").tag(String?.none)
                        ForEach(store.enabledBrowsers) { browser in
                            Text(browser.name).tag(String?.some(browser.id))
                        }
                    }

                    if !selectedBrowserProfiles.isEmpty {
                        Picker("Profile", selection: $rule.action.profileDirectory) {
                            Text("Ask every time").tag(String?.none)
                            ForEach(selectedBrowserProfiles) { profile in
                                Text(profile.name).tag(String?.some(profile.directoryName))
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Save") { onSave(rule) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}

private struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsHeader("About", subtitle: "An open-source browser chooser for macOS.")

            HStack(spacing: 18) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 82)

                VStack(alignment: .leading, spacing: 5) {
                    Text("BrowserBranch")
                        .font(.title.bold())
                    Text("Version 0.1.1")
                        .foregroundStyle(.secondary)
                    Text("MIT License")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Text("Send every link to the right browser and profile. BrowserBranch is open source and keeps its settings locally on your Mac.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: 520, alignment: .leading)

            Spacer()
        }
        .padding(28)
    }
}

@ViewBuilder
private func settingsHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
            .font(.largeTitle.bold())
        Text(subtitle)
            .font(.body)
            .foregroundStyle(.secondary)
    }
}
