﻿<#
.SYNOPSIS
	Sets the working directory to the logs folder
.DESCRIPTION
	This PowerShell script changes the current working directory to the logs directory.
.EXAMPLE
	PS> ./cd-logs
	📂/var/logs
.LINK
	https://github.com/fleschutz/PowerShell
.NOTES
	Author: Markus Fleschutz | License: CC0
#>

function GetLogsDir {
	if ($IsLinux) { return "/var/logs" }
	$WinDir = [System.Environment]::GetFolderPath('Windows')
	return "$WinDir\Logs"
}

try {
	$path = GetLogsDir
	Set-Location "$path"
	"📂$path"
	exit 0 # success
} catch {
	"⚠️ Error: $($Error[0])"
	exit 1
}
