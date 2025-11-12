<#
Clean-AllTemps-NoDownloads.ps1
Aggressive but safe Windows 11 cleanup with HARD protection for Downloads, multi-profile browser/dev cache purges,
optional Windows Update/DeliveryOptimization cache clears, optional Windows built-ins (cleanmgr/DISM/SFC), and SSD ReTrim.

Run as Administrator. First run with -DryRun to preview.

⚠️  IMPORTANT: Close Visual Studio, IDEs, and build tools before running with -IncludeDevCaches or -PurgeNuGetPackages!
    The script will warn if dev processes are active but will continue (file locks may occur).

📦 NUGET CLEANUP OPTIONS:
   1. -IncludeDevCaches (SAFE, RECOMMENDED)
      • Only clears temp/HTTP cache
      • Keeps ALL packages
      • Next restore: INSTANT
      • Use: Daily cleanup
      
   2. -SelectivePurgeNuGet (SMART, BALANCED) 💡
      • Keeps 225 framework packages (Microsoft.*, System.*, testing, gRPC, database, logging)
      • Purges 63 third-party packages (cloud services, utilities)
      • Next restore: ~1 minute
      • Use: Weekly maintenance, suspect package corruption
      
   3. -PurgeNuGetPackages (NUCLEAR, RARELY NEEDED) 🚨
      • DELETES ALL 288 packages
      • Next restore: 15-25 minutes
      • Use: Only for "fresh clone" testing, or severe corruption
      
   ⚡ TIP: Use -SelectivePurgeNuGet instead of -PurgeNuGetPackages in 95% of cases!

Examples:
  # 🔍 Preview mode (always test first!)
  .\Clean-AllTemps-NoDownloads.ps1 -DryRun

  # ✅ RECOMMENDED: Daily/Safe cleanup (temp/cache only, packages preserved)
  .\Clean-AllTemps-NoDownloads.ps1 -IncludeBrowsers -IncludeDevCaches -KillBrowsers -KillDevTools -DryRun:$false

  # 💡 RECOMMENDED: Weekly smart purge (keeps framework, purges 63 third-party packages, ~1 min restore)
  .\Clean-AllTemps-NoDownloads.ps1 -SelectivePurgeNuGet -DryRun:$false
  
  # 🔧 Balanced (adds Windows Update/DeliveryOptimization cache purge)
  .\Clean-AllTemps-NoDownloads.ps1 -IncludeBrowsers -IncludeDevCaches -PurgeUpdateCaches -PurgeDeliveryOptCaches -KillBrowsers -KillDevTools -RunWindowsBuiltins -DryRun:$false

  # 🚀 Ultra comprehensive (everything except NuGet packages)
  .\Clean-AllTemps-NoDownloads.ps1 -Aggressive -IncludeBrowsers -IncludeDevCaches -PurgeUpdateCaches -PurgeDeliveryOptCaches -ClearThumbs -ClearIconCache -IncludePrefetch -KillBrowsers -KillDevTools -DockerPrune -WSLCleanup -AngularCacheClean -JetBrainsCaches -MSBuildExtraClean -ClearFontCache -ResetWindowsStore -ClearNotificationsDB -ClearRecentJumpLists -ExcludeFromDefender -RunWindowsBuiltins -AllUsers -DryRun:$false
  
  # 🧪 Dev-focused (adds Python/Rust/Go/Gradle/Maven caches + Defender exclusions)
  .\Clean-AllTemps-NoDownloads.ps1 -IncludeDevCaches -PythonPipCache -RustCargoCache -GoModCache -GradleCache -JetBrainsCaches -MSBuildExtraClean -ExcludeFromDefender -DryRun:$false
  
  # 🚨 NUCLEAR (RARELY NEEDED): Fresh clone simulation - DELETES ALL 288 packages, 15-25 min restore
  #    ⚠️  Use -SelectivePurgeNuGet instead in 95% of cases!
  .\Clean-AllTemps-NoDownloads.ps1 -PurgeNuGetPackages -DryRun:$false
  
  # 🔇 Silence process warnings (script warns but continues by default)
  .\Clean-AllTemps-NoDownloads.ps1 -IncludeDevCaches -Force -DryRun:$false
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [switch]$DryRun = $true,

  # What to clean
  [switch]$Aggressive = $false,
  [switch]$IncludeBrowsers = $false,
  [switch]$IncludeDevCaches = $false,
  [switch]$PurgeUpdateCaches = $false,
  [switch]$PurgeDeliveryOptCaches = $false,
  [switch]$ClearThumbs = $false,
  [switch]$ClearIconCache = $false,
  [switch]$IncludePrefetch = $false,
  [switch]$ClearEventLogs = $false,

  # Process control
  [switch]$KillBrowsers = $false,
  [switch]$KillDevTools = $false,

  # Dev/Platform maintenance (optional extras)
  [switch]$DockerPrune = $false,
  [switch]$WSLCleanup = $false,          # shutdown WSL and optionally compact VHDX if Hyper-V tools are available
  [switch]$AngularCacheClean = $false,   # run `ng cache clean` if Angular CLI is present
  [switch]$JetBrainsCaches = $false,     # clear JetBrains caches under %LOCALAPPDATA\JetBrains
  [switch]$MSBuildExtraClean = $false,   # purge MSBuild temp under %LOCALAPPDATA\Microsoft\MSBuild
  
  # Additional dev/language caches
  [switch]$PythonPipCache = $false,      # clear pip cache
  [switch]$RustCargoCache = $false,      # clear Cargo registry cache
  [switch]$GoModCache = $false,          # clear Go modules cache
  [switch]$GradleCache = $false,         # clear Gradle caches
  [switch]$MavenCache = $false,          # clear Maven repository (WARNING: large re-downloads)
  [switch]$PurgeNuGetPackages = $false,  # NUCLEAR (RARELY NEEDED): delete ALL 288 packages, 15-25 min restore (Use -SelectivePurgeNuGet instead!)
  [switch]$SelectivePurgeNuGet = $false, # SMART (RECOMMENDED): keeps 225 framework packages, purges 63 third-party, ~1 min restore

  # Performance boosters
  [switch]$ClearFontCache = $false,      # rebuild font cache (fixes slow app launches)
  [switch]$ResetWindowsStore = $false,   # reset Windows Store cache
  [switch]$ClearNotificationsDB = $false, # clear notifications database
  [switch]$ClearRecentJumpLists = $false, # clear recent files and jump lists
  [switch]$ExcludeFromDefender = $false, # exclude temp/cache folders from Windows Defender (performance boost)

  # Windows built-ins and policy
  [switch]$RunWindowsBuiltins = $false,
  [switch]$DeepComponentCleanup = $false,  # adds DISM /ResetBase (less rollback history)
  [switch]$EnforceNoDownloadsClean = $true, # enforce Storage Sense NEVER touches Downloads
  
  # Multi-user cleanup
  [switch]$AllUsers = $false,              # clean temp/cache for ALL users on this PC (not just current user)
  
  # Additional cleanup options
  [switch]$IISLogs = $false,               # clear IIS web server logs (only if IIS installed)
  
  # Safety overrides
  [switch]$Force = $false                  # silence process detection warnings (script warns but continues by default)
)

# =================== Utilities ===================
function Ensure-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script as Administrator."
  }
}

function Test-DevProcessesRunning {
  $devProcessNames = @(
    'devenv',              # Visual Studio
    'MSBuild',             # MSBuild
    'VBCSCompiler',        # Roslyn compiler
    'ServiceHub.Host.dotnet',
    'ServiceHub.RoslynCodeAnalysisService',
    'ServiceHub.Host.CLR',
    'PerfWatson',
    'PerfWatson2',
    'dotnet',              # .NET SDK/runtime
    'Code',                # VS Code
    'rider64',             # JetBrains Rider
    'WebStorm64',          # JetBrains WebStorm
    'idea64',              # JetBrains IntelliJ IDEA
    'node'                 # Node.js (build processes)
  )
  
  $runningProcs = @()
  foreach ($procName in $devProcessNames) {
    $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if ($procs) {
      $runningProcs += $procs | Select-Object Name, Id, Path
    }
  }
  
  return $runningProcs
}

