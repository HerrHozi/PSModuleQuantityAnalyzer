function Set-NuGetApiKey {
    <#
    .SYNOPSIS
    Stores a NuGet API key as a DPAPI-protected current-user environment variable.

    .DESCRIPTION
    Prompts for a NuGet API key as a SecureString, protects it with Windows DPAPI
    using the current-user scope, and stores the Base64-encoded value in the
    current user's environment variables. The protected value is also set in the
    current PowerShell process so it can be passed directly to Publish-QAModule.

    The key can only be decrypted by the same Windows user who stored it.
    PowerShell 7.4 or later and Windows are required.

    .PARAMETER VariableName
    Specifies the environment variable name used to store the protected key.
    The default is NuGetApiKey.

    .EXAMPLE
    Set-NuGetApiKey

    Prompts for the API key and stores it in the current user's NuGetApiKey
    environment variable.

    .EXAMPLE
    Set-NuGetApiKey -VariableName 'PSGalleryApiKey'

    Prompts for the API key and stores it under a custom environment variable
    name for the current user.

    .EXAMPLE
    Set-NuGetApiKey -WhatIf

    Shows the environment variable update that would be performed without
    prompting for or storing the key.

    .NOTES
    The stored value is encrypted for the current Windows user. Use the value
    from the current process, for example $env:NuGetApiKey, with Publish-QAModule.
    #>
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
