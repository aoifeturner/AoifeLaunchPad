# ChatQnA Docker Compose Setup

This directory contains the Docker Compose configuration for running ChatQnA with AMD GPU support using ROCm.

## Quick Start

### Automated Setup (Recommended for Remote Nodes)

For new remote node deployments, use the automated setup script:

```bash
# Complete setup including Redis index fix
./setup_remote_node.sh

# Fix Redis index issues (if needed)
./fix_redis_index.sh

# Test the system
./quick_test_chatqna.sh eval-only
```

### Manual Setup

1. **Configure Environment**
   ```bash
   # Create .env file with your Hugging Face token
   echo "HF_TOKEN=your_token_here" > .env
   ```

2. **Start Services**
   ```bash
   docker-compose up -d
   ```

3. **Fix Redis Index** (Required for remote nodes with newer Docker images)
   ```bash
   ./fix_redis_index.sh
   ```

4. **Test the System**
   ```bash
   ./quick_test_chatqna.sh eval-only
   ```

## Services

The following services are included:

- **Frontend**: React application (Port 5173)
- **Backend**: FastAPI server (Port 8889)
- **Retriever**: Vector search service (Port 7000)
- **Redis**: Vector database (Port 6379)
- **Nginx**: Reverse proxy (Port 8080) - Changed from 80 to avoid conflicts

## Port Configuration

**Note**: The nginx port has been changed from 80 to 8080 to avoid conflicts with common web servers like Caddy on remote nodes.

- Frontend: http://localhost:5173
- Backend API: http://localhost:8889
- Retriever API: http://localhost:7000
- Nginx Proxy: http://localhost:8080 (redirects to frontend)

## Common Issues

### 1. Port Conflicts
If you encounter port conflicts (especially on port 80), the nginx port has been changed to 8080. If you need to change it back:

```bash
# Edit the relevant .env files to change NGINX_PORT back to 80
# Or stop conflicting services like Caddy:
sudo systemctl stop caddy
```

### 2. Redis Index Missing
Newer Docker images require the Redis index to exist before the retriever service starts:

```bash
# Automated fix
./fix_redis_index.sh

# Manual fix
docker exec chatqna-redis-vector-db redis-cli FT.CREATE rag-redis ON HASH PREFIX 1 doc: SCHEMA content TEXT WEIGHT 1.0 distance NUMERIC
```

### 3. HF Token Issues
Ensure your Hugging Face token is properly formatted in the `.env` file:

```bash
# Correct format
HF_TOKEN=hf_your_token_here  # Optional comment

# Incorrect format (will truncate token)
HF_TOKEN=hf_your_token_here#Optional comment
```

## Scripts

### `setup_remote_node.sh`
Complete automated setup script for remote nodes that handles:
- Environment validation
- Port conflict detection
- Virtual environment setup
- Service startup
- Basic testing

### `fix_redis_index.sh`
Fixes Redis index issues common on remote nodes with newer Docker images.

### `quick_test_chatqna.sh`
Tests the complete ChatQnA system.

### `detect_issues.sh`
Detects common issues on fresh remote node deployments.

## Documentation

For detailed setup instructions and troubleshooting, see:
- [Remote Node Setup Guide](REMOTE_NODE_SETUP.md) - Comprehensive guide for remote deployments
- [Troubleshooting Guide](REMOTE_NODE_SETUP.md#troubleshooting-commands) - Common issues and solutions

## Development

### Building Images
```bash
docker-compose build
```

### Viewing Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend-server
```

### Stopping Services
```bash
docker-compose down
```

## Requirements

- Docker and Docker Compose
- AMD GPU with ROCm drivers
- Hugging Face token for model downloads
- Python 3.8+ (for evaluation scripts)
