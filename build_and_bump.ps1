<#
.SYNOPSIS
Interactive script to manage Shorebird Releases and Patches.

.DESCRIPTION
This script asks you whether you want to deploy a Major Release (APK) or a Minor Patch (OTA).
If Release, it bumps the patch version in pubspec.yaml and builds `shorebird release android`.
If Patch, it simply deploys `shorebird patch android` directly to your users over the air.

.EXAMPLE
.\build_and_bump.ps1
#>

$pubspecPath = "pubspec.yaml"

if (-Not (Test-Path $pubspecPath)) {
    Write-Host "Error: pubspec.yaml not found in current directory." -ForegroundColor Red
    exit 1
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Shorebird Release and Patch Manager" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "What kind of update are you pushing to users?" -ForegroundColor Yellow
Write-Host "[1] Major Release (Bumps pubspec version, generates new APK)"
Write-Host "[2] Minor Patch   (Deploys fix instantly over-the-air, no version bump)"
Write-Host ""

$choice = Read-Host "Enter 1 or 2"

switch ($choice) {
    "2" {
        Write-Host ""
        Write-Host "Starting Shorebird OTA Patch deployment..." -ForegroundColor Magenta
        & "$env:USERPROFILE\.shorebird\bin\shorebird.bat" patch android --allow-asset-diffs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Success: Patch deployed successfully to all users on the current release!" -ForegroundColor Green
        }
        else {
            Write-Host "Error: Shorebird patch failed." -ForegroundColor Red
        }
        exit 0
    }
    
    "1" {
        $content = Get-Content $pubspecPath
        
        # Regex to find `version: X.Y.Z` or `version: X.Y.Z+B`
        $versionRegex = "^version:\s*(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?"
        
        $newContent = [System.Collections.Generic.List[string]]::new()
        $versionUpdated = $false
        $newVersionString = ""
        
        foreach ($line in $content) {
            if ($line -match $versionRegex) {
                $major = [int]$matches[1]
                $minor = [int]$matches[2]
                $patch = [int]$matches[3]
                
                if ($matches.Count -ge 5 -and $matches[4]) {
                    $buildNumber = [int]$matches[4]
                }
                else {
                    $buildNumber = 0
                }
        
                # Increment patch and build number
                $newPatch = $patch + 1
                $newBuildNumber = $buildNumber + 1
                
                $newVersionString = "version: $major.$minor.$newPatch+$newBuildNumber"
                $newContent.Add($newVersionString)
                $versionUpdated = $true
                Write-Host "Bumped pubspec version to $newVersionString" -ForegroundColor Green
            }
            else {
                $newContent.Add($line)
            }
        }
        
        if (-Not $versionUpdated) {
            Write-Host "Error: Could not find a valid version string in pubspec.yaml to bump." -ForegroundColor Red
            exit 1
        }
        
        # Write changes back to pubspec.yaml securely without BOM
        $absPubspecPath = "$PWD\$pubspecPath"
        [System.IO.File]::WriteAllLines($absPubspecPath, $newContent.ToArray(), (New-Object System.Text.UTF8Encoding $false))
        
        Write-Host ""
        Write-Host "Starting Shorebird Major Release build..." -ForegroundColor Magenta
        & "$env:USERPROFILE\.shorebird\bin\shorebird.bat" release android --artifact apk
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Success: Release finished successfully! The new version is $newVersionString." -ForegroundColor Green
            Write-Host "Please upload this APK to your GitHub Release page:" -ForegroundColor Yellow
            Write-Host " -> build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Yellow
        }
        else {
            Write-Host "Error: Shorebird release failed." -ForegroundColor Red
        }
    }
    
    default {
        Write-Host "Invalid choice. Exiting." -ForegroundColor Red
        exit 1
    }
}
