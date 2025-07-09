#!/bin/bash

# Fix Redis Index Script for ChatQnA Remote Nodes
# This script fixes the "rag-redis: no such index" error on remote nodes
# with newer Docker images that have stricter error handling

set -e

echo "🔧 Fixing Redis Index for ChatQnA Remote Node"
echo "=============================================="

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
    
    if docker ps --format "{{.Names}}" | grep -q "chatqna-backend-server"; then
        print_success "ChatQnA services are running"
        return 0
    else
        print_error "ChatQnA services are not running. Please start them first with:"
        echo "  ./run_chatqna.sh start"
        exit 1
    fi
}

# Check if Redis index exists
check_redis_index() {
    print_status "Checking if Redis index exists..."
    
    # Connect to Redis and check if rag-redis index exists
    if docker exec chatqna-redis-vector-db redis-cli FT.INFO rag-redis > /dev/null 2>&1; then
        print_success "Redis index 'rag-redis' already exists"
        return 0
    else
        print_warning "Redis index 'rag-redis' does not exist. Creating it..."
        return 1
    fi
}

# Create Redis index
create_redis_index() {
    print_status "Creating Redis index 'rag-redis'..."
    
    # Create the index with the correct schema
    docker exec chatqna-redis-vector-db redis-cli FT.CREATE rag-redis ON HASH PREFIX 1 doc: SCHEMA content TEXT WEIGHT 1.0 distance NUMERIC
    
    if [ $? -eq 0 ]; then
        print_success "Redis index 'rag-redis' created successfully"
    else
        print_error "Failed to create Redis index"
        exit 1
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
        print_success "Retriever service is working correctly!"
        print_status "Response: $response_body"
    else
        print_error "Retriever service is still failing (HTTP $http_code)"
        print_status "Response: $response_body"
        exit 1
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
        print_success "Backend service is working correctly!"
        print_status "Response preview: ${response_body:0:100}..."
    else
        print_warning "Backend service may still be starting up (HTTP $http_code)"
        print_status "Response: $response_body"
    fi
}

# Main execution
main() {
    echo "Starting Redis index fix..."
    echo ""
    
    # Check if services are running
    check_services
    
    # Check if Redis index exists
    if check_redis_index; then
        print_success "Redis index already exists, testing services..."
    else
        # Create the index
        create_redis_index
    fi
    
    # Test services
    test_retriever
    test_backend
    
    echo ""
    print_success "Redis index fix completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Test the full system: ./quick_test_chatqna.sh eval-only"
    echo "2. Access the UI: http://localhost:5173"
    echo "3. If you need to ingest documents, you'll need to find the correct dataprep API format"
    echo ""
    echo "Note: The system will work with empty results until documents are ingested."
}

# Handle command line arguments
case "${1:-}" in
    "check-only")
        check_services
        check_redis_index
        test_retriever
        test_backend
        ;;
    "create-only")
        create_redis_index
        ;;
    "test-only")
        test_retriever
        test_backend
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (no args)    Complete fix (check + create + test)"
        echo "  check-only   Only check services and index status"
        echo "  create-only  Only create the Redis index"
        echo "  test-only    Only test the services"
        echo "  help         Show this help message"
        ;;
    *)
        main
        ;;
esac 