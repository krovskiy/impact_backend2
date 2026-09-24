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
            if action == "url":
                command += f"ConvertTo-GitHubUrl {quote_ps(value)}"
            elif action == "publish":
                command += f"Publish-Project {quote_ps(value)} 'Student' 'student@example.invalid'"
            else:
                command += f"Test-GitTarget {quote_ps(value)}"
            argv = [PS, "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", command]
        else:
            function = {"url": "normalize_github_url", "publish": "publish_project", "check": "check_git_target"}[action]
            command = 'set -euo pipefail; source "$1"; ' + function + ' "$2" Student student@example.invalid'
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

    def test_urls(self):
        valid = {
            " https://github.com/student/my-project ": "https://github.com/student/my-project.git",
            "https://github.com/student/my-project.git/": "https://github.com/student/my-project.git",
            "git@github.com:student/my-project.git": "https://github.com/student/my-project.git",
            "https://github.com/a/repo.name": "https://github.com/a/repo.name.git",
        }
        for value, expected in valid.items():
            with self.subTest(url=value):
                self.assertEqual(self.helper("url", value), expected)
        for value in [
            "", "https://github.com/student", "http://github.com/student/repo",
            "https://github.com.evil.test/student/repo",
            "https://github.com/student/repo/tree/main",
            "https://github.com/student/repo?token=secret",
            "https://token@github.com/student/repo",
            "https://github.com/-student/repo",
            "https://github.com/student/..",
            "https://github.com/student/repo;echo",
            "https://github.com/student/repo#readme",
        ]:
            with self.subTest(url=value):
                self.helper("url", value, expect_ok=False)

    def test_replace_teacher_origin_push_and_rerun(self):
        teacher = self.bare("teacher.git")
        student = self.bare()
        self.initial_commit()
        self.git("remote", "add", "origin", teacher)
        self.git("push", "origin", "main")
        teacher_head = self.git("--git-dir", teacher, "rev-parse", "main")
        (self.work / "lesson.txt").write_text("student work\n")
        self.helper("publish", student)
        self.assertEqual(self.git("remote"), "origin")
        self.assertEqual(self.git("remote", "get-url", "origin"), student)
        self.assertEqual(self.git("--git-dir", student, "rev-parse", "main"), self.git("rev-parse", "HEAD"))
        self.assertEqual(self.git("--git-dir", teacher, "rev-parse", "main"), teacher_head)
        first = self.git("rev-parse", "HEAD")
        self.helper("publish", student)
        self.assertEqual(self.git("rev-parse", "HEAD"), first)
        self.assertEqual(self.git("rev-parse", "--abbrev-ref", "@{upstream}"), "origin/main")

    def test_zip_download_initializes_and_pushes(self):
        destination = self.bare()
        (self.work / "lesson.txt").write_text("ZIP download\n")
        self.helper("publish", destination)
        self.assertEqual(self.git("branch", "--show-current"), "main")
        self.assertEqual(self.git("--git-dir", destination, "rev-parse", "main"), self.git("rev-parse", "HEAD"))

    def test_unrelated_remote_does_not_change_origin_or_commit(self):
        destination = self.bare()
        other = self.base / "other"
        other.mkdir()
        self.git("init", "-b", "main", cwd=other)
        (other / "README.md").write_text("unrelated README\n")
        self.git("add", ".", cwd=other)
        self.git("commit", "-m", "different history", cwd=other)
        self.git("push", destination, "main", cwd=other)
        before = self.initial_commit()
        self.git("remote", "add", "origin", "https://github.com/teacher/class.git")
        (self.work / "lesson.txt").write_text("uncommitted work\n")
        self.helper("publish", destination, expect_ok=False)
        self.assertEqual(self.git("rev-parse", "HEAD"), before)
        self.assertEqual(self.git("remote", "get-url", "origin"), "https://github.com/teacher/class.git")
        self.assertEqual((self.work / "lesson.txt").read_text(), "uncommitted work\n")

    def test_detached_head_rejected(self):
        destination = self.bare()
        before = self.initial_commit()
        self.git("checkout", "--detach", before)
        self.helper("check", destination, expect_ok=False)

    def test_different_existing_main_rejected(self):
        destination = self.bare()
        self.initial_commit()
        self.git("checkout", "-b", "lesson")
        self.helper("check", destination, expect_ok=False)
        self.assertEqual(self.git("branch", "--show-current"), "lesson")

    def test_single_master_branch_renamed(self):
        destination = self.bare()
        self.initial_commit("master")
        self.helper("publish", destination)
        self.assertEqual(self.git("branch", "--show-current"), "main")

    def test_nested_project_rejected(self):
        destination = self.bare()
        self.initial_commit()
        nested = self.work / "nested"
        nested.mkdir()
        self.helper("check", destination, expect_ok=False, cwd=nested)

    def test_missing_remote_rejected(self):
        self.initial_commit()
        self.helper("check", (self.base / "missing.git").as_posix(), expect_ok=False)

    def test_remote_with_only_another_branch_rejected(self):
        destination = self.bare()
        self.initial_commit()
        self.git("push", destination, "main:lesson")
        self.helper("check", destination, expect_ok=False)


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
        self.original = (PROJECT / "pom.xml").read_bytes()
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
