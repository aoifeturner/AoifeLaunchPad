#!/bin/bash

# AvatarChatbot TGI Example Usage Script
# Demonstrates how to interact with the AvatarChatbot backend

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_header() { echo -e "${BLUE}================================${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}================================${NC}"; }

BACKEND_URL="http://localhost:8888/v1/avatarchatbot"

check_services() {
    print_header "Checking Service Status"
    if ! docker ps --format "{{.Names}}" | grep -q "avatarchatbot-backend-server"; then
        print_warning "AvatarChatbot backend service is not running. Please start it first."; exit 1;
    fi
    print_status "AvatarChatbot backend service is running"
}

ask_questions() {
    print_header "Asking Sample Questions"
    questions=(
        "What is AvatarChatbot?"
        "How does TGI work?"
        "Tell me a joke."
        "What is deep learning?"
        "Who created you?"
    )
    for question in "${questions[@]}"; do
        print_status "Question: $question"
        response=$(curl -s "$BACKEND_URL" \
            -H "Content-Type: application/json" \
            -d "{\"messages\": \"$question\"}")
        if [ $? -eq 0 ]; then
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
        sleep 1
    done
}

batch_processing() {
    print_header "Batch Processing Example"
    questions=(
        "What is AI?"
        "Explain AvatarChatbot."
        "What is TGI?"
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
            echo "\u2713 Question $((i+1)) processed"
        else
            echo "\u2717 Question $((i+1)) failed"
        fi
    done
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc -l)
    echo ""
    print_status "Batch processing completed in ${duration}s"
    print_status "Average time per question: $(echo "scale=3; $duration / ${#questions[@]}" | bc -l)s"
}

error_handling() {
    print_header "Error Handling Examples"
    print_status "Testing with invalid JSON..."
    response=$(curl -s "$BACKEND_URL" \
        -H "Content-Type: application/json" \
        -d '{"invalid": "data"}' \
        -w "%{http_code}")
    http_code="${response: -3}"
    if [ "$http_code" != "200" ]; then
        print_status "\u2713 Properly handled invalid JSON (HTTP $http_code)"
    else
        print_warning "\u26a0 Unexpected response for invalid JSON"
    fi
    print_status "Testing with empty request..."
    response=$(curl -s "$BACKEND_URL" \
        -H "Content-Type: application/json" \
        -d '{}' \
        -w "%{http_code}")
    http_code="${response: -3}"
    if [ "$http_code" != "200" ]; then
        print_status "\u2713 Properly handled empty request (HTTP $http_code)"
    else
        print_warning "\u26a0 Unexpected response for empty request"
    fi
}

show_api_endpoints() {
    print_header "Available API Endpoints"
    echo "Backend API: $BACKEND_URL"
    echo ""
    echo "Example API call:"
    echo "curl -X POST $BACKEND_URL \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '{\"messages\": \"What is AvatarChatbot?\"}'"
}

show_monitoring() {
    print_header "Monitoring Information"
    echo "Service Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep avatarchatbot
    echo ""
    echo "Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep avatarchatbot
    echo ""
    echo "Recent Logs (last 5 lines):"
    docker compose logs --tail=5 avatarchatbot-backend-server
}

show_help() {
    echo "AvatarChatbot TGI Example Usage Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  ask            Ask sample questions"
    echo "  batch          Demonstrate batch processing"
    echo "  errors         Test error handling"
    echo "  api            Show API endpoints"
    echo "  monitor        Show monitoring information"
    echo "  all            Run all examples"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ask         # Ask sample questions"
    echo "  $0 all         # Run all examples"
}

main() {
    case "${1:-help}" in
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

main "$@" 