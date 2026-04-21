@{
    RootModule = 'PSInteractiveMenu.psm1'
    ModuleVersion = '0.0.1' # Major.Minor.Patch
    Author = 'Norbert Marton'
    Description = 'Interactive keyboard-driven console menus for PowerShell modules and scripts.'
    GUID = '76b74419-5903-4776-9d96-b8b4446dd4f0'
    CompanyName = 'Concept MARTON'
    Copyright = 'Copyright (c) 2026 Norbert Marton'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FunctionsToExport = @(
        'New-PSInteractiveMenuOption'
        'Read-PSInteractiveMenuBoolean'
        'Read-PSInteractiveMenuTextInput'
        'Show-PSInteractiveMenu'
    )
    CmdletsToExport = @()
    AliasesToExport = @(
        'psmenu'
    )
    VariablesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('PowerShell', 'interactive-menu', 'console', 'menu', 'terminal', 'tui')
            LicenseUri = 'https://github.com/djtroi/PSInteractiveMenu/blob/main/LICENSE'
            ProjectUri = 'https://github.com/djtroi/PSInteractiveMenu'
            ReleaseNotes = 'Initial standalone PSInteractiveMenu module with keyboard-driven menus, text input, and boolean prompt helpers.'
        }
    }
}

