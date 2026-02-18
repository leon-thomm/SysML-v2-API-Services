# Docker Deployment Guide

## Quick Start

```bash
# Start services
export DB_PASSWORD=your-secure-password  # Optional, defaults to 'mysecretpassword'
docker compose up

# Access API at http://localhost:9000/docs/
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `postgres` | PostgreSQL hostname |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `sysml2` | Database name |
| `DB_USER` | `postgres` | Database username |
| `DB_PASSWORD` | `mysecretpassword` | Database password |
| `HIBERNATE_DDL_AUTO` | `update` | Schema mode: `update` (recommended), `create`, `create-drop`, `validate`, `none` |
| `PLAY_SECRET_KEY` | auto-generated | Play Framework secret key (change for production) |

**Note**: The default `update` mode creates tables on first run and preserves data between restarts. Use `create-drop` only for testing (drops all data on shutdown).

**Security**: For production, generate a secure secret key with: `head -c 32 /dev/urandom | base64`

Set via `.env` file or shell export before running `docker compose up`.

### Port Configuration

Edit `docker-compose.yml` to change exposed ports:
```yaml
services:
  sysml2-api:
    ports:
      - "8080:9000"  # Access API on port 8080
```

## Common Commands

```bash
# Start in background
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down

# Rebuild after code changes
docker compose build

# Remove volumes (deletes data)
docker compose down -v
```

## Troubleshooting

**Port in use**: Change port mapping in `docker-compose.yml` or stop conflicting service

**Build failures**: Check internet connection, try `docker compose build --no-cache`

**Database connection**: Wait a few seconds for PostgreSQL to initialize

## Production Deployment

**Security**:
- Set strong `DB_PASSWORD` via environment variable
- Don't expose PostgreSQL port publicly
- Use Docker secrets for sensitive data
- Regular backups of `postgres_data` volume

**Pre-built Images**: Once published, pull from GitHub Container Registry:
```bash
docker pull ghcr.io/leon-thomm/sysml-v2-api-services:latest
```
