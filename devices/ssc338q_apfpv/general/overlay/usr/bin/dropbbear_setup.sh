#!/bin/sh
# --- run ON THE CONTROLLER ---------------------------------------------------
set -e                                    # stop on any error

MASTER_IP="$(fw_printenv -n master_ip)"   # camera’s IP from U‑Boot
[ -n "$MASTER_IP" ] || { echo "master_ip not set"; exit 1; }

# 1) Create ~/.ssh and a 2048‑bit RSA key if missing
mkdir -p /root/.ssh && chmod 700 /root/.ssh
if [ ! -f /root/.ssh/id_rsa ]; then
    echo "Generating controller key …"
    dropbearkey -t rsa -s 2048 -f /root/.ssh/id_rsa
    dropbearkey -y -f /root/.ssh/id_rsa | grep '^ssh-rsa' \
        > /root/.ssh/id_rsa.pub
fi

# 2) Push the public key to the camera (you’ll type the root password once)
echo "Installing key on $MASTER_IP (will ask for password this one time) …"
dbclient -y root@"$MASTER_IP" \
  'mkdir -p /etc/dropbear && chmod 700 /etc/dropbear && \
   cat >> /etc/dropbear/authorized_keys && chmod 600 /etc/dropbear/authorized_keys' \
  < /root/.ssh/id_rsa.pub

echo "✓ Key installed. Test login:"
dbclient -y -i /root/.ssh/id_rsa root@"$MASTER_IP" uptime
