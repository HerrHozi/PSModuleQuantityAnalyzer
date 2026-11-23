<#
.SYNOPSIS
Backs up a PowerShell module working tree and updates its version.

.DESCRIPTION
Module selects the project-root environment variable (for example GCCare reads GCCARE).
Set it in the current session before the first call, for example:
$env:AS2Go = "C:\GitHub\AS2GO"
The variable must contain an absolute path to the project root, which holds the
Dev, Backup, Release and Archive folders.
Unset folder parameters default to Dev, Backup, Release, and Archive below that root.
Explicit folder parameters override their defaults independently. If all four folder
parameters are supplied, no project-root environment variable is required.

Without switches, copies the previous version to Backup/<year>/<month>/<version> and
updates the working files, including the DEV label in <Module>.code-workspace
when that file exists. -Commit supplies the text for a local commit.
-NewBranch commits on the current branch, then creates and switches to a branch.
The new branch gets a permanent local start reference for -ResetBranch.
-Push CurrentBranch commits and pushes the current (or newly created) branch.
-Push ToMain commits, fast-forwards local main to the current branch, and pushes main.
ToMain stops if local or remote main contains commits missing from the current branch.
-NewRelease copies the current working files to Release/<ModuleVersion>, replacing
an existing folder for that version. It uses the manifest version and Git ignore
rules (including nested .gitignore files and ignored tracked files).
Git is required for releases. Review the result before using Publish-Module;
this script does not upload to PowerShell Gallery.
Backups include ignored files; only Git metadata is excluded.
-Rollback restores files from an explicit backup and first saves the current files.
Git history is unchanged. Files absent from the backup are removed.
Existing backup folders are never overwritten; repeated snapshots use -001, -002, etc.
Checkpoint versions always increase, including repeated calls within the same minute.

.EXAMPLE
$env:AS2Go = "C:\GitHub\AS2GO"
Checkpoint-PSModuleVersion -Module AS2Go
Sets the project-root environment variable first (named like the module; required unless all
four folder parameters are supplied). Dev, Backup, Release and Archive are expected below
that root. Then saves the current files and updates the version and changelog without a Git commit.

.EXAMPLE
Checkpoint-PSModuleVersion -Module AS2Go -NewBranch 'feature/Ptt' -Commit 'Add Ptt'
Creates a checkpoint, commits on the current branch, then switches to feature/Ptt.

.EXAMPLE
Checkpoint-PSModuleVersion -Module AS2Go -Push CurrentBranch -Commit 'Update help'
Creates a checkpoint and commit, then pushes the current branch to origin.

.EXAMPLE
Checkpoint-PSModuleVersion -Module AS2Go -NewRelease
Copies Dev to the release folder for the current manifest version, replacing it if present.

.EXAMPLE
Checkpoint-PSModuleVersion -Module AS2Go -Rollback '../Backup/2026/10/2026.10.24.600' -WhatIf
Previews restoration. Remove -WhatIf to back up the current files and restore.

.PARAMETER SourceFolder
Module working directory. Defaults to Dev below the module environment-variable root.

.PARAMETER BackupFolder
Backup root outside SourceFolder. Defaults to Backup below the project root.

.PARAMETER ReleaseFolder
Release root outside SourceFolder. Defaults to Release below the project root.

.PARAMETER ArchiveFolder
Archive destination. Defaults to Archive below the project root. Used by -OrganizeBackups.

.PARAMETER Module
Required module name for the manifest, module file, and project-root environment variable.

.PARAMETER NewBranch
New branch to create after committing on the current branch.

.PARAMETER Push
CurrentBranch pushes the current branch to origin. ToMain fast-forwards local main
to the current branch and pushes main to origin. Neither mode force-pushes.
ToMain cannot be combined with NewBranch and leaves main checked out on success.
The old switch-only -Push syntax is replaced by an explicit destination.

.PARAMETER AuthorName
Git commit author and default committer name. Defaults to HerrHoZi.

.PARAMETER AuthorEmail
Git commit author and default committer email. Defaults to zimmermann.holger@live.de.
These settings apply to this script's commit only; Git configuration is not changed.

