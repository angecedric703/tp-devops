#!/bin/bash
set -euo pipefail

VM_NAME="devops-k3s"
IP=$(VBoxManage guestproperty get "$VM_NAME" \
  "/VirtualBox/GuestInfo/Net/1/V4/IP" \
  | awk '/Value:/ {print $2}')

if [[ -z "$IP" || "$IP" == "No" ]]; then
  echo "IP non trouvée"
  exit 1
fi

echo "IP de la VM : $IP"
echo "$IP" > /tmp/vm_ip.txt
