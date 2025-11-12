# Windows Cleanup Script

**Comprehensive PowerShell script for Windows 11 system cleanup with smart NuGet package management.**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Windows-11-0078D6.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🌟 Features

### Core Cleanup

- ✅ **Safe & Aggressive**: Hard protection for Downloads folder
- ✅ **Multi-User Support**: Clean temp/cache for all user profiles
- ✅ **Browser Caches**: Chrome, Edge, Firefox (all profiles)
- ✅ **System Maintenance**: Windows Update cache, Delivery Optimization, Prefetch
- ✅ **Dev Tools**: npm, yarn, pnpm, NuGet, VS Code, Visual Studio, Docker, WSL

### 🚀 Smart NuGet Management (Unique Feature!)

Three cleanup modes optimized for different scenarios:

| Mode                                  | Packages Kept    | Packages Purged | Restore Time  | Use Case            |
| ------------------------------------- | ---------------- | --------------- | ------------- | ------------------- |
| **Safe** (`-IncludeDevCaches`)        | All packages     | 0               | Instant       | Daily cleanup       |
| **Smart** (`-SelectivePurgeNuGet`) ⭐ | Framework (~75%) | Third-party     | ~1-2 minutes  | Weekly maintenance  |
| **Nuclear** (`-PurgeNuGetPackages`)   | 0                | All packages    | 15-25 minutes | Fresh clone testing |

> 💡 **Example:** In a typical ASP.NET project with 288 packages, Smart Mode keeps ~225 framework packages and purges ~63 third-party packages.

**Smart Mode** keeps stable framework packages (Microsoft._, System._, testing, gRPC, database, logging) while purging frequently-updated third-party packages (cloud services, utilities).

### Performance Boosters

- 🔥 **Windows Defender Exclusions**: Exclude temp/cache folders for CPU/disk boost
- 🔥 **SSD TRIM**: Optimize all SSD drives
- 🔥 **Font Cache Rebuild**: Fix slow app launches
- 🔥 **Multi-Threading**: Parallel cleanup operations

### Safety Features

- 🛡️ **Downloads Protection**: Never touches Downloads folder (including OneDrive redirection)
- 🛡️ **Process Detection**: Warns if dev tools are running (file lock prevention)
- 🛡️ **Dry-Run Mode**: Preview changes before applying
- 🛡️ **Reboot Detection**: Defers operations if system pending reboot

## 📥 Installation

1. **Download the script:**

   ```powershell
   # Clone the repository
   git clone https://github.com/vit-h/windows-speedup-via-cleanup.git
   cd windows-speedup-via-cleanup
   ```

2. **Run as Administrator** (required for system-level cleanup)

## 🚀 Quick Start

```powershell
# 1. Preview what will be cleaned (DRY RUN - always test first!)
.\Clean-AllTemps-NoDownloads.ps1 -DryRun

# 2. Daily/Safe cleanup (temp/cache only, packages preserved)
.\Clean-AllTemps-NoDownloads.ps1 -IncludeBrowsers -IncludeDevCaches -KillBrowsers -KillDevTools -DryRun:$false

# 3. Weekly smart purge (⭐ RECOMMENDED - keeps framework, purges third-party)
.\Clean-AllTemps-NoDownloads.ps1 -SelectivePurgeNuGet -DryRun:$false
```

## 📖 Usage Examples

### Recommended Workflows

```powershell
# ✅ DAILY: Safe cleanup (no package deletion)
.\Clean-AllTemps-NoDownloads.ps1 `
  -IncludeBrowsers `
  -IncludeDevCaches `
  -KillBrowsers `
  -KillDevTools `
  -DryRun:$false

# 💡 WEEKLY: Smart selective purge (~1 min restore)
.\Clean-AllTemps-NoDownloads.ps1 `
  -SelectivePurgeNuGet `
  -DryRun:$false

# 🚀 MONTHLY: Ultra comprehensive cleanup
.\Clean-AllTemps-NoDownloads.ps1 `
  -Aggressive `
  -IncludeBrowsers `
  -IncludeDevCaches `
  -PurgeUpdateCaches `
  -PurgeDeliveryOptCaches `
  -ClearThumbs `
  -ClearIconCache `
  -IncludePrefetch `
  -KillBrowsers `
  -KillDevTools `
  -DockerPrune `
  -WSLCleanup `
  -ClearFontCache `
  -ExcludeFromDefender `
  -RunWindowsBuiltins `
  -AllUsers `
  -DryRun:$false
```

### Developer-Focused

