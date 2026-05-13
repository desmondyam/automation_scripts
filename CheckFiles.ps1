$targetFolders = "Desktop","Documents","Downloads","Pictures"

Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $profilePath = $_.FullName
    $user = $_.Name

    foreach ($folder in $targetFolders) {
        $path = Join-Path $profilePath $folder

        try {
            if (Test-Path -LiteralPath $path -ErrorAction Stop) {
                $files = Get-ChildItem -LiteralPath $path -Recurse -File -ErrorAction Stop |
                         Where-Object { $_.Name -ne "Microsoft Edge.lnk" }

                if ($files.Count -gt 0) {
                    Write-Host "`n$user - $folder"
                    $files.Name
                }
            }
        }
        catch {
            continue
        }
    }
}