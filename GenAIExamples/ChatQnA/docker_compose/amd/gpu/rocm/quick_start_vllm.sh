#!/bin/bash

# ChatQnA vLLM Quick Start Script
# This script provides a streamlined deployment and evaluation process

set -e

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

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Check ROCm (optional, for AMD GPU users)
    if command -v rocm-smi &> /dev/null; then
        print_status "ROCm detected - AMD GPU support available"
    else
        print_warning "ROCm not detected - GPU acceleration may not be available"
    fi
    
    print_status "Prerequisites check passed"
}

# Function to setup environment
setup_environment() {
    print_header "Setting Up Environment"
    
    # Check for HF token
    if [ -z "$HF_TOKEN" ]; then
        print_warning "HF_TOKEN not set. Please set your Hugging Face token:"
        print_status "export HF_TOKEN='your_token_here'"
        print_status "Or create a .env file with: echo 'HF_TOKEN=your_token_here' > .env"
    else
        print_status "HF_TOKEN is set"
    fi
    
    # Source vLLM environment
    if [ -f "set_env_vllm.sh" ]; then
        source set_env_vllm.sh
        print_status "vLLM environment variables loaded"
    else
        print_error "set_env_vllm.sh not found. Please run this script from the correct directory."
        exit 1
    fi
}

# Function to deploy ChatQnA with vLLM
deploy_chatqna() {
    print_header "Deploying ChatQnA with vLLM"
    
    # Check if services are already running
    if docker ps --format "{{.Names}}" | grep -q "chatqna-vllm-service"; then
        print_warning "vLLM services are already running"
        return 0
    fi
    
    print_status "Starting vLLM services (this may take several minutes for first run)..."
    
    # Start services
    docker compose -f compose_vllm.yaml up -d
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Check if services are running
    if docker ps --format "{{.Names}}" | grep -q "chatqna-vllm-service"; then
        print_status "vLLM services deployed successfully"
    else
        print_error "Failed to deploy vLLM services"
        print_status "Check logs with: docker compose -f compose_vllm.yaml logs"
        exit 1
    fi
}

# Function to test deployment
test_deployment() {
    print_header "Testing Deployment"
    
    # Wait a bit more for services to be fully ready
    sleep 10
    
    # Test backend API
    print_status "Testing backend API..."
    if curl -s http://localhost:8890/v1/chatqna \
        -H "Content-Type: application/json" \
        -d '{"messages": "Hello"}' > /dev/null 2>&1; then
        print_status "Backend API is responding"
    else
        print_warning "Backend API may not be fully ready yet"
    fi
    
    # Test document upload
    print_status "Testing document upload..."
    if curl -s -X POST http://localhost:18104/v1/dataprep/ingest \
        -H "Content-Type: application/json" \
        -d '{"file_name": "test.txt", "content": "This is a test document."}' > /dev/null 2>&1; then
        print_status "Document upload is working"
    else
        print_warning "Document upload may not be ready yet"
    fi
    
    print_status "Deployment test completed"
}

# Function to run basic performance evaluation
run_performance_eval() {
    print_header "Running Basic Performance Evaluation"
    
    # Check if GenAIEval is available
    BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../../.." && pwd)"
    GENAIEVAL_DIR="$BASEDIR/GenAIEval"
    
    if [ ! -d "$GENAIEVAL_DIR" ]; then
        print_warning "GenAIEval directory not found. Skipping performance evaluation."
        print_status "To run evaluation, please install GenAIEval first."
        return 0
    fi
    
    print_status "Running basic performance tests..."
    
    # Simple throughput test
    print_status "Testing throughput (10 requests)..."
    for i in {1..10}; do
        start_time=$(date +%s.%N)
        curl -s http://localhost:8890/v1/chatqna \
            -H "Content-Type: application/json" \
            -d '{"messages": "What is machine learning?"}' > /dev/null
        end_time=$(date +%s.%N)
        echo "Request $i: $(echo "$end_time - $start_time" | bc) seconds"
    done
    
    # Resource monitoring
    print_status "Current resource usage:"
    echo "GPU Memory:"
    if command -v rocm-smi &> /dev/null; then
        rocm-smi --showmeminfo | grep -E "(GPU|Memory)"
    else
        echo "GPU monitoring not available"
    fi
    
    echo "Docker containers:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    
    print_status "Basic performance evaluation completed"
}

# Function to show service status
show_status() {
    print_header "Service Status"
    
    echo "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep chatqna
    
    echo ""
    echo "Service endpoints:"
    echo "- Frontend: http://localhost:8081"
    echo "- Backend API: http://localhost:8890"
    echo "- vLLM API: http://localhost:18009"
    echo "- Redis Insight: http://localhost:8002"
    
    echo ""
    echo "Useful commands:"
    echo "- View logs: docker compose -f compose_vllm.yaml logs -f"
    echo "- Stop services: docker compose -f compose_vllm.yaml down"
    echo "- Restart services: ./run_chatqna.sh restart-vllm"
}

# Function to show help
show_help() {
    echo "ChatQnA vLLM Quick Start Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  deploy      Deploy ChatQnA with vLLM (default)"
    echo "  test        Test the deployment"
    echo "  eval        Run basic performance evaluation"
    echo "  status      Show service status"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy and test"
    echo "  $0 deploy            # Deploy only"
    echo "  $0 test              # Test only"
    echo "  $0 eval              # Run evaluation only"
    echo "  $0 status            # Show status only"
}

# Main script logic
main() {
    case "${1:-deploy}" in
        "deploy")
            check_prerequisites
            setup_environment
            deploy_chatqna
            test_deployment
            show_status
            ;;
        "test")
            test_deployment
            show_status
            ;;
        "eval")
            run_performance_eval
            ;;
        "status")
            show_status
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 