```powershell
# Dev cache cleanup (npm, yarn, pnpm, NuGet temp, VS, Docker, etc.)
.\Clean-AllTemps-NoDownloads.ps1 `
  -IncludeDevCaches `
  -PythonPipCache `
  -RustCargoCache `
  -GoModCache `
  -GradleCache `
  -DockerPrune `
  -WSLCleanup `
  -JetBrainsCaches `
  -AngularCacheClean `
  -DryRun:$false
```

### Multi-User Cleanup

```powershell
# Clean temp/cache for ALL user profiles on this PC
.\Clean-AllTemps-NoDownloads.ps1 `
  -IncludeBrowsers `
  -IncludeDevCaches `
  -AllUsers `
  -DryRun:$false
```

## 📋 Parameters Reference

### Core Cleanup Options

| Parameter     | Description                        | Impact                      |
| ------------- | ---------------------------------- | --------------------------- |
| `-DryRun`     | Preview mode (default: `$true`)    | Shows what would be cleaned |
| `-Aggressive` | Enable all safe cleanup operations | More thorough cleanup       |
| `-AllUsers`   | Clean for all user profiles        | Multi-user systems          |

### Dev Cache Options

| Parameter              | Description                     | Restore Time  |
| ---------------------- | ------------------------------- | ------------- |
| `-IncludeDevCaches`    | ✅ SAFE: Clear temp/HTTP only   | Instant       |
| `-SelectivePurgeNuGet` | 💡 SMART: Keep framework (~75%) | ~1-2 minutes  |
| `-PurgeNuGetPackages`  | 🚨 NUCLEAR: Delete all packages | 15-25 minutes |

### Browser & System

| Parameter                 | Description                                  |
| ------------------------- | -------------------------------------------- |
| `-IncludeBrowsers`        | Clean browser caches (Chrome, Edge, Firefox) |
| `-KillBrowsers`           | Auto-close browsers before cleanup           |
| `-PurgeUpdateCaches`      | Clear Windows Update cache                   |
| `-PurgeDeliveryOptCaches` | Clear Delivery Optimization cache            |
| `-RunWindowsBuiltins`     | Run cleanmgr, DISM, SFC                      |

### Performance Boosters

| Parameter              | Description                                    |
| ---------------------- | ---------------------------------------------- |
| `-ExcludeFromDefender` | Exclude temp/cache from Windows Defender scans |
| `-ClearFontCache`      | Rebuild font cache (fixes slow app launches)   |
| `-ClearThumbs`         | Clear thumbnail database                       |
| `-ClearIconCache`      | Clear icon cache                               |
| `-ResetWindowsStore`   | Reset Windows Store cache                      |

### Safety & Process Control

| Parameter                  | Description                              |
| -------------------------- | ---------------------------------------- |
| `-Force`                   | Silence process detection warnings       |
| `-KillDevTools`            | Auto-close dev tools (VS, VS Code, etc.) |
| `-EnforceNoDownloadsClean` | Ensure Downloads folder is never touched |

## 📊 What Gets Cleaned

<details>
<summary><b>Core System (Always)</b></summary>

- User temp folders (`%TEMP%`, `%LOCALAPPDATA%\Temp`)
- Windows temp (`C:\Windows\Temp`)
- Crash dumps
- Windows Error Reporting (WER)
- Recycle Bin
- DNS cache
- BITS transfer jobs
</details>

<details>
<summary><b>Browsers (with -IncludeBrowsers)</b></summary>

- Chrome: Cache, Code Cache, GPU Cache, Service Workers
- Edge: Cache, Code Cache, GPU Cache, Service Workers
- Firefox: cache2
- **All user profiles** and **all browser profiles**
</details>

<details>
<summary><b>Dev Tools (with -IncludeDevCaches)</b></summary>

- npm, yarn, pnpm cache
- NuGet temp/HTTP cache (packages preserved!)
- Visual Studio ComponentModelCache, MEFCache
- VS Code cache, workspaceStorage
- Docker build cache (with `-DockerPrune`)
- WSL VHDX compaction (with `-WSLCleanup`)
- JetBrains IDE caches (with `-JetBrainsCaches`)
- Angular CLI cache (with `-AngularCacheClean`)
</details>

<details>
<summary><b>Selective NuGet Purge (with -SelectivePurgeNuGet)</b></summary>

> 📊 **Example:** Based on a typical ASP.NET Core project. Actual numbers vary by project.

**Keeps (~75% of packages):**

