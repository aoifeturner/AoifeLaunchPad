# ChatQnA vLLM Deployment and Performance Evaluation Tutorial

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [System Architecture](#system-architecture)
4. [Deployment Guide](#deployment-guide)
5. [Performance Evaluation](#performance-evaluation)
6. [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
7. [Advanced Configuration](#advanced-configuration)
8. [Troubleshooting](#troubleshooting)

## Overview

ChatQnA is a Retrieval-Augmented Generation (RAG) system that combines document retrieval with LLM inference. This tutorial provides a comprehensive guide for deploying ChatQnA using vLLM on AMD GPUs with ROCm support, and performing pipeline performance evaluation.

### Key Features
- **vLLM Integration**: LLM serving with optimized inference on AMD Instinct GPUs
- **AMD GPU Support**: ROCm-based GPU acceleration
- **Vector Search**: Redis-based document retrieval
- **RAG Pipeline**: Complete question-answering system
- **Performance Monitoring**: Built-in metrics and evaluation tools

## Prerequisites
- **AMD Developer Cloud**: 1xMI300X GPU / 192 GB VRAM / 20 vCPU / 240 GB RAM Droplet
- **Hugging Face Token**: For model access

## System Architecture

### Service Components

The following is the complete system architecture diagram.

**Architecture Overview:**

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│                               EXTERNAL ACCESS                                     │
│                                                                                   │
│   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────────┐   │
│   │   Web Browser   │    │   API Clients   │    │      Monitoring Tools       │   │
│   │                 │    │                 │    │    (Grafana, Prometheus)    │   │
│   └─────────────────┘    └─────────────────┘    └─────────────────────────────┘   │
│           │                       │                           │                   │
│           │                       │                           │                   │
│           ▼                       ▼                           ▼                   │
│   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────────┐   │
│   │   Nginx Proxy   │    │   Backend API   │    │        Redis Insight        │   │
│   │   (Port 8081)   │    │   (Port 8890)   │    │         (Port 8002)         │   │
│   └─────────────────┘    └─────────────────┘    └─────────────────────────────┘   │
│           │                       │                           │                   │
│           │                       │                           │                   │
│           ▼                       ▼                           ▼                   │
│   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────────┐   │
│   │   Frontend UI   │    │     Backend     │    │   Redis Vector Database     │   │
│   │   (Port 5174)   │    │     Server      │    │         (Port 6380)         │   │
│   │   (React App)   │    │    (FastAPI)    │    │      (Vector Storage)       │   │
│   └─────────────────┘    └─────────────────┘    └─────────────────────────────┘   │
│                                   │                           │                   │
│                                   │                           │                   │
│                                   ▼                           ▼                   │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │                             RAG PIPELINE                                    │  │
│  │                                                                             │  │
│  │  ┌───────────────────┐ ┌─────────────────────┐ ┌─────────────────────────┐  │  │
│  │  │ Retriever Service │ │TEI Embedding Service│ │  TEI Reranking Service  │  │  │
│  │  │                   │ │                     │ │                         │  │  │
│  │  │   (Port 7001)     │ │    (Port 18091)     │ │      (Port 18809)       │  │  │
│  │  │                   │ │                     │ │                         │  │  │
│  │  │ • Vector Search   │ │ • Text Embedding    │ │ • Document Reranking    │  │  │
│  │  │ • Similarity      │ │ • BGE Model         │ │ • Relevance Scoring     │  │  │
│  │  │   Matching        │ │ • CPU Inference     │ │ • CPU Inference         │  │  │
│  │  └───────────────────┘ └─────────────────────┘ └─────────────────────────┘  │  │
│  │            │                      │                         │               │  │
│  │            │                      │                         │               │  │
│  │            ▼                      ▼                         ▼               │  │
│  │  ┌───────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                           vLLM Service                                │  │  │
│  │  │                           (Port 18009)                                │  │  │
│  │  │                                                                       │  │  │
│  │  │                  • High-Performance LLM Inference                     │  │  │
│  │  │                  • AMD GPU Acceleration (ROCm)                        │  │  │
│  │  │                  • Qwen2.5-7B-Instruct Model                          │  │  │
│  │  │                  • Optimized for Throughput & Latency                 │  │  │
│  │  │                  • Tensor Parallel Support                            │  │  │
│  │  └───────────────────────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
│                                      │                                            │
│                                      │                                            │
│                                      ▼                                            │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │                            DATA PIPELINE                                    │  │
│  │                                                                             │  │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐  │  │
│  │  │   Dataprep      │    │   Model Cache   │    │   Document Storage      │  │  │
│  │  │   Service       │    │   (./data)      │    │   (Redis Vector DB)     │  │  │
│  │  │   (Port 18104)  │    │                 │    │                         │  │  │
│  │  │                 │    │ • Downloaded    │    │ • Vector Embeddings     │  │  │
│  │  │ • Document      │    │   Models        │    │ • Metadata Index        │  │  │
│  │  │   Processing    │    │ • Model Weights │    │ • Full-Text Search      │  │  │
│  │  │ • Text          │    │ • Cache Storage │    │ • Similarity Search     │  │  │
│  │  │   Extraction    │    │ • Shared Volume │    │ • Redis Stack           │  │  │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────────┘
```

**Additional Services:**
- **Dataprep Service** (Port 18104): Document processing and ingestion
- **Redis Insight** (Port 8002): Database monitoring interface
- **Model Cache** (./data): Shared volume for model storage

### Data Flow
1. **User Input**: Question submitted via frontend
2. **Embedding**: Question converted to vector using TEI service
3. **Retrieval**: Similar documents retrieved from Redis vector database
4. **Reranking**: Retrieved documents reranked for relevance
5. **LLM Inference**: vLLM generates answer using retrieved context
6. **Response**: Answer returned to user via frontend

## Deployment Guide

### Step 1: Pull source code from GitHub 

Open Platform for Enterprise AI (OPEA):
```bash
git clone https://github.com/opea-project/GenAIExamples.git
```
One click deployment scripts for the use case:
```bash
git clone https://github.com/Yu-amd/LaunchPad.git
```

The LaunchPad project uses the same hierarchy as OPEA project. You need to copy the scripts and yaml files from the directory: LaunchPad/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm/ to the corresponding directory in OPEA folder:
```bash
# Copy necessary scrips and configuration files to the OPEA directory
cp *.sh *.yaml /path/to/OPEA/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm/
```

### Step 2: Environment Setup

Navigate to the OPEA deployment directory:
```bash
cd /path/to/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm
```
Set up your Hugging Face token and environment:
```bash
# Edit the following line in set_env_vllm.sh with your Hugging Face Token
export CHATQNA_HUGGINGFACEHUB_API_TOKEN="your hugging face token"

# Save and exit the file
# Source the vLLM environment configuration
source set_env_vllm.sh
```

### Step 3: Deploy Services

#### Option A: Using the Unified Script (Recommended)
```bash
# Setup vLLM environment
./run_chatqna.sh setup-vllm

![set_env_vllm.sh output](img/set_env_vllm_output.png)

# Start vLLM services
./run_chatqna.sh start-vllm

![start vllm service output](img/start-vllm_output.png)

# Check service status
./run_chatqna.sh status
```

#### Option B: Manual Deployment
```bash
# Source environment variables
source set_env_vllm.sh

# Start all services
docker compose -f compose_vllm.yaml up -d

# Check service status
docker ps
```

### Step 4: Verify Deployment

Check that all services are running:
```bash
# Check running containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test backend API
curl -X POST http://localhost:8890/v1/chatqna \
  -H "Content-Type: application/json" \
  -d '{"messages": "Hello, how are you?"}'

# Access the web interface
# Open browser: http://localhost:8081
```

### Step 5: Upload Documents

Upload documents for the RAG system:
```bash
# Test document upload
curl -X POST http://localhost:18104/v1/dataprep/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "file_name": "test_document.txt",
    "content": "This is a test document for the ChatQnA system."
  }'
```

## Performance Evaluation

### Overview

Performance evaluation helps you understand:
- **Throughput**: Requests per second
- **Latency**: Response time
- **Accuracy**: Answer quality
- **Resource Usage**: CPU, GPU, memory utilization

### Step 1: Setup Evaluation Environment

```bash
# Navigate to evaluation directory
cd /home/yw/Desktop/OPEA/GenAIEval

# Create virtual environment
python3 -m venv opea_eval_env
source opea_eval_env/bin/activate

# Install evaluation dependencies
pip install -r requirements.txt
pip install -e .
```

### Step 2: Run Basic Evaluation

#### Using the Automated Script
```bash
# Run vLLM evaluation
./run_chatqna.sh vllm-eval

# Run comparison between TGI and vLLM
./run_chatqna.sh compare-eval
```

#### Manual Evaluation
```bash
# Activate evaluation environment
source opea_eval_env/bin/activate

# Run evaluation
python -m genaieval.evaluators.chatqna_evaluator \
  --backend_url http://localhost:8890/v1/chatqna \
  --eval_dataset path/to/evaluation/dataset \
  --output_dir /path/to/results
```

### Step 3: Performance Metrics

#### Throughput Testing
```bash
# Test concurrent requests
ab -n 100 -c 10 -p test_data.json -T application/json \
  http://localhost:8890/v1/chatqna
```

#### Latency Testing
```bash
# Measure response times
curl -w "@curl-format.txt" -X POST http://localhost:8890/v1/chatqna \
  -H "Content-Type: application/json" \
  -d '{"messages": "What is machine learning?"}'
```

### Step 4: Resource Monitoring

#### GPU Monitoring
```bash
# Monitor GPU usage
watch -n 1 'rocm-smi'

# Monitor GPU memory
rocm-smi --showproductname --showmeminfo
```

#### System Monitoring
```bash
# Monitor system resources
htop

# Monitor Docker containers
docker stats
```

### Step 5: Evaluation Results

Evaluation results include:
- **Response Time**: Average, median, 95th percentile
- **Throughput**: Requests per second
- **Accuracy**: Answer quality metrics
- **Resource Usage**: CPU, GPU, memory consumption

## Monitoring and Troubleshooting

### Service Monitoring

#### Check Service Status
```bash
# Check all services
./run_chatqna.sh status

# Check specific service logs
docker compose -f compose_vllm.yaml logs -f chatqna-vllm-service
```

#### Monitor Performance
```bash
# Start monitoring stack
./run_chatqna.sh monitor-start

# Access Grafana dashboard
# Open browser: http://localhost:3000 (admin/admin)
```

### Common Issues and Solutions

#### Issue 1: GPU Memory Errors
**Symptoms**: `CUDA out of memory` or similar errors
**Solution**:
```bash
# Reduce batch size in vLLM configuration
# Edit compose_vllm.yaml, modify vLLM service command:
--max-model-len 2048 --tensor-parallel-size 1
```

#### Issue 2: Service Startup Failures
**Symptoms**: Services fail to start or remain in "starting" state
**Solution**:
```bash
# Check logs for specific errors
docker compose -f compose_vllm.yaml logs

# Restart services
./run_chatqna.sh restart-vllm
```

#### Issue 3: Redis Index Issues
**Symptoms**: Retrieval service fails to find documents
**Solution**:
```bash
# Fix Redis index
./fix_redis_index.sh

# Recreate index manually
docker exec chatqna-redis-vector-db redis-cli FT.CREATE rag-redis ON HASH PREFIX 1 doc: SCHEMA content TEXT WEIGHT 1.0 distance NUMERIC
```

#### Issue 4: Model Download Failures
**Symptoms**: Services fail to download models
**Solution**:

```bash
# Check HF token
echo $CHATQNA_HUGGINGFACEHUB_API_TOKEN

# Set token manually
export CHATQNA_HUGGINGFACEHUB_API_TOKEN="your_token_here"
```

## Advanced Configuration

### Custom Model Configuration

Edit `set_env_vllm.sh` to use different models:

```bash
# Change LLM model
export CHATQNA_LLM_MODEL_ID="Qwen/Qwen2.5-14B-Instruct"

# Change embedding model
export CHATQNA_EMBEDDING_MODEL_ID="BAAI/bge-large-en-v1.5"

# Change reranking model
export CHATQNA_RERANK_MODEL_ID="BAAI/bge-reranker-large"
```

### vLLM Optimization

Modify vLLM service configuration in `compose_vllm.yaml`:

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

### Network Configuration

For remote access, configure firewall:
```bash
# Allow required ports
sudo ufw allow 8081/tcp  # Nginx
sudo ufw allow 8890/tcp  # Backend API
sudo ufw allow 18009/tcp # vLLM API
```

## Troubleshooting

### Diagnostic Commands

```bash
# Check system resources
./detect_issues.sh

# Test complete system
./quick_test_chatqna.sh eval-only

# Check service health
docker compose -f compose_vllm.yaml ps
```

### Log Analysis

```bash
# View all logs
docker compose -f compose_vllm.yaml logs

# Follow specific service logs
docker compose -f compose_vllm.yaml logs -f chatqna-vllm-service

# Check for errors
docker compose -f compose_vllm.yaml logs | grep -i error
```

## Conclusion

This tutorial provides a comprehensive guide for deploying ChatQnA with vLLM on AMD GPUs and performing detailed performance evaluation. The system offers:

- **High Performance**: vLLM-optimized inference
- **Scalability**: Docker-based microservices architecture
- **Monitoring**: Built-in performance metrics
- **Flexibility**: Configurable models and parameters

For additional support or advanced configurations, refer to the project documentation or create issues in the repository.

### Next Steps

1. **Customize Models**: Experiment with different LLM and embedding models
2. **Scale Deployment**: Add multiple GPU nodes for higher throughput
3. **Optimize Performance**: Fine-tune vLLM parameters for your specific use case
4. **Monitor Production**: Set up comprehensive monitoring for production deployments

### Useful Commands Reference

```bash
# Service Management
./run_chatqna.sh start-vllm      # Start vLLM services
./run_chatqna.sh stop-vllm       # Stop vLLM services
./run_chatqna.sh restart-vllm    # Restart vLLM services
./run_chatqna.sh status          # Check service status

# Evaluation
./run_chatqna.sh vllm-eval       # Run vLLM evaluation
./run_chatqna.sh compare-eval    # Compare TGI vs vLLM
./run_chatqna.sh quick-eval      # Quick evaluation

# Monitoring
./run_chatqna.sh monitor-start   # Start monitoring stack
./run_chatqna.sh monitor-stop    # Stop monitoring stack

# Logs and Debugging
./run_chatqna.sh logs-vllm       # View vLLM logs
./run_chatqna.sh cleanup         # Clean up resources
```

---

**Note**: This tutorial assumes you have the necessary permissions and that all required software is installed. For production deployments, consider additional security measures and monitoring solutions. 
