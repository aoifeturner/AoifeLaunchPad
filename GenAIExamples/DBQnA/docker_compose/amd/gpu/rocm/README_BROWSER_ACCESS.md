# DBQnA Browser Access Guide

This guide provides step-by-step instructions for launching DBQnA and accessing it through a web browser on your DigitalOcean droplet with AMD ROCm GPU.

## 🚀 Quick Start

### 1. Setup Environment

First, set up the environment variables:

```bash
cd AoifeLaunchPad/GenAIExamples/DBQnA/docker_compose/amd/gpu/rocm/
source set_env_complete.sh
```

### 2. Setup Firewall (DigitalOcean Droplet)

Open the necessary ports in UFW:

```bash
sudo bash firewall_setup.sh
```

This will open the following ports:
- 22 (SSH) - already open
- 80 (HTTP) - already open  
- 443 (HTTPS) - already open
- 8889 (DBQnA Backend)
- 5174 (DBQnA Frontend)
- 8008 (TGI Service)
- 9090 (Text-to-SQL Service)
- 5442 (PostgreSQL)
- 8080 (Nginx - optional)

### 3. Launch DBQnA

Use the unified management script:

```bash
# Setup environment
./run_dbqna.sh setup

# Start services
./run_dbqna.sh start

# Check status
./run_dbqna.sh status
```

### 4. Access via Browser

Once services are running, you can access DBQnA through your browser:

- **Frontend UI**: `http://YOUR_DROPLET_IP:5174`
- **Backend API**: `http://YOUR_DROPLET_IP:8889/v1/dbqna`
- **Text-to-SQL API**: `http://YOUR_DROPLET_IP:9090/v1/texttosql`
- **TGI Service**: `http://YOUR_DROPLET_IP:8008`
- **PostgreSQL**: `YOUR_DROPLET_IP:5442`

## 📋 Service Architecture

DBQnA consists of the following microservices:

| Service | Port | Description |
|---------|------|-------------|
| PostgreSQL | 5442 | Database backend with Chinook sample data |
| TGI Service | 8008 | LLM inference service (Mistral-7B) |
| Text-to-SQL | 9090 | Converts natural language to SQL |
| UI Server | 5174 | React-based web interface |
| Backend | 8889 | Additional API endpoints (optional) |
| Nginx | 8080 | Reverse proxy (optional) |

## 🔧 Management Commands

The `run_dbqna.sh` script provides comprehensive management:

```bash
# Setup environment
./run_dbqna.sh setup

# Start all services
./run_dbqna.sh start

# Stop all services
./run_dbqna.sh stop

# Restart all services
./run_dbqna.sh restart

# Check service status
./run_dbqna.sh status

# Check service health
./run_dbqna.sh health

# View logs (all services)
./run_dbqna.sh logs

# View logs for specific service
./run_dbqna.sh logs dbqna-tgi-service

# Test API endpoints
./run_dbqna.sh test

# Setup firewall (requires sudo)
sudo ./run_dbqna.sh firewall
```

## 🧪 Testing

### Manual API Testing

Test the Text-to-SQL API directly:

```bash
curl http://YOUR_DROPLET_IP:9090/v1/texttosql \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{
        "input_text": "Find the total number of Albums.",
        "conn_str": {
            "user": "postgres",
            "password": "testpwd",
            "host": "YOUR_DROPLET_IP",
            "port": "5442",
            "database": "chinook"
        }
    }'
```

### Automated Testing

Run the comprehensive test script:

```bash
python3 test_dbqna_api.py http://YOUR_DROPLET_IP
```

## 🌐 Browser Access Examples

### Frontend UI

1. Open your browser and navigate to: `http://YOUR_DROPLET_IP:5174`
2. You should see the DBQnA interface
3. Enter natural language queries like:
   - "Find the total number of Albums"
   - "Show me all artists from the database"
   - "What is the average track length?"
   - "List all customers from Germany"

### API Endpoints

You can also test the APIs directly in your browser:

- **Health Check**: `http://YOUR_DROPLET_IP:8008/health`
- **Text-to-SQL**: `http://YOUR_DROPLET_IP:9090/v1/texttosql`
- **Backend**: `http://YOUR_DROPLET_IP:8889/v1/dbqna`

## 🔍 Troubleshooting

### Check Service Status

```bash
# Check all containers
docker ps -a

# Check specific service logs
./run_dbqna.sh logs dbqna-tgi-service

# Check service health
./run_dbqna.sh health
```

### Common Issues

1. **Port Already in Use**: Stop conflicting services or change ports in `set_env_complete.sh`
2. **GPU Not Found**: Ensure ROCm drivers are installed and `/dev/kfd` exists
3. **Database Connection Failed**: Check if PostgreSQL container is running
4. **Model Download Issues**: Check internet connection and HF token

### Reset Everything

```bash
# Stop all services
./run_dbqna.sh stop

# Remove all containers and volumes
docker-compose -f compose_complete.yaml down -v

# Clean up Docker system
docker system prune -f

# Restart from scratch
./run_dbqna.sh setup
./run_dbqna.sh start
```

## 📊 Monitoring

### Service Health

Monitor service health in real-time:

```bash
# Watch service status
watch -n 5 './run_dbqna.sh status'

# Monitor logs
./run_dbqna.sh logs
```

### Resource Usage

Check resource usage:

```bash
# Docker resource usage
docker stats

# GPU usage (ROCm)
rocm-smi

# System resources
htop
```

## 🔐 Security Notes

- The default PostgreSQL password is `testpwd` - change this in production
- Only necessary ports are opened in the firewall
- Consider using HTTPS in production
- Regularly update Docker images and system packages

## 📝 Sample Queries

Try these sample queries in the UI:

1. **Basic Queries**:
   - "Find the total number of Albums"
   - "Show me all artists"
   - "List all customers"

2. **Complex Queries**:
   - "What is the average track length?"
   - "How many tracks are there in the Rock genre?"
   - "Show me customers from Germany"
   - "Find albums by Queen"

3. **Analytics Queries**:
   - "What is the total revenue by country?"
   - "Which genre has the most tracks?"
   - "Show me the top 5 artists by album count"

## 🎯 Next Steps

1. **Customize the Database**: Replace `chinook.sql` with your own database schema
2. **Change the Model**: Update `DBQNA_LLM_MODEL_ID` in `set_env_complete.sh`
3. **Add Authentication**: Implement user authentication for production use
4. **Scale Up**: Use multiple GPU instances for higher throughput
5. **Monitor Performance**: Set up monitoring and alerting

## 📞 Support

If you encounter issues:

1. Check the logs: `./run_dbqna.sh logs`
2. Verify firewall settings: `sudo ufw status`
3. Test individual services: `./run_dbqna.sh health`
4. Check system resources: `docker stats` and `rocm-smi`

For more information, refer to the main DBQnA documentation and the OPEA project resources. 