[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [String] $ConfigurationScript,

    [Parameter()]
    [Switch] $Package,

    [Parameter()]
    [String] $PackagePath
)

$ConfigurationScriptContent = Get-Content -Path $ConfigurationScript -Raw
$ast = [System.Management.Automation.Language.Parser]::ParseInput($ConfigurationScriptContent, [ref]$null, [ref]$null)
$configAst = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAst]}, $true)
$moduleSpecifcation = @()
foreach ($config in $configAst)
{
    $dksAst = $config.FindAll({ $args[0] -is [System.Management.Automation.Language.DynamicKeywordStatementAst]}, $true)

    foreach ($dynKeyword in $dksAst)
    {
        [System.Management.Automation.Language.CommandElementAst[]] $cea = $dynKeyword.CommandElements.Copy()
        $allCommands = [System.Management.Automation.Language.CommandAst]::new($dynKeyword.Extent, $cea, [System.Management.Automation.Language.TokenKind]::Unknown, $null)
        foreach ($importCommand in $allCommands)
        {
            if ($importCommand.CommandElements[0].Value -eq 'Import-DscResource')
            {
                [System.Management.Automation.Language.StaticBindingResult]$spBinder = [System.Management.Automation.Language.StaticParameterBinder]::BindCommand($importCommand, $false)
            
                $moduleNames = ''
                $resourceNames = ''
                $moduleVersion = ''
                foreach ($item in $spBinder.BoundParameters.GetEnumerator())
                { 
                    $parameterName = $item.key
                    $argument = $item.Value.Value.Extent.Text

                    #Check if the parametername is Name
                    $parameterToCheck = 'Name'
                    $parameterToCheckLength = $parameterToCheck.Length
                    $parameterNameLength = $parameterName.Length

                    if (($parameterNameLength -le $parameterToCheckLength) -and ($parameterName.Equals($parameterToCheck.Substring(0,$parameterNameLength))))
                    {
                        $resourceNames = $argument.Split(',')
                    }

                    #Check if the parametername is ModuleName
                    $parameterToCheck = 'ModuleName'
                    $parameterToCheckLength = $parameterToCheck.Length
                    $parameterNameLength = $parameterName.Length
                    if (($parameterNameLength -le $parameterToCheckLength) -and ($parameterName.Equals($parameterToCheck.Substring(0,$parameterNameLength))))
                    {
                        $moduleNames = $argument.Split(',')
                    }

                    #Check if the parametername is ModuleVersion
                    $parameterToCheck = 'ModuleVersion'
                    $parameterToCheckLength = $parameterToCheck.Length
                    $parameterNameLength = $parameterName.Length
                    if (($parameterNameLength -le $parameterToCheckLength) -and ($parameterName.Equals($parameterToCheck.Substring(0,$parameterNameLength))))
                    {
                        if (-not ($moduleVersion.Contains(',')))
                        {
                            $moduleVersion = $argument
                        }
                        else
                        {
                            throw 'Cannot specify more than one moduleversion' 
                        }
                    }
                }

                #Get the module details
                #"Module Names: " + $moduleNames
                #"Resource Name: " + $resourceNames
                #"Module Version: " + $moduleVersion 

                if($moduleVersion)
                {
                    if (-not $moduleNames)
                    {
                        throw '-ModuleName is required when -ModuleVersion is used'
                    }

                    if ($moduleNames.Count -gt 1)
                    {
                        throw 'Cannot specify more than one module when ModuleVersion parameter is used'
                    }
                }

                if ($resourceNames)
                {
                    if ($moduleNames.Count -gt 1)
                    {
                        throw 'Cannot specify more than one module when the Name parameter is used'
                    }
                }
            
                #We have multiple combinations of parameters possible
                #Case 1: All three are provided: ModuleName,ModuleVerison, and Name
                #Case 2: ModuleName and ModuleVersion are provided
                #Case 3: Only Name is provided
                #Case 4: Only ModuleName is provided
                
                #Case 1, 2, and 3
                #At the moment, there is no error check on the resource names supplied as argument to -Name
                if ($moduleNames)
                {
                    foreach ($module in $moduleNames)
                    {
                        if (-not ($module -eq 'PSDesiredStateConfiguration'))
                        {
                            $moduleHash = @{
                                ModuleName = $module
                            }

                            if ($moduleVersion)
                            {
                                $moduleHash.Add('ModuleVersion',$moduleVersion)
                            }
                            else
                            {
                                $availableModuleVersion = Get-RecentModuleVersion -ModuleName $module
                                $moduleHash.Add('ModuleVersion',$availableModuleVersion)
                            }

                            $moduleInfo = Get-Module -ListAvailable -FullyQualifiedName $moduleHash -Verbose:$false -ErrorAction SilentlyContinue
                            if ($moduleInfo)
                            {
                                #TODO: Check if listed resources are equal or subset of what module exports
                                $moduleSpecifcation += $moduleInfo
                            }
                            else
                            {
                                throw "No module exists with name ${module}"
                            }
                        }
                    }    
                }

                #Case 2
                #Foreach resource, we need to find a module
                if ((-not $moduleNames) -and $resourceNames)
                {
                    $moduleHash = Get-DscModulesFromResourceName -ResourceNames $resourceNames -Verbose:$false
                    foreach ($module in $moduleHash)
                    {
                        $moduleInfo = Get-Module -ListAvailable -FullyQualifiedName $module -Verbose:$false   
                        $moduleSpecifcation += $moduleInfo 
                    }
                }
            }
        }
    }
}

