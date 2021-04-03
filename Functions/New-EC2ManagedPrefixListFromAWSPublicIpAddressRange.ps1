#Requires -Version 5.1

<#
.SYNOPSIS
Accesses ip-ranges.json and automatically generates a prefix list based on the CIDR extracted according to the conditions.

.EXAMPLE
$param = @{
    Region = 'ap-northeast-1'
    ServiceKey = 'S3', 'AMAZON_CONNECT'
    IpAddressFormat = 'Ipv4'
    MaxEntry = 30
    PrefixListName = 'test-prefix-01'
}
New-EC2ManagedPrefixListFromAWSPublicIpAddressRange @param

.NOTES
Author: nekrassov01
#>

Function New-EC2ManagedPrefixListFromAWSPublicIpAddressRange
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        [Parameter(Position = 1, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ProfileName = 'default',

        [Parameter(Position = 2, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ServiceKey,

        [Parameter(Position = 3, Mandatory = $false)]
        [ValidateSet('Ipv4', 'Ipv6')]
        [string]$IpAddressFormat,

        [Parameter(Position = 4, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [int]$MaxEntry,

        [Parameter(Position = 5, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrefixListName
    )

    begin
    {
        try
        {
            Set-StrictMode -Version Latest
            Set-DefaultAWSRegion -Region $Region
            Import-Module -Name AWS.Tools.EC2

            $isExist = Get-EC2ManagedPrefixList -Filter @{ Name="prefix-list-name"; Values=$prefixListName } -ProfileName $profileName

            if ($isExist.State.Value -eq 'create-complete')
            {
                $isExist
                return
            }

            $AWSPublicIpAddresses = Get-AWSPublicIpAddressRange -ServiceKey $serviceKey -Region $region
            
            $ipv4Entries = @()
            $ipv6Entries = @()
            
            foreach ($awsPublicIpAddress In $awsPublicIpAddresses)
            {
                if ($awsPublicIpAddress.IpPrefix -like '*.*' -and $ipAddressFormat -eq 'Ipv4')
                {
                    $ipv4Entry = New-Object -TypeName Amazon.EC2.Model.AddPrefixListEntry
                    $ipv4Entry.Cidr = $awsPublicIpAddress.IpPrefix
                    $ipv4Entry.Description = $awsPublicIpAddress.Service
                    $ipv4Entries += $ipv4Entry
                }
            
                if ($awsPublicIpAddress.IpPrefix -like '*:*' -and $ipAddressFormat -eq 'Ipv6')
                {
                    $ipv6Entry = New-Object -TypeName Amazon.EC2.Model.AddPrefixListEntry
                    $ipv6Entry.Cidr = $awsPublicIpAddress.IpPrefix
                    $ipv6Entry.Description = $awsPublicIpAddress.Service
                    $ipv6Entries += $ipv6Entry
                }
            }
            
            $tags = @{ Key='Name'; Value=$prefixListName }
            $nameTag = New-Object -TypeName Amazon.EC2.Model.TagSpecification
            $nameTag.ResourceType = 'prefix-list'
            $nameTag.Tags.Add($tags)
            
            $param = @{
                ProfileName = $profileName
                AddressFamily = $ipAddressFormat
                MaxEntry = $maxEntry
                PrefixListName = $prefixListName
                TagSpecification = $nameTag
            }
            
            if ($ipAddressFormat -eq 'Ipv4')
            {
                $param.Add('Entry', $ipv4Entries)
            }
            
            if ($ipAddressFormat -eq 'Ipv6')
            {
                $param.Add('Entry', $ipv6Entries)
            }

            $prefixList = New-EC2ManagedPrefixList @param
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    end
    {
        if (Test-Path -LiteralPath 'Variable:prefixList')
        {
            return $prefixList
        }
    }
}
