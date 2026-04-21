Register-PSInteractiveMenuFunction 'New-PSInteractiveMenuOption'
function New-PSInteractiveMenuOption {
    <#
    .SYNOPSIS
    Creates a menu option object for PSInteractiveMenu.
    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Label,

        [string]$Description,
        $Value,
        [string]$HotKey,
        [bool]$IsDefault = $false,
        [bool]$IsEnabled = $true,
        [bool]$Selected = $false
    )

    $normalizedHotKey = $null
    if (-not [string]::IsNullOrWhiteSpace($HotKey)) {
        $normalizedHotKey = $HotKey.Substring(0, 1).ToUpperInvariant()
    }

    return [PSCustomObject]@{
        PSTypeName = 'PSInteractiveMenu.Option'
        Key = $Key
        Label = $Label
        Description = $Description
        Value = $Value
        HotKey = $normalizedHotKey
        IsDefault = [bool]$IsDefault
        IsEnabled = [bool]$IsEnabled
        Selected = [bool]$Selected
    }
}

