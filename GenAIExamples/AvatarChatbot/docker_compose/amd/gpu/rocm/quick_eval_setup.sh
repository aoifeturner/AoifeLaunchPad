#!/bin/bash

# OPEA AvatarChatbot Quick Evaluation Setup Script
# This script automates the setup and evaluation process for AvatarChatbot (TGI backend)

set -e  # Exit on any error

# Set up base directories
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../../.." && pwd)"
GENAIEXAMPLES_DIR="$BASEDIR/GenAIExamples"
GENAIEVAL_DIR="$BASEDIR/GenAIEval"
EVAL_RESULTS_DIR="$BASEDIR/evaluation_results"

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_prerequisites() {
    print_status "Checking prerequisites..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."; exit 1; fi
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."; exit 1; fi
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3 first."; exit 1; fi
    print_success "Prerequisites check passed"
}

setup_env() {
    print_status "Setting up environment variables..."
    HOST_IP=${host_ip:-"localhost"}
    if [ -z "$HF_TOKEN" ]; then
        print_warning "HF_TOKEN not set. Some models may not be accessible."
        print_status "To set HF_TOKEN, run: export HF_TOKEN='your_token_here'"
    fi
    export host_ip="$HOST_IP"
    export http_proxy=${http_proxy:-""}
    export https_proxy=${https_proxy:-""}
    export no_proxy=localhost,127.0.0.1,$host_ip
    print_success "Environment variables configured"
}

setup_genaieval() {
    print_status "Setting up GenAIEval..."
    cd $GENAIEVAL_DIR
    if [ ! -d "opea_eval_env" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv opea_eval_env
    fi
    source opea_eval_env/bin/activate
    print_status "Installing GenAIEval dependencies..."
    pip install -r requirements.txt
    pip install -e .
    print_success "GenAIEval setup completed"
}

deploy_avatarchatbot() {
    print_status "Deploying AvatarChatbot application (AMD/ROCm configuration)..."
    cd $GENAIEXAMPLES_DIR/AvatarChatbot/docker_compose/amd/gpu/rocm
    if docker ps --format "table {{.Names}}" | grep -q "avatarchatbot-backend-server"; then
        print_warning "AvatarChatbot services are already running"
        return 0
    fi
    print_status "Setting up environment variables..."
    source ./set_env.sh
    print_status "Starting AvatarChatbot services (this may take several minutes)..."
    docker compose up -d
    print_status "Waiting for services to be ready..."
    sleep 30
    if docker ps --format "table {{.Names}}" | grep -q "avatarchatbot-backend-server"; then
        print_success "AvatarChatbot services deployed successfully"
    else
        print_error "Failed to deploy AvatarChatbot services"
        print_status "Check logs with: docker compose logs"
        exit 1
    fi
}

test_avatarchatbot() {
    print_status "Testing AvatarChatbot backend service..."
    sleep 10
    # Test the backend service (adjust endpoint/port as needed)
    if curl -s http://localhost:8888/v1/avatarchatbot \
        -H "Content-Type: application/json" \
        -d '{"messages": "Hello"}' > /dev/null 2>&1; then
        print_success "AvatarChatbot backend service is responding"
    else
        print_warning "AvatarChatbot backend service may not be fully ready yet"
        print_status "You can check service status with: docker ps"
    fi
}

run_evaluation() {
    print_status "Running AvatarChatbot evaluation..."
    cd $GENAIEVAL_DIR
    source opea_eval_env/bin/activate
    mkdir -p $EVAL_RESULTS_DIR
    # Use a generic/simple eval script if available, otherwise skip
    if [ -f evals/benchmark/chatqna_simple_eval.py ]; then
        print_status "Starting evaluation (this will take a few minutes)..."
        python evals/benchmark/chatqna_simple_eval.py \
            --service-url http://localhost:8888 \
            --output $EVAL_RESULTS_DIR/avatarchatbot_eval.json
        print_success "Evaluation completed!"
        print_status "Results saved to: $EVAL_RESULTS_DIR/avatarchatbot_eval.json"
    else
        print_warning "No evaluation script found. Skipping evaluation."
    fi
}

show_results() {
    print_status "Evaluation Results Summary:"
    echo "=================================="
    if [ -f "$EVAL_RESULTS_DIR/avatarchatbot_eval.json" ]; then
        python3 -c "
import json
try:
    with open('$EVAL_RESULTS_DIR/avatarchatbot_eval.json', 'r') as f:
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
        print(f'📊 Full results: $EVAL_RESULTS_DIR/avatarchatbot_eval.json')
except Exception as e:
    print('❌ Error reading results:', str(e))
"
    else
        print_error "Results file not found"
    fi
}

main() {
    echo "Starting OPEA AvatarChatbot evaluation setup..."
    echo ""
    check_prerequisites
    setup_env
    setup_genaieval
    deploy_avatarchatbot
    test_avatarchatbot
    run_evaluation
    show_results
    echo ""
    echo "🎉 Setup and evaluation completed!"
    echo ""
    echo "Next steps:"
    echo "1. View detailed results: cat $EVAL_RESULTS_DIR/avatarchatbot_eval.json"
    echo "2. Access AvatarChatbot backend: http://localhost:8888"
    echo "3. Stop services: cd $GENAIEXAMPLES_DIR/AvatarChatbot/docker_compose/amd/gpu/rocm && docker compose down"
}

case "${1:-}" in
    "deploy-only")
        check_prerequisites
        setup_env
        deploy_avatarchatbot
        test_avatarchatbot
        ;;
    "eval-only")
        check_prerequisites
        setup_genaieval
        run_evaluation
        show_results
        ;;
    "cleanup")
        print_status "Stopping AvatarChatbot services..."
        cd $GENAIEXAMPLES_DIR/AvatarChatbot/docker_compose/amd/gpu/rocm
        docker compose down
        print_success "Services stopped"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (no args)    Complete setup and evaluation"
        echo "  deploy-only  Only deploy AvatarChatbot services"
        echo "  eval-only    Only run evaluation (assumes services are running)"
        echo "  cleanup      Stop all AvatarChatbot services"
        echo "  help         Show this help message"
        ;;
    *)
        main
        ;;
esac
