# Windows 11 Compatibility Check

$ErrorActionPreference = "SilentlyContinue"

$cpu = Get-CimInstance Win32_Processor
$computerSystem = Get-CimInstance Win32_ComputerSystem
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$os = Get-CimInstance Win32_OperatingSystem

$ramGB = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
$diskGB = [math]::Round($disk.Size / 1GB, 2)

# TPM Check
$tpm = Get-Tpm
$tpmPresent = if ($null -ne $tpm) { $tpm.TpmPresent } else { $false }
$tpmReady = if ($null -ne $tpm) { $tpm.TpmReady } else { $false }
$tpmVersionOK = if ($null -ne $tpm.SpecVersion) { $tpm.SpecVersion -match "2.0" } else { $false }

# Secure Boot Check
try {
    $secureBootOK = Confirm-SecureBootUEFI
} catch {
    $secureBootOK = $false
}

# Checks
$cpuCoresOK = $cpu.NumberOfCores -ge 2
$cpuSpeedOK = $cpu.MaxClockSpeed -ge 1000
$ramOK = $ramGB -ge 4
$storageOK = $diskGB -ge 64
$isWindows11 = $os.Caption -like "*Windows 11*"

$hardwareReady = (
    $cpuCoresOK -and
    $cpuSpeedOK -and
    $ramOK -and
    $storageOK -and
    $tpmPresent -and
    $tpmReady -and
    $tpmVersionOK -and
    $secureBootOK
)

[PSCustomObject]@{
    ComputerName  = $env:COMPUTERNAME
    OS            = $os.Caption
    CPUCoresOK    = $cpuCoresOK
    CPUSpeedOK    = $cpuSpeedOK
    RAMGB         = $ramGB
    RAMOK         = $ramOK
    StorageGB     = $diskGB
    StorageOK     = $storageOK
    TPMPresent    = $tpmPresent
    TPMReady      = $tpmReady
    TPMVersionOK  = $tpmVersionOK
    SecureBootOK  = $secureBootOK
    IsWindows11   = $isWindows11
    HardwareReady = $hardwareReady
} | Format-List

Read-Host "Press Enter to exit"