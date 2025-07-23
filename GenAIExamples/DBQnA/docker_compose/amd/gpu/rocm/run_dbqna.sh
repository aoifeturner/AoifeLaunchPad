#!/bin/bash

# Unified DBQnA Management Script
# This script provides a unified interface for all DBQnA operations

set -e

# Define paths for evaluation
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../../.." && pwd)"
GENAIEVAL_DIR="$BASEDIR/GenAIEval"
EVAL_RESULTS_DIR="$BASEDIR/evaluation_results"

# Colors for output
RED='\033[0;31m'
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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Function to check if required files exist
check_requirements() {
    local missing_files=()
    
    if [[ ! -f "compose_complete.yaml" ]]; then
        missing_files+=("compose_complete.yaml")
    fi
    
    if [[ ! -f "set_env_complete.sh" ]]; then
        missing_files+=("set_env_complete.sh")
    fi
    
    if [[ ! -f "chinook.sql" ]]; then
        missing_files+=("chinook.sql")
    fi
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required files: ${missing_files[*]}"
        print_error "Please run this script from the DBQnA/docker_compose/amd/gpu/rocm/ directory"
        exit 1
    fi
}

# Function to detect running services
detect_services() {
    TGI_RUNNING=$(docker ps --format "{{.Names}}" | grep -q "dbqna-tgi-service" && echo "yes" || echo "no")
    POSTGRES_RUNNING=$(docker ps --format "{{.Names}}" | grep -q "dbqna-postgres-db" && echo "yes" || echo "no")
    TEXT2SQL_RUNNING=$(docker ps --format "{{.Names}}" | grep -q "dbqna-text2sql-service" && echo "yes" || echo "no")
    UI_RUNNING=$(docker ps --format "{{.Names}}" | grep -q "dbqna-ui-server" && echo "yes" || echo "no")
    
    if [ "$TGI_RUNNING" = "yes" ]; then
        print_status "TGI service is running (port 8008)"
    fi
    if [ "$POSTGRES_RUNNING" = "yes" ]; then
        print_status "PostgreSQL service is running (port 5442)"
    fi
    if [ "$TEXT2SQL_RUNNING" = "yes" ]; then
        print_status "Text-to-SQL service is running (port 9090)"
    fi
    if [ "$UI_RUNNING" = "yes" ]; then
        print_status "UI service is running (port 5174)"
    fi
    if [ "$TGI_RUNNING" = "no" ] && [ "$POSTGRES_RUNNING" = "no" ] && [ "$TEXT2SQL_RUNNING" = "no" ] && [ "$UI_RUNNING" = "no" ]; then
        print_warning "No DBQnA services are currently running"
    fi
}

# Function to setup environment
setup_environment() {
    print_header "Setting up DBQnA Environment"
    check_docker
    check_requirements
    
    print_status "Setting up environment variables..."
    source set_env_complete.sh
    
    print_status "Environment setup complete!"
}

# Function to start DBQnA services
start_services() {
    print_header "Starting DBQnA Services"
    
    if [[ -z "$HOST_IP" ]]; then
        print_error "Environment not set up. Please run setup first."
        exit 1
    fi
    
    print_status "Starting DBQnA services with docker-compose..."
    docker-compose -f compose_complete.yaml up -d
    
    print_status "Waiting for services to start..."
    sleep 30
    
    # Check service status
    print_status "Checking service status..."
    docker-compose -f compose_complete.yaml ps
    
    print_status "DBQnA services started successfully!"
    print_status "Access points:"
    print_status "  - Frontend UI: http://${HOST_IP_EXTERNAL}:${DBQNA_FRONTEND_SERVICE_PORT}"
    print_status "  - Backend API: ${DBQNA_BACKEND_SERVICE_ENDPOINT}"
    print_status "  - Text-to-SQL API: ${DBQNA_TEXT_TO_SQL_ENDPOINT}"
    print_status "  - TGI Service: ${DBQNA_TGI_LLM_ENDPOINT}"
    print_status "  - PostgreSQL: ${HOST_IP_EXTERNAL}:${DBQNA_POSTGRES_PORT}"
}

