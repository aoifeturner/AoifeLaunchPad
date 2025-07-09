#!/bin/bash

# Quick ChatQnA Test Script
# This script provides a fast way to test ChatQnA with lightweight settings

set -e

echo "🚀 Quick ChatQnA Test Setup"
echo "============================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if services are already running
check_services() {
    print_status "Checking if ChatQnA services are running..."
    
    if docker ps --format "{{.Names}}" | grep -q "chatqna-backend-server"; then
        print_warning "ChatQnA services are already running"
        return 0
    else
        print_status "No ChatQnA services found, will start them"
        return 1
    fi
}

# Start ChatQnA with lightweight configuration
start_chatqna() {
    print_status "Starting ChatQnA with lightweight configuration..."
    
    cd /home/yw/Desktop/OPEA/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm
    
    # Source lightweight environment
    source ./set_env_lightweight.sh
    
    # Stop any existing services
    print_status "Stopping any existing services..."
    docker compose down 2>/dev/null || true
    
    # Start services
    print_status "Starting ChatQnA services (this may take 2-3 minutes for first startup)..."
    docker compose up -d
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 60
    
    # Check if services are running
    if docker ps --format "{{.Names}}" | grep -q "chatqna-backend-server"; then
        print_success "ChatQnA services started successfully"
    else
        print_error "Failed to start ChatQnA services"
        print_status "Check logs with: docker compose logs"
        exit 1
    fi
}

# Test the service
test_service() {
    print_status "Testing ChatQnA service..."
    
    # Wait a bit more for services to be fully ready
    sleep 30
    
    # Test with a simple query
    print_status "Sending test query..."
    
    response=$(curl -s -w "\n%{http_code}" http://localhost:8888/v1/chatqna \
        -H "Content-Type: application/json" \
        -d '{"messages": "Hello"}' 2>/dev/null || echo "Connection failed")
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        print_success "ChatQnA service is responding correctly!"
        print_status "Response preview: ${response_body:0:100}..."
    else
        print_warning "Service may still be starting up (HTTP $http_code)"
        print_status "Response: $response_body"
    fi
}

# Run quick evaluation
run_quick_eval() {
    print_status "Running quick evaluation..."
    
    cd /home/yw/Desktop/OPEA/GenAIEval
    
    # Activate virtual environment
    if [ -d "opea_eval_env" ]; then
        source opea_eval_env/bin/activate
    else
        print_warning "GenAIEval environment not found, creating it..."
        python3 -m venv opea_eval_env
        source opea_eval_env/bin/activate
        pip install -r requirements.txt
        pip install -e .
    fi
    
    # Create results directory
    mkdir -p /home/yw/Desktop/OPEA/evaluation_results
    
    # Run lightweight evaluation
    print_status "Running lightweight evaluation (should complete in 1-2 minutes)..."
    python evals/benchmark/chatqna_lightweight_eval.py \
        --service-url http://localhost:8888 \
        --output /home/yw/Desktop/OPEA/evaluation_results/chatqna_quick_test.json
    
    print_success "Quick evaluation completed!"
}

# Show results
show_results() {
    print_status "Quick Test Results:"
    echo "====================="
    
    if [ -f "/home/yw/Desktop/OPEA/evaluation_results/chatqna_quick_test.json" ]; then
        python3 -c "
import json
try:
    with open('/home/yw/Desktop/OPEA/evaluation_results/chatqna_quick_test.json', 'r') as f:
        data = json.load(f)
    
    summary = data.get('evaluation_summary', {})
    if 'error' in summary:
        print('❌ Evaluation failed:', summary['error'])
    else:
        print(f'✅ Total Queries: {summary.get(\"total_queries\", \"N/A\")}')
        print(f'✅ Successful Queries: {summary.get(\"successful_queries\", \"N/A\")}')
        print(f'✅ Success Rate: {summary.get(\"success_rate\", \"N/A\"):.1f}%')
        print(f'⏱️  Avg Response Time: {summary.get(\"avg_response_time\", \"N/A\"):.2f}s')
        print(f'📝 Avg Response Length: {summary.get(\"avg_response_length\", \"N/A\"):.0f} chars')
        
        print(f'\\n📊 Full results: /home/yw/Desktop/OPEA/evaluation_results/chatqna_quick_test.json')
except Exception as e:
    print('❌ Error reading results:', str(e))
"
    else
        print_error "Results file not found"
    fi
}

# Main execution
main() {
    echo "Starting quick ChatQnA test..."
    echo ""
    
    if ! check_services; then
        start_chatqna
    fi
    
    test_service
    run_quick_eval
    show_results
    
    echo ""
    echo "🎉 Quick test completed!"
    echo ""
    echo "Next steps:"
    echo "1. View detailed results: cat /home/yw/Desktop/OPEA/evaluation_results/chatqna_quick_test.json"
    echo "2. Access ChatQnA UI: http://localhost:5173"
    echo "3. Stop services: cd /home/yw/Desktop/OPEA/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm && docker compose down"
    echo "4. Run full evaluation: /home/yw/Desktop/OPEA/quick_eval_setup.sh"
}

# Handle command line arguments
case "${1:-}" in
    "start-only")
        start_chatqna
        test_service
        ;;
    "test-only")
        test_service
        ;;
    "eval-only")
        run_quick_eval
        show_results
        ;;
    "stop")
        print_status "Stopping ChatQnA services..."
        cd /home/yw/Desktop/OPEA/GenAIExamples/ChatQnA/docker_compose/amd/gpu/rocm
        docker compose down
        print_success "Services stopped"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (no args)    Complete quick test (start + test + evaluate)"
        echo "  start-only   Only start ChatQnA services"
        echo "  test-only    Only test if service is responding"
        echo "  eval-only    Only run evaluation (assumes services are running)"
        echo "  stop         Stop all ChatQnA services"
        echo "  help         Show this help message"
        ;;
    *)
        main
        ;;
esac 