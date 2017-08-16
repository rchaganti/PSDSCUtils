[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String]
    $ModuleName,

    [Parameter(Mandatory)]
    [String]
    $ResourceName
)

Process
{
    [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ClearCache() 
    $functionsToDefine = New-Object -TypeName 'System.Collections.Generic.Dictionary[string,ScriptBlock]'([System.StringComparer]::OrdinalIgnoreCase)
    $builtinModules = @('PSDesiredStateConfiguration'.'PSDesiredStateConfigurationEngine')
        
    [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::LoadDefaultCimKeywords($functionsToDefine)
    if ($builtinModules -notcontains $ModuleName)
    {
        $modInfo = Get-Module -Name $ModuleName -ListAvailable
        $schemaFilePath = $null
        $keywordErrors = New-Object -TypeName 'System.Collections.ObjectModel.Collection[System.Exception]'
        $foundCimSchema = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportCimKeywordsFromModule($modInfo, $ResourceName, [ref] $SchemaFilePath, $functionsToDefine, $keywordErrors)
        $foundScriptSchema = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportScriptKeywordsFromModule($modInfo, $ResourceName, [ref] $SchemaFilePath, $functionsToDefine)
    }

    $resourceProperties = ([System.Management.Automation.Language.DynamicKeyword]::GetKeyword($ResourceName)).Properties
    foreach ($key in $resourceProperties.Keys)
    {
        $resourceProperties.$key | Select Name, TypeConstraint, IsKey, Mandatory, Values, Range
    }
}
