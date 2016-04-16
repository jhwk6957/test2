# This script installs and configures Java JDKs on developer PCs.
#
# NOTE: This script must run with administrator permissions.

#Read-Host "All Java programs will close. Please SAVE ALL WORK and then press ENTER"
Get-Process -Name java* | Stop-Process -Force

# create temp directory if it doesn't already exist
New-Item -Path C:\Temp -ItemType Directory -Force | Out-Null

Start-Transcript "C:\Temp\jdksetup.log"

$installDir = "C:\Program Files\Java"
$preferredJdk = "jdk"

Write-Host "Running JDK installation..."

# use 32-bit installers, if necessary
Write-Host "Selecting architecture..."
$archString = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
if ($archString -eq "64-bit") {
	$arch = "x64"
} else {
	$arch = "x86"
}

# uninstall all JDKs currently installed on workstation
Write-Host "Uninstalling JDKs..."
$jdksToUninstall = @(Get-WmiObject Win32_Product | Where-Object { $_.Name -match "java" })
ForEach ($jdk in $jdksToUninstall) {
	Write-Host "  Uninstalling $($jdk.Name)..."
	Start-Process MsiExec.exe -ArgumentList "/x $($jdk.IdentifyingNumber) /qn" -Wait
}

# remove old symbolic links
#Write-Host "Removing old symbolic links..."
#$links = @(Get-ChildItem $installDir | Where {$_.Attributes -match "ReparsePoint"})
#ForEach ($link in $links) {
#	Write-Host "  Removing: $link"
#	cmd /c rmdir "$installDir\$link"
#}

# get list of JDKs to install
Write-Host "Populating list of JDKs to install..."
$jdksToInstall = Get-ChildItem "installers\$arch" | ForEach-Object { $_.Name -replace ".exe", "" }
#jdksToInstall = Get-ChildItem "C:\Users\josh\workspace\testProject\installers\$arch\jdk.exe" | ForEach-Object { $_.Name -replace ".exe", "" }

# install new version of JDK
Write-Host "Installing JDKs..."
ForEach ($jdk in $jdksToInstall) {
	$jre = $jdk -replace "jdk", "jre"
	Write-Host "  Installing JDK ($jdk) and JRE ($jre)"
	Start-Process installers\$arch\$jdk.exe -arg "/s ADDLOCAL=`"ToolsFeature,SourceFeature,PublicjreFeature`" INSTALLDIR=`"$installDir\$jdk`" /INSTALLDIRPUBJRE=`"$installDir\$jre`" /L C:\Temp\$jdk-install.log" -Wait

#	Write-Host "  Updating policy files and cacerts for JDK ($jdk) and JRE ($jre)"
#	Copy-Item "patches\$jdk\*" "$installDir\$jdk" -Force -Recurse
#	Copy-Item "patches\$jdk\jre\*" "$installDir\$jre" -Force -Recurse
}

# create symbolic link to preferred JDK
Write-Host "Creating symlink to $preferredJdk..."
cmd /c mklink /D "$installDir\jdk" "$installDir\$preferredJdk"

# test JAVA_HOME environment variable and fix if it's broken
# this is meant to support people who point to un-managed JDKs (such as IBM)
if (Test-Path "$env:JAVA_HOME\bin\java.exe") {
	Write-Host "Current JAVA_HOME is valid: $env:JAVA_HOME"
} else {
	Write-Host "Current JAVA_HOME is invalid: $env:JAVA_HOME"
	$javaHome="C:\Program Files\Java\jdk"
	Write-Host "  Setting JAVA_HOME to `"$javaHome`"..."
	[Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
}

Stop-Transcript
