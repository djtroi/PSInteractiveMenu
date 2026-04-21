function New-PSInteractiveMenuTypedObject {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory)]
        [string]$TypeName,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Properties
    )

    $object = [PSCustomObject]$Properties
    $object.PSObject.TypeNames.Insert(0, $TypeName)
    return $object
}

function Assert-PSInteractiveMenuConsoleSupport {
    [CmdletBinding()]
    param()

    try {
        $null = [System.Console]::WindowWidth
        $null = [System.Console]::WindowHeight
    }
    catch {
        throw 'PSInteractiveMenu requires an interactive console with System.Console support.'
    }

    if ([System.Console]::IsInputRedirected -or [System.Console]::IsOutputRedirected) {
        throw 'PSInteractiveMenu requires direct keyboard and screen access and cannot run with redirected console input or output.'
    }
}

function ConvertTo-PSInteractiveMenuText {
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [AllowNull()]
        $Value
    )

    if ($null -eq $Value) {
        return '-'
    }

    if ($Value -is [bool]) {
        if ($Value) {
            return 'Yes'
        }

        return 'No'
    }

    if ($Value -is [datetime]) {
        return $Value.ToString('yyyy-MM-dd HH:mm:ss')
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $pairs = @()
        foreach ($key in $Value.Keys) {
            $pairs += ('{0}={1}' -f $key, (ConvertTo-PSInteractiveMenuText -Value $Value[$key]))
        }

        if ($pairs.Count -gt 0) {
            return ($pairs -join '; ')
        }

        return '-'
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $items = @(
            $Value |
                ForEach-Object { [string]$_ } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )

        if ($items.Count -gt 0) {
            return ($items -join ', ')
        }

        return '<none>'
    }

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return '-'
    }

    return $text.Trim()
}

function Get-PSInteractiveMenuViewport {
    [CmdletBinding()]
    param()

    $width = 100
    $height = 30

    try {
        if ($Host.UI -and $Host.UI.RawUI) {
            $width = [Math]::Max([int]$Host.UI.RawUI.WindowSize.Width, 80)
            $height = [Math]::Max([int]$Host.UI.RawUI.WindowSize.Height, 24)
        }
    }
    catch {
        $width = 100
        $height = 30
    }

    return New-PSInteractiveMenuTypedObject -TypeName 'PSInteractiveMenu.Viewport' -Properties ([ordered]@{
        Width = $width
        Height = $height
    })
}

function Format-PSInteractiveMenuLine {
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [AllowEmptyString()]
        [string]$Text,
        [ValidateRange(1, 1000)]
        [int]$Width
    )

    $safeText = if ($null -eq $Text) { '' } else { $Text }
    $normalized = ($safeText -replace "`r", ' ' -replace "`n", ' ').Trim()
    if ($normalized.Length -gt $Width) {
        if ($Width -le 3) {
            return $normalized.Substring(0, $Width)
        }

        return $normalized.Substring(0, $Width - 3) + '...'
    }

    return $normalized.PadRight($Width)
}

function Get-PSInteractiveMenuFirstEnabledIndex {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Options
    )

    for ($i = 0; $i -lt $Options.Count; $i++) {
        if ([bool]$Options[$i].IsEnabled) {
            return $i
        }
    }

    return -1
}

function Get-PSInteractiveMenuLastEnabledIndex {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Options
    )

    for ($i = $Options.Count - 1; $i -ge 0; $i--) {
        if ([bool]$Options[$i].IsEnabled) {
            return $i
        }
    }

    return -1
}

function Find-PSInteractiveMenuEnabledIndex {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Options,
        [int]$RequestedIndex,
        [bool]$SearchBackward = $false
    )

    if (-not $Options -or $Options.Count -eq 0) {
        return -1
    }

    if ($RequestedIndex -lt 0) {
        if ($SearchBackward) {
            return Get-PSInteractiveMenuLastEnabledIndex -Options $Options
        }

        return Get-PSInteractiveMenuFirstEnabledIndex -Options $Options
    }

    if ($RequestedIndex -ge $Options.Count) {
        if ($SearchBackward) {
            return Get-PSInteractiveMenuLastEnabledIndex -Options $Options
        }

        return Get-PSInteractiveMenuFirstEnabledIndex -Options $Options
    }

    if ([bool]$Options[$RequestedIndex].IsEnabled) {
        return $RequestedIndex
    }

    if ($SearchBackward) {
        for ($i = $RequestedIndex - 1; $i -ge 0; $i--) {
            if ([bool]$Options[$i].IsEnabled) {
                return $i
            }
        }

        for ($i = $RequestedIndex + 1; $i -lt $Options.Count; $i++) {
            if ([bool]$Options[$i].IsEnabled) {
                return $i
            }
        }
    }
    else {
        for ($i = $RequestedIndex + 1; $i -lt $Options.Count; $i++) {
            if ([bool]$Options[$i].IsEnabled) {
                return $i
            }
        }

        for ($i = $RequestedIndex - 1; $i -ge 0; $i--) {
            if ([bool]$Options[$i].IsEnabled) {
                return $i
            }
        }
    }

    return -1
}

function New-PSInteractiveMenuResultObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Action,
        $Option,
        [AllowEmptyCollection()]
        [object[]]$SelectedOptions = @(),
        [AllowEmptyCollection()]
        [object[]]$SelectedValues = @(),
        [int]$SelectedIndex = -1
    )

    return New-PSInteractiveMenuTypedObject -TypeName 'PSInteractiveMenu.Result' -Properties ([ordered]@{
        Action = $Action
        Option = $Option
        Value = if ($null -ne $Option -and $Option.PSObject.Properties.Name -contains 'Value') { $Option.Value } else { $null }
        SelectedOptions = @($SelectedOptions)
        SelectedValues = @($SelectedValues)
        SelectedIndex = $SelectedIndex
    })
}

function Write-PSInteractiveMenuScreen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        [string]$Subtitle,
        [string[]]$Breadcrumb,
        [hashtable]$Status,
        [string[]]$Info,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Options,
        [ValidateRange(-1, 100000)]
        [int]$SelectedIndex = 0,
        [switch]$AllowBack,
        [switch]$AllowCancel,
        [switch]$MultiSelect
    )

    $viewport = Get-PSInteractiveMenuViewport
    $contentWidth = [Math]::Max(20, $viewport.Width - 4)

    $statusLines = @()
    if ($Status) {
        foreach ($key in $Status.Keys) {
            $statusLines += ('{0}: {1}' -f $key, (ConvertTo-PSInteractiveMenuText -Value $Status[$key]))
        }
    }

    $infoLines = @($Info | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    $selectedDescriptionLines = @()
    if ($SelectedIndex -ge 0 -and $SelectedIndex -lt $Options.Count) {
        $selectedOption = $Options[$SelectedIndex]
        if (-not [string]::IsNullOrWhiteSpace([string]$selectedOption.Description)) {
            $selectedDescriptionLines = @(
                [string]$selectedOption.Description -split "(`r`n|`n|`r)" |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            )
        }
    }

    $reservedLineCount = 8
    if (-not [string]::IsNullOrWhiteSpace($Subtitle)) { $reservedLineCount++ }
    if ($Breadcrumb -and $Breadcrumb.Count -gt 0) { $reservedLineCount++ }
    if ($statusLines.Count -gt 0) { $reservedLineCount += $statusLines.Count + 1 }
    if ($infoLines.Count -gt 0) { $reservedLineCount += $infoLines.Count + 1 }
    if ($selectedDescriptionLines.Count -gt 0) { $reservedLineCount += [Math]::Min($selectedDescriptionLines.Count, 4) + 1 }

    $pageSize = [Math]::Max(5, $viewport.Height - $reservedLineCount)
    if ($Options.Count -gt 0) {
        $pageSize = [Math]::Min($pageSize, $Options.Count)
    }

    $pageIndex = 0
    $pageCount = 1
    if ($Options.Count -gt 0 -and $pageSize -gt 0) {
        $pageIndex = [Math]::Floor($SelectedIndex / $pageSize)
        $pageCount = [Math]::Ceiling($Options.Count / [double]$pageSize)
    }

    $startIndex = if ($Options.Count -gt 0) { $pageIndex * $pageSize } else { 0 }
    $endIndex = if ($Options.Count -gt 0) {
        [Math]::Min(($startIndex + $pageSize - 1), ($Options.Count - 1))
    }
    else {
        -1
    }

    Clear-Host
    Write-Host ''
    Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text $Title -Width $contentWidth))

    if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
        Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text $Subtitle -Width $contentWidth))
    }

    if ($Breadcrumb -and $Breadcrumb.Count -gt 0) {
        $breadcrumbText = 'Path: {0}' -f ($Breadcrumb -join ' > ')
        Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text $breadcrumbText -Width $contentWidth))
    }

    if ($statusLines.Count -gt 0) {
        Write-Host ''
        Write-Host '  Context'
        foreach ($line in $statusLines) {
            Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text $line -Width $contentWidth))
        }
    }

    if ($infoLines.Count -gt 0) {
        Write-Host ''
        Write-Host '  Notes'
        foreach ($line in $infoLines) {
            Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text $line -Width $contentWidth))
        }
    }

    Write-Host ''
    $actionHeader = if ($pageCount -gt 1) {
        'Actions (page {0}/{1})' -f ($pageIndex + 1), $pageCount
    }
    else {
        'Actions'
    }
    Write-Host ('  ' + $actionHeader)

    if ($Options.Count -eq 0) {
        Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text 'No actions available.' -Width $contentWidth)) -ForegroundColor DarkGray
    }
    else {
        for ($i = $startIndex; $i -le $endIndex; $i++) {
            $option = $Options[$i]
            $cursorPrefix = if ($i -eq $SelectedIndex) { '>' } else { ' ' }
            $selectionPrefix = if ($MultiSelect) {
                if ([bool]$option.Selected) { '[x] ' } else { '[ ] ' }
            }
            else {
                ''
            }

            $hotKeyText = if (-not [string]::IsNullOrWhiteSpace([string]$option.HotKey)) {
                '[{0}] ' -f $option.HotKey
            }
            else {
                ''
            }

            $suffixText = if (-not [bool]$option.IsEnabled) { ' (not available)' } else { '' }
            $lineText = '{0} {1}{2}{3}' -f $cursorPrefix, $selectionPrefix, $hotKeyText, $option.Label
            $lineText += $suffixText
            $formattedLine = '  ' + (Format-PSInteractiveMenuLine -Text $lineText -Width $contentWidth)

            if ($i -eq $SelectedIndex) {
                Write-Host $formattedLine -ForegroundColor Black -BackgroundColor Gray
            }
            elseif (-not [bool]$option.IsEnabled) {
                Write-Host $formattedLine -ForegroundColor DarkGray
            }
            else {
                Write-Host $formattedLine
            }
        }
    }

    if ($selectedDescriptionLines.Count -gt 0) {
        Write-Host ''
        Write-Host '  Details'
        foreach ($line in $selectedDescriptionLines | Select-Object -First 4) {
            Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text $line -Width $contentWidth))
        }
    }

    Write-Host ''
    $controlSegments = @('[Up/Down] Move', '[Home/End] Jump', '[PageUp/PageDown] Page', '[Enter] Select')
    if ($MultiSelect) {
        $controlSegments += '[Space] Toggle'
        $controlSegments += '[Insert] All'
        $controlSegments += '[Delete] None'
    }

    if ($AllowBack) {
        $controlSegments += '[Esc] Back'
    }
    elseif ($AllowCancel) {
        $controlSegments += '[Esc] Cancel'
    }

    Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text ('Controls: ' + ($controlSegments -join ' | ')) -Width $contentWidth))

    if ($MultiSelect) {
        $selectedCount = @($Options | Where-Object { [bool]$_.Selected }).Count
        Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text ('Selected items: {0}' -f $selectedCount) -Width $contentWidth))
    }

    return New-PSInteractiveMenuTypedObject -TypeName 'PSInteractiveMenu.Layout' -Properties ([ordered]@{
        PageSize = $pageSize
        PageIndex = $pageIndex
        PageCount = $pageCount
    })
}

