function Set-NuGetApiKey {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$VariableName = 'NuGetApiKey'
    )

    if ($PSVersionTable.PSVersion -lt [version]'7.4') {
        throw 'PowerShell 7.4 or later is required.'
    }

    if (-not $IsWindows) {
        throw 'This function requires Windows because it uses DPAPI.'
    }

    if (-not ('System.Security.Cryptography.ProtectedData' -as [type])) {
        Add-Type -AssemblyName System.Security.Cryptography.ProtectedData -ErrorAction Stop
    }

    if ($PSCmdlet.ShouldProcess("Current user environment variable '$VariableName'", 'Store encrypted NuGet API key')) {
        $secureString = $null
        $pointer = [IntPtr]::Zero
        $plainBytes = $null

        try {
            $secureString = Read-Host 'Enter the NuGet API key' -AsSecureString
            $pointer = [Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($secureString)
            $plainBytes = [byte[]]::new($secureString.Length * 2)

            [Runtime.InteropServices.Marshal]::Copy(
                $pointer,
                $plainBytes,
                0,
                $plainBytes.Length
            )

            $encryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect(
                $plainBytes,
                $null,
                [System.Security.Cryptography.DataProtectionScope]::CurrentUser
            )

            $encryptedBase64 = [Convert]::ToBase64String($encryptedBytes)

            # Persist for this Windows user
            [Environment]::SetEnvironmentVariable(
                $VariableName,
                $encryptedBase64,
                [EnvironmentVariableTarget]::User
            )

            # Make it available in the current PowerShell process
            [Environment]::SetEnvironmentVariable(
                $VariableName,
                $encryptedBase64,
                [EnvironmentVariableTarget]::Process
            )

            Write-Host "Encrypted API key stored in the current user's environment."
        }
        finally {
            if ($null -ne $plainBytes) {
                [Array]::Clear($plainBytes, 0, $plainBytes.Length)
            }

            if ($pointer -ne [IntPtr]::Zero) {
                [Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($pointer)
            }

            if ($null -ne $secureString) {
                $secureString.Dispose()
            }
        }
    }
}