#Requires -Version 5.1
param([switch]$Redis, [switch]$Database, [switch]$CheckLessons, [switch]$Run, [ValidateRange(1, 65535)][int]$Port = 8080)
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
    param([switch]$Managed)
    if (-not $Managed -and (Get-Command mvn -ErrorAction SilentlyContinue) -and (Get-Command javac -ErrorAction SilentlyContinue)) { return }
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
    Enable-Toolchain -Managed
    Invoke-Checked "$env:JAVA_HOME\bin\javac.exe" @('-version')
    Invoke-Checked mvn @('--version')
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


function Get-LocalRedisState {
    $client = New-Object Net.Sockets.TcpClient
    try {
        $pending = $client.BeginConnect('127.0.0.1', 6379, $null, $null)
        if (-not $pending.AsyncWaitHandle.WaitOne(1500)) { return 'closed' }
        try { $client.EndConnect($pending) } catch { return 'closed' }
        $stream = $client.GetStream()
        $stream.ReadTimeout = 1500
        $stream.WriteTimeout = 1500
        $bytes = [Text.Encoding]::ASCII.GetBytes("PING`r`n")
        $stream.Write($bytes, 0, $bytes.Length)
        $reader = New-Object IO.StreamReader($stream)
        if ($reader.ReadLine() -eq '+PONG') { return 'ready' }
        return 'occupied'
    } catch {
        return 'occupied'
    } finally {
        $client.Dispose()
    }
}

function Get-MemuraiCli {
    $command = Get-Command memurai-cli.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $candidate = Join-Path $env:ProgramFiles 'Memurai\memurai-cli.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    return $null
}


function Invoke-MemuraiInstaller {
    $winget = (Get-Command winget -ErrorAction Stop).Source
    $logDirectory = Join-Path $env:LOCALAPPDATA 'impact-backend\setup-logs'
    New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
    $log = Join-Path $logDirectory ('memurai-' + [guid]::NewGuid().ToString('N') + '.log')
    $arguments = @('install', '--id', 'Memurai.MemuraiDeveloper', '--exact', '--source', 'winget',
        '--accept-package-agreements', '--accept-source-agreements', '--silent',
        '--override', '/quiet /norestart INSTALL_SERVICE=1 PORT=6379 ADD_INSTALLFOLDER_TO_PATH=1 ADD_FIREWALL_RULE=0')
    # Elevate before WinGet invokes MSI; its direct MSI API can otherwise fail with 1603.
    # Encode PowerShell source to preserve paths/arguments through the UAC launch.
    $quotedArguments = @($arguments | ForEach-Object { "'" + $_.Replace("'", "''") + "'" })
    $command = '$ErrorActionPreference = "Continue"; & ' + "'" + $winget.Replace("'", "''") + "' " +
        ($quotedArguments -join ' ') + " *> '" + $log.Replace("'", "''") + "'" + '; exit $LASTEXITCODE'
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    try {
        $process = Start-Process -FilePath "$PSHOME\powershell.exe" -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile', '-EncodedCommand', $encoded)
    } catch {
        throw 'Memurai installation needs administrator approval. Accept the Windows prompt when you rerun .\setup.cmd redis.'
    }
    if ($process.ExitCode -ne 0) {
        throw "Memurai installation failed (exit $($process.ExitCode)). Installer output: $log . Check that log before retrying."
    }
}