function Assert-SafeForDevCacheCleanup {
  param([switch]$Force)
  
  if ($Force) {
    Log "⚠️  -Force flag enabled: bypassing process detection (file locks may occur)"
    return
  }
  
  $runningDevProcs = Test-DevProcessesRunning
  if ($runningDevProcs.Count -gt 0) {
    Log "`n⚠️  WARNING: Dev processes are running - file locks may occur!"
    Log "═══════════════════════════════════════════════════════════"
    
    $grouped = $runningDevProcs | Group-Object Name
    foreach ($group in $grouped) {
      $count = $group.Count
      $name = $group.Name
      Log "   • $name ($count process(es))"
    }
    
    Log ""
    Log "⚠️  Continuing anyway, but you may experience:"
    Log "   - File lock errors during cleanup"
    Log "   - 'Access denied' errors on some packages"
    Log "   - Corrupted package cache (requiring restore)"
    Log ""
    Log "💡 TIP: For safest cleanup, close all dev tools first or use -Force to acknowledge this risk"
    Log "═══════════════════════════════════════════════════════════"
  } else {
    Log "✓ Safety check passed: No dev processes running"
  }
}

# Get cached user profiles list (call once, reuse everywhere)
$script:CachedUserProfiles = $null
function Get-UserProfiles {
  if ($null -eq $script:CachedUserProfiles) {
    $script:CachedUserProfiles = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | 
                                  Where-Object { $_.Name -notin @('Public', 'Default', 'Default User', 'All Users') }
  }
  return $script:CachedUserProfiles
}

# Expand path templates for single or multi-user mode
# Templates use {UserProfile} placeholder, e.g. "{UserProfile}\AppData\Local\Temp"
function Expand-UserPaths {
  param(
    [Parameter(Mandatory)]
    [string[]]$PathTemplates,
    [switch]$AllUsers
  )
  
  $expandedPaths = @()
  
  if ($AllUsers) {
    # Multi-user: expand for each user profile
    $userProfiles = Get-UserProfiles
    foreach ($userProfile in $userProfiles) {
      foreach ($template in $PathTemplates) {
        if ($template -like '*{UserProfile}*') {
          $path = $template -replace '\{UserProfile\}', $userProfile.FullName
          $expandedPaths += $path
        } else {
          # System-wide path (no placeholder) - add once
          if ($expandedPaths -notcontains $template) {
            $expandedPaths += $template
          }
        }
      }
    }
  } else {
    # Single user: expand for current user only
    foreach ($template in $PathTemplates) {
      if ($template -like '*{UserProfile}*') {
        $path = $template -replace '\{UserProfile\}', $env:USERPROFILE
        $expandedPaths += $path
      } else {
        $expandedPaths += $template
      }
    }
  }
  
  return $expandedPaths | Select-Object -Unique
}
function New-Logger {
  $logDir = Join-Path $env:ProgramData "CleanupLogs"
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
  $script:LogPath = Join-Path $logDir ("Clean-AllTemps-{0}.log" -f (Get-Date -f "yyyyMMdd-HHmmss"))
  "=== Cleanup started {0} ===" -f (Get-Date) | Tee-Object -FilePath $LogPath
}
function Log { param([string]$msg) $msg | Tee-Object -FilePath $LogPath -Append }

# --- Resolve Downloads folders (supports OneDrive redirection + Public) ---
function Get-DownloadsPath {
  try {
    $uf = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
    $dl = (Get-ItemProperty -Path $uf -Name '{374DE290-123F-4565-9164-39C4925E467B}' -ErrorAction Stop).'{374DE290-123F-4565-9164-39C4925E467B}'
    $expanded = [Environment]::ExpandEnvironmentVariables($dl)
    if ($expanded) { return $expanded }
  } catch {}
  return (Join-Path $env:USERPROFILE 'Downloads') # fallback
}
$Global:DownloadsPath = Get-DownloadsPath
$Global:PublicDownloadsPath = 'C:\Users\Public\Downloads'

function In-Downloads([string]$FullPath) {
  foreach ($d in @($Global:DownloadsPath, $Global:PublicDownloadsPath)) {
    if ($d -and $FullPath -like ($d.TrimEnd('\\') + '*')) { return $true }
  }
  return $false
}
function Assert-NotDownloads {
  param([Parameter(Mandatory)][string]$Path)
  $resolved = Resolve-Path $Path -ErrorAction SilentlyContinue
  $full = if ($resolved) { $resolved.Path } else { $null }
  if ($full -and (In-Downloads $full)) { throw "Safety guard: refusing to touch Downloads: $full" }
}

function Get-FolderSize {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return 0 }
  try {
    $items = @(Get-ChildItem -Path $Path -Recurse -Force -File -ErrorAction SilentlyContinue)
    $size = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    if ($size) { return [long]$size }
    return 0
  } catch { return 0 }
}
function Format-FileSize {
  param([long]$Bytes)
  if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
  elseif ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
  elseif ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
  else { return "{0} bytes" -f $Bytes }
}

function Remove-PathSafe {
  param([Parameter(Mandatory)] [string]$Path, [switch]$Recurse = $true)
  try { Assert-NotDownloads -Path $Path } catch { Log "SKIP (Downloads guard): $($PSItem.Exception.Message)"; return }
  if (-not (Test-Path $Path)) { return }  # Silent skip for missing paths
  if ($DryRun) { 
    $size = Get-FolderSize -Path $Path
    $sizeStr = Format-FileSize -Bytes $size
    Log "[DryRun] Would remove: $Path ($sizeStr)"
    $script:TotalBytesToFree += $size
    return 
  }
  try {
    $size = Get-FolderSize -Path $Path
    if (Test-Path $Path -PathType Container) { 
      $itemCount = (Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object).Count
      Remove-Item -LiteralPath $Path -Recurse:$Recurse -Force -ErrorAction SilentlyContinue 
    } else { 
      $itemCount = 1
      Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue 
    }
    $script:SessionFilesRemoved += $itemCount
    $script:SessionBytesFreed += $size
    Log "✓ Removed: $Path ($itemCount files, $(Format-FileSize -Bytes $size))"
  } catch { Log "Error removing $Path : $($_.Exception.Message)" }
}
function Clear-Children { 
  param(
    [Parameter(Mandatory)][string]$Path,
    [switch]$Silent  # Suppress individual log messages
  )
  try { Assert-NotDownloads -Path $Path } catch { Log "SKIP (Downloads guard): $($PSItem.Exception.Message)"; return }
  if (-not (Test-Path $Path)) { return }  # Silent skip for missing paths
  if ($DryRun) {
    $size = Get-FolderSize -Path $Path
    $sizeStr = Format-FileSize -Bytes $size
    if (-not $Silent) {
      Log "[DryRun] Would clear contents of: $Path ($sizeStr)"
    }
    $script:TotalBytesToFree += $size
    return
  }
  $size = Get-FolderSize -Path $Path
  $itemCount = (Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object).Count
  $items = Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  foreach ($i in $items) { Remove-Item -LiteralPath $i.FullName -Recurse -Force -ErrorAction SilentlyContinue }
  if ($itemCount -gt 0) {
    $script:SessionFilesRemoved += $itemCount
    $script:SessionBytesFreed += $size
    if (-not $Silent) {
      Log "✓ Cleared: $Path ($itemCount files, $(Format-FileSize -Bytes $size))"
    }
  }
}

function Stop-ServiceSafe { param([string]$name)
  try {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -ne 'Stopped') {
      if ($DryRun) { Log "[DryRun] Would Stop-Service $name" }
      else { Stop-Service -Name $name -Force -ErrorAction SilentlyContinue; Log "Stopped service: $name" }
    }
  } catch { $err = $_.Exception.Message; Log "Error stopping $name`: $err" }
}
function Start-ServiceSafe { param([string]$name)
  try {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -ne 'Running') {
      if ($DryRun) { Log "[DryRun] Would Start-Service $name" }
      else { Start-Service -Name $name -ErrorAction SilentlyContinue; Log "Started service: $name" }
    }
  } catch { $err = $_.Exception.Message; Log "Error starting $name`: $err" }
}

# === CONSOLIDATED HELPER FUNCTIONS FOR COMMON PATTERNS ===

# Execute external command with consistent error handling
function Invoke-ExternalCommand {
  param(
    [Parameter(Mandatory)][string]$CommandName,
    [Parameter(Mandatory)][string]$Arguments,
    [Parameter(Mandatory)][string]$SuccessMessage,
    [string]$NotFoundMessage = "$CommandName not found; skipping."
  )
  $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
  if ($cmd) {
    if ($DryRun) { 
      Log "[DryRun] Would run: $CommandName $Arguments" 
    } else {
      try { 
        Invoke-Expression "$CommandName $Arguments" | Out-Null
        Log $SuccessMessage
      } catch { 
        Log "$CommandName error: $($_.Exception.Message)" 
      }
    }
  } else { 
    Log $NotFoundMessage 
  }
}

