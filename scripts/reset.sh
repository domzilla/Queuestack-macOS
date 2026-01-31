#!/bin/bash
#
# Resets Picker app to fresh install state
# Wrapper for the generic reset-app script
#

BUNDLE_ID="net.domzilla.queuestack"
RESET_APP=~/GIT/Projects/Misc/scripts/development/macos/reset-app

if [[ -x "$RESET_APP" ]]; then
    exec "$RESET_APP" "$@" "$BUNDLE_ID"
else
    echo "Error: reset-app script not found at $RESET_APP"
    echo "Please ensure the script exists and is executable."
    exit 1
fi