.EXAMPLE
Checkpoint-PSModuleVersion -Module AS2Go -Push ToMain -Commit 'Publish current changes'
Creates a checkpoint, fast-forwards main to the current branch, and pushes main.

.PARAMETER NewRelease
Refresh the release folder for the current manifest version using Git ignore rules.
SourceFolder must be the Git root. Commit, NewBranch and Push can still be supplied.

.PARAMETER Commit
Commit message and changelog entry. Supplying it enables a local Git commit.

.PARAMETER Rollback
Backup directory to restore, without updating the version or Git history.

.PARAMETER ResetBranch
Restore the current branch to its saved start commit. First backs up all working
files, then resets tracked files and removes untracked and ignored files.
The start is the checkpoint committed when -NewBranch created the branch.
Only branches created with this script's start reference can be reset.
Does not push or modify the remote branch.

.PARAMETER OrganizeBackups
Move legacy version directories and ZIPs into Backup/<year>/<month>, then create
Archive/<Module>_<year>.<month>.zip containing each month's version folders.
Existing ZIPs are refreshed only after SHA256 verification of all entries.
Source backups remain. Unknown names outside month folders remain untouched.
ZIPs exclude .git directories/files and Git administrative files such as .gitignore,
.gitattributes, .gitmodules, .gitkeep, .gitconfig, .gitmessage and .git-blame-ignore-revs.

.EXAMPLE
$Settings = @{
    SourceFolder = 'C:\Programming\GitHub\AS2Go\Dev'
    BackupFolder = 'C:\Programming\GitHub\AS2Go\Backup'
    ReleaseFolder = 'C:\Programming\GitHub\AS2Go\Release'
}
Checkpoint-PSModuleVersion -Module AS2Go @Settings -NewBranch 'feature/backup' -Commit 'Start backup work'
Passes folder settings using splatting and records the new branch's starting checkpoint.

.EXAMPLE
Checkpoint-PSModuleVersion -Module AS2Go @Settings -ResetBranch -WhatIf
Previews resetting the current branch to its saved starting checkpoint.

.EXAMPLE
Checkpoint-PSModuleVersion -Module AS2Go @Settings -OrganizeBackups
Sorts backups into year/month and creates verified monthly ZIPs without a checkpoint.

