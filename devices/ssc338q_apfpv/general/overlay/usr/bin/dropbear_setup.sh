#!/bin/sh

##############################################################################
# CONFIGURATION – change only if you keep keys elsewhere
##############################################################################
KEYDIR=/root/.ssh                    # where the new key will live on controller
KEY_DB=$KEYDIR/id_rsa                # Dropbear‑format private key
KEY_SSH=$KEYDIR/id_rsa.openssh       # OpenSSH‑format private key (converted)
PUB=$KEYDIR/id_rsa.pub               # OpenSSH‑format public key
MASTER_IP=$(fw_printenv -n master_ip)
REMOTE_SSH_DIR=/root/.ssh            # OpenSSH's authorized_keys lives here
##############################################################################

set -e

echo "[*] Cleaning up old keys …"
rm -f "$KEY_DB" "$KEY_SSH" "$PUB"
mkdir -p "$KEYDIR" && chmod 700 "$KEYDIR"
sed -i "/$MASTER_IP/d" "$KEYDIR/known_hosts" 2>/dev/null || true

echo "[*] Generating fresh 2048‑bit RSA key with dropbearkey …"
dropbearkey -t rsa -s 2048 -f "$KEY_DB"

echo "[*] Converting private key to OpenSSH format (optional but handy) …"
# produces $KEY_SSH
dropbearconvert dropbear openssh "$KEY_DB" "$KEY_SSH"
chmod 600 "$KEY_DB" "$KEY_SSH"

echo "[*] Extracting public half in OpenSSH format …"
dropbearkey -y -f "$KEY_DB" | grep '^ssh-rsa' > "$PUB"

echo "[*] Installing public key on $MASTER_IP …"
# Creates ~/.ssh and appends the key to authorized_keys (OpenSSH path)
dbclient -y root@"$MASTER_IP" "
  mkdir -p $REMOTE_SSH_DIR && chmod 700 $REMOTE_SSH_DIR &&
  cat >> $REMOTE_SSH_DIR/authorized_keys &&
  chmod 600 $REMOTE_SSH_DIR/authorized_keys" < "$PUB"

echo "[*] Verifying password‑less login with dbclient …"
dbclient -y -i "$KEY_DB" root@"$MASTER_IP" 'echo OK – key works'

echo "[✔] Key regeneration + distribution complete."
echo "    Use $KEY_DB with dbclient; use $KEY_SSH with OpenSSH if needed."
