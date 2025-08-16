#!/bin/sh

AP_IP="192.168.0.1"
PORT=12355
TIMEOUT=11

# Helper to send command with timeout
send_cmd() {
    echo "$1" | nc -w $TIMEOUT $AP_IP $PORT
}

# Get all channels
CHANNELS=$(send_cmd get_all_ap_channels)
if [ -z "$CHANNELS" ]; then
    echo "[!] No response or empty channel list from AP"
    exit 1
fi

# Display numbered list
echo
echo "Available AP channels:"
echo "$CHANNELS" | nl -w2 -s'. '

# Get and show current channel
CURRENT=$(send_cmd get_current_ap_channel)
if [ -z "$CURRENT" ]; then
    echo "[!] No response from AP (timeout ${TIMEOUT}s)"
    exit 1
fi

echo
echo "[*] Current AP channel: $CURRENT"

# Prompt for selection
echo
echo -n "Enter the number of the channel to set: "
read CHOICE

SELECTED=$(echo "$CHANNELS" | sed -n "${CHOICE}p")
if [ -z "$SELECTED" ]; then
    echo "[!] Invalid choice"
    exit 1
fi

# Set the selected channel
echo
echo "[*] Setting AP channel to: $SELECTED..."
RESULT=$(send_cmd "set_ap_channel $SELECTED")

if [ -z "$RESULT" ]; then
    echo "[!] No response from AP while setting channel"
    exit 1
fi

echo "[+] AP Response: $RESULT"
