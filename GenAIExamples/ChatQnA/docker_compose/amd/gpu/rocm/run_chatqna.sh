#!/bin/bash

# Unified ChatQnA Management Script
# This script provides a unified interface for all ChatQnA operations (TGI and vLLM)

set -e

# Define paths for evaluation
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../../.." && pwd)"
GENAIEVAL_DIR="$BASEDIR/GenAIEval"
EVAL_RESULTS_DIR="$BASEDIR/evaluation_results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Function to check if required files exist
check_requirements() {
    local missing_files=()
    
    if [[ ! -f "compose.yaml" ]]; then
        missing_files+=("compose.yaml")
    fi
    
    if [[ ! -f "compose_vllm.yaml" ]]; then
        missing_files+=("compose_vllm.yaml")
    fi
    
    if [[ ! -f "set_env.sh" ]]; then
        missing_files+=("set_env.sh")
    fi
    
    if [[ ! -f "set_env_vllm.sh" ]]; then
        missing_files+=("set_env_vllm.sh")
    fi
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required files: ${missing_files[*]}"
        print_error "Please run this script from the ChatQnA/docker_compose/amd/gpu/rocm/ directory"
        exit 1
    fi
}

# Function to detect running services
detect_services() {
    TGI_RUNNING=$(docker ps --format "{{.Names}}" | grep -q "chatqna-tgi-service" && echo "yes" || echo "no")
    VLLM_RUNNING=$(docker ps --format "{{.Names}}" | grep -q "chatqna-vllm-service" && echo "yes" || echo "no")
    
    if [ "$TGI_RUNNING" = "yes" ]; then
        print_status "TGI services are running (port 8889)"
    fi
    if [ "$VLLM_RUNNING" = "yes" ]; then
        print_status "vLLM services are running (port 8890)"
    fi
    if [ "$TGI_RUNNING" = "no" ] && [ "$VLLM_RUNNING" = "no" ]; then
        print_warning "No ChatQnA services are currently running"
    fi
}

# Function to setup TGI environment
setup_tgi_environment() {
    print_header "Setting up ChatQnA TGI Environment"
    check_docker
    check_requirements
    
    print_status "Setting up TGI environment variables..."
    source set_env.sh
    
    print_status "TGI environment setup complete!"
}

# Function to setup vLLM environment
setup_vllm_environment() {
    print_header "Setting up ChatQnA vLLM Environment"
    check_docker
    check_requirements
    
    print_status "Setting up vLLM environment variables..."
    source set_env_vllm.sh
    
    print_status "vLLM environment setup complete!"
}

# Function to setup lightweight environment
setup_lightweight() {
    print_header "Setting up Lightweight ChatQnA Environment"
    check_docker
    check_requirements
    
    print_status "Setting up lightweight environment variables..."
    source set_env_lightweight.sh
    
    print_status "Lightweight environment setup complete!"
}

# Function to start TGI services
start_tgi_services() {
    print_header "Starting ChatQnA TGI Services"
    check_docker
    check_requirements
    
    print_status "Starting TGI services with docker compose..."
    docker compose -f compose.yaml up -d
    
    print_status "TGI services started! Check logs with: docker compose -f compose.yaml logs -f"
}

# Function to start vLLM services
start_vllm_services() {
    print_header "Starting ChatQnA vLLM Services"
    check_docker
    check_requirements
    
    print_status "Starting vLLM services with docker compose..."
    docker compose -f compose_vllm.yaml up -d
    
    print_status "vLLM services started! Check logs with: docker compose -f compose_vllm.yaml logs -f"
}

# Function to stop TGI services
stop_tgi_services() {
    print_header "Stopping ChatQnA TGI Services"
    check_docker
    
    print_status "Stopping TGI services..."
    docker compose -f compose.yaml down
    
    print_status "TGI services stopped!"
}

# Function to stop vLLM services
stop_vllm_services() {
    print_header "Stopping ChatQnA vLLM Services"
    check_docker
    
    print_status "Stopping vLLM services..."
    docker compose -f compose_vllm.yaml down
    
    print_status "vLLM services stopped!"
}

# Function to restart TGI services
restart_tgi_services() {
    print_header "Restarting ChatQnA TGI Services"
    stop_tgi_services
    sleep 2
    start_tgi_services
}

