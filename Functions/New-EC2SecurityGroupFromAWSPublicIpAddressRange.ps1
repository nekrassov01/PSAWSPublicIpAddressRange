#Requires -Version 5.1

<#
.SYNOPSIS
Accesses ip-ranges.json and automatically generates a security group based on the CIDR extracted according to the conditions.

.EXAMPLE
$param = @{
    Region = 'ap-northeast-1'
    ServiceKey = 'S3', 'CLOUD9'
    IpAddressFormat = 'Ipv4'
    GroupName = 'test-sec-01'
    Description = 'test-sec-01'
    VpcId = 'vpc-00000000000000000'
    IpProtocol = 'tcp'
    FromPort = 80
    ToPort = 80
}
New-EC2SecurityGroupFromAWSPublicIpAddressRange @param

.NOTES
Author: nekrassov01
#>

function New-EC2SecurityGroupFromAWSPublicIpAddressRange
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

        [Parameter(Position = 3, Mandatory = $true)]
        [ValidateSet('Ipv4', 'Ipv6')]
        [string]$IpAddressFormat,

        [Parameter(Position = 4, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupName,
        
        [Parameter(Position = 5, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,
        
        [Parameter(Position = 6, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$VpcId,
        
        [Parameter(Position = 7, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$IpProtocol,

        [Parameter(Position = 8, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [int]$FromPort,
        
        [Parameter(Position = 9, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [int]$ToPort
    )

    begin
    {
        try
        {
            Set-StrictMode -Version Latest
            Set-DefaultAWSRegion -Region $Region
            Import-Module -Name AWS.Tools.EC2

            $tags = @{ Key='Name'; Value=$groupName }
            $nameTag = New-Object -TypeName Amazon.EC2.Model.TagSpecification
            $nameTag.ResourceType = 'security-group'
            $nameTag.Tags.Add($tags)

            $param = @{
                ProfileName = $profileName
                GroupName = $groupName
                Description = $description
                VpcId = $vpcId
                TagSpecification = $nameTag
            }
            $groupId = New-EC2SecurityGroup @param

            $awsPublicIpAddresses = Get-AWSPublicIpAddressRange -ServiceKey $serviceKey -Region $region

            $Ipv4Ranges = @()
            $Ipv6Ranges = @()

            foreach ($awsPublicIpAddress In $awsPublicIpAddresses)
            {
                if ($awsPublicIpAddress.IpPrefix -like '*.*')
                {
                    $ipv4Range = New-Object -TypeName Amazon.EC2.Model.IpRange
                    $ipv4Range.CidrIp = $awsPublicIpAddress.IpPrefix
                    $ipv4Range.Description = $awsPublicIpAddress.Service
                    $ipv4Ranges += $ipv4Range
                }

                if ($awsPublicIpAddress.IpPrefix -like '*:*')
                {
                    $ipv6Range = New-Object -TypeName Amazon.EC2.Model.Ipv6Range
                    $ipv6Range.CidrIpv6 = $awsPublicIpAddress.IpPrefix
                    $ipv6Range.Description = $awsPublicIpAddress.Service
                    $ipv6Ranges += $ipv6Range
                }
            }

            $ipPermission = New-Object -TypeName Amazon.EC2.Model.IpPermission
            $ipPermission.IpProtocol = $ipProtocol
            $ipPermission.FromPort = $fromPort
            $ipPermission.ToPort = $toPort
            $ipPermission.Ipv4Ranges = $ipv4Ranges
            $ipPermission.Ipv6Ranges = $ipv6Ranges

            if ($ipAddressFormat -eq 'Ipv4')
            {
                $ipPermission.Ipv6Ranges.Clear()
            }
        
            if ($ipAddressFormat -eq 'Ipv6')
            {
                $ipPermission.Ipv4Ranges.Clear()
            }

            Grant-EC2SecurityGroupIngress -GroupId $groupId -IpPermission $ipPermission
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    end
    {
        if ($groupId)
        {
            return Get-EC2SecurityGroup -GroupId $groupId
        }
    }
}
