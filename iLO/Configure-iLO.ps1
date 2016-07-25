#Requires -Version 3.0


function Configure-iLO {
	
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
	
	Install-iLOCertificate -Hostname $Hostname -UserName $UserName -UserPassword $UserPassword

} # end PROCESS block

END {

} # End END block

}