# Function to restart vLLM services
restart_vllm_services() {
    print_header "Restarting ChatQnA vLLM Services"
    stop_vllm_services
    sleep 2
    start_vllm_services
}

# Function to start monitoring
start_monitoring() {
    print_header "Starting Monitoring Stack"
    check_docker
    
    print_status "Starting Prometheus and Grafana..."
    ./start_monitoring.sh
    
    print_status "Monitoring stack started!"
    print_status "Grafana: http://localhost:3000 (admin/admin)"
    print_status "Prometheus: http://localhost:9090"
}

# Function to stop monitoring
stop_monitoring() {
    print_header "Stopping Monitoring Stack"
    check_docker
    
    print_status "Stopping monitoring services..."
    docker compose -f compose.telemetry.yaml down
    
    print_status "Monitoring stack stopped!"
}

# Function to run quick evaluation (auto-detect)
run_quick_eval() {
    print_header "Running Quick Evaluation (Auto-detect)"
    check_docker
    
    print_status "Running quick evaluation with auto-detection..."
    ./quick_test_chatqna.sh
    
    print_status "Quick evaluation complete!"
}

# Function to run full evaluation (auto-detect)
run_full_eval() {
    print_header "Running Full Evaluation (Auto-detect)"
    check_docker
    
    print_status "Setting up evaluation environment..."
    ./quick_eval_setup.sh
    
    print_status "Full evaluation setup complete!"
    print_status "You can now run the evaluation using GenAIEval framework"
}

# Function to run TGI evaluation
run_tgi_eval() {
    print_header "Running TGI Evaluation"
    check_docker
    
    print_status "Setting up TGI evaluation environment..."
    
    # Check if TGI services are running
    if ! docker ps --format "table {{.Names}}" | grep -q "chatqna-tgi-service"; then
        print_error "TGI services are not running. Please start them first with: $0 start-tgi"
        exit 1
    fi
    
    print_status "TGI services are running on:"
    print_status "  Backend: http://localhost:8889"
    print_status "  Retriever: http://localhost:7000"
    print_status "  Frontend: http://localhost:5173"
    
    # Set up GenAIEval
    cd $GENAIEVAL_DIR
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "opea_eval_env" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv opea_eval_env
    fi
    
    # Activate virtual environment
    source opea_eval_env/bin/activate
    
    # Install dependencies
    print_status "Installing GenAIEval dependencies..."
    pip install -r requirements.txt
    pip install -e .
    
    # Create results directory
    mkdir -p $EVAL_RESULTS_DIR
    
    # Run evaluation with TGI ports
    print_status "Starting TGI evaluation (this will take a few minutes)..."
    python evals/benchmark/chatqna_simple_eval.py \
        --service-url http://localhost:8889 \
        --output $EVAL_RESULTS_DIR/chatqna_tgi_eval.json
    
    print_status "TGI evaluation completed!"
    print_status "Results saved to: $EVAL_RESULTS_DIR/chatqna_tgi_eval.json"
    
    # Show results summary
    show_tgi_results
}

# Function to show TGI evaluation results
show_tgi_results() {
    print_status "TGI Evaluation Results Summary:"
    echo "====================================="
    
    if [ -f "$EVAL_RESULTS_DIR/chatqna_tgi_eval.json" ]; then
        # Extract and display key metrics
        python3 -c "
import json
try:
    with open('$EVAL_RESULTS_DIR/chatqna_tgi_eval.json', 'r') as f:
        data = json.load(f)
    
    summary = data.get('evaluation_summary', {})
    if 'error' in summary:
        print('❌ Evaluation failed:', summary['error'])
    else:
        print(f'✅ Total Queries: {summary.get(\"total_queries\", \"N/A\")}')
        print(f'✅ Successful Queries: {summary.get(\"successful_queries\", \"N/A\")}')
        print(f'✅ Success Rate: {summary.get(\"success_rate\", \"N/A\"):.1f}%')
        
        rt_stats = summary.get('response_time_stats', {})
        if rt_stats:
            print(f'⏱️  Mean Response Time: {rt_stats.get(\"mean\", \"N/A\"):.2f}s')
            print(f'⏱️  Median Response Time: {rt_stats.get(\"median\", \"N/A\"):.2f}s')
        
        quality = summary.get('response_quality', {})
        if quality:
            print(f'📝 Avg Response Length: {quality.get(\"avg_response_length\", \"N/A\"):.0f} chars')
        
        print(f'📊 Full results: $EVAL_RESULTS_DIR/chatqna_tgi_eval.json')
        print(f'🌐 Access UI: http://localhost:5173')
except Exception as e:
    print('❌ Error reading results:', str(e))
"
    else
        print_error "Results file not found"
    fi
}

