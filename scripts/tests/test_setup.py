"""Offline tests for the toolchain repair helper and optional Redis installers."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

PROJECT = Path(__file__).resolve().parents[2]
PS = shutil.which("powershell") or shutil.which("pwsh")
BASH = (r"C:\Program Files\Git\bin\bash.exe" if os.name == "nt" else shutil.which("bash"))
if BASH and not Path(BASH).exists():
    BASH = None


def quote_ps(value):
    return "'" + str(value).replace("'", "''") + "'"


class PomTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="impact pom tests ")
        self.addCleanup(self.temp.cleanup)
        self.pom = Path(self.temp.name) / "pom.xml"
        self.backup = self.pom.with_name("pom.xml.before-setup-fix.bak")
        java_home = os.environ.get("JAVA_HOME")
        self.java = str(Path(java_home) / "bin" / ("java.exe" if os.name == "nt" else "java")) if java_home else shutil.which("java")
        if not self.java:
            self.skipTest("Java JDK is required for POM checks")
        # Reproduce the Lesson 1 POM before the missing Lesson 2 dependencies were appended.
        self.original = (PROJECT / "pom.xml").read_bytes()
        start = self.original.index(b'        <!-- Lesson 2:')
        end = self.original.index(b'    </dependencies>', start)
        self.original = self.original[:start] + self.original[end:]
        self.dependency = (
            '<!-- JPA / Hibernate -->\n<dependency>'
            '<groupId>org.springframework.boot</groupId>'
            '<artifactId>spring-boot-starter-data-jpa</artifactId>'
            '</dependency>\n'
            '<dependency><groupId>io.jsonwebtoken</groupId>'
            '<artifactId>jjwt-jackson</artifactId><version>0.12.6</version>'
            '<scope>runtime</scope></dependency>'
        ).encode()

    def check_pom(self, ok=True):
        result = subprocess.run(
            [self.java, str(PROJECT / "scripts/CheckPom.java"), str(self.pom)],
            text=True, capture_output=True,
        )
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("POM CHECK STOPPED", result.stderr)
        return result

    def test_valid_pom_unchanged(self):
        content = self.original + b"\n<!-- Keep this comment: </project> -->\n"
        self.pom.write_bytes(content)
        self.check_pom()
        self.assertEqual(self.pom.read_bytes(), content)
        self.assertFalse(self.backup.exists())

    def test_screenshot_repair_preserves_dependencies_and_backup(self):
        import xml.etree.ElementTree as ET
        broken = self.original + b"\n" + self.dependency
        self.pom.write_bytes(broken)
        self.check_pom()
        self.assertEqual(self.backup.read_bytes(), broken)
        root = ET.parse(self.pom).getroot()
        ns = {"m": "http://maven.apache.org/POM/4.0.0"}
        dependencies = root.findall("m:dependencies/m:dependency", ns)
        self.assertEqual(len(dependencies), 4)
        self.assertEqual(dependencies[-1].find("m:scope", ns).text, "runtime")
        self.assertEqual(dependencies[-1].find("m:version", ns).text, "0.12.6")
        self.assertIsNotNone(root.find("m:build/m:plugins", ns))
        self.assertIn(b"JPA / Hibernate", self.pom.read_bytes())
        repaired = self.pom.read_bytes()
        self.check_pom()
        self.assertEqual(self.pom.read_bytes(), repaired)
        self.assertEqual(self.backup.read_bytes(), broken)

    def test_dependency_wrapper_without_existing_section(self):
        import xml.etree.ElementTree as ET
        self.pom.write_bytes(b"<project><modelVersion>4.0.0</modelVersion></project>\n"
                             b"<dependencies>" + self.dependency + b"</dependencies>")
        self.check_pom()
        self.assertEqual(len(ET.parse(self.pom).getroot().findall("dependencies/dependency")), 2)

    def test_incomplete_snippet_not_modified(self):
        broken = self.original + b"\n<dependency><groupId>demo"
        self.pom.write_bytes(broken)
        self.check_pom(ok=False)
        self.assertEqual(self.pom.read_bytes(), broken)
        self.assertFalse(self.backup.exists())

    def test_duplicate_dependency_not_modified(self):
        broken = self.original + (
            b"<dependency><groupId>org.springframework.boot</groupId>"
            b"<artifactId>spring-boot-starter-web</artifactId></dependency>"
        )
        self.pom.write_bytes(broken)
        self.check_pom(ok=False)
        self.assertEqual(self.pom.read_bytes(), broken)
        self.assertFalse(self.backup.exists())

    def test_arbitrary_trailing_xml_not_modified(self):
        broken = self.original + b"<build><plugins/></build>"
        self.pom.write_bytes(broken)
        self.check_pom(ok=False)
        self.assertEqual(self.pom.read_bytes(), broken)
        self.assertFalse(self.backup.exists())

    def test_existing_backup_not_overwritten(self):
        broken = self.original + self.dependency
        self.pom.write_bytes(broken)
        self.backup.write_bytes(b"previous backup")
        self.check_pom(ok=False)
        self.assertEqual(self.pom.read_bytes(), broken)
        self.assertEqual(self.backup.read_bytes(), b"previous backup")

    def test_broken_project_not_modified(self):
        broken = b"<project><build></project>" + self.dependency
        self.pom.write_bytes(broken)
        self.check_pom(ok=False)
        self.assertEqual(self.pom.read_bytes(), broken)

    def test_external_entities_rejected(self):
        broken = b'<!DOCTYPE project [<!ENTITY x SYSTEM "file:///nonexistent">]><project>&x;</project>'
        self.pom.write_bytes(broken)
        self.check_pom(ok=False)
        self.assertEqual(self.pom.read_bytes(), broken)



class MemuraiTests(unittest.TestCase):
    def run_case(self, script, ok=True):
        if not PS:
            self.skipTest("PowerShell is required")
        preamble = (
            "$ErrorActionPreference = 'Stop'; "
            f". {quote_ps(PROJECT / 'scripts/setup-windows.ps1')}; "
            "function Get-MemuraiCli { return $null }; "
            "function Invoke-Checked { throw 'Unexpected installer call' }; "
        )
        result = subprocess.run([PS, "-NoProfile", "-Command", preamble + script],
                                text=True, capture_output=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result.stdout + result.stderr

    def test_existing_redis_is_reused_without_install(self):
        self.assertIn("PONG", self.run_case("""
