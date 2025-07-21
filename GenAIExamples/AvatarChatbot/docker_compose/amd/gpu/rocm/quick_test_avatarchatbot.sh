#!/bin/bash

# Quick AvatarChatbot Test Script
# This script provides a fast way to test AvatarChatbot with lightweight settings

set -e

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../../.." && pwd)"
GENAIEXAMPLES_DIR="$BASEDIR/GenAIExamples"
GENAIEVAL_DIR="$BASEDIR/GenAIEval"
EVAL_RESULTS_DIR="$BASEDIR/evaluation_results"

echo "🚀 Quick AvatarChatbot Test Setup"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if services are already running
check_services() {
    print_status "Checking if AvatarChatbot services are running..."
    if docker ps --format "{{.Names}}" | grep -q "avatarchatbot-backend-server"; then
        print_warning "AvatarChatbot services are already running"
        return 0
    else
        print_status "No AvatarChatbot services found, will start them"
        return 1
    fi
}

# Start AvatarChatbot with lightweight configuration
start_avatar() {
    print_status "Starting AvatarChatbot with lightweight configuration..."
    cd "$GENAIEXAMPLES_DIR/AvatarChatbot/docker_compose/amd/gpu/rocm"

    source ./set_env-avatar.sh

    print_status "Stopping any existing services..."
    docker compose down 2>/dev/null || true

    print_status "Starting AvatarChatbot services..."
    docker compose up -d

    print_status "Waiting for services to be ready..."
    sleep 60

    if docker ps --format "{{.Names}}" | grep -q "avatarchatbot-backend-server"; then
        print_success "AvatarChatbot services started successfully"
    else
        print_error "Failed to start AvatarChatbot services"
        print_status "Check logs with: docker compose logs"
        exit 1
    fi
}

# Test the service
test_service() {
    print_status "Testing AvatarChatbot service..."
    sleep 30

    print_status "Sending test query..."

    response=$(curl -s -w "\n%{http_code}" http://localhost:8890/v1/avatarchat \
        -H "Content-Type: application/json" \
        -d '{"messages": "Hello"}' 2>/dev/null || echo "Connection failed")

    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)

    if [ "$http_code" = "200" ]; then
        print_success "AvatarChatbot service is responding correctly!"
        print_status "Response preview: ${response_body:0:100}..."
    else
        print_warning "Service may still be starting up (HTTP $http_code)"
        print_status "Response: $response_body"
    fi
}

# Run quick evaluation
run_quick_eval() {
    print_status "Running quick evaluation..."

    cd "$GENAIEVAL_DIR"
    print_status "Changed to directory: $(pwd)"

    if [ -d "opea_eval_env" ]; then
        print_status "Found existing virtual environment, activating..."
        source opea_eval_env/bin/activate
    else
        print_warning "GenAIEval environment not found, creating it..."
        python3 -m venv opea_eval_env
        source opea_eval_env/bin/activate
        pip install -r requirements.txt
        pip install -e .
    fi

    mkdir -p "$EVAL_RESULTS_DIR"

    print_status "Running lightweight evaluation (should complete in 1-2 minutes)..."
    python evals/benchmark/chatqna_lightweight_eval.py \
        --service-url http://localhost:8890 \
        --output "$EVAL_RESULTS_DIR/avatarchat_quick_test.json"

    print_success "Quick evaluation completed!"
}

# Show results
show_results() {
    print_status "Quick Test Results:"
    echo "====================="

    if [ -f "$EVAL_RESULTS_DIR/avatarchat_quick_test.json" ]; then
        python3 -c "
import json
try:
    with open('$EVAL_RESULTS_DIR/avatarchat_quick_test.json', 'r') as f:
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

        print(f'\\n📊 Full results: $EVAL_RESULTS_DIR/avatarchat_quick_test.json')
except Exception as e:
    print('❌ Error reading results:', str(e))
"
    else
        print_error "Results file not found"
    fi
}

# Main execution
main() {
    echo "Starting quick AvatarChatbot test..."
    echo ""

    if ! check_services; then
        start_avatar
    fi

    test_service
    run_quick_eval
    show_results

    echo ""
    echo "🎉 Quick test completed!"
    echo ""
    echo "Next steps:"
    echo "1. View detailed results: cat $EVAL_RESULTS_DIR/avatarchat_quick_test.json"
    echo "2. Access AvatarChatbot UI: http://localhost:5174"
    echo "3. Stop services: cd $GENAIEXAMPLES_DIR/AvatarChatbot/docker_compose/amd/gpu/rocm && docker compose down"
    echo "4. Run full evaluation: $BASEDIR/quick_eval_setup.sh"
}

# Handle command line arguments
case "${1:-}" in
    "start-only")
        start_avatar
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
        print_status "Stopping AvatarChatbot services..."
        cd "$GENAIEXAMPLES_DIR/AvatarChatbot/docker_compose/amd/gpu/rocm"
        docker compose down
        print_success "Services stopped"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (no args)    Complete quick test (start + test + evaluate)"
        echo "  start-only   Only start AvatarChatbot services"
        echo "  test-only    Only test if service is responding"
        echo "  eval-only    Only run evaluation (assumes services are running)"
        echo "  stop         Stop all AvatarChatbot services"
        echo "  help         Show this help message"
        ;;
    *)
        main
        ;;
esac
