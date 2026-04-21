Register-PSInteractiveMenuFunction 'Read-PSInteractiveMenuBoolean'
function Read-PSInteractiveMenuBoolean {
    <#
    .SYNOPSIS
    Shows a boolean confirmation menu and returns $true or $false.
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string]$Prompt,

        [bool]$Default = $true,
        [string[]]$Breadcrumb,
        [hashtable]$Status,
        [string[]]$Info
    )

    $result = Show-PSInteractiveMenu `
        -Title $Title `
        -Subtitle $Prompt `
        -Breadcrumb $Breadcrumb `
        -Status $Status `
        -Info $Info `
        -Options @(
            New-PSInteractiveMenuOption -Key 'Yes' -Label 'Yes' -Description 'Continue with this action.' -HotKey 'Y' -IsDefault $Default
            New-PSInteractiveMenuOption -Key 'No' -Label 'No' -Description 'Do not continue with this action.' -HotKey 'N' -IsDefault (-not $Default)
        )

    return ($result.Option.Key -eq 'Yes')
}

