#!/bin/sh
# Waybeam first-boot customizer
# Runs once via S30customizer, then /etc/custom.ok prevents re-run.
#
# Note: sensor detection is handled by S95venc (runs after S35modules
# loads sensor kernel modules). This script handles non-sensor setup.

echo "Waybeam customizer: first-boot setup complete"
