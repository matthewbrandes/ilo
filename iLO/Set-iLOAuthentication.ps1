#Requires -Version 3.0


function Set-iLOAuthentication {
<#
.SYNOPSIS

	Configures authentication settings on one or more iLO(s).  
	
.PARAMETER HostName

    The iLO(s) where we should configure authentication.  
	Multiple iLO's may be specified and they will be processed in the order received.
	This is a mandatory parameter with no default.

.PARAMETER UserName

    A user name with administrative access to the iLO(s) where we are configuring authentication.  
	Only a single UserName may be specified, meaning this user must have access to all iLO's if multiple are specified.
	This is a mandatory parameter with no default.

.PARAMETER UserPassword

    The password for the user specified in the UserName parameter.  This is a mandatory parameter with no default.


.EXAMPLE
	
	Set-iLOAuthentication -Hostname iLO1 -UserName iLOAdmin -UserPassword iLOPassword

	Configure authentication methods on iLO1 given UserName and UserPassword

.EXAMPLE
	
	"iLO1", "iLO2" | Set-iLOAuthentication -UserName iLOAdmin -UserPassword iLOPassword -Verbose

	Uses piped input from command line to configure authentication methods on named devices.

.EXAMPLE
	
	Find-HPiLO -Range "192.168.1.1", "192.168.3.1" | Set-iLOAuthentication -UserName iLOAdmin -UserPassword iLOPassword -Verbose
	
	Uses piped input from Find-HPiLO command to configure authentication methods on discovered devices.
	
.INPUTS

	Accepts iLO(s), Administrative Username, and Associated Password from the PipeLine.

.OUTPUTS
	NONE

.NOTES
	Only supported on the iLO3 or higher.
#>
	
	[CmdletBinding(PositionalBinding = $false)]
param (
	[Parameter(ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('Computer', 'iLO')]
		[string[]]$Hostname,
	
	[Parameter(ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('AdminUser')]
		[string]$UserName,

	[Parameter(ValueFromPipeline = $true,
		ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('AdminPassword')]
		[string]$UserPassword

	)
BEGIN {

	#Disable iLO Checking For Valid Certificates
	Disable-HPiLOCertificateAuthentication

} # end BEGIN block

PROCESS {
	

	#Loop Through All Hosts Passed In
	foreach ($h in $Hostname) {

		try {

				Write-Verbose "Configure-iLO Is Processing $h"

				Write-Verbose "Checking iLO Generation"

				if((Get-iLOGeneration -ilo $h) -lt 3){throw "iLO Generation Must Be 3 Or Greater"}

				$displayMessage = $false

				Write-Verbose "Getting Directory Information"
				$dinfo = Get-HPiLODirectory -Server $h -Username $username -Password $UserPassword

				If($dinfo.DIR_GRPACCT3_NAME -ne $null){

					Write-Verbose "Setting Schemaless Directory Group 3 Information "
					Set-HPiLOSchemalessDirectory -Server $h -Username $username -Password $UserPassword -Group3Name "DeleteMe3" -Group3Priv "" -Group3SID ""
					
					$displayMessage = $true

				}

				If($dinfo.DIR_GRPACCT4_NAME -ne $null){

					Write-Verbose "Setting Schemaless Directory Group 4 Information "
					Set-HPiLOSchemalessDirectory -Server $h -Username $username -Password $UserPassword -Group4Name "DeleteMe4" -Group4Priv "" -Group4SID ""

					$displayMessage = $true
					
				}

				if($displayMessage){Write-Host "Please Remove Entries Marked 'DeleteMe' on iLO $h Under Administration-->User Administration-->Directory Groups"}

				Write-Verbose "Setting Directory User Context 1 Information"
				Set-HPiLODirectory -Server $h -Username $username -Password $UserPassword -ServerAddress 10.100.24.13 -ServerPort 636 -UserContext1 "OU=Users,OU=OSCA,DC=courts,DC=state,DC=mo,DC=us" -LDAPDirectoryAuthentication Use_Directory_Default_Schema

				Write-Verbose "Setting Schemaless Directory Group 2 Information "
				Set-HPiLOSchemalessDirectory -Server $h -Username $username -Password $UserPassword -Group2Name "CN=OSCITSERVERADMIN,OU=Users,OU=OSCA,DC=courts,DC=state,DC=mo,DC=us" -Group2Priv "1,2,3,4,5" -Group2SID ""




			
				} #End Try

		Catch {

			Write-Warning "[$h] $_"

		} # End Catch

	} # End Foreach ($h in $Hostname)

} # end PROCESS block

END {

} # End END block

}