# Function to run vLLM evaluation
run_vllm_eval() {
    print_header "Running vLLM Evaluation"
    check_docker
    
    print_status "Setting up vLLM evaluation environment..."
    
    # Source vLLM environment variables
    source set_env_vllm.sh
    
    # Check if vLLM services are running
    if ! docker ps --format "table {{.Names}}" | grep -q "chatqna-vllm-service"; then
        print_error "vLLM services are not running. Please start them first with: $0 start-vllm"
        exit 1
    fi
    
    print_status "vLLM services are running on:"
    print_status "  Backend: http://localhost:${CHATQNA_BACKEND_SERVICE_PORT:-8890}"
    print_status "  Retriever: http://localhost:${CHATQNA_REDIS_RETRIEVER_PORT:-7001}"
    print_status "  Frontend: http://localhost:${CHATQNA_FRONTEND_SERVICE_PORT:-5174}"
    
    # Set up GenAIEval
    cd $GENAIEVAL_DIR
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "opea_eval_env" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv opea_eval_env
    fi
    
    # Activate virtual environment
    source opea_eval_env/bin/activate
    
    # Install dependencies
    print_status "Installing GenAIEval dependencies..."
    pip install -r requirements.txt
    pip install -e .
    
    # Create results directory
    mkdir -p $EVAL_RESULTS_DIR
    
    # Run evaluation with correct vLLM ports
    print_status "Starting vLLM evaluation (this will take a few minutes)..."
    python evals/benchmark/chatqna_simple_eval.py \
        --service-url http://localhost:${CHATQNA_BACKEND_SERVICE_PORT:-8890} \
        --output $EVAL_RESULTS_DIR/chatqna_vllm_eval.json
    
    print_status "vLLM evaluation completed!"
    print_status "Results saved to: $EVAL_RESULTS_DIR/chatqna_vllm_eval.json"
    
    # Show results summary
    show_vllm_results
}

# Function to show vLLM evaluation results
show_vllm_results() {
    print_status "vLLM Evaluation Results Summary:"
    echo "========================================"
    
    if [ -f "$EVAL_RESULTS_DIR/chatqna_vllm_eval.json" ]; then
        # Extract and display key metrics
        python3 -c "
import json
try:
    with open('$EVAL_RESULTS_DIR/chatqna_vllm_eval.json', 'r') as f:
        data = json.load(f)
    
    summary = data.get('evaluation_summary', {})
    if 'error' in summary:
        print('❌ Evaluation failed:', summary['error'])
    else:
        print(f'✅ Total Queries: {summary.get(\"total_queries\", \"N/A\")}')
        print(f'✅ Successful Queries: {summary.get(\"successful_queries\", \"N/A\")}')
        print(f'✅ Success Rate: {summary.get(\"success_rate\", \"N/A\"):.1f}%')
        
        rt_stats = summary.get('response_time_stats', {})
        if rt_stats:
            print(f'⏱️  Mean Response Time: {rt_stats.get(\"mean\", \"N/A\"):.2f}s')
            print(f'⏱️  Median Response Time: {rt_stats.get(\"median\", \"N/A\"):.2f}s')
        
        quality = summary.get('response_quality', {})
        if quality:
            print(f'📝 Avg Response Length: {quality.get(\"avg_response_length\", \"N/A\"):.0f} chars')
        
        print(f'📊 Full results: $EVAL_RESULTS_DIR/chatqna_vllm_eval.json')
        print(f'🌐 Access UI: http://localhost:${CHATQNA_FRONTEND_SERVICE_PORT:-5174}')
except Exception as e:
    print('❌ Error reading results:', str(e))
"
    else
        print_error "Results file not found"
    fi
}

