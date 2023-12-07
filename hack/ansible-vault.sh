#!/usr/bin/env bash

# Keychain query fields.
# LABEL is the value you put for "Keychain Item Name" in Keychain.app.

/usr/bin/security find-generic-password -a dylanrobson -l ansible-vault-password -w
