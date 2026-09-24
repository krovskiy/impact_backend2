#Requires -Version 5.1
param([switch]$Run, [ValidateRange(1, 65535)][int]$Port = 8080)
$ErrorActionPreference = 'Stop'

Set-StrictMode -Version Latest

function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed (exit $LASTEXITCODE). Fix the error above and run setup again." }
}

function ConvertTo-GitHubUrl {
    param([string]$Value)
    $value = $Value.Trim()
    if ($value -cmatch '^https://github\.com/([^/]+)/([^/?#]+)/?$' -or
        $value -cmatch '^git@github\.com:([^/]+)/([^/?#]+)/?$') {
        $owner = $Matches[1]
        $repo = $Matches[2] -creplace '\.git$', ''
        if ($owner -cmatch '^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$' -and
            $repo -cmatch '^[A-Za-z0-9_.-]{1,100}$' -and $repo -notin @('.', '..')) {
            return "https://github.com/$owner/$repo.git"
        }
    }
    throw 'Paste the repository link: https://github.com/YOUR-NAME/YOUR-REPO (no /tree/main, spaces, tokens, or other websites).'
}

function Read-GitHubUrl {
    while ($true) {
        $answer = Read-Host 'Paste your GitHub repository link (or Q to quit)'
        if ($answer.Trim() -ieq 'q') { throw 'Setup cancelled.' }
        try { return ConvertTo-GitHubUrl $answer } catch { Write-Host $_.Exception.Message -ForegroundColor Yellow }
    }
}

function Test-GitTarget {
    param([string]$Url)
    # A ZIP download inside another Git repository must never stage the parent.
    # Windows PowerShell turns redirected native stderr into terminating errors.
    $savedPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $root = & git rev-parse --show-toplevel 2>$null
    $hasRepo = $LASTEXITCODE -eq 0
    $ErrorActionPreference = $savedPreference
    if ($hasRepo) {
        if ([IO.Path]::GetFullPath($root).TrimEnd('\', '/') -ine [IO.Path]::GetFullPath((Get-Location).Path).TrimEnd('\', '/')) {
            throw 'This folder is inside another Git repository. Move the extracted project to its own folder and retry.'
        }
        $branch = & git symbolic-ref --quiet --short HEAD
        if ($LASTEXITCODE -ne 0) { throw 'Detached HEAD: switch to your project branch before setup.' }
        foreach ($state in @('MERGE_HEAD', 'CHERRY_PICK_HEAD', 'REVERT_HEAD', 'rebase-merge', 'rebase-apply', 'BISECT_LOG')) {
            $statePath = & git rev-parse --git-path $state
            if (Test-Path -LiteralPath $statePath) { throw 'Finish or abort the in-progress Git operation before setup.' }
        }
        & git show-ref --verify --quiet refs/heads/main
        if ($LASTEXITCODE -eq 0 -and $branch -ne 'main') {
            throw 'A different main branch already exists. Switch to main with your changes, then rerun setup.'
        }
    }
    $refs = @(& git ls-remote --heads --tags -- $Url)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read the repository. Check your internet connection and GitHub sign-in.' }
    $mainRef = @($refs | Where-Object { $_ -match '\srefs/heads/main$' })
    if (@($refs).Count -gt 0 -and $mainRef.Count -eq 0) {
        throw 'The destination already has history but no main branch. Use a new empty repository, or prepare its main branch yourself.'
    }
    if ($mainRef.Count -gt 0) {
        if (-not $hasRepo) { throw 'This ZIP has no Git history. Choose a new EMPTY GitHub repository (no README, license, or .gitignore).' }
        & git rev-parse --verify --quiet HEAD | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Choose an empty GitHub repository for this uncommitted project.' }
        Invoke-Checked git @('fetch', '--no-tags', '--', $Url, 'refs/heads/main')
        & git merge-base --is-ancestor FETCH_HEAD HEAD
        if ($LASTEXITCODE -ne 0) {
            throw 'Remote main has commits missing locally or unrelated history. Use an empty repository, or reconcile the history before rerunning. Nothing was overwritten.'
        }
    }
    if ($hasRepo) {
        & git rev-parse --verify --quiet HEAD | Out-Null
        if ($LASTEXITCODE -eq 0) {
            # Check the push destination and credentials without publishing anything.
            Invoke-Checked git @('-c', 'push.followTags=false', 'push', '--dry-run', $Url, 'HEAD:refs/heads/main')
        }
    }
    Write-Host "Verified repository: $Url" -ForegroundColor Green
}

function Publish-Project {
    param([string]$Url, [string]$AuthorName, [string]$AuthorEmail)
    Test-GitTarget $Url
    if (-not (Test-Path -LiteralPath '.git')) { Invoke-Checked git @('init', '-b', 'main') }
    $branch = & git symbolic-ref --quiet --short HEAD
    if ($branch -ne 'main') { Invoke-Checked git @('branch', '-m', 'main') }
    $name = & git config --get user.name
    if ([string]::IsNullOrWhiteSpace($name)) { Invoke-Checked git @('config', '--local', 'user.name', $AuthorName) }
    $email = & git config --get user.email
    if ([string]::IsNullOrWhiteSpace($email)) { Invoke-Checked git @('config', '--local', 'user.email', $AuthorEmail) }
    # Replace the teacher's origin; do not keep it as another remote.
    if (@(& git remote) -contains 'origin') {
        Invoke-Checked git @('remote', 'remove', 'origin')
    }
    Invoke-Checked git @('remote', 'add', 'origin', $Url)
    $effective = @(& git remote get-url --push --all origin)
    if ($effective.Count -ne 1 -or $effective[0] -cne $Url) {
        throw 'Git configuration rewrites the destination URL. Correct your Git URL settings before pushing.'
    }
    Invoke-Checked git @('add', '--all', '--', '.')
    & git diff --cached --quiet
    $diffResult = $LASTEXITCODE
    if ($diffResult -eq 1) { Invoke-Checked git @('commit', '-m', 'chore: set up Java 21 project') }
    elseif ($diffResult -ne 0) { throw 'Could not inspect staged changes.' }
    # No force push, merge, reset, or deletion. A remote race is rejected by Git.
    Invoke-Checked git @('-c', 'push.followTags=false', 'push', '--set-upstream', 'origin', 'main:refs/heads/main')
}

function Get-ToolchainRoot {
    return Join-Path $env:LOCALAPPDATA 'impact-backend\toolchains'
}

function Enable-Toolchain {
    $root = Get-ToolchainRoot
    $env:JAVA_HOME = Join-Path $root 'jdk-21'
    $env:MAVEN_HOME = Join-Path $root 'apache-maven-3.9.16'
    if (-not (Test-Path -LiteralPath "$env:JAVA_HOME\bin\javac.exe") -or
        -not (Test-Path -LiteralPath "$env:MAVEN_HOME\bin\mvn.cmd")) {
        throw 'Java/Maven setup is incomplete. Run setup.cmd first.'
    }
    $env:Path = "$env:JAVA_HOME\bin;$env:MAVEN_HOME\bin;$env:Path"
}

function Save-ToolchainEnvironment {
    foreach ($key in @('JAVA_HOME', 'MAVEN_HOME')) {
        [Environment]::SetEnvironmentVariable($key, [Environment]::GetEnvironmentVariable($key), 'User')
    }
    $bins = @("$env:JAVA_HOME\bin", "$env:MAVEN_HOME\bin")
    $oldPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($oldPath -split ';' | Where-Object { $_ -and $_ -notin $bins })
    [Environment]::SetEnvironmentVariable('Path', (($bins + $entries) -join ';'), 'User')
}

function Receive-File {
    param([string]$Url, [string]$Destination)
    if (-not $Url.StartsWith('https://')) { throw 'Download URL must use HTTPS.' }
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Destination -TimeoutSec 300
            return
        } catch {
            if ($attempt -eq 3) { throw }
            Start-Sleep -Seconds 2
        }
    }
}

