#!/bin/sh
# Unsupervised CLI installer
# Usage: curl -fsSL https://unsupervised.com/cli/install.sh | sh
#
# Environment variables:
#   UNSUPERVISED_VERSION     — version to install (default: latest)
#   UNSUPERVISED_INSTALL_DIR — install directory (default: ~/.local/bin)

set -eu

if [ -z "${HOME:-}" ]; then
  printf 'error: $HOME is not set — cannot determine install directory\n' >&2
  exit 1
fi

INSTALL_DIR="${UNSUPERVISED_INSTALL_DIR:-$HOME/.local/bin}"
REPO="Unsupervisedcom/unsupervised_cli"
GITHUB_BASE="https://github.com/${REPO}/releases"

# --- helpers ----------------------------------------------------------------

LOG_PREFIX=""
ERR_PREFIX=""
WARN_PREFIX=""
COLOR_RESET=""

if [ -z "${NO_COLOR:-}" ]; then
  if [ -t 1 ]; then
    LOG_PREFIX="$(printf '\033[1;34m')"
    WARN_PREFIX="$(printf '\033[1;33m')"
    COLOR_RESET="$(printf '\033[0m')"
  fi
  if [ -t 2 ]; then
    ERR_PREFIX="$(printf '\033[1;31m')"
    [ -n "$COLOR_RESET" ] || COLOR_RESET="$(printf '\033[0m')"
  fi
fi

log()  { printf '%s%s%s\n' "$LOG_PREFIX" "$*" "$COLOR_RESET"; }
warn() { printf '%swarning: %s%s\n' "$WARN_PREFIX" "$*" "$COLOR_RESET" >&2; }
err()  { printf '%serror: %s%s\n' "$ERR_PREFIX" "$*" "$COLOR_RESET" >&2; exit 1; }

detect_platform() {
  OS="$(uname -s)"
  ARCH="$(uname -m)"

  case "$OS" in
    Linux*)  OS="linux" ;;
    Darwin*) OS="darwin" ;;
    *)       err "Unsupported OS: $OS" ;;
  esac

  case "$ARCH" in
    x86_64|amd64)  ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *)             err "Unsupported architecture: $ARCH" ;;
  esac
}

check_root() {
  if [ "$(id -u)" = "0" ]; then
    case "$INSTALL_DIR" in
      "$HOME"*|/root*)
        warn "Running as root — installing to '${INSTALL_DIR}' will create root-owned files in a user directory."
        warn "Consider using UNSUPERVISED_INSTALL_DIR=/usr/local/bin instead."
        ;;
    esac
  fi
}

PATH_LINE="export PATH=\"${INSTALL_DIR}:\$PATH\""

add_to_profile() {
  profile="$1"
  [ -f "$profile" ] || return 1
  # Already present
  grep -qF "$PATH_LINE" "$profile" 2>/dev/null && return 1
  printf '\n# Added by Unsupervised CLI installer\n%s\n' "$PATH_LINE" >> "$profile"
  return 0
}

ensure_in_path() {
  case ":${PATH:-}:" in
    *":${INSTALL_DIR}:"*) return ;;
  esac

  UPDATED_FILES=""
  FIRST_FILE=""
  for profile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.bash_profile"; do
    if add_to_profile "$profile"; then
      UPDATED_FILES="${UPDATED_FILES} ${profile}"
      [ -z "$FIRST_FILE" ] && FIRST_FILE="$profile"
    fi
  done

  if [ -n "$UPDATED_FILES" ]; then
    log ""
    log "Added ${INSTALL_DIR} to PATH in:${UPDATED_FILES}"
    log ""
    log "Restart your shell or run:  source ${FIRST_FILE}"
  else
    log ""
    log "Add the install directory to your PATH:"
    log ""
    log "  ${PATH_LINE}"
    log ""
    log "Or add it to your shell profile (~/.bashrc, ~/.zshrc, etc.)."
  fi
}

# --- main -------------------------------------------------------------------

main() {
  detect_platform
  check_root

  BINARY="unsupervised-${OS}-${ARCH}"

  # Resolve version: explicit env var, or latest release tag
  if [ -n "${UNSUPERVISED_VERSION:-}" ]; then
    VERSION="${UNSUPERVISED_VERSION#v}"
    TAG="v${VERSION}"
  else
    TAG="$(curl -fsSI "${GITHUB_BASE}/latest" 2>/dev/null | grep -i '^location:' | sed 's|.*/||' | tr -d '\r\n')"
    if [ -z "$TAG" ] || [ "$TAG" = "latest" ]; then
      err "Could not determine latest release. Set UNSUPERVISED_VERSION explicitly."
    fi
    VERSION="${TAG#v}"
  fi

  DOWNLOAD_URL="${GITHUB_BASE}/download/${TAG}/${BINARY}"

  log "Installing unsupervised v${VERSION} (${OS}/${ARCH})..."

  mkdir -p "$INSTALL_DIR"

  TMPDIR_WORK="$(mktemp -d "${TMPDIR:-/tmp}/unsupervised.XXXXXX")"
  trap 'rm -rf "$TMPDIR_WORK"' EXIT

  log "Downloading ${BINARY} from release ${TAG}..."
  if ! curl -fSL --progress-bar -o "${TMPDIR_WORK}/${BINARY}" "$DOWNLOAD_URL"; then
    err "Download failed. Check that release ${TAG} exists at ${GITHUB_BASE}"
  fi

  mv "${TMPDIR_WORK}/${BINARY}" "${INSTALL_DIR}/unsupervised"
  chmod +x "${INSTALL_DIR}/unsupervised"

  log "Installed to ${INSTALL_DIR}/unsupervised"

  # Ensure INSTALL_DIR is in PATH for future sessions
  ensure_in_path

  log ""
  log "Run 'unsupervised --help' to get started."
}

main
