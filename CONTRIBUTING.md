# Contributing to Windows Cleanup Script

First off, thank you for considering contributing to this project! 🎉

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [existing issues](https://github.com/vit-h/windows-cleanup-script/issues) to avoid duplicates.

**When reporting a bug, include:**
- Windows version (e.g., Windows 11 23H2)
- PowerShell version (`$PSVersionTable.PSVersion`)
- Full command you ran
- Expected vs actual behavior
- Relevant log excerpts from `C:\ProgramData\CleanupLogs\`

### Suggesting Enhancements

Enhancement suggestions are tracked as [GitHub Issues](https://github.com/vit-h/windows-cleanup-script/issues).

**When suggesting an enhancement, include:**
- Clear description of the feature
- Why it would be useful
- Example use case
- Potential implementation approach (if you have one)

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make your changes:**
   - Follow PowerShell best practices
   - Add inline comments for complex logic
   - Update parameter descriptions
   - Test with `-DryRun` first

4. **Test thoroughly:**
   ```powershell
   # Always test in dry-run mode first
   .\Clean-AllTemps-NoDownloads.ps1 -DryRun
   
   # Then test actual execution
   .\Clean-AllTemps-NoDownloads.ps1 -YourNewParameter -DryRun:$false
   ```

5. **Update documentation:**
   - Add parameter to README.md
   - Update examples if needed
   - Add to CHANGELOG.md

6. **Commit with clear messages:**
   ```bash
   git commit -m "feat: Add support for clearing XYZ cache"
   ```

7. **Push and create PR:**
   ```bash
   git push origin feature/amazing-feature
   ```

## Development Guidelines

### Code Style

- Use **4-space indentation** (PowerShell standard)
- Use **PascalCase** for functions: `Clear-SomePath`
- Use **kebab-case** for parameters: `-NewParameter`
- Add **inline comments** for complex logic
- Use **verbose parameter names** (readability over brevity)

### Safety Requirements

**CRITICAL:** All new cleanup operations MUST:
1. ✅ Respect Downloads folder protection (`Assert-NotDownloads`)
2. ✅ Support `-DryRun` mode
3. ✅ Log all actions via `Log` function
4. ✅ Handle errors gracefully (try-catch)
5. ✅ Support `-AllUsers` if applicable

### Example: Adding a New Cleanup Option

```powershell
# 1. Add parameter
param(
  # ... existing parameters ...
  [switch]$ClearNewCache = $false  # clear new cache description
)

# 2. Add cleanup section
if ($ClearNewCache) {
  Log-Section "New Cache Cleanup"
  
  # Define paths
  $cachePaths = @(
    '{UserProfile}\AppData\Local\NewApp\Cache',
    '$env:ProgramData\NewApp\Cache'
  )
  
  # Use helper function
  Clear-PathTemplates -Templates $cachePaths -AllUsers:$AllUsers
}

# 3. Update documentation in header comment
# 4. Update README.md
# 5. Add to CHANGELOG.md
```

### Testing Checklist

Before submitting PR:
- [ ] Tested with `-DryRun` (preview works correctly)
- [ ] Tested with `-DryRun:$false` (actual cleanup works)
- [ ] Tested with `-AllUsers` (if applicable)
- [ ] Downloads folder is never touched
- [ ] Logs are clear and informative
- [ ] No errors in PowerShell ISE/VS Code
- [ ] Updated README.md
- [ ] Updated CHANGELOG.md

## Commit Message Guidelines

Use conventional commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `refactor:` Code restructuring
- `perf:` Performance improvement
- `test:` Adding tests
- `chore:` Maintenance

**Examples:**
```
feat: Add support for Rust cargo cache cleanup
fix: Prevent error when Docker daemon not running
docs: Update README with new parameters
refactor: Extract common path expansion logic
```

## Questions?

- **Issues:** [GitHub Issues](https://github.com/vit-h/windows-cleanup-script/issues)
- **Discussions:** [GitHub Discussions](https://github.com/vit-h/windows-cleanup-script/discussions)
- **Email:** vitalii.hon@gmail.com

Thank you for contributing! 🚀