# Clear multiple path templates with consistent pattern
function Clear-PathTemplates {
  param(
    [Parameter(Mandatory)][string[]]$Templates,
    [switch]$AllUsers,
    [switch]$WildcardPaths,  # If paths contain wildcards that need Get-Item resolution
    [string]$NotFoundMessage,  # Optional message when nothing found
    [string]$SuccessMessage   # Optional summary message
  )
  
  $paths = Expand-UserPaths -PathTemplates $Templates -AllUsers:$AllUsers
  $foundAny = $false
  $clearedCount = 0
  
  foreach ($template in $paths) {
    $expandedPath = [Environment]::ExpandEnvironmentVariables($template)
    
    if ($WildcardPaths -and ($expandedPath -like '*`**')) {
      $matchingDirs = Get-Item $expandedPath -ErrorAction SilentlyContinue
      if ($matchingDirs) {
        $foundAny = $true
        foreach ($dir in $matchingDirs) {
          Clear-Children -Path $dir.FullName
          $clearedCount++
        }
      }
    } else {
      if (Test-Path $expandedPath) {
        $foundAny = $true
        Clear-Children -Path $expandedPath
        $clearedCount++
      }
    }
  }
  
  if ($NotFoundMessage -and -not $foundAny) {
    Log $NotFoundMessage
  } elseif ($SuccessMessage -and $foundAny) {
    Log $SuccessMessage
  }
}

# Service-wrapped cleanup (stop service, cleanup, start service)
function Invoke-ServiceWrappedCleanup {
  param(
    [Parameter(Mandatory)][string[]]$ServiceNames,
    [Parameter(Mandatory)][scriptblock]$CleanupAction
  )
  
  foreach ($svc in $ServiceNames) { Stop-ServiceSafe -name $svc }
  & $CleanupAction
  foreach ($svc in $ServiceNames) { Start-ServiceSafe -name $svc }
}

# Clear files matching a pattern with summary statistics
function Clear-FilesWithSummary {
  param(
    [Parameter(Mandatory)][string[]]$PathTemplates,
    [switch]$AllUsers,
    [string]$ItemType = 'files'  # e.g., 'thumbnail files', 'icon cache files'
  )
  
  $paths = Expand-UserPaths -PathTemplates $PathTemplates -AllUsers:$AllUsers
  $filesRemoved = 0
  $bytesFreed = 0
  
  foreach ($template in $paths) {
    $expandedPath = [Environment]::ExpandEnvironmentVariables($template)
    $matchingFiles = Get-Item $expandedPath -ErrorAction SilentlyContinue
    if ($matchingFiles) {
      foreach ($file in $matchingFiles) {
        if ($DryRun) {
          $bytesFreed += $file.Length
          $filesRemoved++
        } else {
          $size = $file.Length
          Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
          $filesRemoved++
          $bytesFreed += $size
          $script:SessionFilesRemoved++
          $script:SessionBytesFreed += $size
        }
      }
    }
  }
  
  if ($filesRemoved -gt 0) {
    if ($DryRun) {
      Log "[DryRun] Would remove $filesRemoved $ItemType ($(Format-FileSize -Bytes $bytesFreed))"
      $script:TotalBytesToFree += $bytesFreed
    } else {
      Log "✓ Removed $filesRemoved $ItemType ($(Format-FileSize -Bytes $bytesFreed))"
    }
  }
}

# Log section header with consistent formatting
function Log-Section {
  param([Parameter(Mandatory)][string]$Title)
  Log "`n-- $Title --"
}

function Stop-Processes { param([string[]]$Names)
  foreach ($n in $Names) {
    $procs = Get-Process -Name $n -ErrorAction SilentlyContinue
    if ($procs) {
      if ($DryRun) { Log "[DryRun] Would kill $($procs.Count) $n process(es)" }
      else {
        $killed = 0
        foreach ($p in $procs) { 
          try { 
            $p.Kill()
            $killed++
          } catch { 
            Log "⚠ Error killing $n (Id=$($p.Id)): $($_.Exception.Message)" 
          } 
        }
        if ($killed -gt 0) {
          Log "✓ Killed $killed $n process(es)"
        }
      }
    }
  }
}

function Test-PendingReboot {
  $keys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' # PendingFileRenameOperations value
  )
  foreach($k in $keys){
    if ($k -like '*Session Manager'){
      $v = (Get-ItemProperty $k -ErrorAction SilentlyContinue).'PendingFileRenameOperations'
      if ($v) { return $true }
    } elseif (Test-Path $k) { return $true }
  }
  return $false
}

# =================== Start ===================
Ensure-Admin
New-Logger
$script:TotalBytesToFree = 0
$script:SessionFilesRemoved = 0
$script:SessionBytesFreed = 0
$script:DeferredOperations = @()  # Track operations deferred due to pending reboot
Log "Parameters: DryRun=$DryRun Aggressive=$Aggressive IncludeBrowsers=$IncludeBrowsers IncludeDevCaches=$IncludeDevCaches PurgeUpdateCaches=$PurgeUpdateCaches PurgeDeliveryOptCaches=$PurgeDeliveryOptCaches ClearThumbs=$ClearThumbs ClearIconCache=$ClearIconCache IncludePrefetch=$IncludePrefetch ClearEventLogs=$ClearEventLogs KillBrowsers=$KillBrowsers KillDevTools=$KillDevTools DockerPrune=$DockerPrune WSLCleanup=$WSLCleanup AngularCacheClean=$AngularCacheClean JetBrainsCaches=$JetBrainsCaches MSBuildExtraClean=$MSBuildExtraClean PythonPipCache=$PythonPipCache RustCargoCache=$RustCargoCache GoModCache=$GoModCache GradleCache=$GradleCache MavenCache=$MavenCache PurgeNuGetPackages=$PurgeNuGetPackages SelectivePurgeNuGet=$SelectivePurgeNuGet ClearFontCache=$ClearFontCache ResetWindowsStore=$ResetWindowsStore ClearNotificationsDB=$ClearNotificationsDB ClearRecentJumpLists=$ClearRecentJumpLists ExcludeFromDefender=$ExcludeFromDefender RunWindowsBuiltins=$RunWindowsBuiltins DeepComponentCleanup=$DeepComponentCleanup EnforceNoDownloadsClean=$EnforceNoDownloadsClean AllUsers=$AllUsers IISLogs=$IISLogs Force=$Force"

# Optional: restore point
try { if ($DryRun) { Log "[DryRun] Would create a system restore point." } else { Checkpoint-Computer -Description "Clean-AllTemps" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue | Out-Null; Log "Restore point attempted." } } catch { Log "Restore point error: $($_.Exception.Message)" }