# Function to run comparison evaluation (both TGI and vLLM)
run_comparison_eval() {
    print_header "Running Comparison Evaluation (TGI vs vLLM)"
    check_docker
    
    # Check if both services are running
    TGI_RUNNING=$(docker ps --format "{{.Names}}" | grep -q "chatqna-tgi-service" && echo "yes" || echo "no")
    VLLM_RUNNING=$(docker ps --format "{{.Names}}" | grep -q "chatqna-vllm-service" && echo "yes" || echo "no")
    
    if [ "$TGI_RUNNING" = "no" ] && [ "$VLLM_RUNNING" = "no" ]; then
        print_error "Neither TGI nor vLLM services are running!"
        print_status "Start TGI services: $0 start-tgi"
        print_status "Start vLLM services: $0 start-vllm"
        exit 1
    fi
    
    print_status "Service Status:"
    if [ "$TGI_RUNNING" = "yes" ]; then
        print_status "  ✅ TGI services running on port 8889"
    fi
    if [ "$VLLM_RUNNING" = "yes" ]; then
        print_status "  ✅ vLLM services running on port 8890"
    fi
    
    # Set up GenAIEval
    cd $GENAIEVAL_DIR
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "opea_eval_env" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv opea_eval_env
    fi
    
    # Activate virtual environment
    source opea_eval_env/bin/activate
    
    # Install dependencies
    print_status "Installing GenAIEval dependencies..."
    pip install -r requirements.txt
    pip install -e .
    
    # Create results directory
    mkdir -p $EVAL_RESULTS_DIR
    
    # Run evaluations for each service
    if [ "$TGI_RUNNING" = "yes" ]; then
        print_status "Running TGI evaluation..."
        python evals/benchmark/chatqna_simple_eval.py \
            --service-url http://localhost:8889 \
            --output $EVAL_RESULTS_DIR/chatqna_tgi_comparison.json
        print_status "TGI evaluation completed!"
    fi
    
    if [ "$VLLM_RUNNING" = "yes" ]; then
        print_status "Running vLLM evaluation..."
        python evals/benchmark/chatqna_simple_eval.py \
            --service-url http://localhost:8890 \
            --output $EVAL_RESULTS_DIR/chatqna_vllm_comparison.json
        print_status "vLLM evaluation completed!"
    fi
    
    # Show comparison results
    show_comparison_results
}

# Function to show comparison results
show_comparison_results() {
    print_status "Comparison Evaluation Results:"
    echo "==================================="
    
    if [ -f "$EVAL_RESULTS_DIR/chatqna_tgi_comparison.json" ] && [ -f "$EVAL_RESULTS_DIR/chatqna_vllm_comparison.json" ]; then
        print_status "Both TGI and vLLM results available:"
        echo ""
        
        # Extract and display TGI metrics
        print_status "TGI Results:"
        python3 -c "
import json
try:
    with open('$EVAL_RESULTS_DIR/chatqna_tgi_comparison.json', 'r') as f:
        data = json.load(f)
    
    summary = data.get('evaluation_summary', {})
    if 'error' not in summary:
        print(f'  ✅ Success Rate: {summary.get(\"success_rate\", \"N/A\"):.1f}%')
        rt_stats = summary.get('response_time_stats', {})
        if rt_stats:
            print(f'  ⏱️  Mean Response Time: {rt_stats.get(\"mean\", \"N/A\"):.2f}s')
except Exception as e:
    print('  ❌ Error reading TGI results')
"
        
        # Extract and display vLLM metrics
        print_status "vLLM Results:"
        python3 -c "
import json
try:
    with open('$EVAL_RESULTS_DIR/chatqna_vllm_comparison.json', 'r') as f:
        data = json.load(f)
    
    summary = data.get('evaluation_summary', {})
    if 'error' not in summary:
        print(f'  ✅ Success Rate: {summary.get(\"success_rate\", \"N/A\"):.1f}%')
        rt_stats = summary.get('response_time_stats', {})
        if rt_stats:
            print(f'  ⏱️  Mean Response Time: {rt_stats.get(\"mean\", \"N/A\"):.2f}s')
except Exception as e:
    print('  ❌ Error reading vLLM results')
"
        
        echo ""
        print_status "Full results:"
        print_status "  TGI: $EVAL_RESULTS_DIR/chatqna_tgi_comparison.json"
        print_status "  vLLM: $EVAL_RESULTS_DIR/chatqna_vllm_comparison.json"
        
    elif [ -f "$EVAL_RESULTS_DIR/chatqna_tgi_comparison.json" ]; then
        print_status "Only TGI results available:"
        show_tgi_results
    elif [ -f "$EVAL_RESULTS_DIR/chatqna_vllm_comparison.json" ]; then
        print_status "Only vLLM results available:"
        show_vllm_results
    else
        print_error "No comparison results found"
    fi
}

