#Requires -Version 3.0


function Initialize-iLOConfiguration {
<#
.SYNOPSIS

	Shortcut to apply multiple settings on one or more iLO(s).  
	
.PARAMETER HostName

    The iLO(s) where we should apply configuration settings.  
	Multiple iLO's may be specified and they will be processed in the order received.
	This is a mandatory parameter with no default.

.PARAMETER UserName

    A user name with administrative access to the iLO(s) we are configuring.  
	Only a single UserName may be specified, meaning this user must have access to all iLO's if multiple are specified.
	This is a mandatory parameter with no default.

.PARAMETER UserPassword

    The password for the user specified in the UserName parameter.  This is a mandatory parameter with no default.


.EXAMPLE
	
	Initialize-iLOConfiguration -Hostname iLO1 -UserName iLOAdmin -UserPassword iLOPassword

	Configure settings on iLO1 given UserName and UserPassword

.EXAMPLE
	
	"iLO1", "iLO2" | Initialize-iLOConfiguration -UserName iLOAdmin -UserPassword iLOPassword -Verbose

	Uses piped input from command line to configure settings on named devices.

.EXAMPLE
	
	Find-HPiLO -Range "192.168.1.1", "192.168.3.1" | Initialize-iLOConfiguration -UserName iLOAdmin -UserPassword iLOPassword -Verbose
	
	Uses piped input from Find-HPiLO command to configure settings on discovered devices.
	
.INPUTS

	Accepts iLO(s), Administrative Username, and Associated Password from the PipeLine.

.OUTPUTS

	NONE

.NOTES

	Currently we run these command in the following order:
		Set-iLOAuthentication
		Install-iLOCertificate

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

} # end BEGIN block

PROCESS {
	
	Set-iLOAuthentication -Hostname $Hostname -UserName $UserName -UserPassword $UserPassword

	Install-iLOCertificate -Hostname $Hostname -UserName $UserName -UserPassword $UserPassword

} # end PROCESS block

END {

} # End END block

}