function Install-Toolchains {
    $root = Get-ToolchainRoot
    New-Item -ItemType Directory -Force -Path $root | Out-Null
    $nativeArch = $env:PROCESSOR_ARCHITEW6432
    if (-not $nativeArch) { $nativeArch = $env:PROCESSOR_ARCHITECTURE }
    switch ($nativeArch) {
        'AMD64' { $arch = 'x64' }
        'ARM64' { $arch = 'aarch64' }
        default { throw 'A 64-bit Windows computer (Intel/AMD or ARM64) is required.' }
    }
    $javaDir = Join-Path $root 'jdk-21'
    if (-not (Test-Path -LiteralPath "$javaDir\bin\javac.exe")) {
        if (Test-Path -LiteralPath $javaDir) { throw "Incomplete installation at $javaDir. Rename that folder and rerun setup." }
        Write-Host 'Downloading and verifying Java 21 JDK...'
        $metadata = Join-Path $script:DownloadDir 'java.json'
        Receive-File "https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=$arch&image_type=jdk&os=windows&vendor=eclipse" $metadata
        $assets = @(Get-Content -Raw -LiteralPath $metadata | ConvertFrom-Json)
        if ($assets.Count -eq 0) { throw "No Java 21 download is available for $arch." }
        $package = $assets[0].binary.package
        $zip = Join-Path $script:DownloadDir 'java.zip'
        Receive-File $package.link $zip
        if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ine $package.checksum) { throw 'Java checksum mismatch. Run setup again to download a fresh copy.' }
        $extract = Join-Path $script:DownloadDir 'java'
        Expand-Archive -LiteralPath $zip -DestinationPath $extract
        $folders = @(Get-ChildItem -LiteralPath $extract -Directory)
        if ($folders.Count -ne 1 -or -not (Test-Path -LiteralPath "$($folders[0].FullName)\bin\javac.exe")) { throw 'Java archive is incomplete.' }
        Move-Item -LiteralPath $folders[0].FullName -Destination $javaDir
    }
    $version = '3.9.16'
    $mavenDir = Join-Path $root "apache-maven-$version"
    if (-not (Test-Path -LiteralPath "$mavenDir\bin\mvn.cmd")) {
        if (Test-Path -LiteralPath $mavenDir) { throw "Incomplete installation at $mavenDir. Rename that folder and rerun setup." }
        Write-Host 'Downloading and verifying Maven...'
        $url = "https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/$version/apache-maven-$version-bin.zip"
        $zip = Join-Path $script:DownloadDir 'maven.zip'
        $checksum = Join-Path $script:DownloadDir 'maven.sha512'
        Receive-File $url $zip
        Receive-File "$url.sha512" $checksum
        $expected = ((Get-Content -Raw -LiteralPath $checksum).Trim() -split '\s+')[0]
        if ($expected -notmatch '^[0-9a-fA-F]{128}$' -or (Get-FileHash -LiteralPath $zip -Algorithm SHA512).Hash -ine $expected) { throw 'Maven checksum mismatch. Run setup again.' }
        $extract = Join-Path $script:DownloadDir 'maven'
        Expand-Archive -LiteralPath $zip -DestinationPath $extract
        $source = Join-Path $extract "apache-maven-$version"
        if (-not (Test-Path -LiteralPath "$source\bin\mvn.cmd")) { throw 'Maven archive is incomplete.' }
        Move-Item -LiteralPath $source -Destination $mavenDir
    }
    Enable-Toolchain
    Invoke-Checked "$env:JAVA_HOME\bin\javac.exe" @('-version')
    Invoke-Checked "$env:MAVEN_HOME\bin\mvn.cmd" @('--version')
    Save-ToolchainEnvironment
}

