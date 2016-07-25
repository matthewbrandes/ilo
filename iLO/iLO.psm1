#mklink /j "C:\Users\brandemr\Documents\WindowsPowerShell\Modules\iLO" "C:\Users\brandemr\Documents\Visual Studio 2015\Projects\iLO\iLO\"
#to remove rename dest folder then delete 
#source stays 


#region Include required files
#
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
try {
    . ("$ScriptDirectory\SupportFunctions.ps1")

}
catch {
    Write-Host -ForegroundColor Red "Error while loading supporting PowerShell Scripts" 
	break
}
#endregion

#region Validate/Load Required Modules
if ((Validate-Module -moduleName HPiLOCmdlets -requiredVersion '1.3.0') -eq $true){

		Write-Verbose "Importing PSPKI Module"
		Import-Module -Name HPiLOCmdlets -Global

		}
	else {

		Write-Host -ForegroundColor Red "You Must Load The HP iLO Cmdlets For This Script To Work"
		Write-Host -ForegroundColor Red "The Minimum Version is 1.3.0"

		break

	}

if ((Validate-Module -moduleName PSPKI -requiredVersion '3.2.5') -eq $true ){

	Write-Verbose "Importing PSPKI Module"
	Import-Module -Name PSPKI -Global

	}
else {

	Write-Host -ForegroundColor Red "You Must Load The Public Key Infrastructure PowerShell Module For This Script To Work"
	Write-Host -ForegroundColor Red "The Minimum Version is 3.2.5"

	break

}

#endregion

Get-ChildItem $PSScriptRoot -Include *.ps1 -Exclude *.tests.* -Recurse | Foreach-Object{ . $_.FullName }