.NOTES
Author: zimmermann.holger@live.de
Version: 2026.10.25.5 (converted from Checkpoint-ModuleVersion.ps1)
Snapshots preserve file contents, not empty directories. OneDrive placeholders are supported.
Symbolic links and junctions are unsupported.
#>
function Checkpoint-PSModuleVersion {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [ValidateNotNullOrEmpty()][string]$SourceFolder,
        [ValidateNotNullOrEmpty()][string]$BackupFolder,
        [ValidateNotNullOrEmpty()][string]$ReleaseFolder,
        [ValidateNotNullOrEmpty()][string]$ArchiveFolder,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Module,
        [ValidateNotNullOrEmpty()][string]$NewBranch,
        [ValidateSet('ToMain', 'CurrentBranch')][string]$Push,
        [switch]$NewRelease,
        [ValidateNotNullOrEmpty()][string]$Commit,
        [ValidateNotNullOrEmpty()][string]$AuthorName = 'HerrHoZi',
        [ValidateNotNullOrEmpty()][string]$AuthorEmail = 'zimmermann.holger@live.de',
        [ValidateNotNullOrEmpty()][string]$Rollback,
        [switch]$ResetBranch,
        [switch]$OrganizeBackups
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    # Resolve defaults after binding so explicit folder parameters always take precedence.
    $folderDefaults = [ordered]@{
        SourceFolder  = 'Dev'
        BackupFolder  = 'Backup'
        ReleaseFolder = 'Release'
        ArchiveFolder = 'Archive'
    }
    $missingFolders = @($folderDefaults.Keys | Where-Object { -not $PSBoundParameters.ContainsKey($_) })
    if ($missingFolders.Count -gt 0) {
        $environmentName = $Module.ToUpperInvariant()
        $projectRoot = [Environment]::GetEnvironmentVariable($environmentName, 'Process')
        if ([string]::IsNullOrWhiteSpace($projectRoot)) {
            throw "Environment variable '$environmentName' is not set. Set it to the module project root or explicitly supply all four folder parameters."
        }
        # IsPathFullyQualified does not exist in .NET Framework (Windows PowerShell 5.1)
        if ($projectRoot -notmatch '^(?:[A-Za-z]:[\\/]|[\\/]{2}[^\\/])') {
            throw "Environment variable '$environmentName' must contain an absolute project-root path."
        }
        foreach ($folderParameter in $missingFolders) {
            Set-Variable -Name $folderParameter -Value (Join-Path $projectRoot $folderDefaults[$folderParameter]) -WhatIf:$false
        }
    }

    $SourceFolder = (Resolve-Path -LiteralPath $SourceFolder).ProviderPath.TrimEnd('\', '/')
    $BackupFolder = [IO.Path]::GetFullPath($BackupFolder)
    $ReleaseFolder = [IO.Path]::GetFullPath($ReleaseFolder)
    $ArchiveFolder = [IO.Path]::GetFullPath($ArchiveFolder)
    if ($Module.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) { throw 'Module must be a valid file name.' }
    $backupPrefix = $BackupFolder.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if ($ArchiveFolder.TrimEnd('\', '/') -eq $BackupFolder.TrimEnd('\', '/') -or
        $ArchiveFolder.StartsWith($backupPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'ArchiveFolder must be outside BackupFolder.' }
    foreach ($destinationRoot in @($BackupFolder, $ReleaseFolder, $ArchiveFolder)) {
        if ($destinationRoot.TrimEnd('\', '/') -eq $SourceFolder -or
            $destinationRoot.StartsWith($SourceFolder + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Backup and release destinations must be outside the source folder.'
        }
    }
    if (@(@($Rollback, $ResetBranch, $OrganizeBackups) | Where-Object { $_ }).Count -gt 1) { throw 'Choose only one restore or organize action.' }
    if (($ResetBranch -or $OrganizeBackups) -and ($Push -or $NewBranch -or $NewRelease -or $PSBoundParameters.ContainsKey('Commit'))) { throw 'Restore/organize cannot be combined with checkpoint actions.' }
    if ($Push -eq 'ToMain' -and $NewBranch) { throw 'ToMain cannot be combined with NewBranch.' }
    if ($OrganizeBackups) { Move-PSModuleLegacyBackups -BackupFolder $BackupFolder -Cmdlet $PSCmdlet; New-PSModuleBackupArchives -Module $Module -BackupFolder $BackupFolder -ArchiveFolder $ArchiveFolder -Cmdlet $PSCmdlet; return }
    if ($ResetBranch) {
        $root = (Invoke-PSModuleGit -Path $SourceFolder -Arguments @('rev-parse', '--show-toplevel') | Select-Object -Last 1).ToString().Replace('/', '\').TrimEnd('\')
        if ($root -ne $SourceFolder.Replace('/', '\')) { throw 'SourceFolder must be the Git repository root.' }
        $branch = (Invoke-PSModuleGit -Path $SourceFolder -Arguments @('symbolic-ref', '--quiet', '--short', 'HEAD')).ToString()
        $startRef = "refs/as2go/branch-start/$branch"
        $startCommit = (Invoke-PSModuleGit -Path $SourceFolder -Arguments @('rev-parse', '--verify', "$startRef^{commit}")).ToString()
        if (Invoke-PSModuleGit -Path $SourceFolder -Arguments @('ls-files', '--stage') | Where-Object { $_ -match '^160000 ' }) { throw 'Branch reset does not support submodules.' }
        $files = @(Get-PSModuleSnapshotFiles -Root $SourceFolder)
        $safetyTarget = Join-Path (Join-Path (Join-Path $BackupFolder (Get-Date -Format yyyy)) (Get-Date -Format MM)) ('BeforeBranchReset-' + [guid]::NewGuid().ToString('N'))
        if ($PSCmdlet.ShouldProcess($SourceFolder, "Save all files to $safetyTarget and reset $branch to $startCommit, removing untracked and ignored files")) {
            Copy-PSModuleVerifiedSnapshot -Root $SourceFolder -Destination $safetyTarget -Files $files
            Invoke-PSModuleGit -Path $SourceFolder -Arguments @('reset', '--hard', $startCommit) | Out-Host
            Invoke-PSModuleGit -Path $SourceFolder -Arguments @('clean', '-fdx') | Out-Host
            Write-Host "Branch restored. Previous files: $safetyTarget"
        }
        return
    }
    if ($Rollback) {
        if ($Push -or $NewBranch -or $NewRelease -or $PSBoundParameters.ContainsKey('Commit')) {
            throw 'Rollback cannot be combined with Git or release actions.'
        }
        $restoreRoot = (Resolve-Path -LiteralPath $Rollback).ProviderPath.TrimEnd('\', '/')
        if (-not (Test-Path -LiteralPath $restoreRoot -PathType Container)) { throw 'Rollback must be a directory.' }
        if ($restoreRoot -eq $SourceFolder -or
            $restoreRoot.StartsWith($SourceFolder + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
            $SourceFolder.StartsWith($restoreRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Source and rollback folders must not overlap.'
        }
        Import-PowerShellDataFile -LiteralPath (Join-Path $restoreRoot "$Module.psd1") | Out-Null
        $restoreFiles = @(Get-PSModuleSnapshotFiles -Root $restoreRoot)
        $currentFiles = @(Get-PSModuleSnapshotFiles -Root $SourceFolder)
        $safetyTarget = Join-Path (Join-Path (Join-Path $BackupFolder (Get-Date -Format yyyy)) (Get-Date -Format MM)) ('BeforeRollback-' + [guid]::NewGuid().ToString('N'))
        if (-not $PSCmdlet.ShouldProcess($SourceFolder, "Save current files to $safetyTarget and restore $restoreRoot")) { return }
        Copy-PSModuleVerifiedSnapshot -Root $SourceFolder -Destination $safetyTarget -Files $currentFiles
        $wanted = @{}
        foreach ($file in $restoreFiles) {
            $relative = $file.FullName.Substring($restoreRoot.Length).TrimStart('\', '/')
            $wanted[$relative] = $true
            $target = Join-Path $SourceFolder $relative
            New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
            $hash = (Get-FileHash -LiteralPath $file.FullName).Hash
            Copy-Item -LiteralPath $file.FullName -Destination $target -Force
            if ($hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw "Restore failed: $relative. Safety backup: $safetyTarget" }
        }
        foreach ($file in $currentFiles) {
            $relative = $file.FullName.Substring($SourceFolder.Length).TrimStart('\', '/')
            if (-not $wanted.ContainsKey($relative)) { Remove-Item -LiteralPath $file.FullName -Force }
        }
        Write-Host "Rollback complete. Previous working files: $safetyTarget"
        return
    }
    $manifestPath = Join-Path $SourceFolder "$Module.psd1"
    $metadata = Import-PowerShellDataFile -LiteralPath $manifestPath
    $oldVersion = [version]$metadata.ModuleVersion
    $version = $oldVersion.ToString()

    $useGit = $Push -or $NewBranch -or $PSBoundParameters.ContainsKey('Commit')
    if ($useGit -or $NewRelease) {
        $root = (Invoke-PSModuleGit -Path $SourceFolder -Arguments @('rev-parse', '--show-toplevel') | Select-Object -Last 1).ToString().Replace('/', '\').TrimEnd('\')
        if ($root -ne $SourceFolder.Replace('/', '\')) { throw 'SourceFolder must be the Git repository root.' }
        $branch = Invoke-PSModuleGit -Path $SourceFolder -Arguments @('symbolic-ref', '--quiet', '--short', 'HEAD')
        $unmerged = Invoke-PSModuleGit -Path $SourceFolder -Arguments @('ls-files', '--unmerged')
        if ($unmerged) { throw 'Resolve Git conflicts before creating a checkpoint.' }
        if ($NewBranch) {
            Invoke-PSModuleGit -Path $SourceFolder -Arguments @('check-ref-format', '--branch', $NewBranch) | Out-Null
            $existing = Invoke-PSModuleGit -Path $SourceFolder -Arguments @('branch', '--list', $NewBranch)
            if ($existing) { throw "Local branch already exists: $NewBranch" }
            $existingStart = Invoke-PSModuleGit -Path $SourceFolder -Arguments @('for-each-ref', '--format=%(refname)', "refs/as2go/branch-start/$NewBranch")
            if ($existingStart) { throw "Branch start reference already exists: $NewBranch" }
        }
        if ($Push) { Invoke-PSModuleGit -Path $SourceFolder -Arguments @('remote', 'get-url', 'origin') | Out-Null }
        if ($Push -eq 'ToMain') {
            # Refresh remote main before testing ancestry; WhatIf remains read-only.
            if (-not $WhatIfPreference) {
                Invoke-PSModuleGit -Path $SourceFolder -Arguments @('fetch', 'origin', '+refs/heads/main:refs/remotes/origin/main') | Out-Host
            }
            foreach ($mainRef in @('refs/heads/main', 'refs/remotes/origin/main')) {
                $reference = Invoke-PSModuleGit -Path $SourceFolder -Arguments @('for-each-ref', '--format=%(refname)', $mainRef)
                if (-not $reference) { throw "Required main reference is missing: $mainRef" }
                & git -C $SourceFolder merge-base --is-ancestor $mainRef HEAD
                if ($LASTEXITCODE -eq 1) { throw "$mainRef contains commits missing from the current branch. Merge main into the current branch before using ToMain." }
                if ($LASTEXITCODE -ne 0) { throw "Unable to compare $mainRef with the current branch." }
            }
        }
    }
    if (-not $Commit) { $Commit = 'Checkpoint' }

    if ($NewRelease) {
        $releaseTarget = [IO.Path]::GetFullPath((Join-Path $ReleaseFolder $version))
        $releasePrefix = $ReleaseFolder.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        $targetPrefix = $releaseTarget + [IO.Path]::DirectorySeparatorChar
        if (-not $releaseTarget.StartsWith($releasePrefix, [StringComparison]::OrdinalIgnoreCase) -or
            $releaseTarget -eq $SourceFolder -or
            $SourceFolder.StartsWith($targetPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Unsafe release destination: $releaseTarget"
        }
        # A linked folder could redirect a recursive delete outside the release path.
        for ($path = $releaseTarget; $path; $path = Split-Path -Path $path -Parent) {
            $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
            if ($item -and (-not $item.PSIsContainer -or $item.LinkType -in @('SymbolicLink', 'Junction'))) {
                throw "Release path must use ordinary directories: $path"
            }
        }
        if (-not $PSCmdlet.ShouldProcess($releaseTarget, 'Replace the release folder with a verified copy of the current working files')) { return }
        $releaseFiles = @(Get-PSModuleSnapshotFiles -Root $SourceFolder | Where-Object {
                $relative = $_.FullName.Substring($SourceFolder.Length).TrimStart('\', '/').Replace('\', '/')
                & git -C $SourceFolder check-ignore --no-index --quiet -- $relative
                if ($LASTEXITCODE -gt 1) { throw "Git ignore check failed: $relative" }
                $LASTEXITCODE -eq 1
            })
        if ($manifestPath -notin @($releaseFiles | ForEach-Object FullName)) { throw 'The module manifest is ignored; cannot release.' }
    }
    else {
        $now = Get-Date
        $candidateVersion = [version]('{0}.{1}.{2}.{3}' -f $now.Year, $now.Month, $now.Day, (($now.Hour * 60) + $now.Minute))
        # Multiple checkpoints within a minute must still advance the module version.
        if ($candidateVersion -le $oldVersion) {
            if ($oldVersion.Revision -eq [int]::MaxValue) { throw 'Cannot increment the current version revision.' }
            $candidateVersion = [version]::new($oldVersion.Major, $oldVersion.Minor, $oldVersion.Build, ($oldVersion.Revision + 1))
        }
        $version = $candidateVersion.ToString()
        $date = $now.ToString('yyyy-MM-dd')
        $backupName = '{0}.{1:D2}.{2:D2}.{3}' -f $oldVersion.Major, $oldVersion.Minor, $oldVersion.Build, $oldVersion.Revision
        $backupTarget = Join-Path (Join-Path (Join-Path $BackupFolder $oldVersion.Major.ToString()) ('{0:D2}' -f $oldVersion.Minor)) $backupName
        # Retain previous snapshots, including snapshots left by a failed Git action.
        $backupIndex = 0
        $backupBaseTarget = $backupTarget
        while (Test-Path -LiteralPath $backupTarget) {
            $backupIndex++
            $backupTarget = '{0}-{1:D3}' -f $backupBaseTarget, $backupIndex
        }

        # Prepare all text changes before copying or modifying any files.
        $updates = @{}
        foreach ($name in @("$Module.psd1", "$Module.psm1", 'README.md', 'ChangeLog.md')) {
            $path = Join-Path $SourceFolder $name
            $content = [IO.File]::ReadAllText($path)
            $changed = $content
            if ($name -eq "$Module.psd1") {
                if ([regex]::Matches($content, "(?m)^\s*ModuleVersion\s*=\s*'[^']*'").Count -ne 1) { throw 'Expected exactly one ModuleVersion in manifest.' }
                $changed = $changed -replace "(?m)^(\s*ModuleVersion\s*=\s*)'[^']*'", "`${1}'$version'"
                $changed = $changed -replace "(LastUpdate\s*=\s*)'[^']*'", "`${1}'$date'"
            }
            elseif ($name -eq "$Module.psm1") {
                $changed = $changed -replace "(######\s*ModuleVersion\s*=\s*)'[^']*'", "`${1}'$version'"
                $changed = $changed -replace "(######\s*LastUpdate\s*=\s*)'[^']*'", "`${1}'$date'"
            }
            else {
                $changed = $changed -replace '(?m)^Current Version:[^\r\n]*', "Current Version: $version"
                $changed = $changed -replace '(?m)^Last Update:[^\r\n]*', "Last Update:     $date"
                if ($name -eq 'README.md') {
                    $changed = $changed -replace "(?<=git commit -m 'Version )\d{4}\.\d{1,2}\.\d{1,2}\.\d{1,4}", $version
                    $changed = $changed -replace '(git (?:push -u origin|checkout -b) version_)\d+\.\d+\.\d+\.\d+', "`${1}$version"
                }
                else {
                    $match = [regex]::Match($changed, '(?m)^- Version ')
                    if (-not $match.Success) { throw 'Cannot locate version entries in ChangeLog.md.' }
                    $newline = if ($content.Contains("`r`n")) { "`r`n" } else { "`n" }
                    $changed = $changed.Insert($match.Index, "- Version $version${newline}  - $Commit$newline$newline")
                }
            }
            if ($changed -ne $content) { $updates[$path] = $changed }
        }

        # Update only the DEV folder label; preserve workspace comments and formatting.
        $workspacePath = Join-Path $SourceFolder "$Module.code-workspace"
        if (Test-Path -LiteralPath $workspacePath -PathType Leaf) {
            $workspaceContent = [IO.File]::ReadAllText($workspacePath)
            $foldersMatch = [regex]::Match($workspaceContent, '"folders"\s*:\s*\[(?<folders>.*?)\]', [Text.RegularExpressions.RegexOptions]::Singleline)
            if (-not $foldersMatch.Success) { throw "Cannot locate folders in workspace: $workspacePath" }
            $folderObjects = [regex]::Matches($foldersMatch.Groups['folders'].Value, '\{[^{}]*\}')
            $devFolders = @($folderObjects | Where-Object {
                    $_.Value -match '"path"\s*:\s*"\."'
                })
            if ($devFolders.Count -ne 1) { throw "Expected exactly one source folder with path '.' in workspace: $workspacePath" }
            $devFolder = $devFolders[0]
            $nameMatch = [regex]::Match($devFolder.Value, '"name"\s*:\s*"(?<label>(?:\\.|[^"\\])*)"')
            if (-not $nameMatch.Success) { throw "The source folder has no name in workspace: $workspacePath" }
            # Keep custom labels such as 'Dev - MrHozi'; replace only the version suffix.
            $label = $nameMatch.Groups['label']
            $baseLabel = $label.Value -replace '\s*\|\s*\d+\.\d+\.\d+(?:\.\d+)?\s*$', ''
            $newFolder = $devFolder.Value.Remove($label.Index, $label.Length).Insert($label.Index, "$baseLabel | $version")
            $offset = $foldersMatch.Groups['folders'].Index + $devFolder.Index
            $changedWorkspace = $workspaceContent.Remove($offset, $devFolder.Length).Insert($offset, $newFolder)
            if ($changedWorkspace -ne $workspaceContent) { $updates[$workspacePath] = $changedWorkspace }
        }
        Write-Host "`nVersion: $oldVersion -> $version" -ForegroundColor Yellow
        Write-Host "Backup:  $backupTarget"
        Move-PSModuleLegacyBackups -BackupFolder $BackupFolder -Cmdlet $PSCmdlet
        if (-not $PSCmdlet.ShouldProcess($SourceFolder, 'Create verified backup, update version and perform selected Git actions')) { return }

        $files = @(Get-PSModuleSnapshotFiles -Root $SourceFolder)
        Copy-PSModuleVerifiedSnapshot -Root $SourceFolder -Destination $backupTarget -Files $files
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        foreach ($path in $updates.Keys) { [IO.File]::WriteAllText($path, $updates[$path], $utf8) }
        $check = Import-PowerShellDataFile -LiteralPath $manifestPath
        if ($check.ModuleVersion -ne $version) { throw 'Updated manifest version validation failed.' }
    }

    if ($useGit) {
        Invoke-PSModuleGit -Path $SourceFolder -Arguments @('add', '-A') | Out-Host
        Invoke-PSModuleGit -Path $SourceFolder -Arguments @('-c', "user.name=$AuthorName", '-c', "user.email=$AuthorEmail", 'commit', '--author', "$AuthorName <$AuthorEmail>", '-m', "$version | $Commit") | Out-Host
        if ($NewBranch) {
            Invoke-PSModuleGit -Path $SourceFolder -Arguments @('switch', '-c', $NewBranch) | Out-Host
            Invoke-PSModuleGit -Path $SourceFolder -Arguments @('update-ref', "refs/as2go/branch-start/$NewBranch", 'HEAD', ('0' * 40)) | Out-Null
        }
    }
    if ($NewRelease) {
        if (Test-Path -LiteralPath $releaseTarget) {
            Remove-Item -LiteralPath $releaseTarget -Recurse -Force -Confirm:$false
        }
        Copy-PSModuleVerifiedSnapshot -Root $SourceFolder -Destination $releaseTarget -Files $releaseFiles
        Write-Host "Release: $releaseTarget"
    }
    if ($Push -eq 'ToMain') {
        $publishCommit = (Invoke-PSModuleGit -Path $SourceFolder -Arguments @('rev-parse', 'HEAD')).ToString()
        Invoke-PSModuleGit -Path $SourceFolder -Arguments @('switch', 'main') | Out-Host
        Invoke-PSModuleGit -Path $SourceFolder -Arguments @('merge', '--ff-only', $publishCommit) | Out-Host
        Invoke-PSModuleGit -Path $SourceFolder -Arguments @('push', '-u', 'origin', 'main:main') | Out-Host
    }
    elseif ($Push -eq 'CurrentBranch') {
        Invoke-PSModuleGit -Path $SourceFolder -Arguments @('push', '-u', 'origin', 'HEAD') | Out-Host
    }
    if (-not $NewRelease) { Write-Host "Checkpoint complete: $version" }
}
