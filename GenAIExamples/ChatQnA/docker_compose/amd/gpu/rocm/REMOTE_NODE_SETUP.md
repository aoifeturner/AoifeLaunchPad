# ChatQnA Remote Node Setup Guide

This guide covers setting up ChatQnA on remote nodes, including solutions for common issues encountered during deployment.

## Quick Start

For automated setup, use the provided scripts:

```bash
# Complete setup (recommended)
./setup_remote_node.sh

# Fix Redis index issues
./fix_redis_index.sh

# Test the system
./quick_test_chatqna.sh eval-only
```

## Prerequisites

1. **Docker and Docker Compose** installed
2. **Python 3.8+** installed
3. **Hugging Face Token** - Get one from [Hugging Face Settings](https://huggingface.co/settings/tokens)
4. **Git** to clone the repository

## Step-by-Step Setup

### 1. Clone and Navigate to Directory

```bash
cd /path/to/your/workspace
git clone <repository-url>
cd GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm
```

### 2. Configure Environment

Create or update `.env` file:

```bash
# Create .env file
cat > .env << EOF
HF_TOKEN=your_hugging_face_token_here
EOF
```

**Important**: Ensure there's a space before any comments in the `.env` file:
```bash
# Correct format
HF_TOKEN=hf_your_token_here  # Optional comment

# Incorrect format (will truncate token)
HF_TOKEN=hf_your_token_here#Optional comment
```

### 3. Check for Port Conflicts

Common port conflicts on remote nodes:

- **Port 80**: Often used by Caddy or other web servers
- **Port 5173**: Frontend service
- **Port 8889**: Backend service  
- **Port 7000**: Retriever service

If you encounter port conflicts:

```bash
# Stop Caddy (if running)
sudo systemctl stop caddy

# Or change nginx port in .env files
# Update NGINX_PORT=8080 in relevant .env files
```

### 4. Setup Virtual Environment

```bash
# Create virtual environment
python3 -m venv opea_eval_env

# Activate environment
source opea_eval_env/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r ../../../requirements.txt
```

### 5. Start Services

```bash
# Start all services
docker-compose up -d

# Wait for services to initialize (30-60 seconds)
sleep 30
```

### 6. Fix Redis Index (Critical for Remote Nodes)

Newer Docker images have stricter error handling and require the Redis index to exist:

```bash
# Run the automated fix
./fix_redis_index.sh

# Or manually create the index
docker exec chatqna-redis-vector-db redis-cli FT.CREATE rag-redis ON HASH PREFIX 1 doc: SCHEMA content TEXT WEIGHT 1.0 distance NUMERIC
```

### 7. Test the System

```bash
# Test evaluation
./quick_test_chatqna.sh eval-only

# Access the UI
# Open http://localhost:5173 in your browser
```

## Common Issues and Solutions

### 1. 401 Unauthorized Error (HF Token)

**Symptoms**: 
- Model download fails with 401 error
- `BAAI/bge-base-en-v1.5` download fails

**Solution**:
```bash
# Check token format in .env
cat .env | grep HF_TOKEN

# Ensure proper format with space before comments
HF_TOKEN=hf_your_token_here  # Comment here
```

### 2. Port Conflicts

**Symptoms**:
- Services fail to start
- "Address already in use" errors

**Solutions**:
```bash
# Check what's using the ports
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :5173

# Stop conflicting services
sudo systemctl stop caddy  # If using port 80

# Or change ports in docker-compose.yml
```

### 3. Redis Index Missing

**Symptoms**:
- Retriever service returns 500 errors
- "rag-redis: no such index" in logs

**Solution**:
```bash
# Automated fix
./fix_redis_index.sh

# Manual fix
docker exec chatqna-redis-vector-db redis-cli FT.CREATE rag-redis ON HASH PREFIX 1 doc: SCHEMA content TEXT WEIGHT 1.0 distance NUMERIC
```

### 4. Virtual Environment Issues

**Symptoms**:
- `opea_eval_env/bin/activate` not found
- Python dependencies missing

**Solution**:
```bash
# Remove and recreate environment
rm -rf opea_eval_env
python3 -m venv opea_eval_env
source opea_eval_env/bin/activate
pip install -r ../../../requirements.txt
```

### 5. Service Health Issues

**Check service status**:
```bash
# Check all containers
docker ps

# Check logs
docker-compose logs -f

# Test individual services
curl http://localhost:7000/health  # Retriever
curl http://localhost:8889/health  # Backend
curl http://localhost:5173         # Frontend
```

## Troubleshooting Commands

### Automated Issue Detection
```bash
# Complete detection of all common issues
./detect_issues.sh

# Specific issue checks
./detect_issues.sh redis-only      # Check Redis index
./detect_issues.sh retriever-only  # Test retriever service
./detect_issues.sh backend-only    # Test backend service
./detect_issues.sh cors-only       # Check CORS configuration
./detect_issues.sh logs-only       # Check logs for errors
```

### Manual Issue Detection

**Check Redis Index:**
```bash
docker exec chatqna-redis-vector-db redis-cli FT.INFO rag-redis
# Expected: Index info or "Unknown index name"
```

**Test Retriever Service:**
```bash
curl -X POST http://localhost:7000/v1/retrieval \
  -H "Content-Type: application/json" \
  -d '{"query": "test", "top_k": 3}'
# Expected: {"retrieved_docs":[]} or 500 error
```

**Test Backend Service:**
```bash
curl -X POST http://localhost:8889/v1/chatqna \
  -H "Content-Type: application/json" \
  -d '{"messages": "Hello"}'
# Expected: JSON response or 500 error
```

**Check Logs for Errors:**
```bash
docker-compose logs retriever | grep -i "redis\|index"
# Look for: "rag-redis: no such index"
```

### Check Service Status
```bash
# List running containers
docker ps

# Check service logs
docker-compose logs -f [service-name]

# Restart services
docker-compose restart
```

### Debug Redis Issues
```bash
# Connect to Redis
docker exec -it chatqna-redis-vector-db redis-cli

# Check if index exists
FT.INFO rag-redis

# List all indexes
FT._LIST
```

### Test API Endpoints
```bash
# Test retriever
curl -X POST http://localhost:7000/v1/retrieval \
  -H "Content-Type: application/json" \
  -d '{"query": "test", "top_k": 3}'

# Test backend
curl -X POST http://localhost:8889/v1/chatqna \
  -H "Content-Type: application/json" \
  -d '{"messages": "Hello"}'
```

## Performance Considerations

### GPU Requirements
- Ensure ROCm drivers are installed for AMD GPUs
- Check GPU availability: `rocm-smi`

### Memory Requirements
- Minimum 16GB RAM recommended
- Monitor memory usage: `docker stats`

### Storage Requirements
- Ensure sufficient disk space for Docker images
- Models will be downloaded to `~/.cache/huggingface/`

## Security Notes

1. **HF Token**: Keep your Hugging Face token secure
2. **Port Exposure**: Be careful when exposing ports to external networks
3. **Docker Images**: Use official images from trusted sources

## Maintenance

### Regular Updates
```bash
# Pull latest images
docker-compose pull

# Update services
docker-compose up -d

# Clean up unused images
docker image prune
```

### Backup and Restore
```bash
# Backup Redis data
docker exec chatqna-redis-vector-db redis-cli BGSAVE

# Backup configuration
cp .env .env.backup
```

## Support

If you encounter issues not covered in this guide:

1. Check the logs: `docker-compose logs -f`
2. Verify your environment matches the prerequisites
3. Ensure all ports are available
4. Check that your HF token is valid and properly formatted

## Scripts Reference

### `setup_remote_node.sh`
Complete automated setup script that handles:
- Directory validation
- HF token verification
- Port conflict detection
- Virtual environment setup
- Service startup
- Basic testing

**Usage**:
```bash
./setup_remote_node.sh          # Complete setup
./setup_remote_node.sh check-only  # Only check configuration
./setup_remote_node.sh start-only  # Only start services
```

### `fix_redis_index.sh`
Fixes Redis index issues common on remote nodes with newer Docker images.

**Usage**:
```bash
./fix_redis_index.sh           # Complete fix
./fix_redis_index.sh check-only  # Only check status
./fix_redis_index.sh create-only # Only create index
./fix_redis_index.sh test-only   # Only test services
```

### `quick_test_chatqna.sh`
Tests the complete ChatQnA system.

**Usage**:
```bash
./quick_test_chatqna.sh eval-only  # Run evaluation test
./quick_test_chatqna.sh help       # Show all options
```

### `detect_issues.sh`
Detects common issues on fresh remote node deployments.

**Usage**:
```bash
./detect_issues.sh                 # Complete detection (all checks)
./detect_issues.sh redis-only      # Check Redis index status
./detect_issues.sh retriever-only  # Test retriever service
./detect_issues.sh backend-only    # Test backend service
./detect_issues.sh cors-only       # Check CORS configuration
./detect_issues.sh logs-only       # Check logs for errors
./detect_issues.sh help            # Show all options
``` 