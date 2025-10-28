# AdGuard Home HA Deployment - Quick Start Guide

This guide will help you deploy a highly available AdGuard Home DNS infrastructure using the provided Ansible role.

## Architecture Summary

- **Master DNS**: pi-net01 (10.1.20.91) - Priority 200
- **Backup DNS**: pi-net02 (10.1.20.92) - Priority 100
- **Virtual IP**: 10.1.20.53 (shared via Keepalived)
- **Fallback DNS**: OPNsense (10.1.20.254)

## Prerequisites

1. Two Pi servers (pi-net01, pi-net02) with Ubuntu/Debian
2. Ansible installed on control machine
3. SSH access to both servers
4. Servers on same network segment

## Deployment Steps

### 1. Install Required Ansible Collections

```bash
ansible-galaxy collection install community.docker
```

### 2. Create Vault for Sensitive Data

```bash
# Create vault directory
mkdir -p inventory/group_vars/adguardhome_servers

# Create encrypted vault file
ansible-vault create inventory/group_vars/adguardhome_servers/vault.yaml
```

Add the following content (use strong passwords):

```yaml
---
vault_keepalived_auth_pass: "your-strong-keepalived-password"
vault_adguardhome_username: "admin"
vault_adguardhome_password: "your-strong-adguard-password"
vault_adguardhome_master_password: "your-strong-adguard-password"
```

Save and exit (`:wq` in vim).

### 3. Review Configuration Files

The following files have been created for you:

- `inventory/hosts.yaml` - Server inventory (✓ already configured)
- `inventory/host_vars/pi-net01.yaml` - Master configuration (✓ created)
- `inventory/host_vars/pi-net02.yaml` - Backup configuration (✓ created)
- `inventory/group_vars/adguardhome_servers.yaml` - Shared settings (✓ created)
- `playbooks/adguardhome.yaml` - Deployment playbook (✓ created)

### 4. Deploy AdGuard Home

```bash
# Deploy to both servers
ansible-playbook -i inventory/hosts.yaml playbooks/adguardhome.yaml --ask-vault-pass

# Or if using vault password file
ansible-playbook -i inventory/hosts.yaml playbooks/adguardhome.yaml --vault-password-file ~/.vault_pass
```

### 5. Initial Configuration

1. **Access Web Interface**: 
   - Navigate to `http://10.1.20.53:3000` (VIP) or `http://10.1.20.91:3000` (master directly)

2. **Complete Setup Wizard**:
   - Click "Get Started"
   - Admin Web Interface: Leave as default (port 3000)
   - DNS Server: Leave as default (port 53, all interfaces)
   - Username: Use value from vault (`admin`)
   - Password: Use value from vault
   - Click "Next" and "Open Dashboard"

3. **Configure DNS Settings**:
   - Go to **Settings** → **DNS settings**
   - Upstream DNS servers should already be configured
   - Enable "Parallel requests" for faster resolution
   - Enable "DNSSEC" if desired
   - Save configuration

4. **Add Blocklists**:
   - Go to **Filters** → **DNS blocklists**
   - Click "Add blocklist" → "Choose from the list"
   - Recommended lists:
     - AdGuard DNS filter
     - AdAway Default Blocklist
     - Dan Pollock's List
   - Click "Save"

5. **Verify Sync** (on backup server):
   ```bash
   ssh pi-net02
   docker logs adguardhome-sync
   ```
   You should see successful sync messages.

### 6. Configure Clients

#### Option A: DHCP Configuration (Recommended)

Configure your DHCP server (e.g., OPNsense):
1. Go to **Services** → **DHCPv4**
2. Set DNS servers:
   - Primary: `10.1.20.53`
   - Secondary: `10.1.20.254`
3. Save and apply

#### Option B: Manual Configuration

On each client device, set DNS servers:
- DNS 1: `10.1.20.53`
- DNS 2: `10.1.20.254`

### 7. Test Deployment

#### Test DNS Resolution

```bash
# Test VIP
dig @10.1.20.53 google.com

# Test master directly
dig @10.1.20.91 google.com

# Test backup directly
dig @10.1.20.92 google.com

# Test blocking (should return 0.0.0.0 or NXDOMAIN)
dig @10.1.20.53 doubleclick.net
```

