#!/bin/bash

# ChatQnA vLLM Example Usage Script
# This script demonstrates how to interact with the ChatQnA system

set -e

# Colors for output
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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Configuration
BACKEND_URL="http://localhost:8890/v1/chatqna"
DATAPREP_URL="http://localhost:18104/v1/dataprep/ingest"
FRONTEND_URL="http://localhost:8081"

# Function to check if services are running
check_services() {
    print_header "Checking Service Status"
    
    if ! docker ps --format "{{.Names}}" | grep -q "chatqna-vllm-service"; then
        print_warning "vLLM services are not running. Please start them first:"
        print_status "./run_chatqna.sh start-vllm"
        exit 1
    fi
    
    print_status "vLLM services are running"
}

# Function to upload sample documents
upload_documents() {
    print_header "Uploading Sample Documents"
    
    # Sample documents for testing
    documents=(
        '{"file_name": "ai_introduction.txt", "content": "Artificial Intelligence (AI) is a branch of computer science that aims to create intelligent machines that work and react like humans. Some of the activities computers with artificial intelligence are designed for include speech recognition, learning, planning, and problem solving."}'
        '{"file_name": "machine_learning.txt", "content": "Machine Learning is a subset of artificial intelligence that enables computers to learn and improve from experience without being explicitly programmed. It focuses on developing computer programs that can access data and use it to learn for themselves."}'
        '{"file_name": "deep_learning.txt", "content": "Deep Learning is a subset of machine learning that uses neural networks with multiple layers to model and understand complex patterns. It has been particularly successful in areas like image recognition, natural language processing, and speech recognition."}'
        '{"file_name": "neural_networks.txt", "content": "Neural Networks are computing systems inspired by biological neural networks. They consist of interconnected nodes (neurons) that process information and can learn to recognize patterns in data."}'
        '{"file_name": "nlp_overview.txt", "content": "Natural Language Processing (NLP) is a field of artificial intelligence that focuses on the interaction between computers and human language. It involves developing algorithms and models that can understand, interpret, and generate human language."}'
    )
    
    for doc in "${documents[@]}"; do
        print_status "Uploading document..."
        response=$(curl -s -X POST "$DATAPREP_URL" \
            -H "Content-Type: application/json" \
            -d "$doc")
        
        if [ $? -eq 0 ]; then
            print_status "✓ Document uploaded successfully"
        else
            print_warning "⚠ Failed to upload document"
        fi
    done
}

# Function to ask questions
ask_questions() {
    print_header "Asking Sample Questions"
    
    # Sample questions
    questions=(
        "What is artificial intelligence?"
        "How does machine learning work?"
        "Explain deep learning"
        "What are neural networks?"
        "What is natural language processing?"
    )
    
    for question in "${questions[@]}"; do
        print_status "Question: $question"
        
        response=$(curl -s "$BACKEND_URL" \
            -H "Content-Type: application/json" \
            -d "{\"messages\": \"$question\"}")
        
        if [ $? -eq 0 ]; then
            # Extract the answer from the response (assuming JSON format)
            answer=$(echo "$response" | grep -o '"response":"[^"]*"' | cut -d'"' -f4)
            if [ -n "$answer" ]; then
                echo "Answer: $answer"
            else
                echo "Response: $response"
            fi
        else
            print_warning "Failed to get response"
        fi
        
        echo ""
        sleep 1  # Small delay between requests
    done
}

