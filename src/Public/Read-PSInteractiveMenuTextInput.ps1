Register-PSInteractiveMenuFunction 'Read-PSInteractiveMenuTextInput'
function Read-PSInteractiveMenuTextInput {
    <#
    .SYNOPSIS
    Shows a styled text input screen that matches the PSInteractiveMenu visual layout.
    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string]$Prompt,

        [string]$Subtitle,
        [string[]]$Breadcrumb,
        [hashtable]$Status,
        [string[]]$Info,
        [string]$CurrentValue
    )

    return Read-PSInteractiveMenuTextInputCore `
        -Title $Title `
        -Subtitle $Subtitle `
        -Breadcrumb $Breadcrumb `
        -Status $Status `
        -Info $Info `
        -Prompt $Prompt `
        -CurrentValue $CurrentValue
}