# Function to run comprehensive TGI benchmark test
run_tgi_benchmark() {
    print_header "Running Comprehensive TGI Benchmark Test"
    check_docker
    
    print_status "Setting up TGI benchmark environment..."
    
    # Check if TGI services are running
    if ! docker ps --format "{{.Names}}" | grep -q "chatqna-tgi-service"; then
        print_error "TGI services are not running. Please start them first with: $0 start-tgi"
        exit 1
    fi
    
    print_status "TGI services are running on:"
    print_status "  Backend: http://localhost:8889"
    print_status "  Retriever: http://localhost:7000"
    print_status "  Frontend: http://localhost:5173"
    
    # Set up GenAIEval
    cd $GENAIEVAL_DIR
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "opea_eval_env" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv opea_eval_env
    fi
    
    # Activate virtual environment
    source opea_eval_env/bin/activate
    
    # Install dependencies
    print_status "Installing GenAIEval dependencies..."
    pip install -r requirements.txt
    pip install -e .
    
    # Install additional dependencies for benchmark
    print_status "Installing benchmark dependencies..."
    pip install locust
    
    # Create results directory
    mkdir -p $EVAL_RESULTS_DIR
    
    # Create benchmark configuration for TGI
    print_status "Creating TGI benchmark configuration..."
    create_tgi_benchmark_config
    
    # Run comprehensive benchmark
    print_status "Starting comprehensive TGI benchmark (this will take 10-15 minutes)..."
    cd evals/benchmark/
    python benchmark.py --yaml benchmark_tgi.yaml --report
    
    print_status "TGI benchmark completed!"
    print_status "Results saved to: $EVAL_RESULTS_DIR/tgi_benchmark_results/"
    
    # Show benchmark results
    show_tgi_benchmark_results
}

# Function to run comprehensive vLLM benchmark test
run_vllm_benchmark() {
    print_header "Running Comprehensive vLLM Benchmark Test"
    check_docker
    
    print_status "Setting up vLLM benchmark environment..."
    
    # Source vLLM environment variables
    source set_env_vllm.sh
    
    # Check if vLLM services are running
    if ! docker ps --format "{{.Names}}" | grep -q "chatqna-vllm-service"; then
        print_error "vLLM services are not running. Please start them first with: $0 start-vllm"
        exit 1
    fi
    
    print_status "vLLM services are running on:"
    print_status "  Backend: http://localhost:${CHATQNA_BACKEND_SERVICE_PORT:-8890}"
    print_status "  Retriever: http://localhost:${CHATQNA_REDIS_RETRIEVER_PORT:-7001}"
    print_status "  Frontend: http://localhost:${CHATQNA_FRONTEND_SERVICE_PORT:-5174}"
    
    # Set up GenAIEval
    cd $GENAIEVAL_DIR
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "opea_eval_env" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv opea_eval_env
    fi
    
    # Activate virtual environment
    source opea_eval_env/bin/activate
    
    # Install dependencies
    print_status "Installing GenAIEval dependencies..."
    pip install -r requirements.txt
    pip install -e .
    
    # Install additional dependencies for benchmark
    print_status "Installing benchmark dependencies..."
    pip install locust
    
    # Create results directory
    mkdir -p $EVAL_RESULTS_DIR
    
    # Create benchmark configuration for vLLM
    print_status "Creating vLLM benchmark configuration..."
    create_vllm_benchmark_config
    
    # Run comprehensive benchmark
    print_status "Starting comprehensive vLLM benchmark (this will take 10-15 minutes)..."
    cd evals/benchmark/
    python benchmark.py --yaml benchmark_vllm.yaml --report
    
    print_status "vLLM benchmark completed!"
    print_status "Results saved to: $EVAL_RESULTS_DIR/vllm_benchmark_results/"
    
    # Show benchmark results
    show_vllm_benchmark_results
}

