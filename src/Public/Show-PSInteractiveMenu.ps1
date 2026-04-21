Register-PSInteractiveMenuFunction 'Show-PSInteractiveMenu'
function Show-PSInteractiveMenu {
    <#
    .SYNOPSIS
    Displays an interactive console menu and returns the selected action.

    .DESCRIPTION
    Supports breadcrumbs, context/status sections, information notes, hotkeys,
    paging, optional multi-select, and back/cancel navigation.
    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Options,

        [string]$Subtitle,
        [string[]]$Breadcrumb,
        [hashtable]$Status,
        [string[]]$Info,
        [switch]$AllowBack,
        [switch]$AllowCancel,
        [switch]$MultiSelect,
        [switch]$AllowEmptySelection
    )

    return Show-PSInteractiveMenuCore `
        -Title $Title `
        -Subtitle $Subtitle `
        -Breadcrumb $Breadcrumb `
        -Status $Status `
        -Info $Info `
        -Options $Options `
        -AllowBack:$AllowBack `
        -AllowCancel:$AllowCancel `
        -MultiSelect:$MultiSelect `
        -AllowEmptySelection:$AllowEmptySelection
}

