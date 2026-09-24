"""Offline integration tests: real Git, disposable repositories, no GitHub access."""
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


class SetupTests:
    engine = None

    def setUp(self):
        if not self.engine:
            self.skipTest("Required shell is not installed")
        self.temp = tempfile.TemporaryDirectory(prefix="impact setup tests ")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.work = self.base / "student project"
        self.work.mkdir()
        self.env = os.environ.copy()
        for key in list(self.env):
            if key.startswith("GIT_"):
                del self.env[key]
        self.env.update({
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": str(self.base / "empty-gitconfig"),
            "GIT_TERMINAL_PROMPT": "0",
            "GCM_INTERACTIVE": "Never",
        })
        (self.base / "empty-gitconfig").write_text(
            "[user]\n name = Test Student\n email = student@example.invalid\n"
            "[commit]\n gpgSign = false\n"
        )

    def git(self, *args, cwd=None, check=True):
        return subprocess.run(
            ["git", *map(str, args)], cwd=cwd or self.work, env=self.env,
            text=True, capture_output=True, check=check,
        ).stdout.strip()

    def bare(self, name="student.git"):
        path = self.base / name
        self.git("init", "--bare", "-b", "main", path)
        return path.as_posix()

    def initial_commit(self, branch="main"):
        self.git("init", "-b", branch)
        (self.work / "lesson.txt").write_text("classroom project\n")
        self.git("add", ".")
        self.git("commit", "-m", "teacher starter")
        return self.git("rev-parse", "HEAD")

    def helper(self, action, value, expect_ok=True, cwd=None):
        if self.engine == "powershell":
            helper = PROJECT / "scripts/setup-windows.ps1"
            command = (
                "$ErrorActionPreference = 'Stop'; "
                f". {quote_ps(helper)}; "
            )
            if action == "sync":
                command += f"Sync-Origin {quote_ps(value)}"
            elif action == "frontend":
                command += f"Sync-Frontend (Get-Location).Path {quote_ps(value)}"
            else:
                raise ValueError(action)
            argv = [PS, "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", command]
        else:
            function = {"sync": "sync_origin", "frontend": "sync_frontend"}[action]
            arguments = ' "$PWD" "$2"' if action == "frontend" else ' "$2"'
            command = 'set -euo pipefail; source "$1"; ' + function + arguments
            argv = [BASH, "-c", command, "test", (PROJECT / "scripts/setup-common.sh").as_posix(), value]
        result = subprocess.run(
            argv, cwd=cwd or self.work, env=self.env, text=True, capture_output=True,
        )
        output = result.stdout + result.stderr
        if expect_ok:
            self.assertEqual(result.returncode, 0, output)
        else:
            self.assertNotEqual(result.returncode, 0, output)
        return result.stdout.strip()

    def test_sync_origin_fast_forward_keeps_local_edits(self):
        remote = self.bare()
        self.initial_commit()
        self.git("remote", "add", "origin", remote)
        self.git("push", "origin", "main")
        student = self.base / "student clone"
        self.git("clone", remote, student)
        (student / "lesson.txt").write_text("local student work\n")
        (self.work / "new.txt").write_text("teacher update\n")
        self.git("add", "new.txt")
        self.git("commit", "-m", "remote update")
        self.git("push", "origin", "main")
        self.helper("sync", student.as_posix(), cwd=student)
        self.assertEqual((student / "new.txt").read_text(), "teacher update\n")
        self.assertEqual((student / "lesson.txt").read_text(), "local student work\n")

    def test_sync_empty_origin(self):
        remote = self.bare()
        before = self.initial_commit()
        self.git("remote", "add", "origin", remote)
        self.helper("sync", self.work.as_posix())
        self.assertEqual(self.git("rev-parse", "HEAD"), before)

    def test_sync_divergence_preserves_local_commits(self):
        remote = self.bare()
        self.initial_commit()
        self.git("remote", "add", "origin", remote)
        self.git("push", "origin", "main")
        student = self.base / "student clone"
        self.git("clone", remote, student)
        (student / "local.txt").write_text("local commit\n")
        self.git("add", "local.txt", cwd=student)
        self.git("commit", "-m", "local change", cwd=student)
        before = self.git("rev-parse", "HEAD", cwd=student)
        (self.work / "remote.txt").write_text("different commit\n")
        self.git("add", "remote.txt")
        self.git("commit", "-m", "remote change")
        self.git("push", "origin", "main")
        self.helper("sync", student.as_posix(), cwd=student, expect_ok=False)
        self.assertEqual(self.git("rev-parse", "HEAD", cwd=student), before)
        self.assertFalse((student / "remote.txt").exists())

    def test_sync_refuses_to_overwrite_dirty_file(self):
        remote = self.bare()
        self.initial_commit()
        self.git("remote", "add", "origin", remote)
        self.git("push", "origin", "main")
        student = self.base / "student clone"
        self.git("clone", remote, student)
        (student / "lesson.txt").write_text("student's unsaved work\n")
        (self.work / "lesson.txt").write_text("remote lesson change\n")
        self.git("add", "lesson.txt")
        self.git("commit", "-m", "remote lesson")
        self.git("push", "origin", "main")
        self.git("config", "merge.autoStash", "true", cwd=student)
        self.helper("sync", student.as_posix(), cwd=student, expect_ok=False)
        self.assertEqual((student / "lesson.txt").read_text(), "student's unsaved work\n")

    def test_frontend_clone_and_repeat_update(self):
        remote = self.bare("frontend.git")
        self.initial_commit()
        (self.work / "index.html").write_text("<html>first frontend</html>")
        self.git("add", "index.html")
        self.git("commit", "-m", "frontend")
        self.git("remote", "add", "origin", remote)
        self.git("push", "origin", "main")
        self.helper("frontend", remote)
        front = self.work / "frontend"
        self.assertEqual((front / "index.html").read_text(), "<html>first frontend</html>")
        (self.work / "index.html").write_text("<html>updated frontend</html>")
        self.git("add", "index.html")
        self.git("commit", "-m", "update frontend")
        self.git("push", "origin", "main")
        (front / "notes.txt").write_text("keep my notes")
        self.helper("frontend", remote)
        self.assertEqual((front / "index.html").read_text(), "<html>updated frontend</html>")
        self.assertEqual((front / "notes.txt").read_text(), "keep my notes")
        self.assertEqual(self.git("remote", "get-url", "origin"), remote)

    def test_frontend_existing_non_repo_preserved(self):
        front = self.work / "frontend"
        front.mkdir()
        (front / "index.html").write_text("my frontend")
        self.helper("frontend", self.bare(), expect_ok=False)
        self.assertEqual((front / "index.html").read_text(), "my frontend")

    def test_frontend_wrong_origin_rejected(self):
        remote = self.bare()
        self.initial_commit()
        self.git("push", remote, "main")
        self.git("clone", remote, self.work / "frontend")
        self.helper("frontend", self.bare("different.git"), expect_ok=False)
        self.assertEqual(self.git("remote", "get-url", "origin", cwd=self.work / "frontend"), remote)

    def test_frontend_missing_index_rejected(self):
        remote = self.bare()
        self.initial_commit()
        self.git("push", remote, "main")
        self.helper("frontend", remote, expect_ok=False)


class PowerShellTests(SetupTests, unittest.TestCase):
    engine = "powershell" if PS else None


class BashTests(SetupTests, unittest.TestCase):
    engine = "bash" if BASH else None




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


if __name__ == "__main__":
    unittest.main(verbosity=2)
