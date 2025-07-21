#!/bin/bash

# Remote Node Setup Script for AvatarChatbot
# Handles common setup issues for AvatarChatbot on remote nodes
# including HF token authentication, port conflicts, and service health

set -e

echo "🚀 AvatarChatbot Remote Node Setup Script"
echo "===================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_directory() {
    print_status "Checking current directory..."
    if [ ! -f "compose.yaml" ]; then
        print_error "Please run this script from the AvatarChatbot docker_compose directory"
        print_status "Expected location: docker_compose/amd/gpu/rocm/"
        exit 1
    fi
    print_success "Found compose.yaml in current directory"
}

fix_hf_token() {
    print_status "Checking Hugging Face token configuration..."
    if [ -f ".env" ]; then
        if grep -q "^HF_TOKEN=" .env; then
            token_line=$(grep "^HF_TOKEN=" .env)
            if echo "$token_line" | grep -q "hf_"; then
                if echo "$token_line" | grep -q "#"; then
                    print_warning "Found HF_TOKEN with comment, checking format..."
                    token=$(echo "$token_line" | cut -d'=' -f2 | cut -d'#' -f1 | tr -d ' ')
                    if [ ${#token} -lt 30 ]; then
                        print_error "HF_TOKEN appears to be truncated due to comment format"
                        print_status "Please update .env file to ensure proper token format:"
                        echo "  HF_TOKEN=your_token_here  # Optional comment"
                        echo "Make sure there's a space before the # comment"
                        return 1
                    fi
                fi
            fi
        else
            print_warning "HF_TOKEN not found in .env file"
            print_status "Please add your Hugging Face token to .env file:"
            echo "  HF_TOKEN=your_token_here"
            return 1
        fi
    else
        print_warning ".env file not found"
        print_status "Please create .env file with your HF_TOKEN"
        return 1
    fi
    print_success "HF_TOKEN configuration looks good"
    return 0
}

check_port_conflicts() {
    print_status "Checking for port conflicts..."
    conflicts=()
    # Check port 80 (TGI)
    if netstat -tlnp 2>/dev/null | grep -q ":80 "; then conflicts+=("80"); fi
    # Check port 8888 (backend)
    if netstat -tlnp 2>/dev/null | grep -q ":8888 "; then conflicts+=("8888"); fi
    # Check port 3000 (Grafana)
    if netstat -tlnp 2>/dev/null | grep -q ":3000 "; then conflicts+=("3000"); fi
    # Check port 9090 (Prometheus)
    if netstat -tlnp 2>/dev/null | grep -q ":9090 "; then conflicts+=("9090"); fi
    if [ ${#conflicts[@]} -gt 0 ]; then
        print_warning "Found port conflicts on ports: ${conflicts[*]}"
        print_status "If you encounter port conflicts, you may need to:"
        echo "  1. Stop conflicting services"
        echo "  2. Or modify ports in compose.yaml"
        return 1
    else
        print_success "No port conflicts detected"
        return 0
    fi
}

setup_virtual_env() {
    print_status "Setting up Python virtual environment..."
    if [ ! -d "opea_eval_env" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv opea_eval_env
        print_success "Virtual environment created"
    else
        print_status "Virtual environment already exists"
    fi
    if [ ! -f "opea_eval_env/bin/activate" ]; then
        print_error "Virtual environment is corrupted or incomplete"
        print_status "Removing and recreating..."
        rm -rf opea_eval_env
        python3 -m venv opea_eval_env
        print_success "Virtual environment recreated"
    fi
    print_status "Installing dependencies..."
    source opea_eval_env/bin/activate
    pip install --upgrade pip
    if [ -f ../../../requirements.txt ]; then
        pip install -r ../../../requirements.txt
    fi
    print_success "Virtual environment setup complete"
}

start_services() {
    print_status "Starting AvatarChatbot services..."
    docker compose down 2>/dev/null || true
    docker compose up -d
    print_success "Services started"
    print_status "Waiting for services to initialize..."
    sleep 30
}

test_services() {
    print_status "Testing services..."
    # Test backend
    print_status "Testing backend service..."
    if curl -s http://localhost:8888/health > /dev/null 2>&1; then
        print_success "Backend service is responding"
    else
        print_warning "Backend service may still be starting"
    fi
    # Test TGI
    print_status "Testing TGI service..."
    if curl -s http://localhost:80 > /dev/null 2>&1; then
        print_success "TGI service is responding"
    else
        print_warning "TGI service may still be starting"
    fi
    # Test Grafana (optional)
    print_status "Testing Grafana (if running)..."
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        print_success "Grafana is responding"
    else
        print_warning "Grafana may not be running or is still starting"
    fi
    # Test Prometheus (optional)
    print_status "Testing Prometheus (if running)..."
    if curl -s http://localhost:9090 > /dev/null 2>&1; then
        print_success "Prometheus is responding"
    else
        print_warning "Prometheus may not be running or is still starting"
    fi
}

main() {
    echo "Starting remote node setup..."
    echo ""
    check_directory
    if ! fix_hf_token; then
        print_error "Please fix HF_TOKEN configuration and run again"
        exit 1
    fi
    check_port_conflicts
    setup_virtual_env
    start_services
    test_services
    echo ""
    print_success "Setup completed!"
    echo ""
    echo "Next steps:"
    echo "1. Test the system: ./quick_eval_setup.sh eval-only"
    echo "2. Access the backend: http://localhost:8888"
    echo "3. Access Grafana: http://localhost:3000"
    echo "4. Access Prometheus: http://localhost:9090"
    echo ""
    echo "If you encounter issues:"
    echo "- Check logs: docker compose logs -f"
    echo "- Restart services: docker compose restart"
}

case "${1:-}" in
    "check-only")
        check_directory
        fix_hf_token
        check_port_conflicts
        ;;
    "start-only")
        start_services
        test_services
        ;;
    "env-only")
        setup_virtual_env
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (no args)    Complete setup (check + env + start + test)"
        echo "  check-only   Only check configuration and ports"
        echo "  start-only   Only start the services"
        echo "  env-only     Only setup virtual environment"
        echo "  help         Show this help message"
        ;;
    *)
        main
        ;;
esac
