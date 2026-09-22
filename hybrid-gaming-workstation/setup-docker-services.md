# Task #6: Launch Docker Services for Resolve

## Scope

For the Resolve remote-render pipeline, the only required Docker service is **PostgreSQL 14**. OpenChamber and OpenCode Server will be added later.

## File location

The `docker-compose.yml` lives in the project repo at:

```
hybrid-gaming-workstation/docker/docker-compose.yml
```

Run Docker directly from that directory. Do not copy the file elsewhere.

## Step 1: Clone or pull the project repo on the Windows PC

If you do not already have the repo on the PC:

```powershell
git clone https://github.com/miltonyoung/opencode-personal-assistant-projects.git C:\Users\milton\projects\opencode-personal-assistant-projects
```

If you already have it:

```powershell
cd C:\Users\milton\projects\opencode-personal-assistant-projects
git pull
```

The operational path used on this PC is `C:\Users\milton\projects\opencode-personal-assistant-projects`.

## Step 2: Open Windows Firewall port 5432 for Tailscale

Run in PowerShell as Administrator:

```powershell
New-NetFirewallRule -DisplayName "Resolve PostgreSQL Tailscale" -Direction Inbound -LocalPort 5432 -Protocol TCP -RemoteAddress 100.64.0.0/10 -Action Allow
```

This allows incoming TCP 5432 only from Tailscale IPs (`100.64.0.0/10`). It does not expose the port to the public internet.

## Step 3: Launch the PostgreSQL container

Open PowerShell (does not need Administrator) and run:

```powershell
cd C:\Users\milton\projects\opencode-personal-assistant-projects\hybrid-gaming-workstation\docker
docker compose down
docker compose up -d
```

The `docker compose down` is needed because the port binding changed from `"5432:5432"` to `"0.0.0.0:5432:5432"`.

## Step 4: Verify the container is running

```powershell
docker ps
```

Expected: a container named `resolve-postgres` with status `Up` and port `0.0.0.0:5432->5432/tcp` mapped.

## Step 5: Test the database connection from Windows

Install the PostgreSQL command-line client or use a simple Python test.

### Option A: psql (requires PostgreSQL client)

If you install PostgreSQL client tools, run:

```powershell
psql -h localhost -p 5432 -U postgres -d resolve
```

Password: `DaVinci`

### Option B: Python quick test

Open a PowerShell prompt and run:

```powershell
uv run python -c "import psycopg2; conn=psycopg2.connect(host='localhost', port=5432, dbname='resolve', user='postgres', password='DaVinci'); print(conn.server_version); conn.close()"
```

If `psycopg2` is not installed, use:

```powershell
uv add psycopg2-binary
```

## Step 6: Test the database connection from the MacBook

On the MacBook, run:

```bash
psql -h powerhouse.tail006229.ts.net -p 5432 -U postgres -d resolve
```

Password: `DaVinci`

If you do not have `psql` installed, use any PostgreSQL client or a Python script. If the connection succeeds, the port is reachable over Tailscale.

## Step 7: Configure DaVinci Resolve to use the database

### On the Windows PC

1. Open **DaVinci Resolve Studio**.
2. In the **Project Manager**, click the database icon or right-click in the project library area.
3. Choose **Connect** → **PostgreSQL**.
4. Enter:
   - **Host:** `localhost`
   - **Port:** `5432`
   - **Database:** `resolve`
   - **Username:** `postgres`
   - **Password:** `DaVinci`
5. Save.

### On the MacBook

1. Open **DaVinci Resolve Studio**.
2. In the Project Manager, connect to PostgreSQL.
3. Enter:
   - **Host:** `powerhouse.tail006229.ts.net`
   - **Port:** `5432`
   - **Database:** `resolve`
   - **Username:** `postgres`
   - **Password:** `DaVinci`
4. Save.

Resolve should now create or connect to the shared project library on PostgreSQL.

## Step 8: Enable Remote Rendering in Resolve

1. In the Project Manager, right-click the shared PostgreSQL database.
2. Select **Remote Rendering** → **Enable Remote Rendering**.
3. Close Resolve.

If the right-click menu does not show a Remote Rendering option, Resolve Studio may enable it automatically once both machines are connected to the same shared database.

## Step 9: Launch Resolve headlessly for render node operation

Open PowerShell and run:

```powershell
& "C:\Program Files\Blackmagic Design\DaVinci Resolve\Resolve.exe" -nogui
```

Resolve will run without drawing a window but will remain in the user session.

## Step 10: Record completion

Once `docker ps` shows `resolve-postgres` running with `0.0.0.0:5432`, the MacBook can connect to `powerhouse.tail006229.ts.net:5432`, and Resolve connects to the database on both machines, return here so we can mark Task #6 complete and move to Task #7 (Resolve remote rendering end-to-end test).

## Troubleshooting

- **Port 5432 already in use:** Another PostgreSQL instance may be running. Stop it or change the left-hand port mapping (e.g., `5433:5432`). If you change it, tell Resolve to use port `5433`.
- **Container keeps restarting:** Check logs with `docker logs resolve-postgres`.
- **MacBook cannot connect over Tailscale:** Verify Tailscale is running on both machines. Check the firewall rule exists (`Get-NetFirewallRule -DisplayName "Resolve PostgreSQL Tailscale"`). Verify `powerhouse.tail006229.ts.net` resolves from the MacBook.
- **Database password rejected:** Ensure `POSTGRES_PASSWORD` is exactly `DaVinci` (case-sensitive).
- **Exposing 5432 on all interfaces feels too open:** The `0.0.0.0` bind is required because Docker Desktop for Windows does not bind to specific interface IPs reliably. The Windows Firewall rule restricts incoming connections to Tailscale only. If you want stricter control, run PostgreSQL natively on Windows and bind it to the Tailscale IP directly.