# Function to create TGI benchmark configuration
create_tgi_benchmark_config() {
    cd $GENAIEVAL_DIR/evals/benchmark/
    
    cat > benchmark_tgi.yaml << 'EOF'
test_suite_config:
  namespace: "default"
  examples: ["chatqna"]
  warm_ups: 10
  user_queries: [50, 100, 200]
  random_prompt: false
  test_output_dir: "/home/yw/Desktop/OPEA/evaluation_results/tgi_benchmark_results"
  run_time: null
  collect_service_metric: true
  llm_model: "Qwen/Qwen2.5-7B-Instruct-1M"
  deployment_type: "docker"
  service_ip: "localhost"
  service_port: 8889
  load_shape:
    name: "constant"
    params:
      constant:
        concurrent_level: 5
  query_timeout: 120
  seed: 42

test_cases:
  chatqna:
    e2e:
      service_name: "chatqna-tgi"
      run_test: true
      service_list: ["chatqna-tgi-service"]
      dataset: "default"
      prompts: null
      max_output: 512
      max_new_tokens: 512
      stream: true
      summary_type: "stuff"
      k: 5
      top_n: 3
      chat_template: "qwen"
EOF
}

# Function to create vLLM benchmark configuration
create_vllm_benchmark_config() {
    cd $GENAIEVAL_DIR/evals/benchmark/
    
    cat > benchmark_vllm.yaml << 'EOF'
test_suite_config:
  namespace: "default"
  examples: ["chatqna"]
  warm_ups: 10
  user_queries: [50, 100, 200]
  random_prompt: false
  test_output_dir: "/home/yw/Desktop/OPEA/evaluation_results/vllm_benchmark_results"
  run_time: null
  collect_service_metric: true
  llm_model: "Qwen/Qwen2.5-7B-Instruct-1M"
  deployment_type: "docker"
  service_ip: "localhost"
  service_port: 8890
  load_shape:
    name: "constant"
    params:
      constant:
        concurrent_level: 5
  query_timeout: 120
  seed: 42

test_cases:
  chatqna:
    e2e:
      service_name: "chatqna-vllm"
      run_test: true
      service_list: ["chatqna-vllm-service"]
      dataset: "default"
      prompts: null
      max_output: 512
      max_new_tokens: 512
      stream: true
      summary_type: "stuff"
      k: 5
      top_n: 3
      chat_template: "qwen"
EOF
}

# Function to show TGI benchmark results
show_tgi_benchmark_results() {
    print_status "TGI Benchmark Results Summary:"
    echo "===================================="
    
    local results_dir="$EVAL_RESULTS_DIR/tgi_benchmark_results"
    if [ -d "$results_dir" ]; then
        print_status "Benchmark results directory: $results_dir"
        print_status "Check the following files for detailed results:"
        ls -la "$results_dir" 2>/dev/null || print_warning "Results directory not found"
        
        # Try to find and display summary
        find "$results_dir" -name "*.json" -type f | head -1 | while read -r file; do
            print_status "Sample results from: $file"
            python3 -c "
import json
try:
    with open('$file', 'r') as f:
        data = json.load(f)
    print('  📊 Benchmark completed successfully')
    print(f'  📁 Results location: $results_dir')
except Exception as e:
    print('  ❌ Error reading benchmark results')
"
        done
    else
        print_warning "Benchmark results directory not found"
    fi
}

# Function to show vLLM benchmark results
show_vllm_benchmark_results() {
    print_status "vLLM Benchmark Results Summary:"
    echo "====================================="
    
    local results_dir="$EVAL_RESULTS_DIR/vllm_benchmark_results"
    if [ -d "$results_dir" ]; then
        print_status "Benchmark results directory: $results_dir"
        print_status "Check the following files for detailed results:"
        ls -la "$results_dir" 2>/dev/null || print_warning "Results directory not found"
        
        # Try to find and display summary
        find "$results_dir" -name "*.json" -type f | head -1 | while read -r file; do
            print_status "Sample results from: $file"
            python3 -c "
import json
try:
    with open('$file', 'r') as f:
        data = json.load(f)
    print('  📊 Benchmark completed successfully')
    print(f'  📁 Results location: $results_dir')
except Exception as e:
    print('  ❌ Error reading benchmark results')
"
        done
    else
        print_warning "Benchmark results directory not found"
    fi
}

# Function to show TGI service logs
show_tgi_logs() {
    print_header "Showing TGI Service Logs"
    check_docker
    
    print_status "Showing TGI logs (Ctrl+C to exit)..."
    docker compose -f compose.yaml logs -f
}

