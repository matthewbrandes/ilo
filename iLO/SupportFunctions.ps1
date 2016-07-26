
function Validate-Module {
	[cmdletbinding(PositionalBinding = $true)]
	Param([Parameter(Position = 0,
	ValueFromPipelineByPropertyName = $true)]
	[String[]]$moduleName,
	[Parameter(Position = 0,
	ValueFromPipelineByPropertyName = $true)]
	[version]$requiredVersion
	)

	$moduleOk = $false
	$versionOk = $false

	Write-Verbose "Checking Module Availability"

	if (Get-Module -ListAvailable -Name $moduleName) {

		Write-Verbose "$moduleName Is Available"
		$moduleOk = $true

		Write-Verbose "Module Available Checking Module Version"	
		$moduleVersion = [version](Get-Module -Name $moduleName -ListAvailable).Version
	
		Write-Verbose "Module Version Is $moduleVersion"
 
		if($moduleVersion -ge $requiredVersion) {
			write-verbose "$moduleName Module Version Passed"
			$versionOk = $true
			}
		}

		$versionOk
	}


function Get-iLOGeneration{
	Param([Parameter(Position = 0,
	ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
	[string]$iLO)

    $PN = (Find-HPiLO -Range ([System.Net.Dns]::GetHostAddresses($iLO).IPAddressToString) -WarningAction SilentlyContinue).PN

    switch ($PN) {
	  { $_ -like "*(iLO 2)*" } { "2" }
	  { $_ -like "*(iLO 3)*" } { "3" }
	  { $_ -like "*(iLO 4)*" } { "4" }
	  default {0}
		}

}