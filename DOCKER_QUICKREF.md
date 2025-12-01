# Docker Quick Reference

**Fast reference for common Docker commands in Academic Workflow Suite**

## 🚀 Quick Start

```bash
just docker-build    # Build all images
just docker-up       # Start development
just help            # Show all commands
```

## 📦 Build

```bash
just docker-build              # Build all images
just docker-build-core         # Build Core Engine only
just docker-build-backend      # Build Backend Service only
just docker-build-no-cache     # Force rebuild without cache
```

## ▶️ Start/Stop

```bash
just docker-up        # Start dev environment
just docker-prod      # Start production
just docker-down      # Stop services
just docker-restart   # Restart dev environment
```

## 🧪 Testing

```bash
just docker-test           # Run all tests
just docker-test-core      # Test Core Engine
just docker-test-backend   # Test Backend Service
```

## 📊 Logs & Status

```bash
just docker-logs           # All logs
just docker-logs-core      # Core Engine logs
just docker-ps             # Service status
just docker-stats          # Resource usage
```

## 💻 Shell Access

```bash
just docker-shell-core       # Bash in Core Engine
just docker-shell-backend    # Bash in Backend Service
just docker-shell-postgres   # PostgreSQL psql
just docker-shell-redis      # Redis CLI
```

## 🗄️ Database

```bash
just docker-db-migrate    # Run migrations
just docker-db-rollback   # Rollback migration
just docker-db-reset      # Reset database
just docker-db-seed       # Seed database
just docker-db-backup     # Backup database
```

## 🧹 Cleanup

```bash
just docker-clean            # Clean dangling resources
just docker-clean-volumes    # Remove volumes (⚠️ deletes data)
just docker-reset            # Complete reset (⚠️⚠️⚠️)
```

## 📈 Monitoring

```bash
just docker-prometheus    # Open Prometheus
just docker-grafana       # Open Grafana
just docker-adminer       # Open Adminer
```

## 🔍 Inspection

```bash
docker-compose ps                    # List services
docker-compose logs -f <service>     # Follow logs
docker-compose exec <service> bash   # Execute command
docker inspect <container>           # Inspect container
docker stats --no-stream            # Resource usage
```

## 🌐 Service URLs

| Service    | URL                       |
|------------|---------------------------|
| Nginx      | http://localhost          |
| Core API   | http://localhost:8080     |
| Backend    | http://localhost:4000     |
| Adminer    | http://localhost:8081     |
| Prometheus | http://localhost:9090     |
| Grafana    | http://localhost:3000     |

## 🔑 Default Credentials

| Service    | Username | Password    | Notes          |
|------------|----------|-------------|----------------|
| PostgreSQL | aws_user | (see .env)  | From .env file |
| Redis      | -        | (see .env)  | From .env file |
| Grafana    | admin    | (see .env)  | From .env file |
| Adminer    | -        | Use Postgres| -              |

## 🛠️ Common Tasks

### Add a new service
1. Edit `docker-compose.yml`
2. Add service configuration
3. Run `docker-compose up -d`

### Update a service
1. Edit code
2. Run `docker-compose restart <service>` (or let hot-reload work)

### View service configuration
```bash
docker-compose config
docker-compose config | grep -A 20 "service-name:"
```

### Execute one-off command
```bash
docker-compose run --rm core cargo test
docker-compose run --rm backend mix ecto.migrate
```

### Copy files to/from container
```bash
docker cp myfile.txt aws-core:/app/
docker cp aws-core:/app/logs/app.log ./
```

## 🚨 Troubleshooting

### Service won't start
```bash
docker-compose logs <service>
docker-compose ps
docker inspect <container>
```

### Port already in use
```bash
sudo lsof -i :8080
sudo kill -9 <PID>
```

### Out of disk space
```bash
docker system df
docker system prune -a --volumes
```

### Reset specific service
```bash
docker-compose stop <service>
docker-compose rm -f <service>
docker-compose up -d <service>
```

## 📚 Documentation

- Full Guide: `docs/DOCKER_GUIDE.md`
- Summary: `DOCKER_SETUP_SUMMARY.md`
- Architecture: `docs/ARCHITECTURE.md`
- Justfile Help: `just help`
- Justfile Cookbook: `justfile-cookbook.adoc`

## ⚡ Pro Tips

1. Use `just` commands for convenience (300+ recipes available)
2. Check `just help` or `just --list` for all available commands
3. Use `-d` flag for detached mode
4. Use `--build` flag to force rebuild
5. Use `--no-deps` to not start dependent services
6. Use `--scale` to run multiple instances

## 🔥 Emergency

```bash
# Nuclear option - reset everything
just docker-reset

# Graceful stop with volume preservation
just docker-down

# Force remove everything
docker-compose down -v --remove-orphans
docker system prune -af --volumes
```

---

**Last Updated**: 2025-12-01
