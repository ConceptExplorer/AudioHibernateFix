# Changelog
All notable changes to **AudioHibernateFix** will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to **Semantic Versioning**.

---

## [1.0.0] — 2026-09-29
### Added
- Initial public release of **AudioHibernateFix**.
- Menu‑driven PowerShell diagnostic tool for audio issues after hibernate/sleep.
- Two diagnostic modes:
  - **Simple Check** — quick service and power policy validation.
  - **Detailed Check** — expanded definitions, raw states, and full `powercfg` output.
- Color‑coded output for improved readability (Cyan, Yellow, White, Red, Green, DarkGray).
- Polished header/menu interface.
- Safe stop/start recovery for `audiosrv` and `AudioEndpointBuilder`.
- Detection and correction of legacy `SUB_DEVICE POWERLEVEL` policy.
- Clean exit behavior with friendly shutdown message.
- README with screenshot and color‑annotated menu representation.
- MIT License.

### Notes
- This release establishes the stable baseline for future enhancements (GUI, WASAPI checks, logging, etc.).
