# PSInteractiveMenu

`PSInteractiveMenu` is a standalone PowerShell module for keyboard-driven terminal menus.
It is meant to be embedded into other scripts and modules that need a reliable interactive console layer without duplicating custom `Read-Host` and key-handling logic everywhere.

## Overview

The module currently exposes four public commands:

- `New-PSInteractiveMenuOption`
- `Show-PSInteractiveMenu`
- `Read-PSInteractiveMenuTextInput`
- `Read-PSInteractiveMenuBoolean`

It supports:

- Single-select menus
- Multi-select menus
- Hotkeys
- Paging for long lists
- Breadcrumbs
- Context/status panels
- Informational notes
- Styled text input prompts
- Back/cancel navigation

## Integration Readiness

The module is ready to be consumed by other PowerShell codebases.

What is already in place:

- Explicit module manifest with stable public exports
- PowerShell `5.1+` support
- `Desktop` and `Core` edition compatibility
- No runtime dependency on `RenderKit`
- A build script that generates a staged release artifact
- A bundled `.nupkg` package build flow
- Pester coverage for the public surface

Important limitation:

- `PSInteractiveMenu` requires a real interactive console with direct keyboard and screen access. It is not intended for headless CI jobs, redirected console sessions, or non-interactive remoting flows.

In practice, that means it is a good fit for:

- CLI tools
- Interactive admin scripts
- Setup/configuration wizards
- Import/export assistants
- Menu-driven module entry points

It is not a good fit for:

- GitHub Actions jobs
- background jobs
- scheduled tasks without a visible console
- pipeline-only automation

## Installation

You can consume `PSInteractiveMenu` in three common ways.

### 1. PowerShell Gallery

Use this once the module is published to PowerShell Gallery.

Classic PowerShellGet:

```powershell
Install-Module -Name PSInteractiveMenu -Scope CurrentUser
```

PSResourceGet:

```powershell
Install-PSResource -Name PSInteractiveMenu -Repository PSGallery -Scope CurrentUser
```

After that:

```powershell
Import-Module PSInteractiveMenu -ErrorAction Stop
```

### 2. Directly from GitHub

This is the simplest option during development or when you want to consume the module before it is published.

1. Download the repository zip or a release asset from GitHub.
2. Extract the folder that contains `PSInteractiveMenu.psd1`.
3. Optionally unblock downloaded files:

```powershell
Get-ChildItem 'C:\Tools\PSInteractiveMenu' -Recurse -File | Unblock-File
```

4. Import the module directly from the extracted manifest:

```powershell
Import-Module 'C:\Tools\PSInteractiveMenu\PSInteractiveMenu.psd1' -Force
```

If you want it to behave like a normal installed module, place it in a PowerShell module path.

Recommended current-user locations:

- Windows PowerShell 5.1: `$HOME\Documents\WindowsPowerShell\Modules\PSInteractiveMenu`
- PowerShell 7+: `$HOME\Documents\PowerShell\Modules\PSInteractiveMenu`

### 3. From a `.nupkg` Package

The repo already builds a valid `.nupkg` package.

Build it locally:

```powershell
pwsh ./build/Build-PSInteractiveMenuPackage.ps1
```

The package is created at:

```text
./artifacts/packages/PSInteractiveMenu.<version>.nupkg
```

If you download a `.nupkg` from GitHub or receive one from a maintainer, you can install it manually because a `.nupkg` is just a zip archive.

Example manual install:

```powershell
$version = '0.0.1'
$package = 'C:\Downloads\PSInteractiveMenu.0.0.1.nupkg'
$moduleRoot = Join-Path $HOME "Documents\PowerShell\Modules\PSInteractiveMenu\$version"
$zipPath = [System.IO.Path]::ChangeExtension($package, '.zip')

New-Item -ItemType Directory -Path $moduleRoot -Force | Out-Null
Copy-Item -LiteralPath $package -Destination $zipPath -Force
Expand-Archive -LiteralPath $zipPath -DestinationPath $moduleRoot -Force
Import-Module (Join-Path $moduleRoot 'PSInteractiveMenu.psd1') -Force
```

If you prefer Windows PowerShell 5.1 only, replace `Documents\PowerShell\Modules` with `Documents\WindowsPowerShell\Modules`.

## Using PSInteractiveMenu in Your Own Module

There are three practical integration patterns.

### Pattern 1: Treat it as a normal dependency

This is the cleanest option once the module is installed globally or via PowerShell Gallery.

In your module manifest:

```powershell
@{
    RootModule = 'MyModule.psm1'
    ModuleVersion = '1.0.0'
    RequiredModules = @(
        @{
            ModuleName = 'PSInteractiveMenu'
            ModuleVersion = '0.0.1'
        }
    )
}
```

In your module code:

```powershell
Import-Module PSInteractiveMenu -ErrorAction Stop
```

Use `RequiredVersion` instead of `ModuleVersion` if you want to pin to one exact dependency version.

### Pattern 2: Import from a fixed local path during development

This is useful while your own module and `PSInteractiveMenu` live side-by-side in local repositories.

```powershell
$localMenuModule = 'C:\Repos\PSInteractiveMenu\PSInteractiveMenu\PSInteractiveMenu.psd1'

if (Test-Path -LiteralPath $localMenuModule) {
    Import-Module $localMenuModule -Force
}
else {
    Import-Module PSInteractiveMenu -ErrorAction Stop
}
```