# Function to stop DBQnA services
stop_services() {
    print_header "Stopping DBQnA Services"
    
    print_status "Stopping DBQnA services..."
    docker-compose -f compose_complete.yaml down
    
    print_status "DBQnA services stopped successfully!"
}

# Function to restart DBQnA services
restart_services() {
    print_header "Restarting DBQnA Services"
    
    stop_services
    sleep 5
    start_services
}

# Function to check service health
check_health() {
    print_header "Checking DBQnA Service Health"
    
    local services=(
        "dbqna-postgres-db:5432"
        "dbqna-tgi-service:80"
        "dbqna-text2sql-service:8080"
        "dbqna-ui-server:80"
    )
    
    for service in "${services[@]}"; do
        local container_name="${service%:*}"
        local port="${service#*:}"
        
        if docker ps --format "{{.Names}}" | grep -q "$container_name"; then
            print_status "Checking $container_name..."
            if docker exec "$container_name" curl -f "http://localhost:$port/health" > /dev/null 2>&1; then
                print_status "✓ $container_name is healthy"
            else
                print_warning "⚠ $container_name health check failed"
            fi
        else
            print_error "✗ $container_name is not running"
        fi
    done
}

# Function to view logs
view_logs() {
    print_header "DBQnA Service Logs"
    
    local service=${1:-"all"}
    
    if [[ "$service" == "all" ]]; then
        print_status "Showing logs for all services..."
        docker-compose -f compose_complete.yaml logs -f
    else
        print_status "Showing logs for $service..."
        docker-compose -f compose_complete.yaml logs -f "$service"
    fi
}

# Function to test the API
test_api() {
    print_header "Testing DBQnA API"
    
    if [[ -z "$HOST_IP_EXTERNAL" ]]; then
        print_error "Environment not set up. Please run setup first."
        exit 1
    fi
    
    print_status "Testing Text-to-SQL API..."
    
    local test_query='{
        "input_text": "Find the total number of Albums.",
        "conn_str": {
            "user": "'${POSTGRES_USER}'",
            "password": "'${POSTGRES_PASSWORD}'",
            "host": "'${HOST_IP_EXTERNAL}'",
            "port": "'${DBQNA_POSTGRES_PORT}'",
            "database": "'${POSTGRES_DB}'"
        }
    }'
    
    print_status "Sending test query..."
    echo "$test_query" | curl -X POST \
        -H "Content-Type: application/json" \
        -d @- \
        "${DBQNA_TEXT_TO_SQL_ENDPOINT}" \
        | jq '.' 2>/dev/null || cat
    
    print_status "API test completed!"
}

# Function to setup firewall
setup_firewall() {
    print_header "Setting up Firewall for DBQnA"
    
    if [[ $EUID -ne 0 ]]; then
        print_error "Firewall setup requires root privileges. Please run with sudo."
        exit 1
    fi
    
    if [[ -f "firewall_setup.sh" ]]; then
        print_status "Running firewall setup script..."
        bash firewall_setup.sh
    else
        print_error "Firewall setup script not found."
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup           Setup environment variables"
    echo "  start           Start DBQnA services"
    echo "  stop            Stop DBQnA services"
    echo "  restart         Restart DBQnA services"
    echo "  status          Show service status"
    echo "  health          Check service health"
    echo "  logs [SERVICE]  View service logs (default: all)"
    echo "  test            Test the API"
    echo "  firewall        Setup firewall (requires sudo)"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup"
    echo "  $0 start"
    echo "  $0 logs dbqna-tgi-service"
    echo "  sudo $0 firewall"
}

# Main script logic
case "${1:-help}" in
    setup)
        setup_environment
        ;;
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        detect_services
        docker-compose -f compose_complete.yaml ps
        ;;
    health)
        check_health
        ;;
    logs)
        view_logs "$2"
        ;;
    test)
        test_api
        ;;
    firewall)
        setup_firewall
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac 