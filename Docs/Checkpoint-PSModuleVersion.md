# Guide: Checkpoint-PSModuleVersion

`Checkpoint-PSModuleVersion` creates a verified backup of a module working tree, raises the
module version and keeps the version information in the project files consistent. Optionally it
commits, pushes, creates a branch or builds a release folder.

It does not analyze a module and does not upload anything to the PowerShell Gallery.

## Contents

- [Prerequisites](#prerequisites)
- [Folder layout](#folder-layout)
- [Quick start](#quick-start)
- [What a checkpoint does](#what-a-checkpoint-does)
- [Git actions](#git-actions)
- [Release folder](#release-folder)
- [Rollback and reset](#rollback-and-reset)
- [Organize old backups](#organize-old-backups)
- [Parameter overview](#parameter-overview)
- [Safety](#safety)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- PowerShell 7+ (the path checks use `[IO.Path]::IsPathFullyQualified`, which Windows PowerShell
  5.1 does not provide), the PSModuleQuantityAnalyzer module imported.
- Git on the `PATH` for every Git action, `-NewRelease` and `-ResetBranch`.
- The module working folder contains `<Module>.psd1`, `<Module>.psm1`, `README.md` and
  `ChangeLog.md`.
  - `README.md` and `ChangeLog.md` contain the lines `Current Version:` and `Last Update:`.
  - `ChangeLog.md` already has at least one entry starting with `- Version `.
- The project-root environment variable (see below), or all four folder parameters.

## Folder layout

The function expects one project root with four sub folders:

```text
C:\GitHub\AS2GO
├─ Dev        working tree of the module (Git repository root)
├─ Backup     checkpoint backups   Backup\<year>\<month>\<version>
├─ Release    release copies       Release\<ModuleVersion>
└─ Archive    monthly ZIP files    <Module>_<year>.<month>.zip
```

`Backup`, `Release` and `Archive` must be outside `Dev`, and `Archive` must be outside `Backup`.

### Project-root environment variable

The root is read from an environment variable named like the module (upper case is used, Windows
is not case sensitive). Set it in the current session before the first call:

```powershell
$env:AS2Go = "C:\GitHub\AS2GO"
```

The value must be an absolute path. To make it permanent, set it as a user environment variable:

```powershell
[Environment]::SetEnvironmentVariable('AS2Go', 'C:\GitHub\AS2GO', 'User')
```

A permanent variable is only visible in sessions started afterwards.

Each folder parameter (`-SourceFolder`, `-BackupFolder`, `-ReleaseFolder`, `-ArchiveFolder`)
overrides its default independently. If you pass all four, no environment variable is needed:

```powershell
$Settings = @{
    SourceFolder  = 'C:\GitHub\AS2GO\Dev'
    BackupFolder  = 'C:\GitHub\AS2GO\Backup'
    ReleaseFolder = 'C:\GitHub\AS2GO\Release'
    ArchiveFolder = 'C:\GitHub\AS2GO\Archive'
}
Checkpoint-PSModuleVersion -Module AS2Go @Settings
```

## Quick start

Preview first. `-WhatIf` shows the old and new version and the backup target, and changes nothing:

```powershell
$env:AS2Go = "C:\GitHub\AS2GO"
Checkpoint-PSModuleVersion -Module AS2Go -WhatIf
```

Create the checkpoint without Git:

```powershell
Checkpoint-PSModuleVersion -Module AS2Go
```

Create the checkpoint and a local commit with a message:

```powershell
Checkpoint-PSModuleVersion -Module AS2Go -Commit 'Update help'
```

## What a checkpoint does

1. Reads the current version from `<Module>.psd1`.
2. Calculates the new version `yyyy.M.d.<minutes since midnight>`, for example `2026.11.21.1101`.
   If this is not higher than the current version (second checkpoint in the same minute), the
   last number is increased by one. Versions only ever increase.
3. Copies **all** files of the working folder (including ignored ones, excluding `.git`) to
   `Backup\<year>\<month>\<old version>`. Every file is hash-checked (SHA256) after copying.
   An existing backup folder is never overwritten; a repeated snapshot gets the suffix `-001`,
   `-002` and so on.
4. Updates version and date in:

   | File | Change |
   | --- | --- |
   | `<Module>.psd1` | `ModuleVersion` and `LastUpdate` |
   | `<Module>.psm1` | only the lines `###### ModuleVersion = '…'` and `###### LastUpdate = '…'`, if present |
   | `README.md` | `Current Version:` and `Last Update:` lines, version in `git commit -m 'Version …'` examples |
   | `ChangeLog.md` | same header lines, plus a new entry `- Version <new>` on top |
   | `<Module>.code-workspace` | version suffix of the folder with path `.` (`Dev \| 2026.11.21.1101`), if the file exists |

5. Validates that the manifest still loads and contains the new version.

All text changes are prepared in memory first. If anything fails before the backup, no file is
modified.

The text of the new `ChangeLog.md` entry is the value of `-Commit`. Without `-Commit` it is the
placeholder `Checkpoint`, so pass a meaningful message whenever the entry should be useful.

## Git actions

Any of `-Commit`, `-NewBranch` and `-Push` turns on Git handling. `-SourceFolder` must then be the
repository root, and there must be no unresolved merge conflicts.

| Parameter | Effect |
| --- | --- |
| `-Commit 'text'` | `git add -A`, then commits as `<version> \| text` and writes `text` into the changelog |
| `-NewBranch 'name'` | commits on the **current** branch first, then creates and switches to the new branch. A start reference is saved for `-ResetBranch` |
| `-Push CurrentBranch` | pushes the current (or newly created) branch to `origin` |
| `-Push ToMain` | fast-forwards local `main` to the current branch and pushes `main`; cannot be combined with `-NewBranch` |

`-Push ToMain` stops if local or remote `main` contains commits that the current branch does not
have. Merge `main` into your branch first. Force-push is never used.

Author and committer default to `HerrHoZi <zimmermann.holger@live.de>`. Override them with
`-AuthorName` and `-AuthorEmail`. Your Git configuration is not changed.

Typical flows:

```powershell
# Work on a feature branch
Checkpoint-PSModuleVersion -Module AS2Go -NewBranch 'feature/Ptt' -Commit 'Start Ptt'

# Publish the current branch
Checkpoint-PSModuleVersion -Module AS2Go -Push CurrentBranch -Commit 'Update help'

# Bring finished work to main
Checkpoint-PSModuleVersion -Module AS2Go -Push ToMain -Commit 'Publish current changes'
```

## Release folder

```powershell
Checkpoint-PSModuleVersion -Module AS2Go -NewRelease
```

Copies the working files to `Release\<ModuleVersion>` and replaces that folder if it already
exists. Files ignored by Git (including nested `.gitignore` files and ignored tracked files) are
left out, so the release contains only what belongs to the module. The manifest must not be
ignored.

`-NewRelease` does not change the version: it uses the version currently in the manifest. Run a
normal checkpoint first if the release should carry a new version. Review the folder before you
use `Publish-Module` yourself.

## Rollback and reset

Both actions save the current state first, so they can be undone.

```powershell
# Restore the working files from a backup (always preview first)
Checkpoint-PSModuleVersion -Module AS2Go -Rollback 'C:\GitHub\AS2GO\Backup\2026\10\2026.10.24.600' -WhatIf
Checkpoint-PSModuleVersion -Module AS2Go -Rollback 'C:\GitHub\AS2GO\Backup\2026\10\2026.10.24.600'

# Reset the current branch to the commit where -NewBranch created it
Checkpoint-PSModuleVersion -Module AS2Go -ResetBranch -WhatIf
```

- `-Rollback` saves the current files to `Backup\<year>\<month>\BeforeRollback-<id>`, restores
  the backup and **removes files that are not in the backup**. Git history is unchanged.
- `-ResetBranch` saves all files to `BeforeBranchReset-<id>`, then runs `git reset --hard` to the
  saved start commit and `git clean -fdx`, which deletes untracked **and ignored** files. It only
  works for branches created with `-NewBranch`, and never touches the remote.
- Neither can be combined with commit, branch, push or release switches.

## Organize old backups

```powershell
Checkpoint-PSModuleVersion -Module AS2Go -OrganizeBackups
```

Moves legacy backup folders and ZIPs from `Backup\<year>` into `Backup\<year>\<month>` and creates
one ZIP per month in `Archive` (`AS2Go_2026.11.zip`). A ZIP is published only after every entry
has been verified by hash. The source backups stay in place. ZIP files do not contain `.git` or
Git administrative files such as `.gitignore`.

## Parameter overview

| Parameter | Description |
| --- | --- |
| `-Module` | Module name (mandatory): manifest and module file name, and name of the project-root environment variable |
| `-SourceFolder` | Working folder; default `<root>\Dev` |
| `-BackupFolder` | Backup root; default `<root>\Backup` |
| `-ReleaseFolder` | Release root; default `<root>\Release` |
| `-ArchiveFolder` | Archive folder; default `<root>\Archive` |
| `-Commit` | Commit message and changelog text; enables a local commit |
| `-NewBranch` | Creates and switches to a new branch after committing |
| `-Push` | `CurrentBranch` or `ToMain` |
| `-NewRelease` | Builds `Release\<ModuleVersion>` |
| `-Rollback` | Backup folder to restore |
| `-ResetBranch` | Reset the branch to its saved start commit |
| `-OrganizeBackups` | Sort backups and create monthly ZIPs |
| `-AuthorName`, `-AuthorEmail` | Git author and committer for this call only |
| `-WhatIf`, `-Confirm` | Preview or confirm each step |

`-Rollback`, `-ResetBranch` and `-OrganizeBackups` are mutually exclusive.

## Safety

- Use `-WhatIf` before `-Rollback`, `-ResetBranch`, `-NewRelease` and `-Push`.
- Backups, releases and archives must lie outside the source folder; the function refuses
  overlapping paths.
- Symbolic links and junctions are not supported and stop the run. OneDrive placeholder files
  are fine.
- Empty folders are not part of a backup, only file contents.
- Backups are the safety net, not a version history: keep them on a disk that is itself backed up.

## Troubleshooting

| Message | Cause and fix |
| --- | --- |
| `Environment variable 'AS2GO' is not set` | Set `$env:AS2Go` in this session, or pass all four folder parameters |
| `…must contain an absolute project-root path` | The variable holds a relative path; use a full path |
| `SourceFolder must be the Git repository root` | A Git action needs `-SourceFolder` to be the folder containing `.git` |
| `Expected exactly one ModuleVersion in manifest` | The manifest contains none or several `ModuleVersion =` lines |
| `Cannot locate version entries in ChangeLog.md` | `ChangeLog.md` has no line starting with `- Version ` yet; add one |
| `refs/heads/main contains commits missing from the current branch` | Merge `main` into the current branch, then retry `-Push ToMain` |
| `Links are unsupported` | Remove the symbolic link or junction from the working folder |
| `git rev-parse --verify refs/as2go/branch-start/<branch>^{commit} failed` (with `-ResetBranch`) | The branch has no saved start reference; only branches created with `-NewBranch` can be reset |
