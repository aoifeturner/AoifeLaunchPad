#!/bin/bash

# OPEA ChatQnA Quick Evaluation Setup Script
# This script automates the setup and evaluation process

set -e  # Exit on any error

echo "🚀 OPEA ChatQnA Evaluation Setup"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if Python 3 is installed
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3 first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Setup environment variables
setup_env() {
    print_status "Setting up environment variables..."
    
    # Get host IP
    HOST_IP=${host_ip:-"localhost"}
    
    # Check for HF_TOKEN
    if [ -z "$HF_TOKEN" ]; then
        print_warning "HF_TOKEN not set. Some models may not be accessible."
        print_status "To set HF_TOKEN, run: export HF_TOKEN='your_token_here'"
    fi
    
    # Set default environment variables
    export host_ip="$HOST_IP"
    export http_proxy=${http_proxy:-""}
    export https_proxy=${https_proxy:-""}
    export no_proxy=localhost,127.0.0.1,$host_ip
    
    print_success "Environment variables configured"
}

# Setup GenAIEval
setup_genaieval() {
    print_status "Setting up GenAIEval..."
    
    cd /home/yw/Desktop/OPEA/GenAIEval
    
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
    
    print_success "GenAIEval setup completed"
}

# Deploy ChatQnA
deploy_chatqna() {
    print_status "Deploying ChatQnA application (AMD/ROCm configuration)..."
    
    cd /home/yw/Desktop/OPEA/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm
    
    # Check if services are already running
    if docker ps --format "table {{.Names}}" | grep -q "chatqna-backend-server"; then
        print_warning "ChatQnA services are already running"
        return 0
    fi
    
    # Source the environment setup script
    print_status "Setting up environment variables..."
    source ./set_env.sh
    
    # Deploy services
    print_status "Starting ChatQnA services (this may take several minutes)..."
    docker compose up -d
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Check if services are running
    if docker ps --format "table {{.Names}}" | grep -q "chatqna-backend-server"; then
        print_success "ChatQnA services deployed successfully"
    else
        print_error "Failed to deploy ChatQnA services"
        print_status "Check logs with: docker compose logs"
        exit 1
    fi
}

# Test ChatQnA service
test_chatqna() {
    print_status "Testing ChatQnA service..."
    
    # Wait a bit more for services to be fully ready
    sleep 10
    
    # Test the service
    if curl -s http://localhost:8888/v1/chatqna \
        -H "Content-Type: application/json" \
        -d '{"messages": "Hello"}' > /dev/null 2>&1; then
        print_success "ChatQnA service is responding"
    else
        print_warning "ChatQnA service may not be fully ready yet"
        print_status "You can check service status with: docker ps"
    fi
}

# Run evaluation
run_evaluation() {
    print_status "Running ChatQnA evaluation..."
    
    cd /home/yw/Desktop/OPEA/GenAIEval
    
    # Activate virtual environment
    source opea_eval_env/bin/activate
    
    # Create results directory
    mkdir -p /home/yw/Desktop/OPEA/evaluation_results
    
    # Run simple evaluation
    print_status "Starting evaluation (this will take a few minutes)..."
    python evals/benchmark/chatqna_simple_eval.py \
        --service-url http://localhost:8888 \
        --output /home/yw/Desktop/OPEA/evaluation_results/chatqna_eval.json
    
    print_success "Evaluation completed!"
    print_status "Results saved to: /home/yw/Desktop/OPEA/evaluation_results/chatqna_eval.json"
}

# Show results
show_results() {
    print_status "Evaluation Results Summary:"
    echo "=================================="
    
    if [ -f "/home/yw/Desktop/OPEA/evaluation_results/chatqna_eval.json" ]; then
        # Extract and display key metrics
        python3 -c "
import json
try:
    with open('/home/yw/Desktop/OPEA/evaluation_results/chatqna_eval.json', 'r') as f:
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
        
        print(f'📊 Full results: /home/yw/Desktop/OPEA/evaluation_results/chatqna_eval.json')
except Exception as e:
    print('❌ Error reading results:', str(e))
"
    else
        print_error "Results file not found"
    fi
}

# Main execution
main() {
    echo "Starting OPEA ChatQnA evaluation setup..."
    echo ""
    
    check_prerequisites
    setup_env
    setup_genaieval
    deploy_chatqna
    test_chatqna
    run_evaluation
    show_results
    
    echo ""
    echo "🎉 Setup and evaluation completed!"
    echo ""
    echo "Next steps:"
    echo "1. View detailed results: cat /home/yw/Desktop/OPEA/evaluation_results/chatqna_eval.json"
    echo "2. Access ChatQnA UI: http://localhost:5173"
    echo "3. Stop services: cd /home/yw/Desktop/OPEA/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm && docker compose down"
    echo "4. Read the full guide: /home/yw/Desktop/OPEA/CHATQNA_EVALUATION_GUIDE.md"
}

# Handle command line arguments
case "${1:-}" in
    "deploy-only")
        check_prerequisites
        setup_env
        deploy_chatqna
        test_chatqna
        ;;
    "eval-only")
        check_prerequisites
        setup_genaieval
        run_evaluation
        show_results
        ;;
    "cleanup")
        print_status "Stopping ChatQnA services..."
        cd /home/yw/Desktop/OPEA/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm
        docker compose down
        print_success "Services stopped"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (no args)    Complete setup and evaluation"
        echo "  deploy-only  Only deploy ChatQnA services"
        echo "  eval-only    Only run evaluation (assumes services are running)"
        echo "  cleanup      Stop all ChatQnA services"
        echo "  help         Show this help message"
        ;;
    *)
        main
        ;;
esac 