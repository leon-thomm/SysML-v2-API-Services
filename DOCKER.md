# Docker Deployment Guide for SysML v2 API Services

This guide provides detailed information about deploying and using the SysML v2 API Services with Docker.

## Table of Contents
- [Quick Start](#quick-start)
- [Docker Architecture](#docker-architecture)
- [Building the Docker Image](#building-the-docker-image)
- [Configuration](#configuration)
- [Deployment Options](#deployment-options)
- [Monitoring and Logs](#monitoring-and-logs)
- [Troubleshooting](#troubleshooting)
- [Production Deployment](#production-deployment)

## Quick Start

The fastest way to run the SysML v2 API Services:

```bash
# Clone the repository (adjust URL to match your fork/repository)
git clone https://github.com/leon-thomm/SysML-v2-API-Services.git
cd SysML-v2-API-Services

# Set a secure database password (recommended)
export DB_PASSWORD=your-secure-password

# Start with Docker Compose
docker compose up

# Access the API at http://localhost:9000/docs/
```

## Docker Architecture

The Docker setup consists of two main components:

### 1. PostgreSQL Database (`postgres` service)
- **Image**: PostgreSQL 15 from Docker Hub
- **Port**: 5432
- **Data Persistence**: Uses a named volume `postgres_data`
- **Health Check**: Built-in health check ensures database is ready before API starts

### 2. SysML v2 API Service (`sysml2-api` service)
- **Build**: Multi-stage build using OpenJDK 11
  - **Stage 1 (Builder)**: Compiles the application using sbt
  - **Stage 2 (Runtime)**: Minimal runtime image with only JRE and compiled artifacts
- **Port**: 9000
- **Dependencies**: Waits for PostgreSQL to be healthy before starting

## Building the Docker Image

### Using Docker Compose (Recommended)
Docker Compose automatically builds the image when needed:

```bash
docker compose build
```

### Manual Build
To build the image manually:

```bash
docker build -t sysml2-api:latest .
```

**Note**: The first build takes 10-15 minutes due to:
- Downloading sbt and Scala dependencies
- Compiling the entire application
- Subsequent builds use Docker layer caching and are faster

### Build Arguments
The Dockerfile uses multi-stage builds to optimize image size:
- **Builder stage**: ~1.2 GB (includes JDK and build tools)
- **Runtime stage**: ~400 MB (only JRE and application)

## Configuration

### Environment Variables

The application supports the following environment variables for database configuration:

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `postgres` | PostgreSQL hostname |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `sysml2` | Database name |
| `DB_USER` | `postgres` | Database username |
| `DB_PASSWORD` | `mysecretpassword` | Database password |

### Customizing Configuration

#### Option 1: Using `.env` file
Create a `.env` file in the project root:

```env
DB_HOST=postgres
DB_PORT=5432
DB_NAME=sysml2
DB_USER=myuser
DB_PASSWORD=mypassword
```

#### Option 2: Modify `docker-compose.yml`
Edit the environment section in `docker-compose.yml`:

```yaml
services:
  sysml2-api:
    environment:
      DB_HOST: my-postgres-host
      DB_PASSWORD: my-secure-password
```

#### Option 3: Environment Variables in Shell
```bash
export DB_PASSWORD=mysecurepassword
docker compose up
```

### Port Mapping

To use different ports, modify the port mappings in `docker-compose.yml`:

```yaml
services:
  postgres:
    ports:
      - "15432:5432"  # Access PostgreSQL on port 15432
  
  sysml2-api:
    ports:
      - "8080:9000"   # Access API on port 8080
```

## Deployment Options

### Development Mode
Run with live logs (foreground):
```bash
docker compose up
```

### Production Mode
Run in background (detached):
```bash
docker compose up -d
```

### Scaling (Future Enhancement)
The current setup runs a single instance. For horizontal scaling, you would need to:
1. Configure a load balancer
2. Use a shared database instance
3. Consider session management

## Monitoring and Logs

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f sysml2-api
docker compose logs -f postgres

# Last 100 lines
docker compose logs --tail=100
```

### Container Status
```bash
# View running containers
docker compose ps

# View resource usage
docker stats
```

### Database Access
```bash
# Connect to PostgreSQL container
docker compose exec postgres psql -U postgres -d sysml2

# Run SQL queries
docker compose exec postgres psql -U postgres -d sysml2 -c "SELECT COUNT(*) FROM project;"
```

## Troubleshooting

### Common Issues

#### 1. Port Already in Use
**Error**: `Bind for 0.0.0.0:9000 failed: port is already allocated`

**Solution**: Change the port mapping or stop the conflicting service:
```bash
# Find process using port 9000
lsof -i :9000
# Kill the process or change docker-compose.yml port mapping
```

#### 2. Database Connection Failed
**Error**: `Connection refused` or `FATAL: password authentication failed`

**Solution**: 
- Ensure PostgreSQL container is healthy: `docker compose ps`
- Check environment variables are set correctly
- Wait a few seconds for database initialization

#### 3. Build Failures
**Error**: During `sbt` build

**Solution**:
- Ensure stable internet connection
- Clear Docker build cache: `docker builder prune`
- Try building again: `docker compose build --no-cache`

#### 4. Out of Disk Space
**Solution**:
```bash
# Remove unused Docker resources
docker system prune -a

# Remove old volumes
docker volume prune
```

### Debugging

Enable verbose logging:
```bash
# Run with debug output
docker compose --verbose up

# Check container logs
docker compose logs sysml2-api | grep -i error
```

Inspect container:
```bash
# Execute shell in running container
docker compose exec sysml2-api /bin/bash

# Check environment variables
docker compose exec sysml2-api env

# Check Java process
docker compose exec sysml2-api ps aux
```

## Production Deployment

### Security Considerations

1. **Change Default Passwords**
   - Never use default passwords in production
   - Use strong, randomly generated passwords
   - Consider using Docker secrets or environment variable files

2. **Network Security**
   - Don't expose PostgreSQL port publicly
   - Use reverse proxy (nginx, traefik) for HTTPS
   - Configure firewall rules

3. **Data Persistence**
   - Backup PostgreSQL volume regularly
   - Consider using external database service
   - Implement backup strategy

### Example Production docker-compose.yml

```yaml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: sysml2
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    networks:
      - backend
    # Don't expose port publicly
    
  sysml2-api:
    build: .
    environment:
      DB_HOST: postgres
      DB_USER: ${DB_USER}
      DB_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    depends_on:
      - postgres
    networks:
      - backend
      - frontend
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./certs:/etc/nginx/certs
    networks:
      - frontend
    restart: unless-stopped

secrets:
  db_password:
    file: ./secrets/db_password.txt

networks:
  frontend:
  backend:

volumes:
  postgres_data:
```

### CI/CD with GitHub Actions

The repository includes a GitHub Actions workflow (`.github/workflows/docker-publish.yml`) that:
- Builds the Docker image on every push
- Publishes to GitHub Container Registry (ghcr.io)
- Tags images based on git tags and branches
- Enables easy deployment of pre-built images

To use the published image (adjust repository name as needed):
```bash
# Replace with the actual repository owner/name
docker pull ghcr.io/leon-thomm/sysml-v2-api-services:latest
```

**Note**: The image name will match your GitHub repository structure (`ghcr.io/owner/repository:tag`).

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [SysML v2 API Cookbook](https://github.com/Systems-Modeling/SysML-v2-API-Cookbook)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