if ($Package)
{
    #Create a temp folder
    $null = mkdir "${env:temp}\modules" -Force -Verbose:$false

    #Copy all module folders to a temp folder
    foreach ($module in $moduleSpecifcation)
    {
        $null = mkdir "${env:temp}\modules\$($module.Name)"
        Copy-Item -Path $module.ModuleBase -Destination "${env:temp}\modules\$($module.Name)" -Container -Recurse -Verbose:$false
    }

    #Create an archive with all needed modules
    Compress-Archive -Path "${env:temp}\modules" -DestinationPath $PackagePath -Force -Verbose:$false

    #Remove the folder
    Remove-Item -Path "${env:temp}\modules" -Recurse -Force -Verbose:$false
}
else
{
    return $moduleSpecifcation
}

function Get-DscModulesFromResourceName
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]] $ResourceNames
    )

    process
    {
        $moduleInfo = Get-DscResource -Name $ResourceNames -Verbose:$false | Select -Expand ModuleName -Unique
        $moduleHash = @()
        foreach ($module in $moduleInfo)
        {
            $moduleHash += @{
                 ModuleName = $module
                 ModuleVersion = (Get-RecentModuleVersion -ModuleName $module)
            }
        }

        return $moduleHash
    }
}

function Get-DscResourcesFromModule
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $ModuleName,

        [Parameter()]
        [Version] $ModuleVersion
    )

    process
    {
        $resourceInfo = Get-DscResource -Module $ModuleName -Verbose:$false
        if ($resourceInfo)
        {
            if ($ModuleVersion)
            {
                $resources = $resourceInfo.Where({$_.Module.Version -eq $ModuleVersion})
                return $resources.Name
            }
            else
            {
                #check if there are multiple versions of the modules; if so, return the most recent one
                $mostRecentVersion = Get-RecentModuleVersion -ModuleName $ModuleName
                Get-DscResourcesFromModule -ModuleName $ModuleName -ModuleVersion $mostRecentVersion
            }
        }
    }
}

function Get-RecentModuleVersion
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $ModuleName
    )

    process
    {
        $moduleInfo = Get-Module -ListAvailable -Name $ModuleName -Verbose:$false | Sort -Property Version
        if ($moduleInfo)
        {
            return ($moduleInfo[-1].Version).ToString()
        }
    }
}