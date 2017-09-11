[CmdletBinding()]
param (

)

$dscProviders = Get-CimInstance -ClassName Msft_Providers -Filter "Namespace='root\\Microsoft\\Windows\\DesiredStateConfiguration'"
foreach ($provider in $dscProviders)
{
    $provider | Select Provider, Namespace, @{l='PID';E={$_.HostProcessIdentifier}}, @{l='ProcessName';E={(Get-Process -Id $_.HostProcessIdentifier).ProcessName}}
}
