#!/bin/zsh
# Ansible Vault password script using 1Password CLI
# This script retrieves the Ansible Vault password from 1Password

set -euo pipefail

# Configuration
VAULT_ID="homelab"
VAULT_ANSIBLE_NAME="ansible_vault"

op read "op://$VAULT_ID/$VAULT_ANSIBLE_NAME/password"