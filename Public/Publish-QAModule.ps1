function Publish-QAModule {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$NuGetApiKey,

        [string]$Repository = 'PSGallery'
    )

    if ($PSVersionTable.PSVersion -lt [version]'7.4') {
        throw 'PowerShell 7.4 or later is required.'
    }

    if ([string]::IsNullOrWhiteSpace($NuGetApiKey)) {
        throw 'The NuGet API key cannot be empty.'
    }

    # Resolve a manifest or directory path. Otherwise, treat Name as a module name.
    $publishPath = $null

    if (Test-Path -LiteralPath $Name -PathType Leaf) {
        $resolvedPath = (Resolve-Path -LiteralPath $Name -ErrorAction Stop).Path

        if ([System.IO.Path]::GetExtension($resolvedPath) -ne '.psd1') {
            throw "The file '$Name' is not a PowerShell module manifest (.psd1)."
        }

        $publishPath = Split-Path -Path $resolvedPath -Parent
    }
    elseif (Test-Path -LiteralPath $Name -PathType Container) {
        $publishPath = (Resolve-Path -LiteralPath $Name -ErrorAction Stop).Path
    }

    $plainApiKey = $NuGetApiKey
    $decryptedBytes = $null

    try {
        # Values saved by Set-NuGetApiKey are DPAPI-protected Base64 strings.
        if ($NuGetApiKey.StartsWith('AQAAANCM', [StringComparison]::Ordinal)) {
            if (-not $IsWindows) {
                throw 'The encrypted API key can only be decrypted on Windows.'
            }

            if (-not ('System.Security.Cryptography.ProtectedData' -as [type])) {
                Add-Type -AssemblyName System.Security.Cryptography.ProtectedData -ErrorAction Stop
            }

            $encryptedBytes = [Convert]::FromBase64String($NuGetApiKey)

            $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
                $encryptedBytes,
                $null,
                [System.Security.Cryptography.DataProtectionScope]::CurrentUser
            )

            # Set-NuGetApiKey stores SecureString bytes as UTF-16LE.
            $plainApiKey = [System.Text.Encoding]::Unicode.GetString($decryptedBytes)
        }

        if (-not (Get-Command Publish-Module -ErrorAction SilentlyContinue)) {
            throw 'Publish-Module was not found. Install or import the PowerShellGet module.'
        }

        $target = if ($publishPath) { $publishPath } else { $Name }

        if ($PSCmdlet.ShouldProcess($target, "Publish module to repository '$Repository'")) {
            if ($publishPath) {
                Publish-Module `
                    -Path $publishPath `
                    -NuGetApiKey $plainApiKey `
                    -Repository $Repository
            }
            else {
                Publish-Module `
                    -Name $Name `
                    -NuGetApiKey $plainApiKey `
                    -Repository $Repository
            }
        }
    }
    finally {
        if ($null -ne $decryptedBytes) {
            [Array]::Clear($decryptedBytes, 0, $decryptedBytes.Length)
        }

        $plainApiKey = $null
    }
}