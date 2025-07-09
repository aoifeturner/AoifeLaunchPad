# ChatQnA One-Click Deployment

This directory contains all the scripts needed to manage the ChatQnA system on AMD Ryzen.

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

### `set_env_faqgen.sh` - FAQ Generation Environment
Sets up environment variables for FAQ generation mode.

**Usage:**
```bash
source set_env_faqgen.sh
```

### `set_env_vllm.sh` - vLLM Environment Setup
Sets up environment variables for vLLM-based inference.

**Usage:**
```bash
source set_env_vllm.sh
```

### `set_env_faqgen_vllm.sh` - FAQ Generation with vLLM
Sets up environment variables for FAQ generation using vLLM.

**Usage:**
```bash
source set_env_faqgen_vllm.sh
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

## Docker Compose Files

### `compose.yaml` - Main Services
The main docker-compose file for ChatQnA services.

### `compose.telemetry.yaml` - Monitoring Services
Docker-compose file for monitoring stack (Prometheus, Grafana, cAdvisor).

### `compose_faqgen.yaml` - FAQ Generation Services
Docker-compose file for FAQ generation mode.

### `compose_vllm.yaml` - vLLM Services
Docker-compose file for vLLM-based inference.

### `compose_faqgen_vllm.yaml` - FAQ Generation with vLLM
Docker-compose file for FAQ generation using vLLM.

## Quick Start Guide

1. **Setup Environment:**
   ```bash
   cd /home/yw/Desktop/OPEA/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm/
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

5. **Check Status:**
   ```bash
   ./run_chatqna.sh status
   ```

6. **View Logs:**
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
ChatQnA/docker_compose/amd/gpu/rocm/
├── run_chatqna.sh              # Main management script
├── set_env.sh                  # Standard environment setup
├── set_env_lightweight.sh      # Lightweight environment setup
├── set_env_faqgen.sh           # FAQ generation environment
├── set_env_vllm.sh             # vLLM environment setup
├── set_env_faqgen_vllm.sh      # FAQ generation with vLLM
├── start_monitoring.sh         # Start monitoring stack
├── restart_telemetry.sh        # Restart telemetry services
├── quick_test_chatqna.sh       # Quick evaluation
├── quick_eval_setup.sh         # Full evaluation setup
├── compose.yaml                # Main services
├── compose.telemetry.yaml      # Monitoring services
├── compose_faqgen.yaml         # FAQ generation services
├── compose_vllm.yaml           # vLLM services
├── compose_faqgen_vllm.yaml    # FAQ generation with vLLM
├── grafana/                    # Grafana configuration
│   └── dashboards/            # Dashboard JSON files
└── SCRIPTS_README.md          # This file
```

## Notes

- All scripts should be run from the `ChatQnA/docker_compose/amd/gpu/rocm/` directory
- Make sure Docker is running before executing any scripts
- The `run_chatqna.sh` script provides the most convenient way to manage all operations
- Use the interactive menu (`./run_chatqna.sh`) for easy navigation
- Check the logs if you encounter any issues
- The monitoring stack provides detailed metrics and dashboards for system performance 