function Show-PSInteractiveMenuCore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        [string]$Subtitle,
        [string[]]$Breadcrumb,
        [hashtable]$Status,
        [string[]]$Info,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Options,
        [switch]$AllowBack,
        [switch]$AllowCancel,
        [switch]$MultiSelect,
        [switch]$AllowEmptySelection
    )

    Assert-PSInteractiveMenuConsoleSupport

    $menuOptions = @($Options)
    $selectedIndex = Get-PSInteractiveMenuFirstEnabledIndex -Options $menuOptions
    if ($selectedIndex -lt 0 -and $menuOptions.Count -gt 0) {
        $selectedIndex = 0
    }

    $defaultIndex = -1
    for ($i = 0; $i -lt $menuOptions.Count; $i++) {
        if ([bool]$menuOptions[$i].IsDefault -and [bool]$menuOptions[$i].IsEnabled) {
            $defaultIndex = $i
            break
        }
    }

    if ($defaultIndex -ge 0) {
        $selectedIndex = $defaultIndex
    }

    $cursorVisible = $true
    try {
        $cursorVisible = [System.Console]::CursorVisible
        [System.Console]::CursorVisible = $false

        while ($true) {
            $layout = Write-PSInteractiveMenuScreen `
                -Title $Title `
                -Subtitle $Subtitle `
                -Breadcrumb $Breadcrumb `
                -Status $Status `
                -Info $Info `
                -Options $menuOptions `
                -SelectedIndex $selectedIndex `
                -AllowBack:$AllowBack `
                -AllowCancel:$AllowCancel `
                -MultiSelect:$MultiSelect

            $keyInfo = [System.Console]::ReadKey($true)
            switch ($keyInfo.Key) {
                'DownArrow' {
                    $nextIndex = Find-PSInteractiveMenuEnabledIndex -Options $menuOptions -RequestedIndex ($selectedIndex + 1)
                    if ($nextIndex -ge 0) {
                        $selectedIndex = $nextIndex
                    }
                }
                'UpArrow' {
                    $previousIndex = Find-PSInteractiveMenuEnabledIndex -Options $menuOptions -RequestedIndex ($selectedIndex - 1) -SearchBackward $true
                    if ($previousIndex -ge 0) {
                        $selectedIndex = $previousIndex
                    }
                }
                'Home' {
                    $firstIndex = Get-PSInteractiveMenuFirstEnabledIndex -Options $menuOptions
                    if ($firstIndex -ge 0) {
                        $selectedIndex = $firstIndex
                    }
                }
                'End' {
                    $lastIndex = Get-PSInteractiveMenuLastEnabledIndex -Options $menuOptions
                    if ($lastIndex -ge 0) {
                        $selectedIndex = $lastIndex
                    }
                }
                'PageDown' {
                    $targetIndex = [Math]::Min(($selectedIndex + $layout.PageSize), ($menuOptions.Count - 1))
                    $pageDownIndex = Find-PSInteractiveMenuEnabledIndex -Options $menuOptions -RequestedIndex $targetIndex
                    if ($pageDownIndex -ge 0) {
                        $selectedIndex = $pageDownIndex
                    }
                }
                'PageUp' {
                    $targetIndex = [Math]::Max(($selectedIndex - $layout.PageSize), 0)
                    $pageUpIndex = Find-PSInteractiveMenuEnabledIndex -Options $menuOptions -RequestedIndex $targetIndex -SearchBackward $true
                    if ($pageUpIndex -ge 0) {
                        $selectedIndex = $pageUpIndex
                    }
                }
                'Spacebar' {
                    if ($MultiSelect -and $selectedIndex -ge 0 -and [bool]$menuOptions[$selectedIndex].IsEnabled) {
                        $menuOptions[$selectedIndex].Selected = -not [bool]$menuOptions[$selectedIndex].Selected
                    }
                }
                'Insert' {
                    if ($MultiSelect) {
                        foreach ($option in $menuOptions) {
                            if ([bool]$option.IsEnabled) {
                                $option.Selected = $true
                            }
                        }
                    }
                }
                'Delete' {
                    if ($MultiSelect) {
                        foreach ($option in $menuOptions) {
                            $option.Selected = $false
                        }
                    }
                }
                'Enter' {
                    if ($MultiSelect) {
                        $selectedOptions = @($menuOptions | Where-Object { [bool]$_.Selected })
                        if ($selectedOptions.Count -eq 0 -and -not $AllowEmptySelection) {
                            continue
                        }

                        return New-PSInteractiveMenuResultObject `
                            -Action 'Select' `
                            -SelectedOptions $selectedOptions `
                            -SelectedValues @($selectedOptions | ForEach-Object { $_.Value }) `
                            -SelectedIndex $selectedIndex
                    }

                    if ($selectedIndex -ge 0 -and $selectedIndex -lt $menuOptions.Count -and [bool]$menuOptions[$selectedIndex].IsEnabled) {
                        return New-PSInteractiveMenuResultObject `
                            -Action 'Select' `
                            -Option $menuOptions[$selectedIndex] `
                            -SelectedOptions @($menuOptions[$selectedIndex]) `
                            -SelectedValues @($menuOptions[$selectedIndex].Value) `
                            -SelectedIndex $selectedIndex
                    }
                }
                'Escape' {
                    if ($AllowBack) {
                        return New-PSInteractiveMenuResultObject -Action 'Back' -SelectedIndex $selectedIndex
                    }

                    if ($AllowCancel) {
                        return New-PSInteractiveMenuResultObject -Action 'Cancel' -SelectedIndex $selectedIndex
                    }
                }
                'Backspace' {
                    if ($AllowBack) {
                        return New-PSInteractiveMenuResultObject -Action 'Back' -SelectedIndex $selectedIndex
                    }
                }
                default {
                    $pressedChar = [string]$keyInfo.KeyChar
                    if (-not [string]::IsNullOrWhiteSpace($pressedChar)) {
                        $hotKey = $pressedChar.Substring(0, 1).ToUpperInvariant()
                        $hotKeyMatch = @(
                            $menuOptions |
                                Where-Object {
                                    [bool]$_.IsEnabled -and
                                    -not [string]::IsNullOrWhiteSpace([string]$_.HotKey) -and
                                    [string]$_.HotKey -eq $hotKey
                                }
                        )

                        if ($hotKeyMatch.Count -gt 0) {
                            $match = $hotKeyMatch[0]
                            for ($i = 0; $i -lt $menuOptions.Count; $i++) {
                                if ($menuOptions[$i].Key -eq $match.Key) {
                                    $selectedIndex = $i
                                    break
                                }
                            }

                            if ($MultiSelect) {
                                $match.Selected = -not [bool]$match.Selected
                            }
                            else {
                                return New-PSInteractiveMenuResultObject `
                                    -Action 'Select' `
                                    -Option $match `
                                    -SelectedOptions @($match) `
                                    -SelectedValues @($match.Value) `
                                    -SelectedIndex $selectedIndex
                            }
                        }
                    }
                }
            }
        }
    }
    finally {
        [System.Console]::CursorVisible = $cursorVisible
    }
}

