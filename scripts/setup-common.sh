#!/usr/bin/env bash
# Sourced by both platform entry points; compatible with macOS Bash 3.2.
fail() { printf '\nSETUP STOPPED: %s\n' "$*" >&2; exit 1; }

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


# Return a protocol result, not merely an open-port result. Compatible with Bash 3.2.
local_redis_state() (
    if ! { exec 3<>/dev/tcp/127.0.0.1/6379; } 2>/dev/null; then
        printf 'closed\n'
        return
    fi
    local reply=''
    if printf 'PING\r\n' >&3 && IFS= read -r -t 2 reply <&3 && [[ "$reply" == $'+PONG\r' ]]; then
        printf 'ready\n'
    else
        printf 'occupied\n'
    fi
)

install_redis() {
    local platform="$1" state attempt
    state=$(local_redis_state)
    case "$state" in
        ready)
            printf '%s\n' 'Redis raspunde PONG pe localhost:6379; folosim serverul existent.'
            return ;;
        occupied)
            fail 'Portul 6379 este ocupat sau Redis cere parola. Verifica serverul existent; configuratia lui nu va fi inlocuita.' ;;
    esac
    if [[ "$platform" == mac ]]; then
        command -v brew >/dev/null 2>&1 || fail 'Ruleaza mai intai bash setup.sh pentru instalarea Homebrew.'
        brew install redis
        brew services start redis
    else
        sudo apt-get update
        sudo apt-get install -y redis-server redis-tools
        if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
            sudo systemctl start redis-server
        else
            sudo service redis-server start
        fi
    fi
    for attempt in {1..15}; do
        if [[ "$(local_redis_state)" == ready ]]; then
            printf '%s\n' 'Redis este pregatit pe localhost:6379. Verificare: redis-cli ping'
            return
        fi
        sleep 1
    done
    fail 'Redis nu raspunde PONG pe localhost:6379. Verifica serviciul si configuratia; setup nu modifica parolele sau porturile existente.'
}

redis_main() {
    local platform="$1"
    [[ $EUID -ne 0 ]] || fail 'Ruleaza fara sudo; scriptul cere parola doar cand este necesar.'
    DOWNLOAD_DIR=$(mktemp -d "${TMPDIR:-/tmp}/impact-setup.XXXXXXXX")
    trap '[[ -z "${DOWNLOAD_DIR:-}" ]] || rm -rf -- "$DOWNLOAD_DIR"' EXIT
    install_platform_tools "$platform"
    install_redis "$platform"
    printf '%s\n' 'Pentru lectia 3: porneste explicit cu --spring.cache.type=redis si reporneste backend-ul.'
}

setup_main() {
    local platform="$1"
    [[ $EUID -ne 0 ]] || fail 'Run this script as your normal user, without sudo. It asks for your password only for system installs.'
    printf '%s\n' 'SETUP: Java 21, Maven, Git and build.'
    DOWNLOAD_DIR=$(mktemp -d "${TMPDIR:-/tmp}/impact-setup.XXXXXXXX")
    trap '[[ -z "${DOWNLOAD_DIR:-}" ]] || rm -rf -- "$DOWNLOAD_DIR"' EXIT
    install_platform_tools "$platform"
    install_toolchains "$platform"
    "$JAVA_HOME/bin/java" "$PWD/scripts/CheckPom.java" "$PWD/pom.xml"
    printf '%s\n' 'Building and running tests. The first run downloads dependencies...'
    "$MAVEN_HOME/bin/mvn" --batch-mode --no-transfer-progress clean verify
    printf '\nSUCCESS: setup complete.\nNext: bash setup.sh run\nThen open http://localhost:8080/\n'
}

database_main() {
    printf 'H2 starts inside Java automatically. Next: bash setup.sh run\n'
}

check_lessons() {
    local environment="$HOME/.local/share/impact-backend/toolchains/env.sh"
    [[ -f "$environment" ]] || fail 'Run bash setup.sh first.'
    source "$environment"
    printf 'Checking all lesson answers. All Lessons 1-4 solutions are included.\n'
    exec "$MAVEN_HOME/bin/mvn" -f "$PWD/pom.xml" --batch-mode --no-transfer-progress test
}


start_main() {
    local port=${1:-8080} environment
    if [[ ! "$port" =~ ^[1-9][0-9]{0,4}$ ]] || (( port > 65535 )); then
        fail 'Choose a port from 1 to 65535. Example: bash setup.sh run 8081'
    fi
    environment="$HOME/.local/share/impact-backend/toolchains/env.sh"
    [[ -f "$environment" ]] || fail 'Run bash setup.sh first.'
    source "$environment"
    [[ -x "$JAVA_HOME/bin/javac" && -x "$MAVEN_HOME/bin/mvn" ]] || fail 'Java/Maven setup is incomplete. Rerun bash setup.sh.'
    printf 'Once Spring reports Started, open http://localhost:%s/\nKeep this window open. Press Ctrl+C to stop.\nIf the port is busy, try: bash setup.sh run 8081\n' "$port"
    exec "$MAVEN_HOME/bin/mvn" -f "$PWD/pom.xml" spring-boot:run "-Dspring-boot.run.arguments=--server.port=$port"
}
