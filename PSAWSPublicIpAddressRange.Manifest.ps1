Push-Location -Path $PSScriptRoot

# Variables
$module                 = 'PSAWSPublicIpAddressRange'
$author                 = 'nekrassov01'
$copyright              = '(c) {0} All rights reserved.' -f $author
$moduleVersion          = '0.1.0.0'
$description            = 'PSAWSPublicIpAddressRange accesses ip-ranges.json and automatically generates a security group and prefix list based on the CIDR extracted according to the conditions.'
$powerShellVersion      = '5.1'
$dotNetFrameworkVersion = '4.5'
$clrVersion             = '4.0.0.0'
$psd1Path               = '{0}.psd1' -f $module
$psm1Path               = '{0}.psm1' -f $module
$modulePath             = Join-Path -Path $PSScriptRoot -ChildPath 'Functions'
$requiredModules        = @('AWS.Tools.EC2')
$requiredAssemblies     = @()
$functions              = (Get-ChildItem -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath 'Functions') -Filter '*.ps1' -Recurse).ForEach({ [System.IO.Path]::GetFileNameWithoutExtension($_.Name) })
$aliases                = @()

# Manifest parameters
$script:moduleManifest = @{
    Path                   = $psd1Path
    Author                 = $author
    CompanyName            = $author
    Copyright              = $copyright
    RootModule             = $psm1Path
    ModuleVersion          = $moduleVersion
    Description            = $description
    PowerShellVersion      = $powerShellVersion
    DotNetFrameworkVersion = $dotNetFrameworkVersion
    ClrVersion             = $clrVersion
    RequiredModules        = $requiredModules
    #RequiredAssemblies     = $requiredAssemblies
    CmdletsToExport        = '*'
    FunctionsToExport      = $functions
    #VariablesToExport      = $module
    #AliasesToExport        = $aliases
}

if (Test-Path -Path $psd1Path)
{
    Update-ModuleManifest @moduleManifest
}
else
{
    New-ModuleManifest @moduleManifest
}

Pop-Location
