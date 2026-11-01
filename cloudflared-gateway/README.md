:

# Cloudflared Gateway

A single, shared Cloudflare Tunnel that exposes multiple Docker Compose projects over HTTPS.

Each project connects only the public-facing service to a shared Docker network (`cloudflare-net`). The tunnel container routes public hostnames to the correct internal service by name.

## Included projects

| Project | Compose service name | Internal URL | Public hostname |
| ------- | -------------------- | ------------ | --------------- |
| Annie 30th Birthday Trip site | `web` | `http://web:8080` | TBD |
| Event Media Intake (coordinator) | `event-coordinator` | `http://event-coordinator:3000` | TBD |

## Quick start (stage 1: token-based managed tunnel)

Right now the gateway reuses the existing managed tunnel token from the Annie project. Hostnames and routing are configured in the [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/).

1. **Create the shared Docker network:**

   ```bash
   make network
   ```

2. **Copy the example env file and paste the tunnel token:**

   ```bash
   cp .env.example .env
   ```

   Then edit `.env` and set `CLOUDFLARE_TUNNEL_TOKEN` to the value from `/app-projects/annie-30-birthday-trip-site/.env`.

3. **Start the tunnel:**

   ```bash
   make up
   ```

4. **Configure public hostnames in the Cloudflare dashboard:**

   - Go to **Networks** → **Tunnels** → your shared tunnel.
   - Add or confirm public hostnames pointing to the internal service URLs above, e.g.:
     - Annie: `http://web:8080`
     - Event Media Intake: `http://event-coordinator:3000`

5. **Start each project** so its services join `cloudflare-net`.

   Annie example:

   ```bash
   cd /app-projects/annie-30-birthday-trip-site
   make prod
   ```

## Migration to stage 2: locally-managed tunnel

Stage 2 will move routing into version control using `config.yml` and a `credentials.json` file. When you are ready:

1. Create a new locally-managed tunnel:

   ```bash
   cloudflared tunnel create shared-gateway
   ```

2. Copy the generated credentials file to this directory:

   ```bash
   cp ~/.cloudflared/<tunnel-uuid>.json ./credentials.json
   ```

3. Rename or create `config.yml` from `config.yml.example`, fill in the tunnel UUID and hostnames, and update `docker-compose.yml` to use the config-based command.

4. Update Cloudflare DNS records for each hostname to point to `<tunnel-uuid>.cfargotunnel.com`.

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

Then configure the public hostname in the Cloudflare dashboard (stage 1) or add an ingress rule in this gateway's `config.yml` (stage 2):

```yaml
ingress:
  - hostname: my-service.example.com
    service: http://my-public-service:8080
```

Finally, restart the gateway and the project:

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

- `.env` and `credentials.json` are gitignored. Never commit them.
- Only expose the public-facing service from each project on `cloudflare-net`. Keep databases, caches, and internal APIs on the project's default network only.