- Microsoft.AspNetCore.\*
- Microsoft.Extensions.\*
- System.\*
- Testing (xUnit, TestPlatform, FluentAssertions)
- Code Analysis (Roslyn)
- gRPC/Protobuf
- Database (Npgsql)
- API Docs (Swashbuckle)
- Logging (Serilog, OpenTelemetry)
- Validation (FluentValidation)
- Messaging (MassTransit)

**Purges (~25% of packages):**

- Cloud services (AWS, Stripe, Twilio, Firebase)
- Health checks
- Test helpers (AutoFixture, Bogus, TestContainers)
- Utilities (SkiaSharp, HtmlAgilityPack, YamlDotNet)
</details>

## 🎯 Performance Impact

### Storage Freed (Typical Results)

| System State                | Space Freed    |
| --------------------------- | -------------- |
| Fresh Windows install       | ~500 MB - 1 GB |
| Daily use (1 week)          | ~2-5 GB        |
| Developer machine (1 month) | ~10-20 GB      |
| With full NuGet purge       | +1.5-3 GB      |

### Time Savings

| Operation           | Before (Nuclear) | After (Smart Selective) | Improvement      |
| ------------------- | ---------------- | ----------------------- | ---------------- |
| NuGet restore       | 15-25 min        | 1-2 min                 | **90%+ faster**  |
| Build after cleanup | Slow             | Fast                    | Fewer file locks |
| Defender scans      | Slow             | Fast                    | Excluded temp    |

## 🛡️ Safety Guarantees

### What's NEVER Touched

- ❌ **Downloads folder** (including OneDrive-redirected)
- ❌ **Documents, Pictures, Videos**
- ❌ **Source code** (git repositories, project files)
- ❌ **node_modules** (your installed packages)
- ❌ **NuGet packages** (unless explicitly using `-SelectivePurgeNuGet` or `-PurgeNuGetPackages`)

### Process Detection

The script detects running dev processes and warns before cleanup:

- Visual Studio
- MSBuild, Roslyn Compiler
- dotnet SDK/runtime
- VS Code
- JetBrains IDEs (Rider, WebStorm, IntelliJ)
- Node.js

**Behavior:** Warns but continues (use `-Force` to silence warnings).

## 📝 Logging

All operations are logged to:

```
C:\ProgramData\CleanupLogs\Clean-AllTemps-YYYYMMDD-HHMMSS.log
```

Logs include:

- ✅ Operations performed
- ⚠️ Warnings and skipped items
- 📊 Summary (files removed, space freed)
- 🔄 Deferred operations (if reboot pending)

## ⚙️ System Requirements

- **OS:** Windows 11 (also works on Windows 10)
- **PowerShell:** 5.1 or later (PowerShell 7+ recommended)
- **Privileges:** Administrator (required for system-level cleanup)
- **Optional:**
  - .NET SDK (for NuGet cleanup)
  - Docker Desktop (for Docker cleanup)
  - WSL 2 (for WSL cleanup)
  - Hyper-V (for WSL VHDX compaction)

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Report Issues:** Found a bug? [Open an issue](https://github.com/vit-h/windows-speedup-via-cleanup/issues)
2. **Suggest Features:** Have an idea? [Start a discussion](https://github.com/vit-h/windows-speedup-via-cleanup/discussions)
3. **Submit PRs:**
   - Fork the repository
   - Create a feature branch (`git checkout -b feature/amazing-feature`)
   - Commit your changes (`git commit -m 'Add amazing feature'`)
   - Push to the branch (`git push origin feature/amazing-feature`)
   - Open a Pull Request

### Development Guidelines

- Follow PowerShell best practices
- Test with `-DryRun` first
- Update README for new features
- Add parameter descriptions
- Maintain safety guarantees (never touch Downloads!)

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

**Use at your own risk.** While this script has extensive safety features:

- Always run with `-DryRun` first to preview changes
- Close all applications before running
- Ensure you have backups of important data
- The script creates a system restore point (if possible)

The authors are not responsible for any data loss or system issues.

## 🙏 Acknowledgments

- Inspired by common Windows maintenance needs
- Community feedback on NuGet package management
- PowerShell community best practices

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/vit-h/windows-speedup-via-cleanup/issues)
- **Discussions:** [GitHub Discussions](https://github.com/vit-h/windows-speedup-via-cleanup/discussions)
- **LinkedIn:** [vit-h](https://www.linkedin.com/in/vit-h/)

---

**⭐ If this script helped you, please consider starring the repository!**

Made with ❤️ by [vit-h](https://github.com/vit-h)
