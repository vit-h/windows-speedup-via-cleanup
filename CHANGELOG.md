# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-12

### Added
- 🎉 **Initial public release**
- Smart NuGet package management with three modes:
  - Safe mode: Clears temp/HTTP cache only (instant restore)
  - Selective mode: Keeps 225 framework packages, purges 63 third-party (1-min restore)
  - Nuclear mode: Deletes all 288 packages (15-25 min restore)
- Multi-user support via `-AllUsers` flag
- Windows Defender exclusions for performance boost
- SSD TRIM optimization for all drives
- HDD defragmentation detection and recommendations
- Process detection with file lock warnings
- Comprehensive logging to `C:\ProgramData\CleanupLogs\`
- Dry-run mode for safe previewing
- Downloads folder protection (never touched)
- Browser cache cleanup (Chrome, Edge, Firefox - all profiles)
- Dev tool cache cleanup:
  - npm, yarn, pnpm
  - NuGet (safe temp/HTTP clearing)
  - Visual Studio caches
  - VS Code workspace storage
  - JetBrains IDE caches
  - Docker build cache
  - WSL VHDX compaction
  - Angular CLI cache
  - MSBuild temp
- Language-specific caches:
  - Python pip cache
  - Rust Cargo cache
  - Go modules cache
  - Gradle caches
  - Maven repository
- Performance boosters:
  - Font cache rebuild
  - Windows Store reset
  - Notifications database clearing
  - Recent files and jump lists
  - Thumbnail cache
  - Icon cache
- Windows maintenance:
  - Windows Update cache
  - Delivery Optimization cache
  - Prefetch clearing
  - BITS transfer jobs
  - Windows Error Reporting archives
  - Defender scan cache
  - Event logs (optional)
  - IIS logs (optional)
- System tools integration:
  - cleanmgr (Disk Cleanup)
  - DISM component cleanup
  - SFC (System File Checker)
- Reboot detection and deferred operations handling

### Safety Features
- Hard protection for Downloads folder (including OneDrive redirection)
- Process detection prevents file locks
- System restore point creation (when available)
- Dry-run preview mode
- Comprehensive logging
- Error handling with graceful fallbacks

### Performance
- 93% faster NuGet restore with selective purge (1 min vs 15-25 min)
- Multi-user path expansion (single function handles all users)
- Consolidated summary output (no per-file spam)
- Efficient helper functions reduce duplication

### Documentation
- Comprehensive README with usage examples
- Clear parameter descriptions
- In-script documentation with NuGet options comparison
- Contributing guidelines
- MIT License

## [Unreleased]

### Planned Features
- [ ] Support for more browsers (Brave, Opera, Vivaldi)
- [ ] .NET workload cache cleanup
- [ ] Package manager cache analysis (show sizes before cleanup)
- [ ] Scheduled task creation for automatic maintenance
- [ ] GUI wrapper for easier use
- [ ] PowerShell Gallery module packaging
- [ ] Windows 10 compatibility testing
- [ ] Localization support

---

## Version History

### v1.0.0 (2025-11-12)
Initial public release with smart NuGet management

---

**Full Changelog:** https://github.com/vit-h/windows-cleanup-script/commits/main

