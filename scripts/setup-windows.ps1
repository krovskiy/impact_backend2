#Requires -Version 5.1
param([switch]$Database, [switch]$CheckLesson2, [switch]$Run, [ValidateRange(1, 65535)][int]$Port = 8080)
$ErrorActionPreference = 'Stop'

Set-StrictMode -Version Latest

function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed (exit $LASTEXITCODE). Fix the error above and run setup again." }
}

function Sync-Origin {
    param([string]$Directory)
    if (-not (Test-Path -LiteralPath (Join-Path $Directory '.git'))) {
        Write-Host 'No Git history in this folder yet; skipping its origin update.'
        return
    }
    if (@(& git -C $Directory remote) -notcontains 'origin') {
        Write-Host 'No origin configured yet; skipping its update.'
        return
    }
    $branch = & git -C $Directory symbolic-ref --quiet --short HEAD
    if ($LASTEXITCODE -ne 0) { throw "Detached HEAD in $Directory. Switch to a branch before updating." }
    foreach ($state in @('MERGE_HEAD', 'CHERRY_PICK_HEAD', 'REVERT_HEAD', 'rebase-merge', 'rebase-apply', 'BISECT_LOG')) {
        $statePath = & git -C $Directory rev-parse --git-path $state
        if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect repository state.' }
        if (-not [IO.Path]::IsPathRooted($statePath)) { $statePath = Join-Path $Directory $statePath }
        if (Test-Path -LiteralPath $statePath) { throw "Finish or abort the Git operation in $Directory before updating." }
    }
    Write-Host "Updating $Directory from origin/$branch..."
    Invoke-Checked git @('-C', $Directory, 'fetch', 'origin')
    $remoteBranch = @(& git -C $Directory ls-remote --heads origin "refs/heads/$branch")
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect origin branches.' }
    if ($remoteBranch.Count -eq 0) {
        Write-Host "Origin has no $branch branch yet; nothing to pull."
        return
    }
    # Disable automatic stashes/rebases even when enabled in global Git config.
    Invoke-Checked git @('-C', $Directory, '-c', 'merge.autoStash=false', '-c', 'rebase.autoStash=false',
        'pull', '--ff-only', '--no-rebase', 'origin', $branch)
}

function Sync-Frontend {
    param([string]$ProjectRoot, [string]$RepositoryUrl = 'https://github.com/Victoras23/impact_2_year_fe.git')
    $directory = Join-Path $ProjectRoot 'frontend'
    if (-not (Test-Path -LiteralPath $directory)) {
        Invoke-Checked git @('clone', '--branch', 'main', '--', $RepositoryUrl, $directory)
    } else {
        if (-not (Test-Path -LiteralPath (Join-Path $directory '.git'))) {
            throw 'frontend already exists but is not a Git clone. Rename that folder and retry; your files were retained.'
        }
        $origin = & git -C $directory remote get-url origin
        if ($LASTEXITCODE -ne 0 -or $origin -cne $RepositoryUrl) {
            throw 'frontend has an unexpected origin. Move it aside or restore its expected origin before retrying.'
        }
        $branch = & git -C $directory symbolic-ref --quiet --short HEAD
        if ($LASTEXITCODE -ne 0 -or $branch -ne 'main') { throw 'Switch the frontend repository to main before updating.' }
    }
    Sync-Origin $directory
    $index = Join-Path $directory 'index.html'
    if (-not (Test-Path -LiteralPath $index -PathType Leaf) -or (Get-Item -LiteralPath $index).Length -eq 0) {
        throw 'The frontend repository has no usable index.html. Check its main branch before continuing.'
    }
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

Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)

if ($Database) {
    try {
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
            throw 'Install/open Docker Desktop, or follow database/README.md for native PostgreSQL.'
        }
        Invoke-Checked docker @('compose', '-f', (Join-Path (Split-Path -Parent $PSScriptRoot) 'database\compose.yaml'), 'up', '-d', '--wait')
        Write-Host 'PostgreSQL is ready. Next: .\setup.cmd run'
        exit 0
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host 'If port 5432 is occupied, use your existing PostgreSQL: database/README.md.'
        exit 1
    }
}

if ($CheckLesson2) {
    try {
        Enable-Toolchain
        Write-Host 'Checking Lesson 2. Failures are expected until all six TODOs are complete.'
        Invoke-Checked "$env:MAVEN_HOME\bin\mvn.cmd" @('-f', (Join-Path (Split-Path -Parent $PSScriptRoot) 'pom.xml'), '--batch-mode', '--no-transfer-progress', '-Plesson2-check', 'test')
        exit 0
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}


if ($Run) {
    try {
        Enable-Toolchain
        $project = Split-Path -Parent $PSScriptRoot
        Sync-Frontend $project
        Invoke-Checked "$env:JAVA_HOME\bin\java.exe" @("$PSScriptRoot\CheckPom.java", "$project\pom.xml")
        Write-Host "Once Spring reports Started, open http://localhost:$Port/"
        Write-Host 'Keep this window open. Press Ctrl+C to stop. PostgreSQL must be running (setup.cmd db, or native PostgreSQL).'
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
    Write-Host 'SETUP: Java 21, Maven, Git and build.' -ForegroundColor Cyan
    Install-WindowsCommand git 'Git.Git'
    Sync-Frontend (Get-Location).Path
    $script:DownloadDir = Join-Path ([IO.Path]::GetTempPath()) ("impact-setup-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $script:DownloadDir | Out-Null
    Install-Toolchains
    Invoke-Checked "$env:JAVA_HOME\bin\java.exe" @("$PSScriptRoot\CheckPom.java", (Join-Path (Get-Location) "pom.xml"))
    Write-Host 'Building the project and running its tests. The first run downloads dependencies...'
    Invoke-Checked "$env:MAVEN_HOME\bin\mvn.cmd" @('--batch-mode', '--no-transfer-progress', 'clean', 'verify')
    Write-Host "SUCCESS: setup complete." -ForegroundColor Green
    Write-Host 'Next: prepare PostgreSQL (.\setup.cmd db or database/README.md), run .\setup.cmd run, then open http://localhost:8080/'
} catch {
    Write-Host "SETUP STOPPED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Fix the message above and rerun setup.cmd.'
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
