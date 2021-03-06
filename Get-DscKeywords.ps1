[CmdletBinding()]
param (
    $ImplementingModule
)

Begin
{
    [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ClearCache() 
    $functionsToDefine = New-Object -TypeName 'System.Collections.Generic.Dictionary[string,ScriptBlock]'([System.StringComparer]::OrdinalIgnoreCase) 
    
    $builtInModules = @('PSDesiredStateConfiguration','PSDesiredStateConfigurationEngine') 
}

Process
{
    #Load the default CIM Keywords
    [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::LoadDefaultCimKeywords($functionsToDefine)

    if ($builtInModules -notcontains $ImplementingModule)
    {
        #We need to import either CIM or Script or Class keywords
        #Check if the module exists
        $modInfo = Get-Module -Name $ImplementingModule -ListAvailable
        $dscResourceFolder = "$($modInfo.ModuleBase)\DscResources"
        foreach ($resource in (Get-ChildItem -Path $dscResourceFolder -Directory -Name))
        {
            $schemaFilePath = $null
            $keywordErrors = New-Object -TypeName 'System.Collections.ObjectModel.Collection[System.Exception]'
            $foundCimSchema = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportCimKeywordsFromModule($modInfo, $resource, [ref] $SchemaFilePath, $functionsToDefine, $keywordErrors)
            $foundScriptSchema = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportScriptKeywordsFromModule($modInfo, $resource, [ref] $SchemaFilePath, $functionsToDefine )
        }
    }

    $keywords = [System.Management.Automation.Language.DynamicKeyword]::GetKeyword()
    $keywords.Where({$_.ImplementingModule -eq $ImplementingModule})
}
