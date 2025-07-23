#!/bin/bash

# Unified AvatarChatbot Management Script (TGI Backend Only)
# This script provides a unified interface for all AvatarChatbot operations using TGI as the LLM backend

set -e

# Define paths for evaluation
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../../.." && pwd)"
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
    if [[ ! -f "compose.yaml" ]]; then
        missing_files+=("compose.yaml")
    fi
    if [[ ! -f "set_env.sh" ]]; then
        missing_files+=("set_env.sh")
    fi
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required files: ${missing_files[*]}"
        print_error "Please run this script from the AvatarChatbot/docker_compose/amd/gpu/rocm/ directory"
        exit 1
    fi
}

# Function to detect running services
check_services() {
    TGI_RUNNING=$(docker ps --format "{{.Names}}" | grep -q "tgi-service" && echo "yes" || echo "no")
    BACKEND_RUNNING=$(docker ps --format "{{.Names}}" | grep -q "avatarchatbot-backend-server" && echo "yes" || echo "no")
    if [ "$TGI_RUNNING" = "yes" ]; then
        print_status "TGI (LLM) service is running (tgi-service, port 3006->80)"
    fi
    if [ "$BACKEND_RUNNING" = "yes" ]; then
        print_status "AvatarChatbot backend is running (avatarchatbot-backend-server, port 3009->8888)"
    fi
    if [ "$TGI_RUNNING" = "no" ] && [ "$BACKEND_RUNNING" = "no" ]; then
        print_warning "No AvatarChatbot/TGI services are currently running"
    fi
}

# Function to setup environment
setup_environment() {
    print_header "Setting up AvatarChatbot Environment (TGI)"
    check_docker
    check_requirements
    print_status "Setting up environment variables..."
    source set_env.sh
    print_status "Environment setup complete!"
}

# Function to start all services
start_services() {
    print_header "Starting AvatarChatbot Services (TGI Backend)"
    check_docker
    check_requirements
    print_status "Starting all services with docker compose..."
    docker compose -f compose.yaml up -d
    print_status "All services started! Check logs with: docker compose -f compose.yaml logs -f"
}

# Function to stop all services
stop_services() {
    print_header "Stopping AvatarChatbot Services"
    check_docker
    print_status "Stopping all services..."
    docker compose -f compose.yaml down
    print_status "All services stopped!"
}

# Function to restart all services
restart_services() {
    print_header "Restarting AvatarChatbot Services"
    stop_services
    sleep 2
    start_services
}

# Function to start monitoring
start_monitoring() {
    print_header "Starting Monitoring Stack"
    check_docker
    
    print_status "Starting Prometheus and Grafana..."
    ./start_monitoring.sh
    
    print_status "Monitoring stack started!"
    print_status "Grafana: http://localhost:3000 (admin/admin)"
    print_status "Prometheus: http://localhost:9090"
}

# Function to stop monitoring
stop_monitoring() {
    print_header "Stopping Monitoring Stack"
    check_docker
    if [[ -f "compose.telemetry.yaml" ]]; then
        print_status "Stopping monitoring services..."
        docker compose -f compose.telemetry.yaml down
        print_status "Monitoring stack stopped!"
    else
        print_warning "compose.telemetry.yaml not found. Skipping monitoring shutdown."
    fi
}

# Function to show logs
show_logs() {
    print_header "Showing AvatarChatbot Service Logs"
    check_docker
    print_status "Showing logs (Ctrl+C to exit)..."
    docker compose -f compose.yaml logs -f
}

# Function to check service status
check_status() {
    print_header "Service Status"
    check_docker
    print_status "AvatarChatbot Services:"
    docker compose -f compose.yaml ps
    echo ""
    check_services
}

# Function to clean up
cleanup() {
    print_header "Cleaning Up All Services"
    check_docker
    print_warning "This will stop all AvatarChatbot and monitoring services and remove containers. Continue? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_status "Stopping all services..."
        docker compose -f compose.yaml down
        if [[ -f "compose.telemetry.yaml" ]]; then
            docker compose -f compose.telemetry.yaml down
        fi
        print_status "Removing containers..."
        docker system prune -f
        print_status "Cleanup complete!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Function to show help
show_help() {
    print_header "Unified AvatarChatbot Management Script Help (TGI Backend Only)"
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Environment Setup:"
    echo "  setup           - Setup environment variables"
    echo ""
    echo "Service Management:"
    echo "  start           - Start all AvatarChatbot services"
    echo "  stop            - Stop all AvatarChatbot services"
    echo "  restart         - Restart all AvatarChatbot services"
    echo ""
    echo "Monitoring:"
    echo "  monitor-start   - Start monitoring stack"
    echo "  monitor-stop    - Stop monitoring stack"
    echo ""
    echo "Logs and Status:"
    echo "  logs            - Show AvatarChatbot service logs"
    echo "  status          - Check all service status"
    echo "  cleanup         - Clean up all services"
    echo "  menu            - Show interactive menu"
    echo "  help            - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 setup           # Setup environment"
    echo "  $0 start           # Start all services"
    echo "  $0 logs            # Show logs"
    echo "  $0 status          # Check status"
    echo "  $0 monitor-start   # Start monitoring"
    echo "  $0 cleanup         # Clean up all services"
    echo "  $0 menu            # Interactive menu"
}

# Function to show interactive menu
show_menu() {
    while true; do
        print_header "Unified AvatarChatbot Management Menu (TGI Backend Only)"
        echo "1.  Setup Environment"
        echo "2.  Start All Services"
        echo "3.  Stop All Services"
        echo "4.  Restart All Services"
        echo "5.  Start Monitoring"
        echo "6.  Stop Monitoring"
        echo "7.  Show Logs"
        echo "8.  Check Service Status"
        echo "9.  Cleanup All Services"
        echo "10. Help"
        echo "11. Exit"
        echo ""
        read -p "Select an option (1-11): " choice
        case $choice in
            1) setup_environment ;;
            2) start_services ;;
            3) stop_services ;;
            4) restart_services ;;
            5) start_monitoring ;;
            6) stop_monitoring ;;
            7) show_logs ;;
            8) check_status ;;
            9) cleanup ;;
            10) show_help ;;
            11) print_status "Goodbye!"; exit 0 ;;
            *) print_error "Invalid option. Please try again." ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Main script logic
main() {
    # Check if script is run from correct directory
    if [[ ! -f "compose.yaml" ]]; then
        print_error "Please run this script from the AvatarChatbot/docker_compose/amd/gpu/rocm/ directory"
        exit 1
    fi
    # If no arguments provided, show menu
    if [[ $# -eq 0 ]]; then
        show_menu
        exit 0
    fi
    # Handle command line arguments
    case "$1" in
        start) start_services ;;
        stop) stop_services ;;
        restart) restart_services ;;
        setup) setup_environment ;;
        monitor-start) start_monitoring ;;
        monitor-stop) stop_monitoring ;;
        logs) show_logs ;;
        status) check_status ;;
        cleanup) cleanup ;;
        menu) show_menu ;;
        help|--help|-h) show_help ;;
        *) print_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
}

# Run main function with all arguments
main "$@" 
