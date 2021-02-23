$functionsDir = Join-Path -Path $PSScriptRoot -ChildPath 'Functions'
Get-ChildItem -LiteralPath $functionsDir -Filter '*.ps1' -Recurse | ForEach-Object -Process { . $_.PSPath }
Export-ModuleMember -Function * -Cmdlet * -Alias *