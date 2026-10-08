<p align="center">
  <img src="Assets/BrowserBranchIcon.png" width="128" alt="BrowserBranch app icon">
</p>

<h1 align="center">BrowserBranch</h1>

<p align="center">
  Send every link to the right browser and profile.
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-black" alt="macOS 14 or newer">
</p>

BrowserBranch is a native, open-source link router for macOS. Make it your
default browser, then choose where each link opens—or let a rule decide for
you. Route work and personal links to different browsers, select a Chromium
profile, and keep the whole workflow on your Mac.

## Highlights

- Choose a browser with a single number key.
- Copy the full link from either picker with the **Copia link** button or a
  configurable shortcut (default: `\`). Change it in **General → Copia link**;
  single keys and modifier combinations are supported, while `1`–`9` stay
  reserved for browser selection.
- Continue the same shortcut flow to select a Chromium profile.
- Create first-match rules for exact hosts, domain suffixes, text, or regular
  expressions.
- Send a rule to a specific browser and profile, your favorite browser, the
  best currently running browser, or the chooser.
- Reorder browsers, disable the ones you do not use, and see which are already
  running.
- Use real Chrome, Edge, Brave, Vivaldi, and Chromium profile avatars when
  available.
- Stay out of the way with a lightweight menu bar app and a native macOS UI.

## Privacy

BrowserBranch is local-first. It has no account system, analytics, telemetry,
or remote service. Rules and preferences are stored locally with macOS
`UserDefaults`; detected browser profiles never leave your Mac.

## Requirements

- macOS 14 Sonoma or newer
- Xcode 16 or newer to build from source

## Build from source

Clone the repository and build the app bundle:

```sh
git clone https://github.com/andrealiberatoreilardi/browserbranch.git
cd browserbranch
make test
make app
open .build/BrowserBranch.app
```

The generated app is ad-hoc signed for local development. To keep it installed,
copy `.build/BrowserBranch.app` to `/Applications`, launch it, and choose
**Make BrowserBranch Default** from the menu bar icon.

Useful development commands:

```sh
make build   # Compile the Swift package
make test    # Run the test suite
make icon    # Regenerate the .icns asset from the source PNG
make app     # Build and ad-hoc sign BrowserBranch.app
make run     # Build and launch the app
```

## How routing works

Rules are evaluated from top to bottom and the first match wins. If no rule
matches, BrowserBranch uses the fallback selected in General settings.

| Match type | Example | Matches |
| --- | --- | --- |
| Exact host | `calendar.google.com` | Only that hostname |
| Domain suffix | `example.com` | `example.com` and its subdomains |
| Contains | `/meet/` | Any URL containing that text |
| Regular expression | `^https://github\\.com/.+/issues` | Matching URLs |

When profile management is enabled for a Chromium browser, choosing that
browser opens a second picker. Number shortcuts start again at `1`, so the
entire selection can be made without leaving the keyboard.

## URL scheme

Other apps and scripts can show the chooser through the `browserbranch` URL
scheme:

```sh
open 'browserbranch://open?url=https%3A%2F%2Fexample.com'
```

Only `http` and `https` destination URLs are accepted.

## Project structure

- `Sources/BrowserBranch` — app lifecycle, routing, services, and SwiftUI views
- `Tests/BrowserBranchTests` — routing and Chromium profile tests
- `Assets` — editable source artwork
- `Support` — app metadata, icon bundle, and startup agent template
- `scripts` — reproducible icon and `.app` build scripts

## Contributing

Issues and pull requests are welcome. Please keep routing decisions independent
from UI code and add tests when introducing new matching or action behavior.

## License

BrowserBranch is available under the [MIT License](LICENSE).