# =================== Windows Defender Exclusions (BEFORE cleanup for best performance) ===================
if ($ExcludeFromDefender) {
  Log-Section "Windows Defender Exclusions (Performance Boost)"
  
  # Define exclusion path templates
  $exclusionTemplates = @(
    # Core temp folders
    '{UserProfile}\AppData\Local\Temp',
    '{UserProfile}\AppData\Local\CrashDumps',
    
    # Browser caches
    '{UserProfile}\AppData\Local\Microsoft\Edge\User Data\*\Cache',
    '{UserProfile}\AppData\Local\Microsoft\Edge\User Data\*\Code Cache',
    '{UserProfile}\AppData\Local\Microsoft\Edge\User Data\*\GPUCache',
    '{UserProfile}\AppData\Local\Google\Chrome\User Data\*\Cache',
    '{UserProfile}\AppData\Local\Google\Chrome\User Data\*\Code Cache',
    '{UserProfile}\AppData\Local\Google\Chrome\User Data\*\GPUCache',
    '{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\cache2',
    
    # Dev caches
    '{UserProfile}\AppData\Local\npm-cache',
    '{UserProfile}\AppData\Roaming\npm-cache',
    '{UserProfile}\AppData\Local\Yarn\Cache',
    '{UserProfile}\AppData\Local\pnpm\store',
    '{UserProfile}\.nuget\packages',
    '{UserProfile}\AppData\Local\NuGet\Cache',
    '{UserProfile}\AppData\Local\Microsoft\VisualStudio\*\ComponentModelCache',
    '{UserProfile}\AppData\Roaming\Code\Cache',
    '{UserProfile}\AppData\Roaming\Code\CachedData',
    '{UserProfile}\AppData\Roaming\Code\GPUCache',
    
    # Language/runtime caches
    '{UserProfile}\AppData\Local\pip\cache',
    '{UserProfile}\.cargo\registry\cache',
    '{UserProfile}\.gradle\caches',
    '{UserProfile}\.m2\repository',
    
    # Windows caches
    '{UserProfile}\AppData\Local\Microsoft\Windows\INetCache',
    '{UserProfile}\AppData\Local\Microsoft\Windows\WebCache',
    '{UserProfile}\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db',
    '{UserProfile}\AppData\Local\Microsoft\Windows\Explorer\iconcache_*.db',
    
    # System-wide paths (no {UserProfile} placeholder)
    '$env:WINDIR\Temp',
    '$env:WINDIR\Prefetch',
    '$env:ProgramData\Microsoft\Windows\WER'
  )
  
  # Expand paths using helper function
  $exclusionPaths = Expand-UserPaths -PathTemplates $exclusionTemplates -AllUsers:$AllUsers
  
  if ($AllUsers) {
    $userCount = (Get-UserProfiles).Count
    Log "Multi-user mode: Adding exclusions for $userCount user(s)"
  }
  
  if ($DryRun) {
    Log "[DryRun] Would add $($exclusionPaths.Count) Windows Defender exclusions for temp/cache folders"
  } else {
    $addedCount = 0
    $skippedCount = 0
    
    foreach ($path in $exclusionPaths) {
      # Expand environment variables in the path
      $expandedPath = [Environment]::ExpandEnvironmentVariables($path)
      
      # Only add exclusion if path exists OR contains wildcards (for future use)
      if ($expandedPath -like "*`**" -or (Test-Path $expandedPath -ErrorAction SilentlyContinue)) {
        try {
          Add-MpPreference -ExclusionPath $expandedPath -ErrorAction SilentlyContinue
          $addedCount++
        } catch {
          Log "⚠ Could not exclude $expandedPath : $($_.Exception.Message)"
          $skippedCount++
        }
      }
    }
    
    Log "✓ Added $addedCount Defender exclusions (CPU/disk performance boost)"
    if ($skippedCount -gt 0) {
      Log "⚠ Skipped: $skippedCount exclusions (already exist or path not found)"
    }
  }
}

# =================== DNS cache (BEFORE temp cleanup) ===================
Log-Section "DNS Client cache"
if ($DryRun) { 
  Log "[DryRun] Would Clear-DnsClientCache" 
} else { 
  try { 
    Clear-DnsClientCache
    Log "Cleared DNS client cache." 
  } catch { 
    Log "DNS cache clear error: $($_.Exception.Message)" 
  } 
}

# =================== SSD/HDD Maintenance (BEFORE temp cleanup) ===================
Log-Section "Disk Optimization (TRIM SSDs, detect HDDs)"
try {
  # Get all fixed volumes with drive letters
  $volumes = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' }
  
  $ssdCount = 0
  $hddList = @()
  
  foreach ($vol in $volumes) {
    try {
      # Get physical disk info for this volume
      $partition = Get-Partition | Where-Object { $_.DriveLetter -eq $vol.DriveLetter } | Select-Object -First 1
      if ($partition) {
        $disk = Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceId -eq $partition.DiskNumber } | Select-Object -First 1
        
        if ($disk) {
          if ($disk.MediaType -eq 'SSD') {
            # SSD: Run TRIM
            if ($DryRun) { 
              Log "[DryRun] Would TRIM SSD: $($vol.DriveLetter): ($($vol.FileSystemLabel))"
            } else {
              Optimize-Volume -DriveLetter $vol.DriveLetter -ReTrim -ErrorAction SilentlyContinue | Out-Null
              Log "✓ TRIM completed: $($vol.DriveLetter): ($($vol.FileSystemLabel)) [SSD]"
              $ssdCount++
            }
          } elseif ($disk.MediaType -eq 'HDD') {
            # HDD: Track for recommendation
            $hddList += "$($vol.DriveLetter): ($($vol.FileSystemLabel))"
          }
        }
      }
    } catch {
      Log "Could not optimize $($vol.DriveLetter): - $($_.Exception.Message)"
    }
  }
  
  if (-not $DryRun -and $ssdCount -gt 0) {
    Log "✓ Total SSDs optimized: $ssdCount"
  }
  
  # HDD Defragmentation Recommendations
  if ($hddList.Count -gt 0) {
    Log "`n📊 HDD Defragmentation Recommended:"
    foreach ($hdd in $hddList) {
      Log "   • $hdd - Run manually: Optimize-Volume -DriveLetter <letter> -Defrag"
    }
    Log "   (Skipped auto-defrag: can take 30+ minutes per drive)"
  }
  
} catch {
  Log "Disk optimization error: $($_.Exception.Message)"
}

# =================== BITS Transfer Jobs (BEFORE temp cleanup) ===================
Log-Section "BITS Transfer Jobs"
if ($DryRun) { 
  Log "[DryRun] Would remove all BITS transfer jobs" 
} else {
  try {
    $bitsJobs = Get-BitsTransfer -AllUsers -ErrorAction SilentlyContinue
    if ($bitsJobs) {
      $bitsJobs | Remove-BitsTransfer -ErrorAction SilentlyContinue
      Log "BITS transfer jobs cleared."
    } else { 
      Log "No BITS jobs found." 
    }
  } catch { 
    Log "BITS cleanup error: $($_.Exception.Message)" 
  }
}

# =================== Core temp locations ===================
Log-Section "Core temp & WER cleanup"

# Define path templates (use {UserProfile} placeholder for user-specific paths)
$coreTempTemplates = @(
  '{UserProfile}\AppData\Local\Temp',
  '{UserProfile}\AppData\Local\CrashDumps',
  '{UserProfile}\AppData\Local\Microsoft\Windows\WER',
  '{UserProfile}\AppData\Local\Microsoft\Windows\INetCache',
  '{UserProfile}\AppData\Local\Microsoft\Windows\WebCache',
  '$env:WINDIR\Temp',
  '$env:ProgramData\Microsoft\Windows\WER'
)

# Expand paths based on -AllUsers flag
$pathsToClean = Expand-UserPaths -PathTemplates $coreTempTemplates -AllUsers:$AllUsers

if ($AllUsers) {
  $userCount = (Get-UserProfiles).Count
  Log "Multi-user mode: Cleaning temp for $userCount user(s)"
}

foreach ($p in $pathsToClean) { 
  # Expand environment variables
  $expandedPath = [Environment]::ExpandEnvironmentVariables($p)
  Clear-Children -Path $expandedPath 
}

# Recycle Bin
Log-Section "Recycle Bin"
if ($DryRun) { 
  Log "[DryRun] Would empty Recycle Bin" 
} else { 
  try { 
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Log "Recycle Bin emptied." 
  } catch { 
    Log "Recycle bin error: $($_.Exception.Message)" 
  } 
}

# =================== Browser caches (all profiles) ===================
if ($IncludeBrowsers) {
  if ($KillBrowsers) { Stop-Processes -Names @('msedge','chrome','firefox') }
  Log-Section "Browser caches"

  Clear-PathTemplates -Templates @(
    '{UserProfile}\AppData\Local\Microsoft\Edge\User Data\*\Cache',
    '{UserProfile}\AppData\Local\Microsoft\Edge\User Data\*\Code Cache',
    '{UserProfile}\AppData\Local\Microsoft\Edge\User Data\*\GPUCache',
    '{UserProfile}\AppData\Local\Microsoft\Edge\User Data\*\Service Worker\CacheStorage',
    '{UserProfile}\AppData\Local\Google\Chrome\User Data\*\Cache',
    '{UserProfile}\AppData\Local\Google\Chrome\User Data\*\Code Cache',
    '{UserProfile}\AppData\Local\Google\Chrome\User Data\*\GPUCache',
    '{UserProfile}\AppData\Local\Google\Chrome\User Data\*\Service Worker\CacheStorage',
    '{UserProfile}\AppData\Roaming\Mozilla\Firefox\Profiles\*\cache2'
  ) -AllUsers:$AllUsers -WildcardPaths
}

