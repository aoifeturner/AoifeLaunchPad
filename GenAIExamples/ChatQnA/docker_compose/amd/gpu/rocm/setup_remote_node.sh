#!/bin/bash

# Remote Node Setup Script for ChatQnA
# This script handles all the common issues when setting up ChatQnA on remote nodes
# including HF token authentication, port conflicts, and Redis index issues

set -e

echo "🚀 ChatQnA Remote Node Setup Script"
echo "===================================="

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

# Check if we're in the right directory
check_directory() {
    print_status "Checking current directory..."
    
    if [ ! -f "docker-compose.yml" ]; then
        print_error "Please run this script from the ChatQnA docker-compose directory"
        print_status "Expected location: docker_compose/amd/gpu/rocm/"
        exit 1
    fi
    
    print_success "Found docker-compose.yml in current directory"
}

# Check and fix HF token
fix_hf_token() {
    print_status "Checking Hugging Face token configuration..."
    
    if [ -f ".env" ]; then
        # Check if HF_TOKEN exists and is properly formatted
        if grep -q "^HF_TOKEN=" .env; then
            token_line=$(grep "^HF_TOKEN=" .env)
            
            # Check if token has a comment without space (common issue)
            if echo "$token_line" | grep -q "hf_"; then
                if echo "$token_line" | grep -q "#"; then
                    print_warning "Found HF_TOKEN with comment, checking format..."
                    
                    # Extract token and check if it's truncated
                    token=$(echo "$token_line" | cut -d'=' -f2 | cut -d'#' -f1 | tr -d ' ')
                    
                    if [ ${#token} -lt 30 ]; then
                        print_error "HF_TOKEN appears to be truncated due to comment format"
                        print_status "Please update .env file to ensure proper token format:"
                        echo "  HF_TOKEN=your_token_here  # Optional comment"
                        echo ""
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

# Check for port conflicts
check_port_conflicts() {
    print_status "Checking for port conflicts..."
    
    conflicts=()
    
    # Check port 80 (common conflict with Caddy)
    if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
        conflicts+=("80")
    fi
    
    # Check port 5173 (frontend)
    if netstat -tlnp 2>/dev/null | grep -q ":5173 "; then
        conflicts+=("5173")
    fi
    
    # Check port 8889 (backend)
    if netstat -tlnp 2>/dev/null | grep -q ":8889 "; then
        conflicts+=("8889")
    fi
    
    # Check port 7000 (retriever)
    if netstat -tlnp 2>/dev/null | grep -q ":7000 "; then
        conflicts+=("7000")
    fi
    
    if [ ${#conflicts[@]} -gt 0 ]; then
        print_warning "Found port conflicts on ports: ${conflicts[*]}"
        print_status "If you encounter port conflicts, you may need to:"
        echo "  1. Stop conflicting services"
        echo "  2. Or modify ports in compose.yaml"
        echo ""
        echo "Common solutions:"
        echo "  - Stop Caddy: sudo systemctl stop caddy"
        echo "  - Change nginx port from 80 to 8080 in .env files"
        return 1
    else
        print_success "No port conflicts detected"
        return 0
    fi
}

# Setup virtual environment
setup_virtual_env() {
    print_status "Setting up Python virtual environment..."
    
    if [ ! -d "opea_eval_env" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv opea_eval_env
        print_success "Virtual environment created"
    else
        print_status "Virtual environment already exists"
    fi
    
    # Check if activate script exists
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
    pip install -r ../../../requirements.txt
    
    print_success "Virtual environment setup complete"
}

# Start services
start_services() {
    print_status "Starting ChatQnA services..."
    
    # Stop any existing services first
    docker-compose down 2>/dev/null || true
    
    # Start services
    docker-compose up -d
    
    print_success "Services started"
    print_status "Waiting for services to initialize..."
    sleep 30
}

# Test services
test_services() {
    print_status "Testing services..."
    
    # Test retriever
    print_status "Testing retriever service..."
    if curl -s http://localhost:7000/health > /dev/null 2>&1; then
        print_success "Retriever service is responding"
    else
        print_warning "Retriever service may still be starting"
    fi
    
    # Test backend
    print_status "Testing backend service..."
    if curl -s http://localhost:8889/health > /dev/null 2>&1; then
        print_success "Backend service is responding"
    else
        print_warning "Backend service may still be starting"
    fi
    
    # Test frontend
    print_status "Testing frontend service..."
    if curl -s http://localhost:5173 > /dev/null 2>&1; then
        print_success "Frontend service is responding"
    else
        print_warning "Frontend service may still be starting"
    fi
}

# Main execution
main() {
    echo "Starting remote node setup..."
    echo ""
    
    # Check directory
    check_directory
    
    # Check HF token
    if ! fix_hf_token; then
        print_error "Please fix HF_TOKEN configuration and run again"
        exit 1
    fi
    
    # Check port conflicts
    check_port_conflicts
    
    # Setup virtual environment
    setup_virtual_env
    
    # Start services
    start_services
    
    # Test services
    test_services
    
    echo ""
    print_success "Setup completed!"
    echo ""
    echo "Next steps:"
    echo "1. Run Redis index fix: ./fix_redis_index.sh"
    echo "2. Test the system: ./quick_test_chatqna.sh eval-only"
    echo "3. Access the UI: http://localhost:5173"
    echo ""
    echo "If you encounter issues:"
    echo "- Check logs: docker-compose logs -f"
    echo "- Restart services: docker-compose restart"
    echo "- Check Redis index: ./fix_redis_index.sh check-only"
}

# Handle command line arguments
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
