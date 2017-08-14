# PSDSCUtils
Miscellaneous utility scripts for PowerShell DSC

## Get-DSCResourceModuleFromConfiguration ##
This script reads the configuration script (.ps1) and then emits the custom resource modules being imported in the configuration script using the *Import-DscResource* dynamic keyword.

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

## Get-DscResourceMetaData ##
This script reads the resource property information from the Get-DscResource cmdlet and packages it into a property bag.

### Exmaple 1 - Get property bag of a single resource in a module ###
```powershell
.\Get-DscResourceMetaData.ps1 -Name Service -Module PSDscResources
```

### Example 2 - Get property bag of all resources in a module ###
The following example packages the custom resource modules as a zip package.

```powershell
.\Get-DscResourceMetaData.ps1 -Module PSDscResources
```

## Get-DscResourceProperty ##
This script reads the dyamic keywords exported by the resource modules to provide a better resource property object.

### Exmaple 1 - Get property information of a single resource ###
```powershell
.\Get-DscResourceProperty.ps1 -Name Service
```

