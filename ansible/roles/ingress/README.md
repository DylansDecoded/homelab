# Ingress Role

This Ansible role deploys an ingress stack consisting of:
- **Traefik**: Modern reverse proxy and load balancer
- **Cloudflared**: Cloudflare Tunnel for secure external access

Both services run with host networking mode for direct access to host ports.

## Requirements

- Docker and Docker Compose installed on the target host
- Ansible community.docker collection (`ansible-galaxy collection install community.docker`)
- A Cloudflare Tunnel token (obtain from Cloudflare Zero Trust dashboard)
- A Cloudflare API token for DNS challenges (obtain from Cloudflare dashboard)

## Environment Variables

After deployment, you must create a `.env` file in the ingress directory. Use `.env.example` as a template:

```bash
cp .env.example .env
# Edit .env and add your tokens
```

Required variables:
- `CF_API_TOKEN`: Cloudflare API token with Zone:DNS:Edit permissions for Let's Encrypt DNS challenge
- `CLOUDFLARE_TUNNEL_TOKEN`: Cloudflare Tunnel token for external access

## Role Variables

The role uses minimal Ansible variables for directory paths:

| Variable | Default | Description |
|----------|---------|-------------|
| `ingress_base_dir` | `/home/{{ ansible_user }}/ingress` | Base directory for ingress files |
| `traefik_config_dir` | `{{ ingress_base_dir }}/traefik/config` | Traefik dynamic config directory |
| `traefik_certs_dir` | `{{ ingress_base_dir }}/traefik/letsencrypt` | Traefik certificates directory |
| `traefik_http_port` | `80` | HTTP port (for display message only) |
| `traefik_https_port` | `443` | HTTPS port (for display message only) |

### Static Configuration

The `docker-compose.yaml` file contains static configuration with these defaults:
- **Traefik**: v3.0 with Let's Encrypt DNS challenge via Cloudflare
- **Cloudflared**: Latest image with tunnel token from environment
- **Dashboard**: Available at `traefik.robsonhome.cloud` with TLS
- **Domains**: Internal services use `.internal`, external services use `robsonhome.cloud`

## Example Playbook

```yaml
---
- hosts: homelab
  become: yes
  roles:
    - role: ingress
```

After running the playbook, SSH to the target host and configure environment variables:

```bash
cd ~/ingress
cp .env.example .env
nano .env  # Add your CF_API_TOKEN and CLOUDFLARE_TUNNEL_TOKEN
docker-compose up -d
```

## Getting Your Cloudflare Tokens

### Cloudflare API Token (for Let's Encrypt DNS Challenge)

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **My Profile** > **API Tokens**
3. Click **Create Token**
4. Use the "Edit zone DNS" template
5. Set permissions: **Zone** > **DNS** > **Edit**
6. Set zone resources to include your domain
7. Copy the token

### Cloudflare Tunnel Token

1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Networks** > **Tunnels**
3. Create a new tunnel or select an existing one
4. Copy the tunnel token

## Traefik Configuration

The role deploys a static `providers.yaml` file that configures:

### Split DNS Setup

The configuration supports both internal (`.internal`) and external (`robsonhome.cloud`) access:

**Internal routes** (HTTP only):
- `traefik.internal` → Traefik Dashboard
- `adguard.internal` → AdGuard Home admin panel
- `homeassistant.internal` → Home Assistant
- `aiostreams.internal` → AiOStreams

**External routes** (HTTPS with Let's Encrypt):
- `homeassistant.robsonhome.cloud` → Home Assistant
- `aiostreams.robsonhome.cloud` → AiOStreams

### AdGuard Home DNS Configuration

Configure these **DNS Rewrites** in AdGuard Home for split DNS:

```
# Internal-only services
traefik.internal → <TRAEFIK_HOST_IP>
adguard.internal → <TRAEFIK_HOST_IP>

# Internal access to services (HTTP)
homeassistant.internal → <TRAEFIK_HOST_IP>
aiostreams.internal → <TRAEFIK_HOST_IP>

# Split DNS: Resolve external domains locally when on internal network
homeassistant.robsonhome.cloud → <TRAEFIK_HOST_IP>
aiostreams.robsonhome.cloud → <TRAEFIK_HOST_IP>
```

Replace `<TRAEFIK_HOST_IP>` with your Traefik host's IP address.

### Additional Configuration

You can add more Traefik configuration files to `{{ traefik_config_dir }}` for:
- Custom routers
- Middlewares
- Services
- TLS configurations

## Network Mode

Both services use **host networking mode**, which:
- Allows direct binding to host ports 80, 443
- Simplifies networking (no port mapping needed)
- Required for Traefik to properly discover Docker services
- Enables Cloudflared to connect to local services efficiently

## Security Considerations

1. **Traefik Dashboard**: Protect with basic auth using `traefik_dashboard_auth`
2. **ACME Staging**: Enable `traefik_acme_staging: true` when testing to avoid rate limits
3. **Cloudflared Token**: Store securely using Ansible Vault
4. **Host Network**: Be aware this gives containers direct access to host network

## License

MIT

## Author

Created for homelab automation