function Get-LocalRedisState { 'ready' }
function Get-Service { return $null }
Install-Memurai
"""))

    def test_native_request_does_not_replace_docker(self):
        self.assertIn("already uses port", self.run_case("""
function Get-LocalRedisState { 'ready' }
function Get-Service { return $null }
Install-Memurai -RequireNative
""", ok=False))

    def test_busy_or_authenticated_port_is_not_overwritten(self):
        self.assertIn("occupied", self.run_case("""
function Get-LocalRedisState { 'occupied' }
function Get-Service { return $null }
Install-Memurai
""", ok=False))

    def test_native_running_service_is_reused(self):
        self.assertIn("PONG", self.run_case("""
function Get-LocalRedisState { 'ready' }
function Get-Service { [pscustomobject]@{ Status = 'Running' } }
Install-Memurai -RequireNative
"""))

    def test_existing_cli_without_service_needs_repair(self):
        self.assertIn("without its Windows service", self.run_case("""
function Get-LocalRedisState { 'closed' }
function Get-Service { return $null }
function Get-MemuraiCli { 'C:\\custom\\memurai-cli.exe' }
Install-Memurai
""", ok=False))

    def test_installer_requests_elevation_and_preserves_arguments(self):
        self.assertIn("installer checked", self.run_case("""
