# install-java-and-maven.ps1
# Installs JDK 17 and/or JDK 21 (Eclipse Temurin) plus Apache Maven 3.9.16.
# Everything is installed for the current Windows user under %LOCALAPPDATA%.
# Administrator rights are NOT required.
#
# Examples:
#   .\install-java-and-maven.ps1
#   .\install-java-and-maven.ps1 -JavaVersion 17
#   .\install-java-and-maven.ps1 -JavaVersion 21
#   .\install-java-and-maven.ps1 -InstallBothJava
#
# For Lesson 1, Java 17 is recommended.

param(
    [ValidateSet("17", "21")]
    [string]$JavaVersion,

    [switch]$InstallBothJava
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$MavenVersion = "3.9.16"
$MavenUrl = "https://dlcdn.apache.org/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.zip"

$ProgramsRoot = Join-Path $env:LOCALAPPDATA "Programs"
$JavaRoot = Join-Path $ProgramsRoot "Java"
$MavenRoot = Join-Path $ProgramsRoot "Apache\Maven"

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Add-UserPathEntry {
    param([Parameter(Mandatory=$true)][string]$PathToAdd)

    $PathToAdd = $PathToAdd.TrimEnd("\")
    $UserPath = [Environment]::GetEnvironmentVariable(
        "Path",
        [EnvironmentVariableTarget]::User
    )

    if ([string]::IsNullOrWhiteSpace($UserPath)) {
        $UserPath = ""
    }

    $Entries = @(
        $UserPath -split ";" |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    $AlreadyExists = $false
    foreach ($Entry in $Entries) {
        if ($Entry.Trim().TrimEnd("\") -ieq $PathToAdd) {
            $AlreadyExists = $true
            break
        }
    }

    if (-not $AlreadyExists) {
        if ($UserPath -and -not $UserPath.EndsWith(";")) {
            $UserPath += ";"
        }

        $UserPath += $PathToAdd

        [Environment]::SetEnvironmentVariable(
            "Path",
            $UserPath,
            [EnvironmentVariableTarget]::User
        )

        Write-Host "Added to user PATH: $PathToAdd" -ForegroundColor Green
    } else {
        Write-Host "Already on user PATH: $PathToAdd" -ForegroundColor DarkGreen
    }
}

function Remove-OldJavaPathEntries {
    $UserPath = [Environment]::GetEnvironmentVariable(
        "Path",
        [EnvironmentVariableTarget]::User
    )

    if ([string]::IsNullOrWhiteSpace($UserPath)) {
        return
    }

    $NewEntries = @()

    foreach ($Entry in ($UserPath -split ";")) {
        if ([string]::IsNullOrWhiteSpace($Entry)) {
            continue
        }

        # Remove only Java entries created by THIS script.
        if ($Entry -like "$JavaRoot\jdk-*\bin") {
            continue
        }

        $NewEntries += $Entry
    }

    [Environment]::SetEnvironmentVariable(
        "Path",
        ($NewEntries -join ";"),
        [EnvironmentVariableTarget]::User
    )
}

function Get-AdoptiumArchitecture {
    $Arch = $env:PROCESSOR_ARCHITECTURE

    if ($Arch -eq "ARM64") {
        return "aarch64"
    }

    # AMD64 covers normal Intel/AMD 64-bit Windows PCs.
    return "x64"
}

function Install-Jdk {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("17", "21")]
        [string]$Version
    )

    Write-Section "Installing Eclipse Temurin JDK $Version"

    $Architecture = Get-AdoptiumArchitecture
    $JavaApiUrl = "https://api.adoptium.net/v3/binary/latest/$Version/ga/windows/$Architecture/jdk/hotspot/normal/eclipse"

    $InstallDir = Join-Path $JavaRoot "jdk-$Version"
    $TempZip = Join-Path $env:TEMP "temurin-jdk-$Version.zip"
    $TempExtract = Join-Path $env:TEMP "temurin-jdk-$Version-extract"

    New-Item -ItemType Directory -Force -Path $JavaRoot | Out-Null

    if (Test-Path $TempZip) {
        Remove-Item $TempZip -Force
    }

    if (Test-Path $TempExtract) {
        Remove-Item $TempExtract -Recurse -Force
    }

    Write-Host "Downloading latest Temurin JDK $Version ($Architecture)..." -ForegroundColor Yellow
    Write-Host $JavaApiUrl

    Invoke-WebRequest `
        -Uri $JavaApiUrl `
        -OutFile $TempZip `
        -UseBasicParsing

    Write-Host "Extracting JDK $Version..." -ForegroundColor Yellow
    Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force

    # The Adoptium ZIP normally contains one top-level directory such as:
    # jdk-17.0.x+x or jdk-21.0.x+x
    $ExtractedFolder = Get-ChildItem -Path $TempExtract -Directory |
        Select-Object -First 1

    if (-not $ExtractedFolder) {
        throw "Could not find the extracted JDK $Version directory."
    }

    if (Test-Path $InstallDir) {
        Write-Host "Replacing existing JDK $Version installation..." -ForegroundColor Yellow
        Remove-Item $InstallDir -Recurse -Force
    }

    Move-Item -Path $ExtractedFolder.FullName -Destination $InstallDir

    if (-not (Test-Path (Join-Path $InstallDir "bin\java.exe"))) {
        throw "JDK $Version installation failed: java.exe was not found."
    }

    Remove-Item $TempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $TempExtract -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Installed JDK $Version to:" -ForegroundColor Green
    Write-Host $InstallDir

    return $InstallDir
}

function Set-ActiveJava {
    param(
        [Parameter(Mandatory=$true)][string]$JavaHome
    )

    Write-Section "Configuring JAVA_HOME"

    # JAVA_HOME must point to the JDK root, NOT the bin folder.
    [Environment]::SetEnvironmentVariable(
        "JAVA_HOME",
        $JavaHome,
        [EnvironmentVariableTarget]::User
    )

    # Remove old Java PATH entries previously created by this script,
    # then add the selected JDK.
    Remove-OldJavaPathEntries

    $JavaBin = Join-Path $JavaHome "bin"
    Add-UserPathEntry $JavaBin

    # Update this PowerShell session immediately.
    $env:JAVA_HOME = $JavaHome

    $CurrentEntries = @(
        $env:Path -split ";" |
        Where-Object {
            $_ -and ($_ -notlike "$JavaRoot\jdk-*\bin")
        }
    )

    $env:Path = "$JavaBin;" + ($CurrentEntries -join ";")

    Write-Host "JAVA_HOME = $JavaHome" -ForegroundColor Green
}

function Install-Maven {
    Write-Section "Installing Apache Maven $MavenVersion"

    $MavenHome = Join-Path $MavenRoot "apache-maven-$MavenVersion"
    $MavenBin = Join-Path $MavenHome "bin"

    $TempZip = Join-Path $env:TEMP "apache-maven-$MavenVersion-bin.zip"
    $TempExtract = Join-Path $env:TEMP "apache-maven-$MavenVersion-extract"

    New-Item -ItemType Directory -Force -Path $MavenRoot | Out-Null

    if (Test-Path $TempZip) {
        Remove-Item $TempZip -Force
    }

    if (Test-Path $TempExtract) {
        Remove-Item $TempExtract -Recurse -Force
    }

    Write-Host "Downloading Maven $MavenVersion..." -ForegroundColor Yellow
    Write-Host $MavenUrl

    Invoke-WebRequest `
        -Uri $MavenUrl `
        -OutFile $TempZip `
        -UseBasicParsing

    Write-Host "Extracting Maven..." -ForegroundColor Yellow
    Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force

    $ExtractedMaven = Join-Path $TempExtract "apache-maven-$MavenVersion"

    if (-not (Test-Path $ExtractedMaven)) {
        throw "Expected Maven directory was not found after extraction."
    }

    if (Test-Path $MavenHome) {
        Write-Host "Replacing existing Maven $MavenVersion installation..." -ForegroundColor Yellow
        Remove-Item $MavenHome -Recurse -Force
    }

    Move-Item -Path $ExtractedMaven -Destination $MavenHome

    [Environment]::SetEnvironmentVariable(
        "MAVEN_HOME",
        $MavenHome,
        [EnvironmentVariableTarget]::User
    )

    Add-UserPathEntry $MavenBin

    $env:MAVEN_HOME = $MavenHome

    if (($env:Path -split ";") -notcontains $MavenBin) {
        $env:Path = "$MavenBin;$env:Path"
    }

    Remove-Item $TempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $TempExtract -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "MAVEN_HOME = $MavenHome" -ForegroundColor Green
}

# -------------------------------------------------------------------
# Choose which Java version(s) to install.
# -------------------------------------------------------------------

if (-not $JavaVersion -and -not $InstallBothJava) {
    Write-Host ""
    Write-Host "Which JDK do you want to install?" -ForegroundColor Cyan
    Write-Host "  1. Java 17 / JDK 17  (recommended for Lesson 1)"
    Write-Host "  2. Java 21 / JDK 21"
    Write-Host "  3. Install BOTH JDK 17 and JDK 21"
    Write-Host ""

    $Choice = Read-Host "Choose 1, 2, or 3 [default: 1]"

    if ([string]::IsNullOrWhiteSpace($Choice)) {
        $Choice = "1"
    }

    switch ($Choice) {
        "1" { $JavaVersion = "17" }
        "2" { $JavaVersion = "21" }
        "3" { $InstallBothJava = $true }
        default {
            throw "Invalid choice. Run the script again and choose 1, 2, or 3."
        }
    }
}

$Jdk17Home = $null
$Jdk21Home = $null

if ($InstallBothJava) {
    $Jdk17Home = Install-Jdk -Version "17"
    $Jdk21Home = Install-Jdk -Version "21"

    Write-Host ""
    Write-Host "Both JDKs are installed." -ForegroundColor Green
    Write-Host "Java 17 will be selected as the active JAVA_HOME because Lesson 1 uses Java 17." -ForegroundColor Yellow

    Set-ActiveJava -JavaHome $Jdk17Home
}
elseif ($JavaVersion -eq "21") {
    $Jdk21Home = Install-Jdk -Version "21"
    Set-ActiveJava -JavaHome $Jdk21Home
}
else {
    $Jdk17Home = Install-Jdk -Version "17"
    Set-ActiveJava -JavaHome $Jdk17Home
}

Install-Maven

# -------------------------------------------------------------------
# Verification
# -------------------------------------------------------------------

Write-Section "Verification"

Write-Host "JAVA_HOME:" -ForegroundColor Cyan
Write-Host $env:JAVA_HOME
Write-Host ""

Write-Host "java -version:" -ForegroundColor Cyan
& java -version

Write-Host ""
Write-Host "javac -version:" -ForegroundColor Cyan
& javac -version

Write-Host ""
Write-Host "mvn -version:" -ForegroundColor Cyan
& mvn -version

Write-Host ""
Write-Host "Installation completed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT:" -ForegroundColor Yellow
Write-Host "Close and reopen IntelliJ IDEA / VS Code / PowerShell after installation"
Write-Host "so they receive the updated JAVA_HOME and PATH variables."
Write-Host ""

if ($InstallBothJava) {
    Write-Host "Installed locations:" -ForegroundColor Cyan
    Write-Host "JDK 17: $Jdk17Home"
    Write-Host "JDK 21: $Jdk21Home"
    Write-Host ""
    Write-Host "Java 17 is currently active." -ForegroundColor Green
    Write-Host "To switch to Java 21 later, set JAVA_HOME to:"
    Write-Host $Jdk21Home
}
