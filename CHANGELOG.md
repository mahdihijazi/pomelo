# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-09-23

### Added
- Web app: a single, dependency-free HTML file with a drag-to-set 60-minute dial,
  intentions and tags, overflow mode, auto-start, chimes, generated ambient sound
  (brown noise, soft rain), daily goal, streak, 7-day chart, zen mode, keyboard
  shortcuts, and light/dark/system themes.
- macOS app (SwiftUI, macOS 14+, universal): main window with the same dial,
  a menu-bar countdown with a compact panel, system notifications, keep-awake
  while a session runs, keep-on-top window, and a native Settings window.
- GitHub Actions: deploy the web app to GitHub Pages; build the macOS app on
  every push and attach a zipped build to tagged releases.

[1.0.0]: https://github.com/D-henrique/pomelo/releases/tag/v1.0.0
