BeforeAll {
    $moduleRoot = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path -Path $moduleRoot -ChildPath 'PSInteractiveMenu.psd1') -Force
}

Describe 'PSInteractiveMenu module' {
    It 'exports the expected public commands' {
        $commandNames = @(
            'New-PSInteractiveMenuOption'
            'Read-PSInteractiveMenuBoolean'
            'Read-PSInteractiveMenuTextInput'
            'Show-PSInteractiveMenu'
        )

        foreach ($commandName in $commandNames) {
            Get-Command -Name $commandName -ErrorAction Stop | Should -Not -BeNullOrEmpty
        }
    }

    It 'creates a valid menu option object' {
        $option = New-PSInteractiveMenuOption -Key 'scan' -Label 'Scan source media' -Description 'Start a scan.' -HotKey 'S' -IsDefault

        $option.Key | Should -Be 'scan'
        $option.Label | Should -Be 'Scan source media'
        $option.HotKey | Should -Be 'S'
        $option.IsDefault | Should -BeTrue
        $option.IsEnabled | Should -BeTrue
    }
}

