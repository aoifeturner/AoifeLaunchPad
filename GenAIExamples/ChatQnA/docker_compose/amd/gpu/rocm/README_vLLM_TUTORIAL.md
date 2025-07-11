# ChatQnA vLLM Deployment and Evaluation Tutorial

This directory contains a comprehensive tutorial and tools for deploying ChatQnA with vLLM (Vector Large Language Model) on AMD GPUs and performing detailed performance evaluation.

## 📚 Tutorial Materials

### 1. Main Tutorial
- **[TUTORIAL_vLLM_DEPLOYMENT_AND_EVALUATION.md](TUTORIAL_vLLM_DEPLOYMENT_AND_EVALUATION.md)** - Complete step-by-step guide covering:
  - System architecture and components
  - Prerequisites and setup
  - Deployment instructions
  - Performance evaluation
  - Monitoring and troubleshooting
  - Advanced configuration

### 2. Quick Start Scripts

#### Quick Deployment
- **[quick_start_vllm.sh](quick_start_vllm.sh)** - Streamlined deployment script
  ```bash
  ./quick_start_vllm.sh          # Deploy and test
  ./quick_start_vllm.sh deploy   # Deploy only
  ./quick_start_vllm.sh test     # Test only
  ./quick_start_vllm.sh eval     # Run evaluation
  ./quick_start_vllm.sh status   # Show status
  ```

#### Performance Evaluation
- **[performance_evaluation.sh](performance_evaluation.sh)** - Comprehensive performance testing
  ```bash
  ./performance_evaluation.sh comprehensive  # Complete evaluation
  ./performance_evaluation.sh latency        # Measure latency
  ./performance_evaluation.sh throughput     # Measure throughput
  ./performance_evaluation.sh resources      # Monitor resources
  ./performance_evaluation.sh summary        # Generate report
  ```

#### Example Usage
- **[example_usage.sh](example_usage.sh)** - Demonstrate system interaction
  ```bash
  ./example_usage.sh upload      # Upload sample documents
  ./example_usage.sh ask         # Ask sample questions
  ./example_usage.sh batch       # Batch processing demo
  ./example_usage.sh all         # Run all examples
  ```

## 🚀 Quick Start

### Prerequisites
1. **Hardware**: AMD GPU with ROCm support
2. **Software**: Docker, Docker Compose, ROCm 5.0+
3. **Account**: Hugging Face account with API token

### Step 1: Environment Setup
```bash
# Navigate to the directory
cd /home/yw/Desktop/OPEA/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm

# Set your Hugging Face token
export HF_TOKEN="your_token_here"
# Or create .env file
echo "HF_TOKEN=your_token_here" > .env
```

### Step 2: Deploy ChatQnA with vLLM
```bash
# Quick deployment
./quick_start_vllm.sh

# Or use the unified script
./run_chatqna.sh setup-vllm
./run_chatqna.sh start-vllm
```

### Step 3: Test the System
```bash
# Test deployment
./quick_start_vllm.sh test

# Upload sample documents
./example_usage.sh upload

# Ask questions
./example_usage.sh ask
```

### Step 4: Performance Evaluation
```bash
# Run comprehensive evaluation
./performance_evaluation.sh

# Or run specific tests
./performance_evaluation.sh latency
./performance_evaluation.sh throughput
```

## 📊 System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend UI   │    │   Backend API   │    │   vLLM Service  │
│   (Port 5174)   │◄──►│   (Port 8890)   │◄──►│   (Port 18009)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       │
         │              ┌─────────────────┐              │
         │              │   Retriever     │              │
         │              │   (Port 7001)   │              │
         │              └─────────────────┘              │
         │                       │                       │
         ▼                       ▼                       │
┌─────────────────┐    ┌─────────────────┐              │
│   Nginx Proxy   │    │   Redis Vector  │              │
│   (Port 8081)   │    │   (Port 6380)   │              │
└─────────────────┘    └─────────────────┘              │
                                │                       │
                                ▼                       │
                       ┌─────────────────┐              │
                       │   TEI Embedding │              │
                       │   (Port 18091)  │              │
                       └─────────────────┘              │
                                │                       │
                                ▼                       │
                       ┌─────────────────┐              │
                       │   TEI Rerank    │              │
                       │   (Port 18809)  │              │
                       └─────────────────┘              │
```

## 🔧 Service Management

### Using Unified Script
```bash
# Service management
./run_chatqna.sh start-vllm      # Start vLLM services
./run_chatqna.sh stop-vllm       # Stop vLLM services
./run_chatqna.sh restart-vllm    # Restart vLLM services
./run_chatqna.sh status          # Check service status

# Evaluation
./run_chatqna.sh vllm-eval       # Run vLLM evaluation
./run_chatqna.sh compare-eval    # Compare TGI vs vLLM

# Monitoring
./run_chatqna.sh monitor-start   # Start monitoring stack
./run_chatqna.sh monitor-stop    # Stop monitoring stack

# Logs and debugging
./run_chatqna.sh logs-vllm       # View vLLM logs
./run_chatqna.sh cleanup         # Clean up resources
```

### Manual Docker Commands
```bash
# Start services
docker compose -f compose_vllm.yaml up -d