# Function to demonstrate batch processing
batch_processing() {
    print_header "Batch Processing Example"
    
    # Create a batch of questions
    questions=(
        "What is AI?"
        "Explain ML"
        "What is DL?"
        "How do neural networks work?"
        "What is NLP?"
    )
    
    print_status "Processing ${#questions[@]} questions in batch..."
    
    start_time=$(date +%s.%N)
    
    for i in "${!questions[@]}"; do
        question="${questions[$i]}"
        echo "Processing question $((i+1)): $question"
        
        response=$(curl -s "$BACKEND_URL" \
            -H "Content-Type: application/json" \
            -d "{\"messages\": \"$question\"}")
        
        if [ $? -eq 0 ]; then
            echo "✓ Question $((i+1)) processed"
        else
            echo "✗ Question $((i+1)) failed"
        fi
    done
    
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc -l)
    
    echo ""
    print_status "Batch processing completed in ${duration}s"
    print_status "Average time per question: $(echo "scale=3; $duration / ${#questions[@]}" | bc -l)s"
}

# Function to demonstrate error handling
error_handling() {
    print_header "Error Handling Examples"
    
    # Test with invalid JSON
    print_status "Testing with invalid JSON..."
    response=$(curl -s "$BACKEND_URL" \
        -H "Content-Type: application/json" \
        -d '{"invalid": "data"}' \
        -w "%{http_code}")
    
    http_code="${response: -3}"
    if [ "$http_code" != "200" ]; then
        print_status "✓ Properly handled invalid JSON (HTTP $http_code)"
    else
        print_warning "⚠ Unexpected response for invalid JSON"
    fi
    
    # Test with empty request
    print_status "Testing with empty request..."
    response=$(curl -s "$BACKEND_URL" \
        -H "Content-Type: application/json" \
        -d '{}' \
        -w "%{http_code}")
    
    http_code="${response: -3}"
    if [ "$http_code" != "200" ]; then
        print_status "✓ Properly handled empty request (HTTP $http_code)"
    else
        print_warning "⚠ Unexpected response for empty request"
    fi
}

# Function to demonstrate API endpoints
show_api_endpoints() {
    print_header "Available API Endpoints"
    
    echo "Backend API: $BACKEND_URL"
    echo "Dataprep API: $DATAPREP_URL"
    echo "Frontend: $FRONTEND_URL"
    echo ""
    
    echo "Example API calls:"
    echo ""
    echo "1. Ask a question:"
    echo "   curl -X POST $BACKEND_URL \\"
    echo "     -H \"Content-Type: application/json\" \\"
    echo "     -d '{\"messages\": \"What is AI?\"}'"
    echo ""
    echo "2. Upload a document:"
    echo "   curl -X POST $DATAPREP_URL \\"
    echo "     -H \"Content-Type: application/json\" \\"
    echo "     -d '{\"file_name\": \"test.txt\", \"content\": \"Your document content here.\"}'"
    echo ""
    echo "3. Check service health:"
    echo "   curl $BACKEND_URL"
}

# Function to demonstrate monitoring
show_monitoring() {
    print_header "Monitoring Information"
    
    echo "Service Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep chatqna
    
    echo ""
    echo "Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep chatqna
    
    echo ""
    echo "Recent Logs (last 5 lines):"
    docker compose -f compose_vllm.yaml logs --tail=5
}

# Function to show help
show_help() {
    echo "ChatQnA vLLM Example Usage Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  upload         Upload sample documents"
    echo "  ask            Ask sample questions"
    echo "  batch          Demonstrate batch processing"
    echo "  errors         Test error handling"
    echo "  api            Show API endpoints"
    echo "  monitor        Show monitoring information"
    echo "  all            Run all examples"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 upload      # Upload sample documents"
    echo "  $0 ask         # Ask sample questions"
    echo "  $0 all         # Run all examples"
}

# Main script logic
main() {
    case "${1:-help}" in
        "upload")
            check_services
            upload_documents
            ;;
        "ask")
            check_services
            ask_questions
            ;;
        "batch")
            check_services
            batch_processing
            ;;
        "errors")
            check_services
            error_handling
            ;;
        "api")
            show_api_endpoints
            ;;
        "monitor")
            check_services
            show_monitoring
            ;;
        "all")
            check_services
            upload_documents
            echo ""
            ask_questions
            echo ""
            batch_processing
            echo ""
            error_handling
            echo ""
            show_monitoring
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 