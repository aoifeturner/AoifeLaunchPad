# ChatQnA One-Click Deployment

This directory contains all the scripts needed to manage the ChatQnA system on AMD Ryzen.

**📍 Current Location:** `/home/yw/Desktop/OPEA/LaunchPad/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm/`

## Main Management Script

### `run_chatqna.sh` - Unified Management Interface
The main script that provides a unified interface for all ChatQnA operations.

**Usage:**
```bash
# Interactive menu
./run_chatqna.sh

# Command line options
./run_chatqna.sh setup          # Setup environment
./run_chatqna.sh setup-light    # Setup lightweight environment
./run_chatqna.sh start          # Start services
./run_chatqna.sh stop           # Stop services
./run_chatqna.sh restart        # Restart services
./run_chatqna.sh monitor-start  # Start monitoring
./run_chatqna.sh monitor-stop   # Stop monitoring
./run_chatqna.sh quick-eval     # Run quick evaluation
./run_chatqna.sh full-eval      # Setup full evaluation
./run_chatqna.sh benchmark      # Run GenAIEval benchmark
./run_chatqna.sh logs           # Show service logs
./run_chatqna.sh monitor-logs   # Show monitoring logs
./run_chatqna.sh status         # Check service status
./run_chatqna.sh cleanup        # Clean up all services
./run_chatqna.sh help           # Show help
```

## Environment Setup Scripts

### `set_env.sh` - Standard Environment Setup
Sets up environment variables for the standard ChatQnA configuration.

**Usage:**
```bash
source set_env.sh
```

### `set_env_lightweight.sh` - Lightweight Environment Setup
Sets up environment variables for lightweight testing with smaller models.

**Usage:**
```bash
source set_env_lightweight.sh
```

## Monitoring Scripts

### `start_monitoring.sh` - Start Monitoring Stack
Starts Prometheus and Grafana for monitoring ChatQnA services.

**Usage:**
```bash
./start_monitoring.sh
```

**Access URLs:**
- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090

### `restart_telemetry.sh` - Restart Telemetry Services
Restarts the telemetry and monitoring services.

**Usage:**
```bash
./restart_telemetry.sh
```

## Evaluation Scripts

### `quick_test_chatqna.sh` - Quick Evaluation
Runs a quick evaluation of the ChatQnA system.

**Usage:**
```bash
./quick_test_chatqna.sh
```

### `quick_eval_setup.sh` - Full Evaluation Setup
Sets up the environment for running full evaluations with the GenAIEval framework.

**Usage:**
```bash
./quick_eval_setup.sh
```

### `run_genaieval_benchmark.sh` - GenAIEval Benchmark
Runs comprehensive load testing using the GenAIEval framework.

**Usage:**
```bash
./run_genaieval_benchmark.sh
```

**Features:**
- Tests 12 different concurrency levels (1-2048 users)
- Uses Qwen/Qwen2.5-7B-Instruct-1M model
- Generates detailed performance metrics
- Handles gated models gracefully

## Docker Compose Files

### `compose.yaml` - Main Services
The main docker-compose file for ChatQnA services.

### `compose.telemetry.yaml` - Monitoring Services
Docker-compose file for monitoring stack (Prometheus, Grafana, cAdvisor).

## Quick Start Guide

1. **Setup Environment:**
   ```bash
   cd /home/yw/Desktop/OPEA/LaunchPad/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm/
   ./run_chatqna.sh setup
   ```

2. **Start Services:**
   ```bash
   ./run_chatqna.sh start
   ```

3. **Start Monitoring (Optional):**
   ```bash
   ./run_chatqna.sh monitor-start
   ```

4. **Run Quick Test:**
   ```bash
   ./run_chatqna.sh quick-eval
   ```

5. **Run Benchmark (Optional):**
   ```bash
   ./run_chatqna.sh benchmark
   ```

6. **Check Status:**
   ```bash
   ./run_chatqna.sh status
   ```

7. **View Logs:**
   ```bash
   ./run_chatqna.sh logs
   ```

## Common Operations

### Starting Everything
```bash
./run_chatqna.sh setup
./run_chatqna.sh start
./run_chatqna.sh monitor-start
```

### Stopping Everything
```bash
./run_chatqna.sh stop
./run_chatqna.sh monitor-stop
```

### Restarting Services
```bash
./run_chatqna.sh restart
```

### Running Evaluation
```bash
# Quick evaluation
./run_chatqna.sh quick-eval

# Full evaluation setup
./run_chatqna.sh full-eval

# GenAIEval benchmark
./run_chatqna.sh benchmark
```

### Monitoring
```bash
# Start monitoring
./run_chatqna.sh monitor-start

# Check monitoring logs
./run_chatqna.sh monitor-logs

# Access Grafana dashboard
# Open http://localhost:3000 in your browser
# Username: admin, Password: admin
```

