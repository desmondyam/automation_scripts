# Windows 11 Compatibility Check
# Basic hardware readiness audit

$ErrorActionPreference = "Continue"

$cpu = Get-CimInstance Win32_Processor
$computerSystem = Get-CimInstance Win32_ComputerSystem
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$os = Get-CimInstance Win32_OperatingSystem
$computerInfo = Get-ComputerInfo

$ramGB = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
$diskGB = [math]::Round($disk.Size / 1GB, 2)

# CPU Checks
$cpuCoresOK = $cpu.NumberOfCores -ge 2
$cpuSpeedOK = $cpu.MaxClockSpeed -ge 1000
$architectureOK = [Environment]::Is64BitOperatingSystem

# RAM and Storage Checks
$ramOK = $ramGB -ge 4
$storageOK = $diskGB -ge 64

# UEFI Check
$uefiOK = $computerInfo.BiosFirmwareType -eq "Uefi"

# Secure Boot Check
try {
    $secureBootOK = Confirm-SecureBootUEFI
}
catch {
    $secureBootOK = $false
}

# TPM Check
try {
    $tpm = Get-Tpm
    $tpmPresent = $tpm.TpmPresent
    $tpmReady = $tpm.TpmReady
    $tpmVersionOK = $tpm.SpecVersion -match "2.0"
}
catch {
    $tpmPresent = $false
    $tpmReady = $false
    $tpmVersionOK = $false
}

# Internet Check
try {
    $internetOK = Test-Connection -ComputerName "www.microsoft.com" -Count 1 -Quiet
}
catch {
    $internetOK = $false
}

# OS Check
$isWindows11 = $os.Caption -like "*Windows 11*"

# Final Basic Readiness Check
$basicHardwareCheck = (
    $cpuCoresOK -and
    $cpuSpeedOK -and
    $architectureOK -and
    $ramOK -and
    $storageOK -and
    $uefiOK -and
    $secureBootOK -and
    $tpmPresent -and
    $tpmReady -and
    $tpmVersionOK
)

# Output
[PSCustomObject]@{
    ComputerName       = $env:COMPUTERNAME
    OS                 = $os.Caption
    Processor          = $cpu.Name
    CPUCores           = $cpu.NumberOfCores
    CPUCoresOK         = $cpuCoresOK
    CPUSpeedMHz        = $cpu.MaxClockSpeed
    CPUSpeedOK         = $cpuSpeedOK
    ArchitectureOK     = $architectureOK
    RAMGB              = $ramGB
    RAMOK              = $ramOK
    StorageGB          = $diskGB
    StorageOK          = $storageOK
    BootMode           = $computerInfo.BiosFirmwareType
    UEFIOK             = $uefiOK
    SecureBootOK       = $secureBootOK
    TPMPresent         = $tpmPresent
    TPMReady           = $tpmReady
    TPMVersionOK       = $tpmVersionOK
    InternetOK         = $internetOK
    IsWindows11        = $isWindows11
    BasicHardwareCheck = $basicHardwareCheck
    Note               = "This validates core hardware requirements but does not fully validate Microsoft CPU support list, DirectX, WDDM, display size, or Microsoft account setup requirements."
} | Format-List

Read-Host "Press Enter to exit"