#### Test Failover

1. **Check which server has VIP**:
   ```bash
   # On pi-net01
   ip addr show | grep 10.1.20.53
   ```
   Should show the VIP on master (pi-net01)

2. **Stop AdGuard Home on master**:
   ```bash
   ssh pi-net01
   docker stop adguardhome
   ```

3. **Check VIP moved to backup**:
   ```bash
   # On pi-net02
   ip addr show | grep 10.1.20.53
   ```
   VIP should now be on backup (pi-net02)

4. **Test DNS still works**:
   ```bash
   dig @10.1.20.53 google.com
   ```

5. **Restart master**:
   ```bash
   ssh pi-net01
   docker start adguardhome
   ```
   
   After 15 minutes (preempt_delay), VIP will return to master.

## Monitoring

### Check Service Status

```bash
# Keepalived status
sudo systemctl status keepalived

# View Keepalived logs
journalctl -u keepalived -f

# AdGuard Home status
docker ps
docker logs adguardhome

# AdGuard Home sync status (backup server)
docker logs adguardhome-sync
```

### Check Which Server is Active

```bash
# Check on both servers
ip addr show | grep 10.1.20.53

# Or check from another machine
ping -c 1 10.1.20.53
arp -a | grep 10.1.20.53
```

### View DNS Query Logs

Access web interface at `http://10.1.20.53:3000` and go to **Query Log**.

## Troubleshooting

### VIP Not Assigned

```bash
# Check Keepalived
sudo systemctl status keepalived
journalctl -u keepalived -n 50

# Test health check manually
sudo /etc/keepalived/check_adguardhome.sh
echo $?  # Should return 0 if healthy
```

### DNS Not Resolving

```bash
# Check AdGuard Home is running
docker ps | grep adguardhome

# Check logs
docker logs adguardhome

# Test local resolution
dig @127.0.0.1 google.com

# Check port 53 is listening
sudo netstat -tulpn | grep :53
```

### Sync Not Working (Backup Server)

```bash
# Check sync container
docker logs adguardhome-sync

# Test master API access
curl http://10.1.20.91:3000/control/status

# Restart sync container
cd ~/adguardhome
docker-compose restart adguardhome-sync
```

## Maintenance

### Update AdGuard Home

```bash
# Edit group_vars or defaults
vim inventory/group_vars/adguardhome_servers.yaml

# Set version
adguardhome_version: "v0.107.43"

# Re-run playbook
ansible-playbook -i inventory/hosts.yaml playbooks/adguardhome.yaml --ask-vault-pass
```

### Backup Configuration

```bash
# On master server
ssh pi-net01
tar -czf adguardhome-backup-$(date +%Y%m%d).tar.gz ~/adguardhome/
```

### View Statistics

Access the web interface at `http://10.1.20.53:3000`:
- **Dashboard**: Overall statistics
- **Query Log**: Detailed query logs
- **Filters**: Blocked domains
- **Settings**: Configuration options

## Security Recommendations

1. **Enable HTTPS**: Configure TLS certificates in AdGuard Home settings
2. **Restrict Web Access**: Configure firewall to limit web interface access
3. **Regular Updates**: Keep AdGuard Home and system packages updated
4. **Strong Passwords**: Use complex passwords in vault
5. **Monitor Logs**: Regularly review query logs for anomalies

## Next Steps

1. Configure custom DNS rewrites for internal services
2. Set up custom filtering rules
3. Configure per-client settings
4. Enable query log statistics
5. Set up external monitoring/alerting
6. Document your custom DNS records

## Support

For issues or questions:
- Check the [AdGuard Home documentation](https://github.com/AdguardTeam/AdGuardHome/wiki)
- Review role README: `roles/adguardhome/README.md`
- Check Ansible logs for deployment issues
- Review system logs: `journalctl -xe`

## Configuration Files Reference

- **Role**: `roles/adguardhome/`
- **Inventory**: `inventory/hosts.yaml`
- **Host Vars**: `inventory/host_vars/pi-net0[1-2].yaml`
- **Group Vars**: `inventory/group_vars/adguardhome_servers.yaml`
- **Vault**: `inventory/group_vars/adguardhome_servers/vault.yaml`
- **Playbook**: `playbooks/adguardhome.yaml`
