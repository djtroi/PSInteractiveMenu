# PSInteractiveMenu

`PSInteractiveMenu` is a standalone PowerShell module for building keyboard-driven console menus.
It is designed for scripts and modules that need a clean, reusable terminal UI without hard-coding ad-hoc `Read-Host` flows everywhere.

## Features

- Interactive single-select and multi-select menus
- Paging for long option lists
- Hotkeys, breadcrumbs, status blocks, and info panels
- Text input helper with the same visual style
- Simple boolean prompt helper built on top of the same menu engine

## Public Commands

- `New-PSInteractiveMenuOption`
- `Show-PSInteractiveMenu`
- `Read-PSInteractiveMenuTextInput`
- `Read-PSInteractiveMenuBoolean`

## Quick Start

```powershell
Import-Module .\PSInteractiveMenu.psd1 -Force

$options = @(
    New-PSInteractiveMenuOption -Key 'scan' -Label 'Scan source media' -Description 'Start a media scan now.' -HotKey 'S' -IsDefault
    New-PSInteractiveMenuOption -Key 'settings' -Label 'Open settings' -Description 'Review the current import settings.' -HotKey 'O'
    New-PSInteractiveMenuOption -Key 'quit' -Label 'Quit' -Description 'Leave the workflow.' -HotKey 'Q'
)

$result = Show-PSInteractiveMenu `
    -Title 'Main Menu' `
    -Subtitle 'Example workflow' `
    -Breadcrumb @('Demo', 'Main Menu') `
    -Status ([ordered]@{
        Project = 'ClientA_2026'
        Source  = 'E:\DCIM'
    }) `
    -Info @(
        'Use arrow keys to move through the menu.',
        'Press Enter to confirm the highlighted option.'
    ) `
    -Options $options `
    -AllowCancel

$result
```

## Text Input Example

```powershell
$inputResult = Read-PSInteractiveMenuTextInput `
    -Title 'Project root' `
    -Subtitle 'Enter the destination path.' `
    -Prompt 'Path' `
    -CurrentValue 'D:\Projects\ClientA_2026'

$inputResult
```

## Boolean Prompt Example

```powershell
$confirmed = Read-PSInteractiveMenuBoolean `
    -Title 'Confirm import' `
    -Prompt 'Do you want to continue?' `
    -Default $true

$confirmed
```

## Build

Create a staged package:

```powershell
pwsh ./build/Build-PSInteractiveMenuPackage.ps1
```

Publish the generated package:

```powershell
pwsh ./build/Publish-PSInteractiveMenu.ps1 -Repository PSGallery -ApiKey '<APIKEY>'
```

