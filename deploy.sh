#!/usr/bin/env bash

echo "Lade Kernel-Parameter in /etc/sysctl.d/"

sudo cp ~/.local/src/kernel_parameter/sysctl.d/*.conf /etc/sysctl.d/
sudo sysctl --system
