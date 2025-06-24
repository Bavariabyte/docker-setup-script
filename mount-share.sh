#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 -i <server_ip> -s <share_name> [-m <mount_base>]

  -i  IP-Adresse des NFS-Servers (z.B. 172.16.10.5)
  -s  Name des Shares auf dem Server (z.B. projektdaten)
  -m  Basis-Verzeichnis für den Mountpoint (default: /mnt)
EOF
  exit 1
}

# Optionen parsen
MOUNT_BASE="/mnt"
while getopts "i:s:m:h" opt; do
  case $opt in
    i) SERVER_IP="$OPTARG" ;;
    s) SHARE="$OPTARG"    ;;
    m) MOUNT_BASE="$OPTARG" ;;
    *) usage ;;
  esac
done

# Pflicht-Argumente prüfen
: "${SERVER_IP:?Option -i fehlt.}"; : "${SHARE:?Option -s fehlt.}"

MOUNTPOINT="${MOUNT_BASE}/${SHARE}-data"

echo "==> 0. NFS-Client installieren"
sudo apt update -y && sudo apt install -y nfs-common

echo "==> 1. Mountpoint anlegen: ${MOUNTPOINT}"
sudo mkdir -p "${MOUNTPOINT}"

echo "==> 2. Eintrag in /etc/fstab hinzufügen"
FSTAB_LINE="${SERVER_IP}:/mnt/tank/${SHARE} ${MOUNTPOINT} nfs defaults,_netdev,vers=3 0 0"
if grep -qsF "${SERVER_IP}:/mnt/tank/${SHARE}" /etc/fstab; then
  echo "Eintrag für ${SHARE} existiert bereits in /etc/fstab, überspringe"
else
  echo "${FSTAB_LINE}" | sudo tee -a /etc/fstab
  echo "==> systemd-Daemon reload"
  sudo systemctl daemon-reload
fi

echo "==> 3. Mount ausführen"
sudo mount -a

echo "==> Fertig: ${MOUNTPOINT} ist gemountet:"
mount | grep "${MOUNTPOINT}"