# Function to show vLLM service logs
show_vllm_logs() {
    print_header "Showing vLLM Service Logs"
    check_docker
    
    print_status "Showing vLLM logs (Ctrl+C to exit)..."
    docker compose -f compose_vllm.yaml logs -f
}

# Function to show monitoring logs
show_monitoring_logs() {
    print_header "Showing Monitoring Logs"
    check_docker
    
    print_status "Showing monitoring logs (Ctrl+C to exit)..."
    docker compose -f compose.telemetry.yaml logs -f
}

# Function to check service status
check_status() {
    print_header "Service Status"
    check_docker
    
    print_status "TGI Services:"
    docker compose -f compose.yaml ps
    
    echo ""
    print_status "vLLM Services:"
    docker compose -f compose_vllm.yaml ps
    
    echo ""
    print_status "Monitoring Services:"
    docker compose -f compose.telemetry.yaml ps
    
    echo ""
    detect_services
}

# Function to clean up
cleanup() {
    print_header "Cleaning Up All Services"
    check_docker
    
    print_warning "This will stop all TGI, vLLM, and monitoring services and remove containers. Continue? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_status "Stopping all services..."
        docker compose -f compose.yaml down
        docker compose -f compose_vllm.yaml down
        docker compose -f compose.telemetry.yaml down
        
        print_status "Removing containers..."
        docker system prune -f
        
        print_status "Cleanup complete!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Function to show help
show_help() {
    print_header "Unified ChatQnA Management Script Help"
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Environment Setup:"
    echo "  1) setup-tgi       - Setup TGI environment variables"
    echo "  2) setup-vllm      - Setup vLLM environment variables"
    echo "  3) setup-light     - Setup lightweight environment"
    echo ""
    echo "Service Management:"
    echo "  4) start-tgi       - Start TGI services"
    echo "  5) start-vllm      - Start vLLM services"
    echo "  6) stop-tgi        - Stop TGI services"
    echo "  7) stop-vllm       - Stop vLLM services"
    echo "  8) restart-tgi     - Restart TGI services"
    echo "  9) restart-vllm    - Restart vLLM services"
    echo ""
    echo "Monitoring:"
    echo "  10) monitor-start  - Start monitoring stack"
    echo "  11) monitor-stop   - Stop monitoring stack"
    echo ""
    echo "Evaluation Options:"
    echo "  12) quick-eval     - Quick evaluation (auto-detect TGI/vLLM)"
    echo "  13) full-eval      - Full evaluation (auto-detect TGI/vLLM)"
    echo "  14) tgi-eval       - TGI-specific evaluation (port 8889)"
    echo "  15) vllm-eval      - vLLM-specific evaluation (port 8890)"
    echo "  16) compare-eval   - Compare TGI vs vLLM performance"
    echo "  17) tgi-benchmark  - Comprehensive TGI benchmark (Locust load testing)"
    echo "  18) vllm-benchmark - Comprehensive vLLM benchmark (Locust load testing)"
    echo ""
    echo "Logs and Status:"
    echo "  17) logs-tgi       - Show TGI service logs"
    echo "  18) logs-vllm      - Show vLLM service logs"
    echo "  19) monitor-logs   - Show monitoring logs"
    echo "  20) status         - Check all service status"
    echo "  21) cleanup        - Clean up all services"
    echo "  22) menu           - Show interactive menu"
    echo "  23) help           - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 setup-tgi       # Setup TGI environment"
    echo "  $0 start-tgi       # Start TGI services"
    echo "  $0 tgi-eval        # Run TGI evaluation"
    echo "  $0 vllm-eval       # Run vLLM evaluation"
    echo "  $0 compare-eval    # Compare TGI vs vLLM"
    echo "  $0 tgi-benchmark   # Run comprehensive TGI benchmark"
    echo "  $0 vllm-benchmark  # Run comprehensive vLLM benchmark"
    echo "  $0 menu            # Interactive menu"
}

# Function to show interactive menu
show_menu() {
    while true; do
        print_header "Unified ChatQnA Management Menu"
        echo "Environment Setup:"
        echo "1.  Setup TGI Environment"
        echo "2.  Setup vLLM Environment"
        echo "3.  Setup Lightweight Environment"
        echo ""
        echo "Service Management:"
        echo "4.  Start TGI Services"
        echo "5.  Start vLLM Services"
        echo "6.  Stop TGI Services"
        echo "7.  Stop vLLM Services"
        echo "8.  Restart TGI Services"
        echo "9.  Restart vLLM Services"
        echo ""
        echo "Monitoring:"
        echo "10. Start Monitoring"
        echo "11. Stop Monitoring"
        echo ""
        echo "Evaluation:"
        echo "12. Quick Evaluation (Auto-detect)"
        echo "13. Full Evaluation (Auto-detect)"
        echo "14. TGI Evaluation (Port 8889)"
        echo "15. vLLM Evaluation (Port 8890)"
        echo "16. Comparison Evaluation (TGI vs vLLM)"
        echo "17. TGI Comprehensive Benchmark (Load Testing)"
        echo "18. vLLM Comprehensive Benchmark (Load Testing)"
        echo ""
        echo "Logs and Status:"
        echo "19. Show TGI Logs"
        echo "20. Show vLLM Logs"
        echo "21. Show Monitoring Logs"
        echo "22. Check Service Status"
        echo "23. Cleanup All Services"
        echo "24. Help"
        echo "25. Exit"
        echo ""
        read -p "Select an option (1-25): " choice
        
        case $choice in
            1) setup_tgi_environment ;;
            2) setup_vllm_environment ;;
            3) setup_lightweight ;;
            4) start_tgi_services ;;
            5) start_vllm_services ;;
            6) stop_tgi_services ;;
            7) stop_vllm_services ;;
            8) restart_tgi_services ;;
            9) restart_vllm_services ;;
            10) start_monitoring ;;
            11) stop_monitoring ;;
            12) run_quick_eval ;;
            13) run_full_eval ;;
            14) run_tgi_eval ;;
            15) run_vllm_eval ;;
            16) run_comparison_eval ;;
            17) run_tgi_benchmark ;;
            18) run_vllm_benchmark ;;
            19) show_tgi_logs ;;
            20) show_vllm_logs ;;
            21) show_monitoring_logs ;;
            22) check_status ;;
            23) cleanup ;;
            24) show_help ;;
            25) print_status "Goodbye!"; exit 0 ;;
            *) print_error "Invalid option. Please try again." ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Main script logic
