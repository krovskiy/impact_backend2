#!/usr/bin/env bash
# Sourced by both platform entry points; compatible with macOS Bash 3.2.
fail() { printf '\nSETUP STOPPED: %s\n' "$*" >&2; exit 1; }

sync_origin() {
    local directory="$1" branch state state_path remote_branch
    if [[ ! -e "$directory/.git" ]]; then
        printf '%s\n' 'No Git history in this folder yet; skipping its origin update.'
        return
    fi
    if ! git -C "$directory" remote | grep -qx origin; then
        printf '%s\n' 'No origin configured yet; skipping its update.'
        return
    fi
    branch=$(git -C "$directory" symbolic-ref --quiet --short HEAD) ||
        fail "Detached HEAD in $directory. Switch to a branch before updating."
    for state in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply BISECT_LOG; do
        state_path=$(git -C "$directory" rev-parse --git-path "$state")
        [[ "$state_path" == /* || "$state_path" == [A-Za-z]:/* ]] || state_path="$directory/$state_path"
        [[ ! -e "$state_path" ]] || fail "Finish or abort the Git operation in $directory before updating."
    done
    printf 'Updating %s from origin/%s...\n' "$directory" "$branch"
    git -C "$directory" fetch origin
    remote_branch=$(git -C "$directory" ls-remote --heads origin "refs/heads/$branch")
    if [[ -z "$remote_branch" ]]; then
        printf 'Origin has no %s branch yet; nothing to pull.\n' "$branch"
        return
    fi
    git -C "$directory" -c merge.autoStash=false -c rebase.autoStash=false pull --ff-only --no-rebase origin "$branch"
}

sync_frontend() {
    local project="$1" repository="${2:-https://github.com/Victoras23/impact_2_year_fe.git}" directory
    directory="$project/frontend"
    if [[ ! -e "$directory" ]]; then
        git clone --branch main -- "$repository" "$directory"
    else
        [[ -e "$directory/.git" ]] || fail 'frontend exists but is not a Git clone. Rename that folder and retry; your files were retained.'
        [[ "$(git -C "$directory" remote get-url origin)" == "$repository" ]] ||
            fail 'frontend has an unexpected origin. Move it aside or restore its expected origin before retrying.'
        [[ "$(git -C "$directory" symbolic-ref --quiet --short HEAD)" == main ]] ||
            fail 'Switch the frontend repository to main before updating.'
    fi
    sync_origin "$directory"
    [[ -s "$directory/index.html" ]] || fail 'The frontend repository has no usable index.html. Check its main branch.'
}


normalize_github_url() {
    local value owner repo
    value=$(printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ "$value" =~ ^https://github\.com/([^/]+)/([^/?#]+)/?$ ]] ||
       [[ "$value" =~ ^git@github\.com:([^/]+)/([^/?#]+)/?$ ]]; then
        owner=${BASH_REMATCH[1]}
        repo=${BASH_REMATCH[2]}
        repo=${repo%.git}
        if [[ "$owner" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,37}[A-Za-z0-9])?$ ]] &&
           [[ "$repo" =~ ^[A-Za-z0-9_.-]{1,100}$ ]] && [[ "$repo" != . && "$repo" != .. ]]; then
            printf 'https://github.com/%s/%s.git\n' "$owner" "$repo"
            return 0
        fi
    fi
    return 1
}

read_github_url() {
    local answer
    while true; do
        printf 'Paste your GitHub repository link (or Q to quit): ' >&2
        IFS= read -r answer || fail 'No input received. Run setup in an interactive Terminal.'
        [[ "$answer" != q && "$answer" != Q ]] || fail 'Setup cancelled.'
        if TARGET_URL=$(normalize_github_url "$answer"); then return; fi
        printf '%s\n' 'Use https://github.com/YOUR-NAME/YOUR-REPO (no /tree/main, tokens, spaces, or other websites).' >&2
    done
}

check_git_target() {
    local url="$1" root branch state state_path refs remote_commit has_repo=0
    if root=$(git rev-parse --show-toplevel 2>/dev/null); then
        has_repo=1
        [[ "$(cd "$root" && pwd -P)" == "$(pwd -P)" ]] ||
            fail 'This folder is inside another Git repository. Move the extracted project to its own folder.'
        branch=$(git symbolic-ref --quiet --short HEAD) || fail 'Detached HEAD: switch to your project branch first.'
        for state in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply BISECT_LOG; do
            state_path=$(git rev-parse --git-path "$state")
            [[ ! -e "$state_path" ]] || fail 'Finish or abort the in-progress Git operation before setup.'
        done
        if git show-ref --verify --quiet refs/heads/main && [[ "$branch" != main ]]; then
            fail 'A different main branch already exists. Switch to main with your changes, then rerun setup.'
        fi
    fi
    refs=$(git ls-remote --heads --tags -- "$url") || fail 'Cannot read the repository. Check your internet connection and GitHub sign-in.'
    if [[ -n "$refs" ]]; then
        printf '%s\n' "$refs" | grep -q '[[:space:]]refs/heads/main$' ||
            fail 'Destination already has history but no main branch. Use a new empty repository, or prepare main yourself.'
        [[ "$has_repo" == 1 ]] || fail 'This ZIP has no Git history. Choose an EMPTY repository (no README, license, or .gitignore).'
        git rev-parse --verify --quiet HEAD >/dev/null || fail 'Choose an empty repository for this uncommitted project.'
        remote_commit=$(printf '%s\n' "$refs" | awk '$2 == "refs/heads/main" {print $1}')
        git cat-file -e "$remote_commit^{commit}" 2>/dev/null ||
            fail 'Remote main has commits missing locally. Reconcile the history yourself before rerunning setup.'
        git merge-base --is-ancestor "$remote_commit" HEAD ||
            fail 'Remote main has commits missing locally or unrelated history. Use an empty repository, or reconcile the history first. Nothing was overwritten.'
    fi
    if [[ "$has_repo" == 1 ]] && git rev-parse --verify --quiet HEAD >/dev/null; then
        git -c push.followTags=false push --dry-run "$url" HEAD:refs/heads/main
    fi
    printf 'Verified repository: %s\n' "$url"
}

publish_project() {
    local url="$1" author_name="$2" author_email="$3" branch diff_result
    check_git_target "$url"
    [[ -e .git ]] || git init -b main
    branch=$(git symbolic-ref --quiet --short HEAD)
    [[ "$branch" == main ]] || git branch -m main
    if [[ -z "$(git config --get user.name || true)" ]]; then git config --local user.name "$author_name"; fi
    if [[ -z "$(git config --get user.email || true)" ]]; then git config --local user.email "$author_email"; fi
    # Replace the teacher's origin; do not keep it as another remote.
    if git remote | grep -qx origin; then git remote remove origin; fi
    git remote add origin "$url"
    [[ "$(git remote get-url --push --all origin)" == "$url" ]] ||
        fail 'Git configuration rewrites the destination URL. Correct your Git URL settings first.'
    git add --all -- .
    diff_result=0
    git diff --cached --quiet || diff_result=$?
    if [[ "$diff_result" == 1 ]]; then
        git commit -m 'chore: set up Java 21 project'
    elif [[ "$diff_result" != 0 ]]; then
        fail 'Could not inspect staged changes.'
    fi
    git -c push.followTags=false push --set-upstream origin main:refs/heads/main
}

download() {
    curl --fail --location --show-error --silent --retry 3 --connect-timeout 30 --max-time 600 \
        --proto '=https' --proto-redir '=https' "$1" --output "$2"
}

verify_checksum() {
    local file="$1" expected="$2" bits="$3" actual
    [[ "$expected" =~ ^[0-9a-fA-F]+$ ]] && [[ ${#expected} -eq $((bits / 4)) ]] || fail 'Invalid download checksum.'
    if command -v shasum >/dev/null 2>&1; then
        actual=$(shasum -a "$bits" "$file")
    else
        actual=$("sha${bits}sum" "$file")
    fi
    actual=${actual%% *}
    [[ "$(printf '%s' "$actual" | tr 'A-F' 'a-f')" == "$(printf '%s' "$expected" | tr 'A-F' 'a-f')" ]] ||
        fail 'Download checksum mismatch. Run setup again for a fresh download.'
}

install_toolchains() {
    local platform="$1" arch root java_dir java_home metadata url checksum source version maven_dir profile line
    case "$(uname -m)" in
        x86_64|amd64) arch=x64 ;;
        arm64|aarch64) arch=aarch64 ;;
        *) fail 'A 64-bit Intel/AMD or ARM computer is required.' ;;
    esac
    # Rosetta shells on Apple Silicon should download the native JDK.
    if [[ "$platform" == mac ]] && [[ "$(sysctl -n hw.optional.arm64 2>/dev/null || true)" == 1 ]]; then arch=aarch64; fi
    root="$HOME/.local/share/impact-backend/toolchains"
    mkdir -p "$root"
    java_dir="$root/jdk-21"
    java_home="$java_dir"
    [[ "$platform" != mac ]] || java_home="$java_dir/Contents/Home"
    if [[ ! -x "$java_home/bin/javac" ]]; then
        [[ ! -e "$java_dir" ]] || fail "Incomplete installation at $java_dir. Rename that folder and rerun setup."
        printf '%s\n' 'Downloading and verifying Java 21 JDK...'
        metadata="$DOWNLOAD_DIR/java.json"
        download "https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=$arch&image_type=jdk&os=$platform&vendor=eclipse" "$metadata"
        url=$(jq -er '.[0].binary.package.link' "$metadata")
        checksum=$(jq -er '.[0].binary.package.checksum' "$metadata")
        download "$url" "$DOWNLOAD_DIR/java.tar.gz"
        verify_checksum "$DOWNLOAD_DIR/java.tar.gz" "$checksum" 256
        mkdir "$DOWNLOAD_DIR/java"
        tar -xzf "$DOWNLOAD_DIR/java.tar.gz" -C "$DOWNLOAD_DIR/java"
        set -- "$DOWNLOAD_DIR/java/"*
        [[ $# -eq 1 && -d "$1" ]] || fail 'Unexpected Java archive layout.'
        source="$1"
        if [[ "$platform" == mac ]]; then
            [[ -x "$source/Contents/Home/bin/javac" ]] || fail 'Java archive is incomplete.'
        else
            [[ -x "$source/bin/javac" ]] || fail 'Java archive is incomplete.'
        fi
        mv "$source" "$java_dir"
    fi
    version=3.9.16
    maven_dir="$root/apache-maven-$version"
    if [[ ! -x "$maven_dir/bin/mvn" ]]; then
        [[ ! -e "$maven_dir" ]] || fail "Incomplete installation at $maven_dir. Rename that folder and rerun setup."
        printf '%s\n' 'Downloading and verifying Maven...'
        url="https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/$version/apache-maven-$version-bin.tar.gz"
        download "$url" "$DOWNLOAD_DIR/maven.tar.gz"
        download "$url.sha512" "$DOWNLOAD_DIR/maven.sha512"
        checksum=$(awk 'NR == 1 {print $1}' "$DOWNLOAD_DIR/maven.sha512")
        verify_checksum "$DOWNLOAD_DIR/maven.tar.gz" "$checksum" 512
        mkdir "$DOWNLOAD_DIR/maven"
        tar -xzf "$DOWNLOAD_DIR/maven.tar.gz" -C "$DOWNLOAD_DIR/maven"
        [[ -x "$DOWNLOAD_DIR/maven/apache-maven-$version/bin/mvn" ]] || fail 'Maven archive is incomplete.'
        mv "$DOWNLOAD_DIR/maven/apache-maven-$version" "$maven_dir"
    fi
    export JAVA_HOME="$java_home" MAVEN_HOME="$maven_dir"
    export PATH="$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH"
    "$JAVA_HOME/bin/javac" -version
    "$MAVEN_HOME/bin/mvn" --version
    {
        printf 'export JAVA_HOME=%q\n' "$JAVA_HOME"
        printf 'export MAVEN_HOME=%q\n' "$MAVEN_HOME"
        printf 'export PATH="$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH"\n'
    } > "$root/env.sh"
    printf -v line '[ ! -f %q ] || . %q' "$root/env.sh" "$root/env.sh"
    # Do not create .bash_profile/.bash_login: that would hide an existing .profile.
    for profile in "$HOME/.profile" "$HOME/.bashrc" "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bash_login"; do
        if [[ "$profile" == "$HOME/.bash_profile" || "$profile" == "$HOME/.bash_login" ]]; then
            [[ -f "$profile" ]] || continue
        fi
        if ! grep -Fqx "$line" "$profile" 2>/dev/null; then printf '\n%s\n' "$line" >> "$profile"; fi
    done
}

install_platform_tools() {
    local platform="$1" brew_path
    if [[ "$platform" == mac ]]; then
        if ! command -v brew >/dev/null 2>&1; then
            for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
                if [[ -x "$brew_path" ]]; then eval "$("$brew_path" shellenv)"; break; fi
            done
        fi
        if ! command -v brew >/dev/null 2>&1; then
            printf '%s\n' 'Installing Homebrew and Apple command line tools. Follow any password/install prompts.'
            download https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh "$DOWNLOAD_DIR/homebrew.sh"
            /bin/bash "$DOWNLOAD_DIR/homebrew.sh"
            for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
                if [[ -x "$brew_path" ]]; then eval "$("$brew_path" shellenv)"; break; fi
            done
        fi
        command -v brew >/dev/null 2>&1 || fail 'Homebrew installation did not complete. Rerun setup after finishing its prompts.'
        brew install git jq
        export PATH="$(brew --prefix)/bin:$PATH"
    else
        command -v sudo >/dev/null 2>&1 || fail 'sudo is missing. Ask the computer administrator to install sudo and grant your account access, then rerun as your normal user.'
        printf '%s\n' 'Installing system tools. Enter your computer password if sudo asks (typing stays invisible).'
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl git jq tar gzip
    fi
    git --version
}

setup_main() {
    local platform="$1" owner
    [[ $EUID -ne 0 ]] || fail 'Run this script as your normal user, without sudo. It asks for your password only for system installs.'
    printf '%s\n' 'SETUP: Java 21, Maven, Git, build, commit and push to main.'
    printf '%s\n' 'First create your own EMPTY repository at https://github.com/new (no README, license or .gitignore).'
    printf '%s\n' 'Setup will publish this folder and its existing Git history to the link you enter.'
    read_github_url
    DOWNLOAD_DIR=$(mktemp -d "${TMPDIR:-/tmp}/impact-setup.XXXXXXXX")
    trap '[[ -z "${DOWNLOAD_DIR:-}" ]] || rm -rf -- "$DOWNLOAD_DIR"' EXIT
    install_platform_tools "$platform"
    sync_frontend "$PWD"
    check_git_target "$TARGET_URL"
    install_toolchains "$platform"
    "$JAVA_HOME/bin/java" "$PWD/scripts/CheckPom.java" "$PWD/pom.xml"
    printf '%s\n' 'Building and running tests. The first run downloads dependencies...'
    "$MAVEN_HOME/bin/mvn" --batch-mode --no-transfer-progress clean verify
    owner=${TARGET_URL#https://github.com/}
    owner=${owner%%/*}
    publish_project "$TARGET_URL" "$owner" "$owner@users.noreply.github.com"
    printf '\nSUCCESS: uploaded to %s on main.\nNext: prepare PostgreSQL (bash setup.sh db or database/README.md), then bash setup.sh run\nThen open http://localhost:8080/\n' "$TARGET_URL"
}

database_main() {
    command -v docker >/dev/null 2>&1 || fail 'Install/open Docker Desktop (or Docker Engine + Compose on Debian), or follow database/README.md for native PostgreSQL.'
    docker compose -f "$PWD/database/compose.yaml" up -d --wait
    printf 'PostgreSQL is ready. Next: bash setup.sh run\n'
}

check_lesson2() {
    local environment="$HOME/.local/share/impact-backend/toolchains/env.sh"
    [[ -f "$environment" ]] || fail 'Run bash setup.sh first.'
    source "$environment"
    printf 'Checking Lesson 2. Failures are expected until all six TODOs are complete.\n'
    exec "$MAVEN_HOME/bin/mvn" -f "$PWD/pom.xml" --batch-mode --no-transfer-progress -Plesson2-check test
}


start_main() {
    local port=${1:-8080} environment
    if [[ ! "$port" =~ ^[1-9][0-9]{0,4}$ ]] || (( port > 65535 )); then
        fail 'Choose a port from 1 to 65535. Example: bash setup.sh run 8081'
    fi
    environment="$HOME/.local/share/impact-backend/toolchains/env.sh"
    [[ -f "$environment" ]] || fail 'Run bash setup.sh first.'
    source "$environment"
    sync_frontend "$PWD"
    [[ -x "$JAVA_HOME/bin/javac" && -x "$MAVEN_HOME/bin/mvn" ]] || fail 'Java/Maven setup is incomplete. Rerun bash setup.sh.'
    printf 'Once Spring reports Started, open http://localhost:%s/\nKeep this window open. Press Ctrl+C to stop.\nIf the port is busy, try: bash setup.sh run 8081\n' "$port"
    "$JAVA_HOME/bin/java" "$PWD/scripts/CheckPom.java" "$PWD/pom.xml"
    exec "$MAVEN_HOME/bin/mvn" -f "$PWD/pom.xml" spring-boot:run "-Dspring-boot.run.arguments=--server.port=$port"
}