# Check status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep chatqna

# View logs
docker compose -f compose_vllm.yaml logs -f

# Stop services
docker compose -f compose_vllm.yaml down
```

## 📈 Performance Evaluation

### Metrics Measured
- **Latency**: Response time (average, median, min, max)
- **Throughput**: Requests per second
- **Resource Usage**: CPU, GPU, memory consumption
- **Accuracy**: Answer quality (with GenAIEval)

### Evaluation Scripts
```bash
# Comprehensive evaluation
./performance_evaluation.sh

# Specific tests
./performance_evaluation.sh latency 20    # 20 requests
./performance_evaluation.sh throughput 60 3  # 60s, 3 concurrent
./performance_evaluation.sh resources 30 2   # 30s, every 2s

# Generate summary report
./performance_evaluation.sh summary
```

### Results Location
- Results are saved in `./performance_results/`
- Summary reports in Markdown format
- Detailed logs for each test type

## 🛠️ Troubleshooting

### Common Issues

#### 1. GPU Memory Errors
```bash
# Reduce model size in set_env_vllm.sh
export CHATQNA_LLM_MODEL_ID="Qwen/Qwen2.5-7B-Instruct-1M"

# Or modify vLLM parameters in compose_vllm.yaml
--max-model-len 2048 --tensor-parallel-size 1
```

#### 2. Service Startup Failures
```bash
# Check logs
docker compose -f compose_vllm.yaml logs

# Restart services
./run_chatqna.sh restart-vllm
```

#### 3. Redis Index Issues
```bash
# Fix Redis index
./fix_redis_index.sh
```

#### 4. Model Download Failures
```bash
# Check HF token
echo $CHATQNA_HUGGINGFACEHUB_API_TOKEN

# Set token manually
export CHATQNA_HUGGINGFACEHUB_API_TOKEN="your_token_here"
```

### Diagnostic Commands
```bash
# Check system resources
./detect_issues.sh

# Test complete system
./quick_test_chatqna.sh eval-only

# Check service health
docker compose -f compose_vllm.yaml ps
```

## 🔍 Monitoring

### Service Endpoints
- **Frontend**: http://localhost:8081
- **Backend API**: http://localhost:8890
- **vLLM API**: http://localhost:18009
- **Redis Insight**: http://localhost:8002

### Monitoring Stack
```bash
# Start monitoring
./run_chatqna.sh monitor-start

# Access Grafana
# Open browser: http://localhost:3000 (admin/admin)
```

### Resource Monitoring
```bash
# GPU monitoring
rocm-smi --showproductname --showmeminfo --showuse

# Docker container stats
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep chatqna

# System resources
htop
```

## 📝 API Usage Examples

### Ask Questions
```bash
curl -X POST http://localhost:8890/v1/chatqna \
  -H "Content-Type: application/json" \
  -d '{"messages": "What is machine learning?"}'
```

### Upload Documents
```bash
curl -X POST http://localhost:18104/v1/dataprep/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "file_name": "document.txt",
    "content": "Your document content here."
  }'
```

### Batch Processing
```bash
# Use the example script
./example_usage.sh batch
```

## 🔧 Advanced Configuration

### Custom Models
Edit `set_env_vllm.sh`:
```bash
# Change LLM model
export CHATQNA_LLM_MODEL_ID="Qwen/Qwen2.5-14B-Instruct"

# Change embedding model
export CHATQNA_EMBEDDING_MODEL_ID="BAAI/bge-large-en-v1.5"

# Change reranking model
export CHATQNA_RERANK_MODEL_ID="BAAI/bge-reranker-large"
```

### vLLM Optimization
Modify `compose_vllm.yaml`:
```yaml
command: >
  --model ${CHATQNA_LLM_MODEL_ID}
  --swap-space 32
  --disable-log-requests
  --dtype float16
  --tensor-parallel-size 2
  --host 0.0.0.0
  --port 8011
  --max-model-len 8192
  --gpu-memory-utilization 0.9
```

## 📚 Additional Resources

### Documentation
- [Main README](README.md) - General setup and usage
- [Remote Node Setup](REMOTE_NODE_SETUP.md) - Remote deployment guide
- [Scripts README](SCRIPTS_README.md) - Script documentation

### Related Scripts
- `run_chatqna.sh` - Unified management script
- `setup_remote_node.sh` - Automated remote setup
- `fix_redis_index.sh` - Redis index fix
- `quick_test_chatqna.sh` - System testing

## 🎯 Next Steps

1. **Customize Models**: Experiment with different LLM and embedding models
2. **Scale Deployment**: Add multiple GPU nodes for higher throughput
3. **Optimize Performance**: Fine-tune vLLM parameters for your use case
4. **Monitor Production**: Set up comprehensive monitoring for production deployments
5. **Integrate with Applications**: Use the API to integrate ChatQnA into your applications

## 🤝 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the detailed tutorial
3. Check service logs: `docker compose -f compose_vllm.yaml logs`
4. Run diagnostics: `./detect_issues.sh`

---

**Note**: This tutorial assumes you have the necessary permissions and that all required software is installed. For production deployments, consider additional security measures and monitoring solutions. 