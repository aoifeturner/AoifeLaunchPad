# ChatQnA Docker Compose Setup

This directory contains the Docker Compose configuration for running ChatQnA with AMD GPU support using ROCm.

## Quick Start

### Unified Management Script (Recommended)

Use the unified `run_chatqna.sh` script for all operations:

```bash
# Interactive menu with all options
./run_chatqna.sh menu

# Or use direct commands:
./run_chatqna.sh setup-tgi      # Setup TGI environment
./run_chatqna.sh setup-vllm     # Setup vLLM environment
./run_chatqna.sh start-tgi      # Start TGI services
./run_chatqna.sh start-vllm     # Start vLLM services
./run_chatqna.sh tgi-eval       # Run TGI evaluation
./run_chatqna.sh vllm-eval      # Run vLLM evaluation
./run_chatqna.sh compare-eval   # Compare TGI vs vLLM
```

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
   docker compose up -d
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

The following services are included for both TGI and vLLM configurations:

### TGI Services (compose.yaml)
- **Frontend**: React application (Port 5173)
- **Backend**: FastAPI server (Port 8889)
- **Retriever**: Vector search service (Port 7000)
- **Redis**: Vector database (Port 6379)
- **TGI**: Text Generation Inference (Port 80)
- **Nginx**: Reverse proxy (Port 8080)

### vLLM Services (compose_vllm.yaml)
- **Frontend**: React application (Port 5174)
- **Backend**: FastAPI server (Port 8890)
- **Retriever**: Vector search service (Port 7001)
- **Redis**: Vector database (Port 6380)
- **vLLM**: Vector Large Language Model (Port 18009)
- **Nginx**: Reverse proxy (Port 8081)

## Port Configuration

**Note**: The nginx port has been changed from 80 to 8080/8081 to avoid conflicts with common web servers like Caddy on remote nodes.

### TGI Configuration
- Frontend: http://localhost:5173
- Backend API: http://localhost:8889
- Retriever API: http://localhost:7000
- TGI API: http://localhost:80
- Nginx Proxy: http://localhost:8080 (redirects to frontend)

### vLLM Configuration
- Frontend: http://localhost:5174
- Backend API: http://localhost:8890
- Retriever API: http://localhost:7001
- vLLM API: http://localhost:18009
- Nginx Proxy: http://localhost:8081 (redirects to frontend)

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

### `run_chatqna.sh` (Recommended)
Unified management script for all ChatQnA operations:
- **Environment Setup**: `setup-tgi`, `setup-vllm`, `setup-light`
- **Service Management**: `start-tgi`, `start-vllm`, `stop-tgi`, `stop-vllm`
- **Evaluation**: `tgi-eval`, `vllm-eval`, `compare-eval`, `quick-eval`, `full-eval`
- **Monitoring**: `monitor-start`, `monitor-stop`
- **Logs & Status**: `logs-tgi`, `logs-vllm`, `status`, `cleanup`
- **Interactive Menu**: `menu` for easy navigation

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
# TGI services
docker compose -f compose.yaml build

# vLLM services
docker compose -f compose_vllm.yaml build
```

### Viewing Logs
```bash
# All TGI services
docker compose -f compose.yaml logs -f

# All vLLM services
docker compose -f compose_vllm.yaml logs -f

# Specific service
docker compose -f compose.yaml logs -f backend-server
docker compose -f compose_vllm.yaml logs -f backend-server
```

### Stopping Services
```bash
# TGI services
docker compose -f compose.yaml down

# vLLM services
docker compose -f compose_vllm.yaml down

# All services (using unified script)
./run_chatqna.sh cleanup
```

## Requirements

- Docker and Docker Compose (v2+)
- AMD GPU with ROCm drivers
- Hugging Face token for model downloads
- Python 3.8+ (for evaluation scripts)
- Sufficient RAM (16GB+ recommended)
- Sufficient disk space for model downloads
