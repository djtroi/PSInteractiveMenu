$script:PSInteractiveMenuModuleRoot = $PSScriptRoot
$script:PSInteractiveMenuModuleVersion = '0.0.0'
$script:PSInteractiveMenuPublicFunctions = @(
    'New-PSInteractiveMenuOption'
    'Read-PSInteractiveMenuBoolean'
    'Read-PSInteractiveMenuTextInput'
    'Show-PSInteractiveMenu'
)
$script:PSInteractiveMenuPublicAliases = @(
    'psmenu'
)

$moduleInfo = $ExecutionContext.SessionState.Module
if ($moduleInfo -and $moduleInfo.Version) {
    $script:PSInteractiveMenuModuleVersion = $moduleInfo.Version.ToString()
}

function Register-PSInteractiveMenuFunction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($script:PSInteractiveMenuPublicFunctions -notcontains $Name) {
        return
    }
}

function Get-PSInteractiveMenuSourceFiles {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '',
     Justification = 'Files is the correct noun for this helper')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    Get-ChildItem -LiteralPath $Path -Recurse -File -Filter '*.ps1' |
        Sort-Object -Property FullName
}

$srcRoot = Join-Path -Path $PSScriptRoot -ChildPath 'src'
foreach ($relativePath in 'Classes', 'Private', 'Public') {
    $folderPath = Join-Path -Path $srcRoot -ChildPath $relativePath
    foreach ($sourceFile in Get-PSInteractiveMenuSourceFiles -Path $folderPath) {
        . $sourceFile.FullName
    }
}

Set-Alias -Name 'psmenu' -Value 'Show-PSInteractiveMenu' -Scope Script

Export-ModuleMember -Function $script:PSInteractiveMenuPublicFunctions -Alias $script:PSInteractiveMenuPublicAliases

