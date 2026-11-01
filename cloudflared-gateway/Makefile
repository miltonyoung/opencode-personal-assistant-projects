.PHONY: help up down logs restart status clean

help:
	@echo "Cloudflared Gateway — shared tunnel for multiple Docker Compose projects"
	@echo ""
	@echo "Available targets:"
	@echo "  make up        Start the shared cloudflared tunnel container (creates cloudflare-net if needed)"
	@echo "  make down      Stop the shared cloudflared tunnel container"
	@echo "  make restart   Restart the shared cloudflared tunnel container"
	@echo "  make logs      Follow cloudflared container logs"
	@echo "  make status    Show running containers and the shared network"
	@echo "  make clean     Remove the tunnel container and the shared network"

up:
	@docker compose up -d --build

down:
	@docker compose down

restart: down up

logs:
	@docker compose logs -f

status:
	@echo "=== Gateway containers ==="
	@docker compose ps
	@echo ""
	@echo "=== Shared network: cloudflare-net ==="
	@docker network inspect cloudflare-net --format 'Name: {{.Name}}\nDriver: {{.Driver}}\nContainers: {{len .Containers}}' 2>/dev/null || echo "Network cloudflare-net does not exist. Start the gateway with: make up"
	@echo ""
	@echo "=== Containers attached to cloudflare-net ==="
	@docker network inspect cloudflare-net --format '{{range .Containers}}{{.Name}}\n{{end}}' 2>/dev/null || true

clean: down
	@docker network rm cloudflare-net 2>/dev/null || true
	@echo "Removed cloudflare-net (if it existed)."
