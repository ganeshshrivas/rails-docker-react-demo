#!/usr/bin/env bash
# Full first-time + repeat deploy setup for a fresh EC2 host (Ubuntu, Debian, Amazon Linux).
set -euo pipefail

log() { echo "[bootstrap] $*"; }

docker_cmd() {
  if docker info >/dev/null 2>&1; then
    docker "$@"
  else
    sudo docker "$@"
  fi
}

detect_pkg_mgr() {
  if command -v apt-get >/dev/null 2>&1; then
    PKG_MGR=apt
  elif command -v dnf >/dev/null 2>&1; then
    PKG_MGR=dnf
  elif command -v yum >/dev/null 2>&1; then
    PKG_MGR=yum
  else
    log "ERROR: no supported package manager (apt-get, dnf, yum)."
    exit 1
  fi
  log "Package manager: $PKG_MGR"
}

refresh_package_index() {
  case "$PKG_MGR" in
    apt) sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq ;;
    dnf) sudo dnf makecache -y -q 2>/dev/null || true ;;
    yum) sudo yum makecache -q 2>/dev/null || true ;;
  esac
}

pkg_install() {
  case "$PKG_MGR" in
    apt) sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
    dnf) sudo dnf install -y "$@" ;;
    yum) sudo yum install -y "$@" ;;
  esac
}

install_base_packages() {
  case "$PKG_MGR" in
    apt) pkg_install ca-certificates curl gnupg ;;
    dnf|yum) pkg_install ca-certificates curl ;;
  esac
}

install_git() {
  if command -v git >/dev/null 2>&1; then
    return
  fi
  log "Installing git..."
  pkg_install git
}

install_docker_apt() {
  log "Installing Docker (apt)..."
  . /etc/os-release
  case "${ID:-ubuntu}" in
    debian) DOCKER_DIST=debian ;;
    *) DOCKER_DIST=ubuntu ;;
  esac

  pkg_install ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/${DOCKER_DIST}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DOCKER_DIST} $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
  pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_rpm() {
  log "Installing Docker (dnf/yum)..."
  case "$PKG_MGR" in
    dnf)
      if ! sudo dnf install -y docker docker-compose-plugin 2>/dev/null; then
        sudo dnf install -y docker
      fi
      ;;
    yum)
      if ! sudo yum install -y docker 2>/dev/null; then
        log "ERROR: failed to install docker via yum."
        exit 1
      fi
      ;;
  esac
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    return
  fi
  case "$PKG_MGR" in
    apt) install_docker_apt ;;
    dnf|yum) install_docker_rpm ;;
  esac
  sudo usermod -aG docker "${USER:-$(whoami)}" 2>/dev/null || true
}

install_compose_plugin() {
  if docker_cmd compose version >/dev/null 2>&1; then
    return
  fi
  log "Installing Docker Compose plugin..."
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64|amd64) COMPOSE_ARCH=x86_64 ;;
    aarch64|arm64) COMPOSE_ARCH=aarch64 ;;
    *)
      log "ERROR: unsupported architecture for compose: $ARCH"
      exit 1
      ;;
  esac
  COMPOSE_VERSION=v2.24.6
  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  sudo curl -fsSL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${COMPOSE_ARCH}" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
}

start_docker() {
  log "Starting Docker..."
  sudo systemctl enable docker 2>/dev/null || true
  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl start docker
  else
    sudo service docker start
  fi

  for _ in $(seq 1 30); do
    if docker_cmd info >/dev/null 2>&1; then
      log "Docker is ready."
      return
    fi
    sleep 2
  done
  log "ERROR: Docker did not become ready in time."
  exit 1
}

docker_hub_login() {
  if [ -z "${DOCKERHUB_USERNAME:-}" ] || [ -z "${DOCKERHUB_TOKEN:-}" ]; then
    log "Skipping Docker Hub login (DOCKERHUB_USERNAME or DOCKERHUB_TOKEN not set)."
    return
  fi
  log "Logging in to Docker Hub..."
  echo "$DOCKERHUB_TOKEN" | docker_cmd login -u "$DOCKERHUB_USERNAME" --password-stdin
}

deploy_stack() {
  APP_DIR="${APP_DIR:-$HOME/rails_demo}"
  if [ ! -f "$APP_DIR/docker-compose.prod.yml" ]; then
    log "ERROR: $APP_DIR/docker-compose.prod.yml not found. Clone the repo first."
    exit 1
  fi

  cd "$APP_DIR"
  export JWT_SECRET="${JWT_SECRET:?JWT_SECRET is required}"
  export SECRET_KEY_BASE="${SECRET_KEY_BASE:?SECRET_KEY_BASE is required}"
  export DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:?DOCKERHUB_USERNAME is required}"

  log "Pulling images..."
  docker_cmd compose -f docker-compose.prod.yml pull

  log "Starting stack..."
  docker_cmd compose -f docker-compose.prod.yml up -d --remove-orphans

  log "Pruning unused images..."
  docker_cmd image prune -f

  log "Deploy complete."
  docker_cmd compose -f docker-compose.prod.yml ps
}

main() {
  detect_pkg_mgr
  refresh_package_index
  install_base_packages
  install_git
  install_docker
  install_compose_plugin
  start_docker
  docker_hub_login
  deploy_stack
}

main "$@"