function Read-PSInteractiveMenuTextInputCore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        [string]$Subtitle,
        [string[]]$Breadcrumb,
        [hashtable]$Status,
        [string[]]$Info,
        [Parameter(Mandatory)]
        [string]$Prompt,
        [string]$CurrentValue
    )

    Assert-PSInteractiveMenuConsoleSupport

    $viewport = Get-PSInteractiveMenuViewport
    $contentWidth = [Math]::Max(20, $viewport.Width - 4)

    Clear-Host
    Write-Host ''
    Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text $Title -Width $contentWidth))

    if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
        Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text $Subtitle -Width $contentWidth))
    }

    if ($Breadcrumb -and $Breadcrumb.Count -gt 0) {
        Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text ('Path: {0}' -f ($Breadcrumb -join ' > ')) -Width $contentWidth))
    }

    if ($Status) {
        Write-Host ''
        Write-Host '  Context'
        foreach ($key in $Status.Keys) {
            $line = '{0}: {1}' -f $key, (ConvertTo-PSInteractiveMenuText -Value $Status[$key])
            Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text $line -Width $contentWidth))
        }
    }

    Write-Host ''
    Write-Host '  Notes'
    foreach ($line in @($Info) + @('Press Enter on empty input to go back.')) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            Write-Host ('  ' + (Format-PSInteractiveMenuLine -Text $line -Width $contentWidth))
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($CurrentValue)) {
        Write-Host ''
        Write-Host ('  Current: ' + (Format-PSInteractiveMenuLine -Text $CurrentValue -Width ([Math]::Max(10, $contentWidth - 9))))
    }

    Write-Host ''
    $inputValue = Read-Host $Prompt
    if ([string]::IsNullOrWhiteSpace($inputValue)) {
        return New-PSInteractiveMenuTypedObject -TypeName 'PSInteractiveMenu.TextInputResult' -Properties ([ordered]@{
            Action = 'Back'
            Value = $null
        })
    }

    return New-PSInteractiveMenuTypedObject -TypeName 'PSInteractiveMenu.TextInputResult' -Properties ([ordered]@{
        Action = 'Submit'
        Value = $inputValue.Trim()
    })
}
