#!/bin/bash

# Detection Script for AvatarChatbot Issues
# Detects common issues for AvatarChatbot deployments

set -e

echo "🔍 AvatarChatbot Issue Detection Script"
echo "=================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_services() {
    print_status "Checking if AvatarChatbot services are running..."
    services=("avatarchatbot-backend-server" "tgi-service")
    missing_services=()
    for service in "${services[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "$service"; then
            print_success "$service is running"
        else
            print_error "$service is not running"
            missing_services+=("$service")
        fi
    done
    if [ ${#missing_services[@]} -gt 0 ]; then
        print_error "Missing services: ${missing_services[*]}"
        return 1
    fi
    return 0
}

test_backend() {
    print_status "Testing backend service..."
    response=$(curl -s -w "\n%{http_code}" http://localhost:8888/v1/avatarchatbot \
        -H "Content-Type: application/json" \
        -d '{"messages": "Hello"}' 2>/dev/null || echo "Connection failed")
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    if [ "$http_code" = "200" ]; then
        print_success "Backend service is working correctly"
        return 0
    else
        print_error "Backend service is failing (HTTP $http_code)"
        print_status "Response: $response_body"
        return 1
    fi
}

check_cors() {
    print_status "Checking for CORS configuration..."
    response=$(curl -s -I http://localhost:8888/v1/avatarchatbot 2>/dev/null || echo "")
    if echo "$response" | grep -q "Access-Control-Allow-Origin"; then
        print_success "CORS headers are configured"
        return 0
    else
        print_warning "CORS headers may not be configured properly"
        print_status "This could cause browser CORS errors"
        return 1
    fi
}

check_logs() {
    print_status "Checking backend logs for errors..."
    backend_errors=$(docker compose logs avatarchatbot-backend-server 2>/dev/null | grep -i "error\|fail" | tail -3 || echo "")
    if [ -n "$backend_errors" ]; then
        print_error "Found errors in backend logs:"
        echo "$backend_errors"
        return 1
    else
        print_success "No errors found in backend logs"
        return 0
    fi
}

main() {
    echo "Starting issue detection..."
    echo ""
    issues_found=0
    if ! check_services; then ((issues_found++)); fi
    if ! test_backend; then ((issues_found++)); fi
    if ! check_cors; then ((issues_found++)); fi
    if ! check_logs; then ((issues_found++)); fi
    echo ""
    if [ $issues_found -eq 0 ]; then
        print_success "No issues detected! System is working correctly."
    else
        print_error "Found $issues_found issue(s)"
        echo ""
        echo "Recommended fixes:"
        echo "1. If services are not running: docker compose up -d"
        echo "2. If CORS issues persist: check backend configuration"
        echo "3. For other issues: check logs with 'docker compose logs -f'"
    fi
}

case "${1:-}" in
    "services-only") check_services ;;
    "backend-only") test_backend ;;
    "cors-only") check_cors ;;
    "logs-only") check_logs ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (no args)    Complete detection (all checks)"
        echo "  services-only Check if all services are running"
        echo "  backend-only  Test backend service"
        echo "  cors-only     Check CORS configuration"
        echo "  logs-only     Check logs for errors"
        echo "  help          Show this help message"
        ;;
    *) main ;;
esac 