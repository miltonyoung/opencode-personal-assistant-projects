:

# Cloudflared Gateway

A single, shared Cloudflare Tunnel that exposes multiple Docker Compose projects over HTTPS.

Each project connects only the public-facing service to a shared Docker network (`cloudflare-net`). The gateway's own `docker-compose.yml` creates and owns `cloudflare-net`; other projects attach to it as an external network. Routing is managed in the [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/).

## Included projects

| Project | Compose service name | Internal URL | Public hostname |
| ------- | -------------------- | ------------ | --------------- |
| Annie 30th Birthday Trip site | `web` | `http://web:8080` | `anniethirty.gentechss.com` |
| Event Media Intake (coordinator) | `event-coordinator` | `http://event-coordinator:3000` | TBD |

## Quick start

1. **Copy the env file and paste the tunnel token:**

   ```bash
   cp .env.example .env
   ```

   Then edit `.env` and set `CLOUDFLARE_TUNNEL_TOKEN` to the token from the Cloudflare Zero Trust dashboard.

2. **Start the tunnel (creates `cloudflare-net` automatically):**

   ```bash
   make up
   ```

3. **Configure public hostnames in the Cloudflare dashboard:**

   - Go to **Networks** → **Tunnels** and select the shared tunnel.
   - Add or confirm public hostnames pointing to the internal service URLs above:
     - Annie: `http://web:8080`
     - Event Media Intake: `http://event-coordinator:3000`

4. **Start each project** so its services join `cloudflare-net`.

   Annie example:

   ```bash
   cd /app-projects/annie-30-birthday-trip-site
   make prod
   ```

## How to connect a new project

In the project's `docker-compose.yml`, attach the public-facing service to the shared network:

```yaml
services:
  my-public-service:
    # ... existing config
    networks:
      - default          # keeps the project's internal network
      - cloudflare-net   # joins the shared tunnel network

networks:
  cloudflare-net:
    external: true
    name: cloudflare-net
```

Then configure the public hostname in the Cloudflare tunnel dashboard:

| Subdomain | Domain | Service |
|-----------|--------|---------|
| `my-service` | `gentechss.com` | `http://my-public-service:8080` |

Finally, restart the gateway:

```bash
cd /app-projects/cloudflared-gateway
make restart
```

## Operations

- **Logs:** `make logs`
- **Restart:** `make restart`
- **Stop:** `make down`
- **Status:** `make status`

## Security notes

- `.env` is gitignored. Never commit it.
- Only expose the public-facing service from each project on `cloudflare-net`. Keep databases, caches, and internal APIs on the project's default network only.
