# SKILL.md

## How to Use This Tool
- Run the main cleanup script from `src/` (see README for exact filename).
- Dry-run mode: preview changes without applying — pass the dry-run flag before committing.
- Run as Administrator for full effect (system temp, Windows Update cache, etc.).

## Plugging Into Workflows
- Run periodically (weekly or before low-disk alerts) to reclaim disk space.
- Safe to run alongside active dev sessions — Downloads folder is never touched.
- Pair with `windows-setup` scripts for a full machine maintenance routine.

## Insights
- Cleans: browser caches (Chrome/Edge/Firefox), npm/yarn/pnpm/NuGet/Docker/WSL caches, Windows Update delivery optimization, prefetch, font cache.
- Adds Windows Defender exclusions for temp/cache dirs to reduce CPU overhead.
- Multi-threaded cleanup — faster than sequential scripts.
- Warns if dev tools are running (file lock prevention).

---

## Required Params

- No environment-specific params required.

## Context Overlay

Public skill files stay generic. Context-specific continuation belongs in:
- params/windows-speedup-via-cleanup/skills/windows-speedup-via-cleanup.overlay.md