function Start-Process {
    param($FilePath, $Verb, $WindowStyle, [switch]$Wait, [switch]$PassThru, $ArgumentList)
    if ($Verb -ne 'RunAs' -or $WindowStyle -ne 'Hidden') { throw 'Missing elevation' }
    $decoded = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ArgumentList[2]))
    foreach ($expected in @('Memurai.MemuraiDeveloper', 'INSTALL_SERVICE=1', 'PORT=6379', 'ADD_FIREWALL_RULE=0', 'exit $LASTEXITCODE', '*>')) {
        if (-not $decoded.Contains($expected)) { throw "Missing $expected" }
    }
    [pscustomobject]@{ ExitCode = 0 }
}
Invoke-MemuraiInstaller
Write-Output 'installer checked'
"""))

    def test_installer_failure_reports_log_path(self):
        self.assertIn("Installer output:", self.run_case("""
function Start-Process { [pscustomobject]@{ ExitCode = 1603 } }
Invoke-MemuraiInstaller
""", ok=False))

    def test_clean_install_uses_verified_package_and_local_service_options(self):
        self.assertIn("Memurai is ready", self.run_case("""
$script:installed = $false
$env:PROCESSOR_ARCHITEW6432 = 'AMD64'
function Get-LocalRedisState { if ($script:installed) { 'ready' } else { 'closed' } }
function Get-Service { if ($script:installed) { [pscustomobject]@{ Status = 'Running' } } }
function Get-Command { [pscustomobject]@{ Source = 'winget.exe' } }
function Invoke-MemuraiInstaller { $script:installed = $true }
Install-Memurai -RequireNative
"""))



class UnixRedisTests(unittest.TestCase):
    def run_case(self, script, ok=True):
        if not BASH:
            self.skipTest("Bash is required")
        with tempfile.TemporaryDirectory(prefix="impact redis tests ") as directory:
            result = subprocess.run(
                [BASH, "-c", 'set -euo pipefail; source "$1"; ' + script,
                 "test", (PROJECT / "scripts/setup-common.sh").as_posix()],
                cwd=directory, text=True, capture_output=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout + result.stderr

    def test_reuses_running_server_without_installing(self):
        self.assertIn("PONG", self.run_case("""
local_redis_state() { echo ready; }
brew() { echo 'Unexpected install' >&2; return 99; }
install_redis mac
"""))

    def test_busy_or_authenticated_port_is_preserved(self):
        self.assertIn("ocupat", self.run_case("""
local_redis_state() { echo occupied; }
brew() { echo 'Unexpected install' >&2; return 99; }
install_redis mac
""", ok=False))

    def test_macos_installs_and_starts_user_service(self):
        self.assertIn("pregatit", self.run_case("""
local_redis_state() { if [[ -f running ]]; then echo ready; else echo closed; fi; }
brew() {
    printf '%s\\n' "$*" >> calls
    if [[ "$*" == 'services start redis' ]]; then touch running; fi
}
install_redis mac
[[ "$(cat calls)" == $'install redis\\nservices start redis' ]]
"""))

    def test_debian_installs_and_starts_service(self):
        self.assertIn("pregatit", self.run_case("""
local_redis_state() { if [[ -f running ]]; then echo ready; else echo closed; fi; }
sudo() {
    printf '%s\\n' "$*" >> calls
    case "$*" in
        'service redis-server start'|'systemctl start redis-server') touch running ;;
    esac
}
install_redis linux
grep -qx 'apt-get install -y redis-server redis-tools' calls
"""))

    def test_failed_homebrew_install_stops_setup(self):
        self.run_case("""
local_redis_state() { echo closed; }
brew() { return 17; }
install_redis mac
""", ok=False)

    def test_service_without_pong_reports_failure(self):
        self.assertIn("nu raspunde", self.run_case("""
local_redis_state() { echo closed; }
brew() { return 0; }
sleep() { :; }
install_redis mac
""", ok=False))


if __name__ == "__main__":
    unittest.main(verbosity=2)
