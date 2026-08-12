#!/usr/bin/env bash

# Ermittelt automatisch den Ordner, in dem dieses Skript liegt
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/sysctl.d"
TARGET_DIR="/etc/sysctl.d"

echo "Kernel-Parameter werden aus der Repo ${SRC_DIR} nach ${TARGET_DIR} verlinkt"

for file in "${SRC_DIR}"/*.conf; do
  [ -e "$file" ] || continue
  sudo ln -sf "$file" "${TARGET_DIR}/$(basename "$file")"
done

sudo sysctl --system