## Recent Updates & Fixes

### ✅ Benchmark Integration (Latest)
- **Fixed**: Hugging Face authentication issues with gated models
- **Updated**: Model configuration to use `Qwen/Qwen2.5-7B-Instruct-1M`
- **Added**: Graceful error handling for tokenizer loading
- **Fixed**: Locustfile path issues in GenAIEval framework
- **Enhanced**: Benchmark script with comprehensive load testing

### ✅ Monitoring Stack
- **Fixed**: Docker network configuration issues
- **Updated**: Prometheus scrape configurations
- **Enhanced**: Grafana dashboards with proper container labels
- **Added**: Unified monitoring dashboard for all microservices

### ✅ Service Management
- **Unified**: All scripts into single management interface
- **Enhanced**: Error handling and logging
- **Added**: Interactive menu for easy navigation

## Tested Hardware Configuration

The following configuration has been tested and validated for AMD GPU deployment:

### System Specifications

| **Component** | **Specification** |
|---------------|-------------------|
| **CPU** | AMD Ryzen AI 9 HX 370 w/ Radeon 890M |
| **Architecture** | x86_64 |
| **Cores/Threads** | 12 cores, 24 threads |
| **Memory** | 93GB RAM |
| **Storage** | 8GB Swap available |
| **Operating System** | Ubuntu 24.04 LTS |
| **Kernel** | 6.11.0-28-generic |
| **Docker Version** | 28.2.2 |

### GPU & AI Acceleration

| **Component** | **Specification** |
|---------------|-------------------|
| **Integrated GPU** | AMD Radeon 890M |
| **GPU Architecture** | AMD RDNA 3.5 |
| **AI Engine** | AMD Ryzen AI Engine (XDNA 2) |
| **Memory Usage** | ~7.4GB used / 93GB available |
| **CPU Utilization** | ~54% scaling frequency |

### Software Stack

| **Component** | **Version/Model** |
|---------------|-------------------|
| **Container Runtime** | Docker Compose |
| **AI Framework** | OPEA (Open Platform for Edge AI) |
| **Model Serving** | TGI (Text Generation Inference) |
| **Embedding Service** | TEI (Text Embeddings Inference) |
| **Vector Database** | Redis |
| **Benchmark Framework** | GenAIEval |

### Tested Models

| **Model Type** | **Model Name** | **Use Case** |
|----------------|----------------|--------------|
| **LLM (Standard)** | `Qwen/Qwen2.5-7B-Instruct-1M` | Production inference & Benchmarking |
| **LLM (Lightweight)** | `microsoft/DialoGPT-medium` | Quick testing |
| **Embedding** | `BAAI/bge-base-en-v1.5` | Text embeddings |
| **Reranking** | `BAAI/bge-reranker-base` | Result reranking |

### Deployment Ports

| **Service** | **Port** |
|-------------|----------|
| **Backend** | 8888 |
| **Frontend** | 5173 |
| **TGI Service** | 18008 |
| **TEI Embedding** | 18090 |
| **TEI Reranking** | 18808 |
| **Redis Vector** | 6379 |
| **Grafana** | 3000 |
| **Prometheus** | 9090 |

### Troubleshooting
```bash
# Check service status
./run_chatqna.sh status

# View service logs
./run_chatqna.sh logs

# View monitoring logs
./run_chatqna.sh monitor-logs

# Clean up everything
./run_chatqna.sh cleanup
```

## Directory Structure

```
/home/yw/Desktop/OPEA/LaunchPad/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm/
├── run_chatqna.sh              # Main management script
├── set_env.sh                  # Standard environment setup
├── set_env_lightweight.sh      # Lightweight environment setup
├── start_monitoring.sh         # Start monitoring stack
├── restart_telemetry.sh        # Restart telemetry services
├── quick_test_chatqna.sh       # Quick evaluation
├── quick_eval_setup.sh         # Full evaluation setup
├── run_genaieval_benchmark.sh  # GenAIEval benchmark
├── compose.yaml                # Main services
├── compose.telemetry.yaml      # Monitoring services
├── grafana/                    # Grafana configuration
│   └── dashboards/            # Dashboard JSON files
└── README.md                  # This file
```

## Notes

- All scripts should be run from the `/home/yw/Desktop/OPEA/LaunchPad/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm/` directory
- Make sure Docker is running before executing any scripts
- The `run_chatqna.sh` script provides the most convenient way to manage all operations
- Use the interactive menu (`./run_chatqna.sh`) for easy navigation
- Check the logs if you encounter any issues
- The monitoring stack provides detailed metrics and dashboards for system performance
- The GenAIEval benchmark provides comprehensive load testing capabilities 
