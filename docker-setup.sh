#!/usr/bin/env bash
set -euo pipefail

# Sicherstellen, dass das Script als root läuft
if [[ $EUID -ne 0 ]]; then
  echo "Bitte als root oder mit sudo ausführen." >&2
  exit 1
fi

# 0 Betriebssystem-Erkennung und Codenamen-Handling
. /etc/os-release
case "$ID" in
  ubuntu)
    DOCKER_DISTRO="ubuntu"
    CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
    ;;
  debian)
    DOCKER_DISTRO="debian"
    CODENAME="$VERSION_CODENAME"
    ;;
  kali)
    DOCKER_DISTRO="debian"
    echo "Kali Linux erkannt – Debian-Codenamen werden nicht automatisch ermittelt."
    echo "Bitte wählen Sie einen der folgenden Debian-Codenamen:"
    echo "  1) bookworm  (Debian 12)"
    echo "  2) bullseye  (Debian 11)"
    echo "  3) buster    (Debian 10)"
    echo "  4) Manueller Eintrag"
    read -rp "Auswahl [1–4]: " sel
    case "$sel" in
      1) CODENAME="bookworm" ;;
      2) CODENAME="bullseye" ;;
      3) CODENAME="buster" ;;
      4)
        read -rp "Geben Sie den Debian-Codename ein (z.B. bookworm): " CODENAME
        ;;
      *)
        echo "Ungültige Auswahl, verwende Standard: bookworm"
        CODENAME="bookworm"
        ;;
    esac
    ;;
  *)
    echo "Fehler: Nur Debian, Ubuntu und Kali Linux werden unterstützt. Erkannt: $ID" >&2
    exit 1
    ;;
esac

echo "Installiere Docker für: $ID (${CODENAME})"
echo

# 1 Alte Docker-/Container-Pakete entfernen
pkgs=(
  docker.io
  docker-doc
  docker-compose
  podman-docker
  containerd
  runc
)
echo "Entferne alte Pakete: ${pkgs[*]}"
apt-get remove -y "${pkgs[@]}"

# 2 Abhängigkeiten installieren
echo "Installiere Abhängigkeiten"
apt-get update
apt-get install -y ca-certificates curl

# 3 GPG-Key-Verzeichnis anlegen und Docker-GPG-Key importieren
echo "Richte GPG-Keyring ein"
install -m0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/${DOCKER_DISTRO}/gpg" \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# 4 Docker-Repository einrichten
ARCH=$(dpkg --print-architecture)
REPO_URL="https://download.docker.com/linux/${DOCKER_DISTRO}"
echo "Füge Docker-Repository hinzu"
tee /etc/apt/sources.list.d/docker.list > /dev/null <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] \
${REPO_URL} \
${CODENAME} stable
EOF

# 5 Repository-Index aktualisieren und Docker-Pakete installieren
echo "Installiere Docker-Pakete"
apt-get update
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# 6 Testlauf: Hello-World-Container starten und direkt entfernen
echo "Starte Hello-World-Testcontainer"
docker run --rm hello-world

echo "✔ Docker erfolgreich auf $ID ($CODENAME) installiert."