main() {
    # Check if script is run from correct directory
    if [[ ! -f "compose.yaml" ]] || [[ ! -f "compose_vllm.yaml" ]]; then
        print_error "Please run this script from the ChatQnA/docker_compose/amd/gpu/rocm/ directory"
        exit 1
    fi
    
    # If no arguments provided, show menu
    if [[ $# -eq 0 ]]; then
        show_menu
        exit 0
    fi
    
    # Handle command line arguments
    case "$1" in
        # Service Management
        "start-tgi") start_tgi_services ;;
        "start-vllm") start_vllm_services ;;
        "stop-tgi") stop_tgi_services ;;
        "stop-vllm") stop_vllm_services ;;
        "restart-tgi") restart_tgi_services ;;
        "restart-vllm") restart_vllm_services ;;
        
        # Environment Setup
        "setup-tgi") setup_tgi_environment ;;
        "setup-vllm") setup_vllm_environment ;;
        "setup-light") setup_lightweight ;;
        
        # Monitoring
        "monitor-start") start_monitoring ;;
        "monitor-stop") stop_monitoring ;;
        
        # Evaluation
        "quick-eval") run_quick_eval ;;
        "full-eval") run_full_eval ;;
        "tgi-eval") run_tgi_eval ;;
        "vllm-eval") run_vllm_eval ;;
        "compare-eval") run_comparison_eval ;;
        "tgi-benchmark") run_tgi_benchmark ;;
        "vllm-benchmark") run_vllm_benchmark ;;
        
        # Logs and Status
        "logs-tgi") show_tgi_logs ;;
        "logs-vllm") show_vllm_logs ;;
        "monitor-logs") show_monitoring_logs ;;
        "status") check_status ;;
        "cleanup") cleanup ;;
        "menu") show_menu ;;
        "help"|"-h"|"--help") show_help ;;
        
        # Backward compatibility
        "setup") setup_tgi_environment ;;
        "start") start_tgi_services ;;
        "stop") stop_tgi_services ;;
        "restart") restart_tgi_services ;;
        "logs") show_tgi_logs ;;
        
        *) 
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 