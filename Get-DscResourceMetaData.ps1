[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $Name,

    [Parameter()]
    [String]
    $Module
)

if ($Name -or $Module)
{
    $resourceInfo = Get-DscResource @PSBoundParameters    
    foreach ($resource in $resourceInfo)
    {
        $resourceBag = [Ordered] @{}
        $resourcePropertyInfo = $resource.Properties
        $propertyBag = [ordered] @{}
        foreach ($property in $resourcePropertyInfo)
        {
            $propertyHash = [Ordered] @{
                'Type'        = $property.PropertyType
                'IsMandatory' = $property.IsMandatory
                'Values'      = $property.Values 
            }
            $propertyBag.Add($Property.Name, $propertyHash)
        }

        $resourceBag.Add($resource.Name, $propertyBag)
        $resourceBag
    }

}
else
{
    throw 'Must provide either Name or ModuleName or both'
}