This keeps development easy while still allowing an installed dependency later.

### Pattern 3: Vendor the dependency inside your own repo

If you want fully self-contained distribution, you can ship the dependency inside your own module repository.

Example structure:

```text
MyModule/
  MyModule.psd1
  MyModule.psm1
  Modules/
    PSInteractiveMenu/
      0.0.1/
        PSInteractiveMenu.psd1
        PSInteractiveMenu.psm1
        README.md
        CHANGELOG.md
        LICENSE
```

Then import it explicitly from your module bootstrap:

```powershell
$dependencyManifest = Join-Path $PSScriptRoot 'Modules\PSInteractiveMenu\0.0.1\PSInteractiveMenu.psd1'
Import-Module $dependencyManifest -Force
```

This pattern is useful when you want deterministic packaging without depending on a machine-wide install.

## Recommended Integration Rules

If you want other modules to consume `PSInteractiveMenu` cleanly, keep these rules in mind:

- Use `PSInteractiveMenu` only for interactive entry points
- Keep your business logic separate from menu rendering
- Let the menu collect decisions, but keep execution in your own service layer
- Always provide a non-interactive code path for automation scenarios when possible
- Prefer wrapping `PSInteractiveMenu` calls in your own domain-specific helper functions

That last point is important.
Your consuming module should usually not scatter raw `Show-PSInteractiveMenu` calls everywhere.
Instead, create helpers such as:

- `Show-MyModuleProjectMenu`
- `Select-MyModuleTargetPath`
- `Confirm-MyModuleDeployment`

That keeps `PSInteractiveMenu` as the shared UI engine while your own module keeps ownership of its workflow language and domain rules.

## Example: Single-Select Menu

```powershell
Import-Module PSInteractiveMenu -ErrorAction Stop

$options = @(
    New-PSInteractiveMenuOption -Key 'scan' -Label 'Scan source media' -Description 'Start a media scan now.' -HotKey 'S' -IsDefault $true
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

$result.Action
$result.Option.Key
$result.Value
```

## Example: Multi-Select Menu

```powershell
$result = Show-PSInteractiveMenu `
    -Title 'Select media folders' `
    -Subtitle 'Choose one or more folders to import.' `
    -MultiSelect `
    -Options @(
        New-PSInteractiveMenuOption -Key 'cam-a' -Label 'Camera A'
        New-PSInteractiveMenuOption -Key 'cam-b' -Label 'Camera B' -Selected $true
        New-PSInteractiveMenuOption -Key 'audio' -Label 'Audio Recorder'
    )

$result.SelectedOptions
$result.SelectedValues
```

## Example: Text Input

```powershell
$inputResult = Read-PSInteractiveMenuTextInput `
    -Title 'Project root' `
    -Subtitle 'Enter the destination path.' `
    -Prompt 'Path' `
    -CurrentValue 'D:\Projects\ClientA_2026'

$inputResult.Action
$inputResult.Value
```

## Example: Boolean Prompt

```powershell
$confirmed = Read-PSInteractiveMenuBoolean `
    -Title 'Confirm import' `
    -Prompt 'Do you want to continue?' `
    -Default $true

$confirmed
```

## Controls

- `Up` / `Down`: Move between enabled items
- `Home` / `End`: Jump to the first or last enabled item
- `PageUp` / `PageDown`: Move through long lists page by page
- `Enter`: Confirm the current item
- `Esc` or `Backspace`: Go back when `-AllowBack` is enabled
- `Esc`: Cancel when `-AllowCancel` is enabled
- `Space`: Toggle the current item in multi-select mode
- `Insert`: Select all enabled items in multi-select mode
- `Delete`: Clear all selections in multi-select mode

## Return Objects

`Show-PSInteractiveMenu` returns a `PSInteractiveMenu.Result` object:

- `Action`: `Select`, `Back`, or `Cancel`
- `Option`: The selected option for single-select menus
- `Value`: Convenience access to `Option.Value`
- `SelectedOptions`: All selected option objects
- `SelectedValues`: All selected option values
- `SelectedIndex`: The active cursor index when the menu closes

`Read-PSInteractiveMenuTextInput` returns a `PSInteractiveMenu.TextInputResult` object:

- `Action`: `Submit` or `Back`
- `Value`: The entered text

`New-PSInteractiveMenuOption` returns a `PSInteractiveMenu.Option` object:

- `Key`
- `Label`
- `Description`
- `Value`
- `HotKey`
- `IsDefault`
- `IsEnabled`
- `Selected`

## Testing

Run the module tests:

```powershell
Invoke-Pester ./Tests
```

## Maintainer Build and Publish Workflow

Build a clean staged artifact and `.nupkg` package:

```powershell
pwsh ./build/Build-PSInteractiveMenuPackage.ps1
```

Publish the generated package:

```powershell
pwsh ./build/Publish-PSInteractiveMenu.ps1 -Repository PSGallery -ApiKey '<APIKEY>'
```

If you only want to copy the created package somewhere else:

```powershell
pwsh ./build/Publish-PSInteractiveMenu.ps1 -DestinationPath 'C:\Drops\PSInteractiveMenu'
```
