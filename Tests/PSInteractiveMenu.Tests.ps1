$moduleRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'PSInteractiveMenu.psd1') -Force

Describe 'PSInteractiveMenu module' {
    It 'exports the expected public commands' {
        $commandNames = @(
            'New-PSInteractiveMenuOption'
            'Read-PSInteractiveMenuBoolean'
            'Read-PSInteractiveMenuTextInput'
            'Show-PSInteractiveMenu'
        )

        foreach ($commandName in $commandNames) {
            Get-Command -Name $commandName -ErrorAction Stop | Should Not BeNullOrEmpty
        }
    }

    It 'exports the psmenu alias' {
        $alias = Get-Command -Name 'psmenu' -ErrorAction Stop

        $alias.CommandType | Should Be 'Alias'
        $alias.Definition | Should Be 'Show-PSInteractiveMenu'
    }

    It 'creates a typed menu option object' {
        $option = New-PSInteractiveMenuOption -Key 'scan' -Label 'Scan source media' -Description 'Start a scan.' -HotKey 'S' -IsDefault $true

        $option.Key | Should Be 'scan'
        $option.Label | Should Be 'Scan source media'
        $option.HotKey | Should Be 'S'
        $option.IsDefault | Should Be $true
        $option.IsEnabled | Should Be $true
        $option.Selected | Should Be $false
        $option.PSObject.TypeNames[0] | Should Be 'PSInteractiveMenu.Option'
    }

    It 'normalizes hotkeys to the first uppercase character' {
        $option = New-PSInteractiveMenuOption -Key 'settings' -Label 'Settings' -HotKey 'open'

        $option.HotKey | Should Be 'O'
    }
}