function Install-Memurai {
    param([switch]$RequireNative)
    $state = Get-LocalRedisState
    $service = Get-Service -Name 'Memurai' -ErrorAction SilentlyContinue
    if ($state -eq 'ready') {
        if ($RequireNative -and (-not $service -or $service.Status -ne 'Running')) {
            throw 'Redis already uses port 6379. To replace the lesson Docker instance, run: docker compose -f database/compose.yaml stop redis ; then rerun .\setup.cmd redis. Setup will not stop it for you.'
        }
        Write-Host 'Redis is already answering PONG on localhost:6379.'
        $cli = Get-MemuraiCli
        if ($cli) { Write-Host "CLI: & '$cli' ping" }
        else { Write-Host 'For the lesson Docker instance: docker compose -f database/compose.yaml exec -T redis redis-cli ping' }
        return
    }
    if ($state -eq 'occupied') {
        throw 'Port 6379 is occupied or Redis requires authentication. Check your existing server and application-local.properties; setup will not replace its configuration.'
    }
    $cli = Get-MemuraiCli
    if (-not $service -and -not $cli) {
        $architecture = $env:PROCESSOR_ARCHITEW6432
        if (-not $architecture) { $architecture = $env:PROCESSOR_ARCHITECTURE }
        if ($architecture -ne 'AMD64') { throw 'Automatic Memurai installation requires x64 Windows. See database/README.md for other Redis options.' }
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            throw 'Install/update App Installer from Microsoft Store, then rerun .\setup.cmd redis.'
        }
        Write-Host 'Installing Memurai Developer for local lessons. Accept the Windows administrator prompt.'
        Invoke-MemuraiInstaller
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + $env:Path
        $service = Get-Service -Name 'Memurai' -ErrorAction SilentlyContinue
    }
    if (-not $service) {
        throw 'Memurai is installed without its Windows service. Repair the installation with the service option enabled, then rerun .\setup.cmd redis. Existing settings were retained.'
    }
    if ($service.Status -ne 'Running') {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Start-Service -Name 'Memurai'
        } else {
            $command = '$ErrorActionPreference = "Stop"; try { Start-Service -Name "Memurai"; exit 0 } catch { exit 1 }'
            $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
            $process = Start-Process -FilePath "$PSHOME\powershell.exe" -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ArgumentList @('-NoProfile', '-EncodedCommand', $encoded)
            if ($process.ExitCode -ne 0) { throw 'Could not start Memurai. Check the Windows service and port 6379, then rerun .\setup.cmd redis.' }
        }
    }
    for ($attempt = 0; $attempt -lt 15; $attempt++) {
        if ((Get-LocalRedisState) -eq 'ready') {
            Write-Host 'Memurai is ready on localhost:6379 (PONG).'
            $cli = Get-MemuraiCli
            if ($cli) { Write-Host "CLI: & '$cli' ping" }
            return
        }
        Start-Sleep -Seconds 1
    }
    throw 'Memurai did not answer PONG on localhost:6379. Check its service/configuration and rerun .\setup.cmd redis.'
}

# Dot-sourcing exposes helpers for offline tests without running setup.
if ($MyInvocation.InvocationName -eq '.') { return }

Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)

if ($Redis) {
    try {
        Install-Memurai -RequireNative
        Write-Host 'To enable Lesson 3 caching, pass --spring.cache.type=redis as a Spring Boot argument and restart the backend.'
        exit 0
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}
if ($Database) {
    Write-Host 'H2 starts inside Java automatically. Next: .\setup.cmd run'
    exit 0
}

if ($CheckLessons) {
    try {
        Enable-Toolchain
        Write-Host 'Checking all lesson answers. All Lessons 1-4 solutions are included.'
        Invoke-Checked mvn @('-f', (Join-Path (Split-Path -Parent $PSScriptRoot) 'pom.xml'), '--batch-mode', '--no-transfer-progress', '-Plesson-check', 'test')
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
        Write-Host "Once Spring reports Started, open http://localhost:$Port/"
        Write-Host 'Keep this window open. Press Ctrl+C to stop. H2 and the local cache start automatically.'
        Invoke-Checked mvn @('-f', "$project\pom.xml", 'spring-boot:run', "-Dspring-boot.run.arguments=--server.port=$Port")
        exit 0
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host 'Check the error above: Use Java 21 and Maven. For a busy HTTP port, use .\setup.cmd run 8081'
        exit 1
    }
}

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$script:DownloadDir = $null
Push-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
try {
    Write-Host 'SETUP: Java 21, Maven, Git and build (H2/local cache).' -ForegroundColor Cyan
    Install-WindowsCommand git 'Git.Git'
    $script:DownloadDir = Join-Path ([IO.Path]::GetTempPath()) ("impact-setup-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $script:DownloadDir | Out-Null
    Install-Toolchains
    Invoke-Checked "$env:JAVA_HOME\bin\java.exe" @("$PSScriptRoot\CheckPom.java", (Join-Path (Get-Location) "pom.xml"))
    Write-Host 'Building the project and running its tests. The first run downloads dependencies...'
    Invoke-Checked mvn @('--batch-mode', '--no-transfer-progress', 'clean', 'verify')
    Write-Host "SUCCESS: setup complete." -ForegroundColor Green
    Write-Host 'Next: run .\setup.cmd run, then open http://localhost:8080/'
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
