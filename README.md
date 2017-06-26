# PSDSCUtils
Miscellaneous utility scripts for PowerShell DSC

## Get-DSCResourceModuleFromConfiguration ##
This scripts reads the configuration script (.ps1) and then emits the custom resource modules being imported in the configuration script using the *Import-DscResource* dynamic keyword.

### Exmaple 1 - List Custom Modules ###
The following example emits a ModuleInfo object for all the custom DSC resource modules being imported in a configuration script.

```powershell
.\Get-DscResourceModulesFromConfiguration.ps1 -ConfigurationScript C:\Scripts\config.ps1
```

### Example 2 - Package Custom Modules ###
The following example packages the custom resource modules as a zip package.

```powershell
.\GetModules.ps1 -ConfigurationScript C:\PSConfEU\TipsTricksKnowHows\SampleConfig\VMDscDemo.ps1 -Package -PackagePath C:\Scripts\modules.zip 
```