function Install-WindowsCommand {
    param([string]$Command, [string]$Package)
    if (Get-Command $Command -ErrorAction SilentlyContinue) { return }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'Windows App Installer is missing. Install/update "App Installer" from Microsoft Store, reopen setup.cmd, and retry.'
    }
    Invoke-Checked winget @('install', '--id', $Package, '--exact', '--source', 'winget', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + $env:Path
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "$Package was installed but is not available yet. Close this window and run setup.cmd again."
    }
}

# Dot-sourcing exposes helpers for offline tests without running setup.
if ($MyInvocation.InvocationName -eq '.') { return }

if ($Run) {
    try {
        Enable-Toolchain
        $project = Split-Path -Parent $PSScriptRoot
        Write-Host "Once Spring reports Started, open http://localhost:$Port/api/practice"
        Write-Host 'Keep this window open. Press Ctrl+C to stop.'
        Invoke-Checked "$env:MAVEN_HOME\bin\mvn.cmd" @('-f', "$project\pom.xml", 'spring-boot:run', "-Dspring-boot.run.arguments=--server.port=$Port")
        exit 0
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host 'If the port is busy, run: .\setup.cmd run 8081'
        exit 1
    }
}

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$script:DownloadDir = $null
Push-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
try {
    Write-Host 'SETUP: Java 21, Maven, Git, build, commit and push to main.' -ForegroundColor Cyan
    Write-Host 'First create your own EMPTY repository at https://github.com/new (leave README, license and .gitignore unchecked).'
    Write-Host 'Setup will publish this folder and its existing Git history to the link you enter.'
    $url = Read-GitHubUrl
    Install-WindowsCommand git 'Git.Git'
    Test-GitTarget $url
    $script:DownloadDir = Join-Path ([IO.Path]::GetTempPath()) ("impact-setup-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $script:DownloadDir | Out-Null
    Install-Toolchains
    Write-Host 'Building the project and running its tests. The first run downloads dependencies...'
    Invoke-Checked "$env:MAVEN_HOME\bin\mvn.cmd" @('--batch-mode', '--no-transfer-progress', 'clean', 'verify')
    $owner = ($url.Substring('https://github.com/'.Length) -split '/')[0]
    Publish-Project $url $owner "$owner@users.noreply.github.com"
    Write-Host "SUCCESS: uploaded to $url on main." -ForegroundColor Green
    Write-Host 'Next: run .\setup.cmd run, then open http://localhost:8080/api/practice'
} catch {
    Write-Host "SETUP STOPPED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Fix the message above and rerun setup.cmd. Setup never force-pushes.'
    exit 1
} finally {
    if ($script:DownloadDir -and (Test-Path -LiteralPath $script:DownloadDir)) {
        $resolved = [IO.Path]::GetFullPath($script:DownloadDir)
        $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        if ($resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and
            [IO.Path]::GetFileName($resolved) -match '^impact-setup-[a-f0-9]{32}$') {
            Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Pop-Location
}