# =================== Dev caches ===================
if ($IncludeDevCaches -or $PurgeNuGetPackages -or $SelectivePurgeNuGet) {
  # Safety check: ensure no dev processes are running (unless -Force flag used)
  Assert-SafeForDevCacheCleanup -Force:$Force
}

if ($IncludeDevCaches) {
  
  if ($KillDevTools) { Stop-Processes -Names @('devenv','Code','node','npm','yarn','pnpm') }
  Log-Section "Dev caches (npm/yarn/pnpm, NuGet/dotnet, VS/VSCode)"

  Invoke-ExternalCommand -CommandName 'npm' -Arguments 'cache clean --force' -SuccessMessage 'npm cache cleaned.'
  Invoke-ExternalCommand -CommandName 'yarn' -Arguments 'cache clean' -SuccessMessage 'yarn cache cleaned.'
  Invoke-ExternalCommand -CommandName 'pnpm' -Arguments 'store prune' -SuccessMessage 'pnpm store pruned.'
  
  # ⚠️ SAFE: Only clear temp/http cache, NOT global-packages (prevents build failures)
  Invoke-ExternalCommand -CommandName 'dotnet' -Arguments 'nuget locals temp --clear' -SuccessMessage 'dotnet NuGet temp cache cleared.'
  Invoke-ExternalCommand -CommandName 'dotnet' -Arguments 'nuget locals http-cache --clear' -SuccessMessage 'dotnet NuGet HTTP cache cleared.'

  # Dev cache folder templates
  # NOTE: .nuget\packages cleanup only removes .tmp/.lock files, NOT packages themselves (safe!)
  $devCacheTemplates = @(
    '{UserProfile}\.nuget\packages',
    '{UserProfile}\AppData\Local\Microsoft\VisualStudio\*\ComponentModelCache',
    '{UserProfile}\AppData\Local\Microsoft\VisualStudio\*\MEFCache',
    '{UserProfile}\AppData\Local\Microsoft\VisualStudio\*\Cache',
    '{UserProfile}\AppData\Local\Microsoft\VSCommon\*\ComponentModelCache',
    '{UserProfile}\AppData\Local\Microsoft\VSCommon\*\MEFCache',
    '{UserProfile}\AppData\Local\Microsoft\VSCommon\*\Cache',
    '{UserProfile}\AppData\Roaming\Code\Cache',
    '{UserProfile}\AppData\Roaming\Code\CachedData',
    '{UserProfile}\AppData\Roaming\Code\GPUCache',
    '{UserProfile}\AppData\Roaming\Code\User\workspaceStorage'
  )
  
  $devCachePaths = Expand-UserPaths -PathTemplates $devCacheTemplates -AllUsers:$AllUsers
  
  foreach ($template in $devCachePaths) {
    $expandedPath = [Environment]::ExpandEnvironmentVariables($template)
    
    # Handle wildcard paths
    if ($expandedPath -like '*`**') {
      $matchingDirs = Get-Item $expandedPath -ErrorAction SilentlyContinue
      if ($matchingDirs) {
        foreach ($dir in $matchingDirs) {
          # Remove ONLY .tmp/.lock files from NuGet packages (packages themselves are preserved!)
          if ($dir.FullName -like '*\.nuget\packages') {
            Get-ChildItem $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue |
      Where-Object { $_.Extension -in '.tmp','.lock' } |
      ForEach-Object { Remove-PathSafe -Path $_.FullName -Recurse:$false }
          } else {
            Clear-Children -Path $dir.FullName
          }
        }
      }
    } else {
      # Direct path (no wildcard)
      if ($expandedPath -like '*\.nuget\packages') {
        if (Test-Path $expandedPath) {
          Get-ChildItem $expandedPath -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in '.tmp','.lock' } |
            ForEach-Object { Remove-PathSafe -Path $_.FullName -Recurse:$false }
        }
      } else {
        Clear-Children -Path $expandedPath
      }
    }
    }
  }

# =================== 🚨 NUCLEAR: Purge ALL NuGet Packages ===================
# This runs independently of -IncludeDevCaches for flexibility
# Simulates "fresh clone on new laptop" scenario
if ($PurgeNuGetPackages) {
  Log-Section "🚨 PURGING ALL NuGet Packages (Fresh Clone Mode)"
  
  if ($DryRun) {
    Log "[DryRun] Would run: dotnet nuget locals all --clear"
    Log "[DryRun] ⚠️  This would DELETE ALL downloaded NuGet packages!"
    Log "[DryRun] Next 'dotnet restore' will re-download everything (can take 5-15 minutes)"
  } else {
    Log "⚠️  WARNING: Deleting ALL NuGet packages..."
    Log "   This simulates a fresh repo clone on a new laptop"
    Log "   Next restore will re-download all packages (5-15 minutes)"
    
    $cmd = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($cmd) {
      try {
        dotnet nuget locals all --clear
        Log "✅ All NuGet packages purged! Run 'dotnet restore' to re-download."
      } catch {
        Log "❌ NuGet purge error: $($_.Exception.Message)"
        Log "   If packages are locked, close ALL dev tools and retry"
      }
    } else {
      Log "dotnet CLI not found; skipping NuGet purge"
    }
  }
}

