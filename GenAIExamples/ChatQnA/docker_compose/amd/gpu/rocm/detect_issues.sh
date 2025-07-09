#!/bin/bash

# Detection Script for ChatQnA Issues on Fresh Remote Nodes
# This script detects common issues that occur on new deployments

set -e

echo "🔍 ChatQnA Issue Detection Script"
echo "=================================="

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

# Check if services are running
check_services() {
    print_status "Checking if ChatQnA services are running..."
    
    services=("chatqna-backend-server" "chatqna-retriever" "chatqna-redis-vector-db")
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

# Check Redis index
check_redis_index() {
    print_status "Checking Redis index..."
    
    if docker exec chatqna-redis-vector-db redis-cli FT.INFO rag-redis > /dev/null 2>&1; then
        print_success "Redis index 'rag-redis' exists"
        return 0
    else
        print_error "Redis index 'rag-redis' is missing"
        print_status "This will cause retriever service to fail"
        return 1
    fi
}

# Test retriever service
test_retriever() {
    print_status "Testing retriever service..."
    
    response=$(curl -s -w "\n%{http_code}" http://localhost:7000/v1/retrieval \
        -H "Content-Type: application/json" \
        -d '{"query": "test", "top_k": 3}' 2>/dev/null || echo "Connection failed")
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        print_success "Retriever service is working correctly"
        return 0
    else
        print_error "Retriever service is failing (HTTP $http_code)"
        print_status "Response: $response_body"
        return 1
    fi
}

# Test backend service
test_backend() {
    print_status "Testing backend service..."
    
    response=$(curl -s -w "\n%{http_code}" http://localhost:8889/v1/chatqna \
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

# Check for CORS issues
check_cors() {
    print_status "Checking for CORS configuration..."
    
    # Test if backend returns CORS headers
    response=$(curl -s -I http://localhost:8889/v1/chatqna 2>/dev/null || echo "")
    
    if echo "$response" | grep -q "Access-Control-Allow-Origin"; then
        print_success "CORS headers are configured"
        return 0
    else
        print_warning "CORS headers may not be configured properly"
        print_status "This could cause browser CORS errors"
        return 1
    fi
}

# Check logs for errors
check_logs() {
    print_status "Checking service logs for errors..."
    
    # Check retriever logs for Redis errors
    redis_errors=$(docker-compose logs retriever 2>/dev/null | grep -i "redis\|index" | tail -3 || echo "")
    
    if [ -n "$redis_errors" ]; then
        print_error "Found Redis-related errors in retriever logs:"
        echo "$redis_errors"
        return 1
    else
        print_success "No Redis errors found in retriever logs"
        return 0
    fi
}

# Main detection function
main() {
    echo "Starting issue detection..."
    echo ""
    
    issues_found=0
    
    # Check services
    if ! check_services; then
        ((issues_found++))
    fi
    
    # Check Redis index
    if ! check_redis_index; then
        ((issues_found++))
    fi
    
    # Test retriever
    if ! test_retriever; then
        ((issues_found++))
    fi
    
    # Test backend
    if ! test_backend; then
        ((issues_found++))
    fi
    
    # Check CORS
    if ! check_cors; then
        ((issues_found++))
    fi
    
    # Check logs
    if ! check_logs; then
        ((issues_found++))
    fi
    
    echo ""
    if [ $issues_found -eq 0 ]; then
        print_success "No issues detected! System is working correctly."
    else
        print_error "Found $issues_found issue(s)"
        echo ""
        echo "Recommended fixes:"
        echo "1. If Redis index is missing: ./fix_redis_index.sh"
        echo "2. If services are not running: docker-compose up -d"
        echo "3. If CORS issues persist: check backend configuration"
        echo "4. For other issues: check logs with 'docker-compose logs -f'"
    fi
}

# Handle command line arguments
case "${1:-}" in
    "services-only")
        check_services
        ;;
    "redis-only")
        check_redis_index
        ;;
    "retriever-only")
        test_retriever
        ;;
    "backend-only")
        test_backend
        ;;
    "cors-only")
        check_cors
        ;;
    "logs-only")
        check_logs
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (no args)    Complete detection (all checks)"
        echo "  services-only Check if all services are running"
        echo "  redis-only    Check Redis index status"
        echo "  retriever-only Test retriever service"
        echo "  backend-only  Test backend service"
        echo "  cors-only     Check CORS configuration"
        echo "  logs-only     Check logs for errors"
        echo "  help          Show this help message"
        ;;
    *)
        main
        ;;
esac 