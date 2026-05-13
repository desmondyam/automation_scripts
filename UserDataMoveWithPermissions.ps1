$targetFolders = "Desktop","Documents","Downloads","Pictures"
$destinationRoot = "C:\MovedFiles"

$totalMoved = 0
$totalSkipped = 0

if (!(Test-Path -LiteralPath $destinationRoot)) {
    New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
}

Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue |
Where-Object { $_.Name -ne "Public" } |
ForEach-Object {    $userProfile = $_
    $user = $userProfile.Name

    foreach ($folder in $targetFolders) {
        $sourcePath = Join-Path $userProfile.FullName $folder

        try {
            if (Test-Path -LiteralPath $sourcePath -ErrorAction Stop) {
                $files = Get-ChildItem -LiteralPath $sourcePath -Recurse -File -ErrorAction SilentlyContinue |
                         Where-Object { $_.Name -ne "Microsoft Edge.lnk" }

                foreach ($file in $files) {
                    try {
                        $relativePath = $file.FullName.Substring($sourcePath.Length).TrimStart("\")
                        $destPath = Join-Path $destinationRoot "$user\$folder"
                        $finalDestPath = Join-Path $destPath $relativePath
                        $finalDestFolder = Split-Path $finalDestPath -Parent

                        if (!(Test-Path -LiteralPath $finalDestFolder)) {
                            New-Item -ItemType Directory -Path $finalDestFolder -Force | Out-Null
                        }

                        Move-Item -LiteralPath $file.FullName -Destination $finalDestPath -Force -ErrorAction Stop

                        takeown /f "$finalDestPath" /a | Out-Null
                        icacls "$finalDestPath" /inheritance:e | Out-Null
                        icacls "$finalDestPath" /grant "Administrators:F" /c | Out-Null
                        icacls "$finalDestPath" /grant "Users:F" /c | Out-Null

                        Write-Host "Moved: $($file.FullName)"
                        $totalMoved++
                    }
                    catch {
                        Write-Host "Skipped: $($file.FullName)"
                        $totalSkipped++
                        continue
                    }
                }
            }
        }
        catch {
            Write-Host ""
            Write-Host "$user - $folder"
            Write-Host "Access denied or unavailable"
            continue
        }
    }
}

Write-Host ""
Write-Host "Applying permissions to destination folder..."
takeown /f "$destinationRoot" /r /d y | Out-Null
icacls "$destinationRoot" /inheritance:e /t /c | Out-Null
icacls "$destinationRoot" /grant "Administrators:F" /t /c | Out-Null
icacls "$destinationRoot" /grant "Users:F" /t /c | Out-Null

Write-Host ""
Write-Host "Move completed."
Write-Host "Total files moved: $totalMoved"
Write-Host "Total files skipped: $totalSkipped"
Write-Host "Files moved to: $destinationRoot"
Write-Host ""

Start-Process explorer.exe $destinationRoot

Read-Host "Press Enter to exit"