# =================== 💡 SMART: Selective NuGet Purge ===================
# Keeps Microsoft.*/System.* framework packages (500+ MB, takes 5-10 min to restore)
# Purges third-party and custom packages (faster restore, ~2-3 minutes)
if ($SelectivePurgeNuGet) {
  Log-Section "💡 SMART: Selective NuGet Purge (Keeping Framework Packages)"
  
  $packagesDir = "$env:USERPROFILE\.nuget\packages"
  
  if (-not (Test-Path $packagesDir)) {
    Log "NuGet packages directory not found; skipping selective purge"
  } else {
    # Define packages to KEEP (framework packages that rarely change)
    $keepPrefixes = @(
      # Core .NET Framework
      'microsoft.aspnetcore',
      'microsoft.extensions',
      'microsoft.entityframeworkcore',
      'microsoft.csharp',
      'microsoft.win32',
      'microsoft.visualbasic',
      'microsoft.net.http',
      'microsoft.identity',
      'system.',
      'netstandard',
      'newtonsoft.json',
      'runtime.',
      'windowsbase',
      
      # Testing Infrastructure (stable, rarely changes)
      'xunit',
      'microsoft.testplatform',
      'microsoft.codecoverage',
      'microsoft.net.test.sdk',
      
      # Code Analysis (Roslyn - very stable)
      'microsoft.codeanalysis',
      
      # gRPC/Protobuf (core infrastructure)
      'grpc',
      'google.protobuf',
      'google.api',
      
      # Database Drivers (stable)
      'npgsql',
      
      # API Documentation (very stable)
      'swashbuckle',
      'microsoft.openapi',
      'serilog',
      'opentelemetry',
      'fluentvalidation',
      'fluentassertions',
      'masstransit'
    )
    
    if ($DryRun) {
      Log "[DryRun] Would selectively purge NuGet packages..."
      Log "[DryRun] Keeping: Microsoft.AspNetCore.*, Microsoft.Extensions.*, System.*, etc."
      Log "[DryRun] Purging: All other third-party and custom packages"
      
      $allPackages = Get-ChildItem $packagesDir -Directory -ErrorAction SilentlyContinue
      $keptCount = 0
      $purgeCount = 0
      $keptSize = 0
      $purgeSize = 0
      
      foreach ($pkg in $allPackages) {
        $pkgName = $pkg.Name.ToLowerInvariant()
        $shouldKeep = $false
        
        foreach ($prefix in $keepPrefixes) {
          if ($pkgName -like "$prefix*") {
            $shouldKeep = $true
            break
          }
        }
        
        $pkgSize = (Get-ChildItem $pkg.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        
        if ($shouldKeep) {
          $keptCount++
          $keptSize += $pkgSize
        } else {
          $purgeCount++
          $purgeSize += $pkgSize
        }
      }
      
      Log "[DryRun] Would KEEP: $keptCount packages ($(Format-FileSize -Bytes $keptSize))"
      Log "[DryRun] Would PURGE: $purgeCount packages ($(Format-FileSize -Bytes $purgeSize))"
      Log "[DryRun] Next restore will only re-download $purgeCount packages (~2-3 minutes)"
    } else {
      Log "Analyzing packages..."
      
      $allPackages = Get-ChildItem $packagesDir -Directory -ErrorAction SilentlyContinue
      $keptPackages = @()
      $purgedPackages = @()
      $purgedSize = 0
      
      foreach ($pkg in $allPackages) {
        $pkgName = $pkg.Name.ToLowerInvariant()
        $shouldKeep = $false
        
        foreach ($prefix in $keepPrefixes) {
          if ($pkgName -like "$prefix*") {
            $shouldKeep = $true
            break
          }
        }
        
        if ($shouldKeep) {
          $keptPackages += $pkg.Name
        } else {
          # Purge this package
          $pkgSize = (Get-ChildItem $pkg.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
          try {
            Remove-Item -LiteralPath $pkg.FullName -Recurse -Force -ErrorAction Stop
            $purgedPackages += $pkg.Name
            $purgedSize += $pkgSize
          } catch {
            Log "⚠️  Could not remove $($pkg.Name): $($_.Exception.Message)"
          }
        }
      }
      
      Log "✅ KEPT $($keptPackages.Count) framework packages (Microsoft.*, System.*, etc.)"
      Log "✅ PURGED $($purgedPackages.Count) third-party packages ($(Format-FileSize -Bytes $purgedSize))"
      Log "   Next restore will only download ~$($purgedPackages.Count) packages (2-3 minutes)"
      
      # Also clear temp/HTTP cache
      $cmd = Get-Command dotnet -ErrorAction SilentlyContinue
      if ($cmd) {
        try {
          dotnet nuget locals temp --clear | Out-Null
          dotnet nuget locals http-cache --clear | Out-Null
          Log "✅ Cleared NuGet temp/HTTP cache"
        } catch {
          Log "⚠️  Error clearing NuGet cache: $($_.Exception.Message)"
        }
      }
    }
  }
}

# =================== Windows Update cache ===================
if ($PurgeUpdateCaches -or $Aggressive) {
  Log-Section "Windows Update cache"
  Invoke-ServiceWrappedCleanup -ServiceNames @('wuauserv', 'bits') -CleanupAction {
  $wuPaths = @(
    "$env:WINDIR\SoftwareDistribution\Download",
    "$env:WINDIR\SoftwareDistribution\DataStore\Logs\*.log"
  )
  foreach ($p in $wuPaths) {
    if ($p -like "*.log") {
      if ($DryRun) { Log "[DryRun] Would remove logs: $p" }
      else { Get-ChildItem $p -Force -ErrorAction SilentlyContinue | ForEach-Object { Remove-PathSafe -Path $_.FullName -Recurse:$false } }
    } else { Clear-Children -Path $p }
  }
  }
}

# =================== Delivery Optimization cache ===================
if ($PurgeDeliveryOptCaches -or $Aggressive) {
  Log-Section "Delivery Optimization cache"
  Invoke-ServiceWrappedCleanup -ServiceNames @('DoSvc') -CleanupAction {
  Clear-Children -Path "$env:ProgramData\Microsoft\Windows\DeliveryOptimization\Cache"
  }
}

# =================== Thumbnails & icon cache ===================
if ($ClearThumbs) {
  Log-Section "Thumbnail cache"
  Clear-FilesWithSummary -PathTemplates @('{UserProfile}\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*') -AllUsers:$AllUsers -ItemType 'thumbnail files'
}
if ($ClearIconCache) {
  Log-Section "Icon cache"
  Clear-FilesWithSummary -PathTemplates @(
    '{UserProfile}\AppData\Local\IconCache.db',
    '{UserProfile}\AppData\Local\Microsoft\Windows\Explorer\iconcache_*'
  ) -AllUsers:$AllUsers -ItemType 'icon cache files'
}

# =================== Prefetch (optional) ===================
if ($IncludePrefetch -or $Aggressive) {
  Log-Section "Prefetch"
  Clear-Children -Path "$env:WINDIR\Prefetch"
}

# =================== Event logs (optional) ===================
if ($ClearEventLogs) {
  Log-Section "Clearing Windows event logs"
  $logs = wevtutil el 2>$null
  foreach ($log in $logs) {
    if ($DryRun) { Log "[DryRun] Would clear event log: $log" }
    else { try { wevtutil cl "$log" 2>$null; Log "Cleared: $log" } catch { $err = $_.Exception.Message; Log "Failed to clear $log`: $err" } }
  }
}

# =================== DISM StartComponentCleanup (safe) ===================
if ($Aggressive) {
  Log-Section "DISM StartComponentCleanup"
  if ($DryRun) { 
    Log "[DryRun] Would run: Dism.exe /Online /Cleanup-Image /StartComponentCleanup" 
  } else { 
    try { 
      Start-Process -FilePath "Dism.exe" -ArgumentList "/Online","/Cleanup-Image","/StartComponentCleanup" -Wait -NoNewWindow
      Log "DISM StartComponentCleanup done." 
    } catch { 
      Log "DISM error: $($_.Exception.Message)" 
    } 
  }
}

# =================== Optional Dev/Platform maintenance ===================
# These run BEFORE Windows built-ins. All are safe, optional and gated by flags.

if ($AngularCacheClean) {
  Log-Section "Angular CLI cache"
  Invoke-ExternalCommand -CommandName 'ng' -Arguments 'cache clean' -SuccessMessage 'Angular cache cleaned.' -NotFoundMessage 'Angular CLI not found; skipping.'
}

if ($MSBuildExtraClean) {
  Log-Section "MSBuild temp"
  Clear-PathTemplates -Templates @('{UserProfile}\AppData\Local\Microsoft\MSBuild') -AllUsers:$AllUsers -NotFoundMessage 'No MSBuild temp folders found'
}

if ($JetBrainsCaches) {
  Log-Section "JetBrains caches"
  Clear-PathTemplates -Templates @(
    '{UserProfile}\AppData\Local\JetBrains\*\caches',
    '{UserProfile}\AppData\Local\JetBrains\*\system'
  ) -AllUsers:$AllUsers -WildcardPaths -NotFoundMessage 'No JetBrains caches found' -SuccessMessage 'JetBrains caches cleared'
}

if ($DockerPrune) {
  Log-Section "Docker prune (safe: preserves ALL containers + their dependencies)"
  $docker = Get-Command docker -ErrorAction SilentlyContinue
  if ($docker) {
    # Check if Docker daemon is running
    $dockerRunning = $false
    try {
      docker info 2>&1 | Out-Null
      $dockerRunning = ($LASTEXITCODE -eq 0)
    } catch { $dockerRunning = $false }
    
    if (-not $dockerRunning) {
      Log "⚠ Docker daemon not running; skipping Docker cleanup"
    } elseif ($DryRun) {
      Log "[DryRun] Would run: docker builder prune -a -f (remove build cache)"
      Log "[DryRun] Would run: docker image prune -a -f (remove unused images NOT referenced by containers)"
      Log "[DryRun] Would run: docker volume prune -f (remove volumes NOT attached to containers)"
      Log "[DryRun] Would run: docker network prune -f (remove unused networks)"
      Log "[DryRun] NOTE: ALL containers (running + stopped) are preserved, so you can run them anytime"
    } else {
      $dockerOps = 0
      try { docker builder prune -a -f 2>&1 | Out-Null; $dockerOps++ } catch { }
      try { docker image prune -a -f 2>&1 | Out-Null; $dockerOps++ } catch { }
      try { docker volume prune -f 2>&1 | Out-Null; $dockerOps++ } catch { }
      try { docker network prune -f 2>&1 | Out-Null; $dockerOps++ } catch { }
      if ($dockerOps -gt 0) {
        Log "✓ Docker cleanup complete ($dockerOps operations). All containers preserved - ready to run!"
      }
    }
  } else { Log "Docker CLI not found; skipping." }
}

if ($WSLCleanup) {
  Log-Section "WSL cleanup"
  if ($DryRun) { 
    Log "[DryRun] Would run: wsl --shutdown" 
  } else { 
    try { 
      wsl --shutdown
      Log "WSL shut down." 
    } catch { 
      Log "WSL shutdown error: $($_.Exception.Message)" 
    } 
  }
  
  # Optional VHDX compact if Hyper-V module and ext4.vhdx present
  $optVhd = Get-Command Optimize-VHD -ErrorAction SilentlyContinue
  if ($optVhd) {
    $vhdx = Get-ChildItem "$env:LOCALAPPDATA\Packages" -Recurse -Filter ext4.vhdx -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($vhdx) {
      if ($DryRun) { 
        Log "[DryRun] Would Optimize-VHD -Path '$($vhdx.FullName)' -Mode Full" 
      } else {
        try { 
          Optimize-VHD -Path $vhdx.FullName -Mode Full -ErrorAction SilentlyContinue
          Log "WSL VHDX compacted: $($vhdx.FullName)" 
        } catch { 
          Log "Optimize-VHD error: $($_.Exception.Message)" 
        }
      }
    } else { Log "WSL VHDX not found for compact; skipping." }
  } else { Log "Hyper-V Optimize-VHD not available; skipping compact." }
}

# =================== Additional Language/Dev Caches ===================

if ($PythonPipCache) {
  Log-Section "Python pip cache"
  Invoke-ExternalCommand -CommandName 'pip' -Arguments 'cache purge' -SuccessMessage 'Pip cache purged.' -NotFoundMessage 'pip not found; skipping.'
  Clear-PathTemplates -Templates @('{UserProfile}\AppData\Local\pip\cache') -AllUsers:$AllUsers
}

if ($RustCargoCache) {
  Log-Section "Rust Cargo cache"
  Clear-PathTemplates -Templates @('{UserProfile}\.cargo\registry\cache') -AllUsers:$AllUsers -NotFoundMessage 'No Cargo cache found'
}

if ($GoModCache) {
  Log-Section "Go modules cache"
  Invoke-ExternalCommand -CommandName 'go' -Arguments 'clean -modcache' -SuccessMessage 'Go modules cache cleaned.' -NotFoundMessage 'go not found; skipping.'
}

if ($GradleCache) {
  Log-Section "Gradle caches"
  Clear-PathTemplates -Templates @('{UserProfile}\.gradle\caches') -AllUsers:$AllUsers -SuccessMessage 'Gradle caches cleared'
}

if ($MavenCache) {
  Log-Section "Maven repository (WARNING: large re-downloads)"
  Clear-PathTemplates -Templates @('{UserProfile}\.m2\repository') -AllUsers:$AllUsers -NotFoundMessage 'No Maven repository found'
}

# =================== Performance Boosters ===================

if ($ClearFontCache) {
  Log-Section "Font cache (improves app launch speed)"
  if ($DryRun) {
    Log "[DryRun] Would clear font cache and restart service"
  } else {
    Invoke-ServiceWrappedCleanup -ServiceNames @('FontCache') -CleanupAction {
      $fontCachePath = "$env:WINDIR\ServiceProfiles\LocalService\AppData\Local\FontCache"
      $fontFilesRemoved = 0
      $fontBytesFreed = 0
      if (Test-Path $fontCachePath) {
        $fontFiles = Get-ChildItem $fontCachePath -Filter "*.dat" -ErrorAction SilentlyContinue
        foreach ($file in $fontFiles) {
          $size = $file.Length
          Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
          $fontFilesRemoved++
          $fontBytesFreed += $size
          $script:SessionFilesRemoved++
          $script:SessionBytesFreed += $size
        }
      }
      if ($fontFilesRemoved -gt 0) {
        Log "✓ Font cache cleared: $fontFilesRemoved files ($(Format-FileSize -Bytes $fontBytesFreed))"
      } else {
        Log "✓ Font cache service restarted"
      }
    }
  }
}

if ($ResetWindowsStore) {
  Log-Section "Windows Store cache reset"
  if ($DryRun) { Log "[DryRun] Would run: WSReset.exe (hidden)" }
  else {
    try {
      # Start WSReset in background, wait for it to complete, then kill the Store if it opens
      $wsreset = Start-Process "WSReset.exe" -WindowStyle Hidden -PassThru -ErrorAction SilentlyContinue
      if ($wsreset) {
        Start-Sleep -Seconds 3  # Give it time to complete
        # Kill WinStore.App if it auto-opened
        Get-Process -Name "WinStore.App" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
      }
      Log "Windows Store cache reset completed (Store prevented from opening)."
    } catch { Log "WSReset error: $($_.Exception.Message)" }
  }
}

if ($ClearNotificationsDB) {
  Log-Section "Notifications database"
  $notifPaths = Expand-UserPaths -PathTemplates @('{UserProfile}\AppData\Local\Microsoft\Windows\Notifications\wpndatabase.db') -AllUsers:$AllUsers
  foreach ($path in $notifPaths) {
    $expandedPath = [Environment]::ExpandEnvironmentVariables($path)
    if (Test-Path $expandedPath) {
      if ($DryRun) { 
        Log "[DryRun] Would remove: $expandedPath" 
      } else { 
        Remove-PathSafe -Path $expandedPath -Recurse:$false 
      }
    }
  }
}

if ($ClearRecentJumpLists) {
  Log-Section "Recent files and jump lists"
  $recentTemplates = @('{UserProfile}\AppData\Roaming\Microsoft\Windows\Recent')
  $recentPaths = Expand-UserPaths -PathTemplates $recentTemplates -AllUsers:$AllUsers
  
  $clearedCount = 0
  $totalFilesCleared = 0
  $totalBytesCleared = 0
  
  foreach ($path in $recentPaths) {
    $expandedPath = [Environment]::ExpandEnvironmentVariables($path)
    if (Test-Path $expandedPath) {
      if ($DryRun) { 
        Log "[DryRun] Would clear: $expandedPath" 
      } else { 
        # Count files before clearing (silent mode to avoid individual logs)
        $beforeCount = $script:SessionFilesRemoved
        $beforeBytes = $script:SessionBytesFreed
        Clear-Children -Path $expandedPath -Silent
        $totalFilesCleared += ($script:SessionFilesRemoved - $beforeCount)
        $totalBytesCleared += ($script:SessionBytesFreed - $beforeBytes)
        $clearedCount++
      }
    }
  }
  
  if (-not $DryRun -and $clearedCount -gt 0) {
    if ($AllUsers) {
      Log "✓ Recent files cleared for $clearedCount user(s) ($totalFilesCleared files, $(Format-FileSize -Bytes $totalBytesCleared))"
    } else {
      Log "✓ Recent files and jump lists cleared"
    }
  }
}

# Clear Windows Defender scan cache (safe, auto-rebuilds)
if ($Aggressive) {
  Log-Section "Windows Defender scan cache"
  $defenderCache = "$env:ProgramData\Microsoft\Windows Defender\Scans\History"
  if (Test-Path $defenderCache) {
    if ($DryRun) { 
      Log "[DryRun] Would clear: $defenderCache" 
    } else { 
      Clear-Children -Path $defenderCache
      Log "Windows Defender scan cache cleared." 
    }
  } else { 
    Log "Defender scan cache not found; skipping." 
  }
}

# Clear Windows Error Reporting archives (safe, diagnostic data only)
if ($Aggressive) {
  Log-Section "Windows Error Reporting archives"
  $werPaths = @(
    "$env:ProgramData\Microsoft\Windows\WER\ReportQueue",
    "$env:ProgramData\Microsoft\Windows\WER\ReportArchive"
  )
  foreach ($werPath in $werPaths) {
    if (Test-Path $werPath) {
      if ($DryRun) { Log "[DryRun] Would clear: $werPath" }
      else { Clear-Children -Path $werPath }
    }
  }
  if (-not $DryRun) { Log "✓ WER archives cleared (diagnostic data)" }
}

# Clear IIS logs (optional, only if IIS installed)
if ($IISLogs) {
  Log-Section "IIS web server logs"
  $iisLogPath = "$env:SystemDrive\inetpub\logs\LogFiles"
  if (Test-Path $iisLogPath) {
    if ($DryRun) { 
      Log "[DryRun] Would clear: $iisLogPath" 
    } else { 
      Clear-Children -Path $iisLogPath
      Log "✓ IIS logs cleared" 
    }
  } else { 
    Log "IIS not installed or logs not found; skipping." 
  }
}

# =================== Windows built-ins block ===================
if ($RunWindowsBuiltins) {
  if (Test-PendingReboot) { 
    Log "Pending reboot detected; deferring DISM/SFC/cleanmgr. Reboot then re-run for full effect."
    if ($script:DeferredOperations -notcontains "Windows built-in tools (cleanmgr, DISM, SFC)") {
      $script:DeferredOperations += "Windows built-in tools (cleanmgr, DISM, SFC)"
    }
  }
  else {
    Log-Section "Windows built-ins (Cleanmgr/DISM/SFC)"

    # (1) Storage Sense policy: NEVER delete Downloads (per-user)
    if ($EnforceNoDownloadsClean) {
      try {
        $pol = "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
        if ($DryRun) { Log "[DryRun] Would enforce Storage Sense 'Never delete Downloads' (HKCU policy)." }
        else { New-Item -Path $pol -Force | Out-Null; New-ItemProperty -Path $pol -Name "01" -Type DWord -Value 0 -Force | Out-Null; Log "Enforced Storage Sense: never delete Downloads (HKCU)." }
      } catch { Log "Storage Sense policy error: $($_.Exception.Message)" }
    }

    # (2) Preselect Disk Cleanup handlers EXCLUDING DownloadsFolder
    try {
      $vc = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
      function Enable-Handler([string]$keyName){ $path = Join-Path $vc $keyName; if (Test-Path $path) { if ($DryRun) { Log "[DryRun] Would enable cleanmgr handler: $keyName" } else { New-ItemProperty -Path $path -Name "StateFlags0001" -PropertyType DWord -Value 2 -Force | Out-Null; Log "Enabled handler: $keyName" } } }
      function Disable-Handler([string]$keyName){ $path = Join-Path $vc $keyName; if (Test-Path $path) { if ($DryRun) { Log "[DryRun] Would disable handler: $keyName" } else { New-ItemProperty -Path $path -Name "StateFlags0001" -PropertyType DWord -Value 0 -Force | Out-Null; Log "Disabled handler: $keyName" } } }

      $enable = @(
        "Temporary Files",
        "Temporary Setup Files",
        "Downloaded Program Files",
        "Internet Cache Files",
        "Delivery Optimization Files",
        "Old Chkdsk Files",
        "Recycle Bin",
        "System error memory dump files",
        "System error minidump files",
        "Windows Error Reporting Files",
        "Windows Upgrade Log Files",
        "Device Driver Packages",
        "Previous Installations",
        "Update Cleanup"
      )
      foreach($k in $enable){ Enable-Handler $k }
      Disable-Handler "DownloadsFolder"  # DO NOT touch Downloads

      if ($DryRun) { Log "[DryRun] Would run: cleanmgr.exe /sagerun:1" }
      else { Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -Wait; Log "cleanmgr /sagerun:1 completed." }
    } catch { Log "Cleanmgr selection error: $($_.Exception.Message)" }

    # (3) DISM component cleanup (+ optional ResetBase)
    if ($DryRun) {
      Log "[DryRun] Would run: DISM /Online /Cleanup-Image /StartComponentCleanup"
      if ($DeepComponentCleanup) { Log "[DryRun] Would run: DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase" }
    } else {
      try {
        if ($DeepComponentCleanup) {
          Start-Process -FilePath "Dism.exe" -ArgumentList "/Online","/Cleanup-Image","/StartComponentCleanup","/ResetBase" -Wait -NoNewWindow
          Log "DISM StartComponentCleanup /ResetBase completed."
        } else {
          Start-Process -FilePath "Dism.exe" -ArgumentList "/Online","/Cleanup-Image","/StartComponentCleanup" -Wait -NoNewWindow
          Log "DISM StartComponentCleanup completed."
        }
      } catch { Log "DISM built-ins error: $($_.Exception.Message)" }
    }

    # (4) SFC integrity pass (no deletions)
    if ($DryRun) { Log "[DryRun] Would run: sfc /scannow" }
    else { try { Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow; Log "SFC scan completed." } catch { Log "SFC error: $($_.Exception.Message)" } }
  }
}

# =================== Final ===================
$endTime = Get-Date
Log ("`n=== Cleanup complete {0} ===" -f $endTime)

if ($DryRun) {
  if ($script:TotalBytesToFree -gt 0) {
    $totalStr = Format-FileSize -Bytes $script:TotalBytesToFree
    $summaryMsg = "📊 DRY RUN SUMMARY: Total space to be freed: $totalStr"
    Log "`n$summaryMsg"
    # Note: Log already outputs to console via Tee-Object, no need for Write-Host
  }
} else {
  if ($script:SessionFilesRemoved -gt 0 -or $script:SessionBytesFreed -gt 0) {
    $freedStr = Format-FileSize -Bytes $script:SessionBytesFreed
    $summaryMsg = "📊 CLEANUP SUMMARY: $($script:SessionFilesRemoved) files removed, $freedStr freed"
    Log "`n$summaryMsg"
    # Note: Log already outputs to console via Tee-Object, no need for Write-Host
  }
}

# Post-reboot reminder
if (-not $DryRun -and $script:DeferredOperations.Count -gt 0) {
  # Deduplicate deferred operations
  $uniqueDeferred = @($script:DeferredOperations | Select-Object -Unique)
  
  if ($uniqueDeferred.Count -gt 0) {
    Write-Host "" # Blank line
    Log "⚠️  REBOOT REQUIRED - Some operations were deferred:"
    Log "═══════════════════════════════════════════════════════════"
    Log "The following operations were SKIPPED due to pending reboot:"
    foreach ($op in $uniqueDeferred) {
      Log "   • $op"
    }
    Log ""
    Log "📋 TO COMPLETE CLEANUP:"
    Log "   1. Reboot your computer now"
    Log "   2. Run this script again with the SAME parameters"
    Log ""
    Log "💡 Quick re-run command:"
    
    # Reconstruct the command line
    $rerunParams = @()
    if ($Aggressive) { $rerunParams += "-Aggressive" }
    if ($IncludeBrowsers) { $rerunParams += "-IncludeBrowsers" }
    if ($IncludeDevCaches) { $rerunParams += "-IncludeDevCaches" }
    if ($PurgeUpdateCaches) { $rerunParams += "-PurgeUpdateCaches" }
    if ($PurgeDeliveryOptCaches) { $rerunParams += "-PurgeDeliveryOptCaches" }
    if ($ClearThumbs) { $rerunParams += "-ClearThumbs" }
    if ($ClearIconCache) { $rerunParams += "-ClearIconCache" }
    if ($IncludePrefetch) { $rerunParams += "-IncludePrefetch" }
    if ($KillBrowsers) { $rerunParams += "-KillBrowsers" }
    if ($KillDevTools) { $rerunParams += "-KillDevTools" }
    if ($DockerPrune) { $rerunParams += "-DockerPrune" }
    if ($WSLCleanup) { $rerunParams += "-WSLCleanup" }
    if ($AngularCacheClean) { $rerunParams += "-AngularCacheClean" }
    if ($JetBrainsCaches) { $rerunParams += "-JetBrainsCaches" }
    if ($MSBuildExtraClean) { $rerunParams += "-MSBuildExtraClean" }
    if ($PythonPipCache) { $rerunParams += "-PythonPipCache" }
    if ($RustCargoCache) { $rerunParams += "-RustCargoCache" }
    if ($GoModCache) { $rerunParams += "-GoModCache" }
    if ($GradleCache) { $rerunParams += "-GradleCache" }
    if ($MavenCache) { $rerunParams += "-MavenCache" }
    if ($PurgeNuGetPackages) { $rerunParams += "-PurgeNuGetPackages" }
    if ($SelectivePurgeNuGet) { $rerunParams += "-SelectivePurgeNuGet" }
    if ($ClearFontCache) { $rerunParams += "-ClearFontCache" }
    if ($ResetWindowsStore) { $rerunParams += "-ResetWindowsStore" }
    if ($ClearNotificationsDB) { $rerunParams += "-ClearNotificationsDB" }
    if ($ClearRecentJumpLists) { $rerunParams += "-ClearRecentJumpLists" }
    if ($ExcludeFromDefender) { $rerunParams += "-ExcludeFromDefender" }
    if ($RunWindowsBuiltins) { $rerunParams += "-RunWindowsBuiltins" }
    if ($DeepComponentCleanup) { $rerunParams += "-DeepComponentCleanup" }
    if ($AllUsers) { $rerunParams += "-AllUsers" }
    if ($IISLogs) { $rerunParams += "-IISLogs" }
    $rerunParams += "-DryRun:`$false"
    
    $rerunCmd = ".\Clean-AllTemps-NoDownloads.ps1 $($rerunParams -join ' ')"
    Log "   $rerunCmd"
    Log "═══════════════════════════════════════════════════════════"
  }
}

Write-Host "`nDone. Log: $LogPath" -ForegroundColor Green
if (-not $DryRun) { 
  if ($script:DeferredOperations.Count -gt 0) {
    Write-Host "⚠️  REBOOT NOW to complete cleanup!" -ForegroundColor Yellow
  } else {
    Write-Host "✅ Reboot recommended for best results." -ForegroundColor Green
  }
}
