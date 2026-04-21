# Changelog

## 0.0.1 - 2026-04-21

### Initial Release

---

### Added

- Added the standalone `PSInteractiveMenu` module scaffold with a RenderKit-like source layout
- Added a keyboard-driven interactive menu engine for console-based PowerShell workflows
- Added public helpers for menu display, option creation, text input, and boolean prompts
- Added build scripts for staged packaging and publishing

### Changed

- Improved the interactive host detection so the menu engine can run in supported terminals beyond `ConsoleHost`
- Changed menu option, layout, and result payloads to use real PowerShell type names

### Fixed

- Fixed README examples to match the actual public parameter usage
- Added broader test coverage for aliases, hotkey normalization, and typed option objects
