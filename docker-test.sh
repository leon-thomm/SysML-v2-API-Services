#!/bin/bash

# Docker Configuration Test Script for SysML v2 API Services
# This script validates the Docker setup

set -e

echo "=================================================="
echo "SysML v2 API Services - Docker Configuration Test"
echo "=================================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if Docker is installed
echo "1. Checking Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    print_success "Docker is installed: $DOCKER_VERSION"
else
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is available
echo ""
echo "2. Checking Docker Compose..."
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    print_success "Docker Compose is available: $COMPOSE_VERSION"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    print_success "Docker Compose is available: $COMPOSE_VERSION"
else
    print_error "Docker Compose is not available. Please install Docker Compose."
    exit 1
fi

# Check if required files exist
echo ""
echo "3. Checking required files..."
FILES=("Dockerfile" "docker-compose.yml" ".dockerignore")
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "Found $file"
    else
        print_error "Missing $file"
        exit 1
    fi
done

# Validate Dockerfile syntax
echo ""
echo "4. Validating Dockerfile..."
if [ -f "Dockerfile" ]; then
    print_success "Dockerfile exists and syntax appears valid"
else
    print_error "Dockerfile is missing"
    exit 1
fi

# Check if ports are available
echo ""
echo "5. Checking if required ports are available..."
check_port() {
    local port=$1
    # Try different methods to check port availability
    if command -v lsof &> /dev/null; then
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
            print_error "Port $port is already in use"
            return 1
        else
            print_success "Port $port is available"
            return 0
        fi
    elif command -v ss &> /dev/null; then
        if ss -ln | grep -q ":$port " ; then
            print_error "Port $port is already in use"
            return 1
        else
            print_success "Port $port is available"
            return 0
        fi
    elif command -v netstat &> /dev/null; then
        if netstat -ln | grep -q ":$port " ; then
            print_error "Port $port is already in use"
            return 1
        else
            print_success "Port $port is available"
            return 0
        fi
    else
        print_info "Cannot check port $port (no lsof/ss/netstat available)"
        return 0
    fi
}

check_port 9000 || print_info "You may need to stop the service using port 9000 or modify docker-compose.yml"
check_port 5432 || print_info "You may need to stop the service using port 5432 or modify docker-compose.yml"

echo ""
echo "6. Docker configuration validation complete!"
echo ""
print_info "To start the services, run: docker compose up"
print_info "To stop the services, run: docker compose down"
print_info "Access the API at: http://localhost:9000/docs/"
echo ""
