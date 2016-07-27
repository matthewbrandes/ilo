#Requires -Version 3.0

function Install-iLOCertificate {
<#
.SYNOPSIS

	Generates a CSR request on an iLO, then submits the request to a CA server for signing.  
	Currently the CA is hardcoded to ctscs0001.courts.state.mo.us using the template WebServer.

.PARAMETER HostName

    The iLO(s) where we should install the SSL certificate.  
	Multiple iLO's may be specified and they will be processed in the order received.
	This is a mandatory parameter with no default.

.PARAMETER UserName

    A user name with administrative access to the iLO(s) where we are installing the SSL certificate.  
	Only a single UserName may be specified, meaning this user must have access to all iLO's if multiple are specified.
	This is a mandatory parameter with no default.

.PARAMETER UserPassword

    The password for the user specified in the UserName parameter.  This is a mandatory parameter with no default.


.EXAMPLE
	
	Install-iLOCertificate -Hostname iLO1 -UserName iLOAdmin -UserPassword iLOPassword

	Install certificate on iLO1 given UserName and UserPassword

.EXAMPLE
	
	"iLO1", "iLO2" | Install-iLOCertificate -UserName iLOAdmin -UserPassword iLOPassword -Verbose

	Uses piped input from command line to install certificates on named devices.

.EXAMPLE
	
	Find-HPiLO -Range "192.168.1.1", "192.168.3.1" | Install-iLOCertificate -UserName iLOAdmin -UserPassword iLOPassword -Verbose
	
	Uses piped input from Find-HPiLO command to install certificates on discovered devices.
	
.INPUTS

	Accepts iLO(s), Administrative Username, and Associated Password from the PipeLine.

.OUTPUTS

	NONE

.NOTES

	Only supported on the iLO3 or higher.

	Because installing a new certificate requires the iLO to restart its web server, there can be some delay before it is able to process the next command.
#>

[CmdletBinding(PositionalBinding = $true)]
param (
	[Parameter(Position = 0,
		ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('Hostname', 'iLO')]
		[string[]]$IP,
	
	[Parameter(Position = 1,
		ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('AdminUser')]
		[string]$UserName,

	[Parameter(Position = 2,
		ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('AdminPassword')]
		[string]$UserPassword

	)
BEGIN {

	#Disable iLO Checking For Valid Certificates
	Disable-HPiLOCertificateAuthentication

	Write-Verbose "Creating Temporary File For CSR"
	$CSRTempFile = [System.IO.Path]::GetTempFileName()
	Write-Verbose "CSR Temporary File Is $CSRTempFile"

} # end BEGIN block

PROCESS {

	#Loop Through All Hosts Passed In
	foreach ($h in $IP) {

		try {

			Write-Verbose "Processing $h"

			Write-Verbose "Checking iLO Generation"

			if((Get-iLOGeneration -ilo $h) -lt 3){throw "iLO Generation Must Be 3 Or Greater"}

			Write-Verbose "Getting Hostname and Domain Name For Certificate Request"
			$netinfo = Get-HPiLONetworkSetting -Server $h -Username $UserName -Password $UserPassword
			$iLOHostName = $netinfo.DNS_Name
			$iLODomainName = $netinfo.Domain_Name
			$iLOFQDN = "$iLOHostName.$iLODomainName"
			$iLOIP = $netinfo.IP

			#we should check validity of domain name here

			Write-Verbose "Telling iLO To Generate CSR"
			$cer = Get-HPILOCertificateSigningRequest -Server $h -Username $UserName -Password $UserPassword -Country "US" -State "Missouri" -Locality "Jefferson City" -Organization "Office of State Courts Administrator" -OrganizationalUnit "Information Technology" -CommonName $iLOFQDN

			Write-Verbose "Asking iLO If CSR Generation Is Complete"
			#If We Get An OK Response We Can Move On
			#Otherwise Wait And Check Again
			while($cer.STATUS_TYPE -ine "OK"){

				Write-Verbose "CSR Generation Incomplete - Waiting..."
				Start-Sleep -Seconds 10

				Write-Verbose "Asking iLO If CSR Generation Is Complete"
				#This Is Done By Using The Same Command As We Used To Ask For Generation Originally
				$cer = Get-HPILOCertificateSigningRequest -Server $h -Username $UserName -Password $UserPassword -Country "US" -State "Missouri" -Locality "Jefferson City" -Organization "Office of State Courts Administrator" -OrganizationalUnit "Information Technology" -CommonName $iLOFQDN 

			}

			Write-Verbose "CSR Successfully Generated"

			Write-Verbose "Writing CSR To Temporary File"
			Set-Content -Path $CSRTempFile -Value ($cer.CERTIFICATE_SIGNING_REQUEST).Split("`n") -Force

			Write-Verbose "Connecting To CA"
			$CA = Connect-CertificationAuthority -ComputerName ctscs0001.courts.state.mo.us

			Write-Verbose "Setting Additional Certificate Attributes"
			$attributes = "CertificateTemplate:WebServer", "SAN:dns=$iLOHostName&dns=$iLOFQDN&ipaddress=$iLOIP"
			Write-Verbose "Additional Certificate Attributes Are: $attributes"

			Write-Verbose "Submitting CSR With Attributes To CA"
			$CSRResult = Submit-CertificateRequest -Path $CSRTempFile -CertificationAuthority $CA -Attribute $attributes
			
			Write-Verbose "Putting Certificate Into Standard Format"
			$crt = "-----BEGIN CERTIFICATE-----`r`n"
			$crt = $crt + [System.Convert]::ToBase64String($CSRResult.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert), [System.Base64FormattingOptions]::InsertLineBreaks)
			$crt = $crt + "`r`n-----END CERTIFICATE-----`r`n"
			
			Write-Verbose "Contents Of Certificate Below"
			Write-Verbose "`r`n$crt"

			Write-Verbose "Loading Signed Certificate To iLO"
			Import-HPILOCertificate -Server $h -Username $Username -Password $UserPassword  -Certificate $crt


		} #End Try

		Catch {

			Write-Warning "[$h] $_"

		} # End Catch

	} # End Foreach ($h in $Hostname)

} # End PROCESS

END {

	Write-Verbose "Removing Temporary File For CSR"
	Remove-Item $CSRTempFile -Force

} # End END block
}
