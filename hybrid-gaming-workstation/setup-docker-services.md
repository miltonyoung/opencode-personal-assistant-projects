# Task #6: Launch Docker Services for Resolve

## Scope

For the Resolve remote-render pipeline, the only required Docker service is **PostgreSQL 14**. OpenChamber and OpenCode Server will be added later.

## File location

The `docker-compose.yml` lives in the project repo under `hybrid-gaming-workstation/docker/docker-compose.yml`. Copy it onto the Windows PC at:

```
C:\hybrid-gaming-workstation\docker\docker-compose.yml
```

## Step 1: Create the project directory on Windows

Open PowerShell as Administrator:

```powershell
New-Item -ItemType Directory -Path "C:\hybrid-gaming-workstation\docker" -Force
```

## Step 2: Copy `docker-compose.yml` to the PC

Use File Explorer or PowerShell to copy the file from the repo to `C:\hybrid-gaming-workstation\docker\docker-compose.yml`.

## Step 3: Launch the PostgreSQL container

Open PowerShell (does not need Administrator) and run:

```powershell
cd C:\hybrid-gaming-workstation\docker
docker compose up -d
```

## Step 4: Verify the container is running

```powershell
docker ps
```

Expected: a container named `resolve-postgres` with status `Up` and port `5432/tcp` mapped.

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

## Step 6: Configure DaVinci Resolve to use the database

1. Open **DaVinci Resolve Studio**.
2. On the Project Manager, click the **Database** icon or right-click in the project library area.
3. Choose **Connect** → **PostgreSQL**.
4. Enter:
   - **Host:** `localhost`
   - **Port:** `5432`
   - **Database:** `resolve`
   - **Username:** `postgres`
   - **Password:** `DaVinci`
5. Save.

Resolve should now create or connect to the shared project library on PostgreSQL.

## Step 7: Enable Remote Rendering in Resolve

1. In the Project Manager, right-click the shared PostgreSQL database.
2. Select **Remote Rendering** → **Enable Remote Rendering**.
3. Close Resolve.

## Step 8: Launch Resolve headlessly for render node operation

Open PowerShell and run:

```powershell
& "C:\Program Files\Blackmagic Design\DaVinci Resolve\Resolve.exe" -nogui
```

Resolve will run without drawing a window but will remain in the user session.

## Step 9: Record completion

Once `docker ps` shows `resolve-postgres` running and Resolve connects to the database successfully, return here so we can mark Task #6 complete and move to Task #7 (Resolve remote rendering end-to-end test).

## Troubleshooting

- **Port 5432 already in use:** Another PostgreSQL instance may be running. Stop it or change the left-hand port mapping (e.g., `5433:5432`). If you change it, tell Resolve to use port `5433`.
- **Container keeps restarting:** Check logs with `docker logs resolve-postgres`.
- **Resolve cannot connect:** Verify Windows Firewall allows local TCP port 5432. Docker Desktop may already handle this for WSL2 localhost forwarding.
- **Database password rejected:** Ensure `POSTGRES_PASSWORD` is exactly `DaVinci` (case-sensitive).
