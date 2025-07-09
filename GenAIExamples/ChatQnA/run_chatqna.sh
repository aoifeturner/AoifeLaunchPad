#!/bin/bash

# ChatQnA Management Script
# This script provides a unified interface for all ChatQnA operations

set -e

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
        print_error "Please run this script from the ChatQnA/docker_compose/amd/gpu/rocm/ directory"
        exit 1
    fi
}

# Function to setup environment
setup_environment() {
    print_header "Setting up ChatQnA Environment"
    check_docker
    check_requirements
    
    print_status "Setting up environment variables..."
    source set_env.sh
    
    print_status "Environment setup complete!"
}

# Function to setup lightweight environment
setup_lightweight() {
    print_header "Setting up Lightweight ChatQnA Environment"
    check_docker
    check_requirements
    
    print_status "Setting up lightweight environment variables..."
    source set_env_lightweight.sh
    
    print_status "Lightweight environment setup complete!"
}

# Function to start ChatQnA services
start_services() {
    print_header "Starting ChatQnA Services"
    check_docker
    check_requirements
    
    print_status "Starting services with docker compose..."
    docker compose -f compose.yaml up -d
    
    print_status "Services started! Check logs with: docker compose logs -f"
}

# Function to stop ChatQnA services
stop_services() {
    print_header "Stopping ChatQnA Services"
    check_docker
    
    print_status "Stopping services..."
    docker compose -f compose.yaml down
    
    print_status "Services stopped!"
}

# Function to restart services
restart_services() {
    print_header "Restarting ChatQnA Services"
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
    
    print_status "Stopping monitoring services..."
    docker compose -f compose.telemetry.yaml down
    
    print_status "Monitoring stack stopped!"
}

# Function to run quick evaluation
run_quick_eval() {
    print_header "Running Quick Evaluation"
    check_docker
    
    print_status "Running quick evaluation..."
    ./quick_test_chatqna.sh
    
    print_status "Quick evaluation complete!"
}

# Function to run full evaluation
run_full_eval() {
    print_header "Running Full Evaluation"
    check_docker
    
    print_status "Setting up evaluation environment..."
    ./quick_eval_setup.sh
    
    print_status "Full evaluation setup complete!"
    print_status "You can now run the evaluation using GenAIEval framework"
}

# Function to show logs
show_logs() {
    print_header "Showing Service Logs"
    check_docker
    
    print_status "Showing logs (Ctrl+C to exit)..."
    docker compose -f compose.yaml logs -f
}

# Function to show monitoring logs
show_monitoring_logs() {
    print_header "Showing Monitoring Logs"
    check_docker
    
    print_status "Showing monitoring logs (Ctrl+C to exit)..."
    docker compose -f compose.telemetry.yaml logs -f
}

# Function to check service status
check_status() {
    print_header "Service Status"
    check_docker
    
    print_status "ChatQnA Services:"
    docker compose -f compose.yaml ps
    
    echo ""
    print_status "Monitoring Services:"
    docker compose -f compose.telemetry.yaml ps
}

# Function to clean up
cleanup() {
    print_header "Cleaning Up"
    check_docker
    
    print_warning "This will stop all services and remove containers. Continue? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_status "Stopping all services..."
        docker compose -f compose.yaml down
        docker compose -f compose.telemetry.yaml down
        
        print_status "Removing containers..."
        docker system prune -f
        
        print_status "Cleanup complete!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Function to show help
show_help() {
    print_header "ChatQnA Management Script Help"
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  1) setup          - Setup environment variables"
    echo "  2) setup-light    - Setup lightweight environment"
    echo "  3) start          - Start ChatQnA services"
    echo "  4) stop           - Stop ChatQnA services"
    echo "  5) restart        - Restart ChatQnA services"
    echo "  6) monitor-start  - Start monitoring stack"
    echo "  7) monitor-stop   - Stop monitoring stack"
    echo "  8) quick-eval     - Run quick evaluation"
    echo "  9) full-eval      - Setup full evaluation"
    echo "  10) logs          - Show service logs"
    echo "  11) monitor-logs  - Show monitoring logs"
    echo "  12) status        - Check service status"
    echo "  13) cleanup       - Clean up all services"
    echo "  14) menu          - Show interactive menu"
    echo "  15) help          - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 setup          # Setup environment"
    echo "  $0 start          # Start services"
    echo "  $0 menu           # Interactive menu"
}

# Function to show interactive menu
show_menu() {
    while true; do
        print_header "ChatQnA Management Menu"
        echo "1.  Setup Environment"
        echo "2.  Setup Lightweight Environment"
        echo "3.  Start Services"
        echo "4.  Stop Services"
        echo "5.  Restart Services"
        echo "6.  Start Monitoring"
        echo "7.  Stop Monitoring"
        echo "8.  Run Quick Evaluation"
        echo "9.  Setup Full Evaluation"
        echo "10. Show Service Logs"
        echo "11. Show Monitoring Logs"
        echo "12. Check Status"
        echo "13. Cleanup"
        echo "14. Help"
        echo "15. Exit"
        echo ""
        read -p "Select an option (1-15): " choice
        
        case $choice in
            1) setup_environment ;;
            2) setup_lightweight ;;
            3) start_services ;;
            4) stop_services ;;
            5) restart_services ;;
            6) start_monitoring ;;
            7) stop_monitoring ;;
            8) run_quick_eval ;;
            9) run_full_eval ;;
            10) show_logs ;;
            11) show_monitoring_logs ;;
            12) check_status ;;
            13) cleanup ;;
            14) show_help ;;
            15) print_status "Goodbye!"; exit 0 ;;
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
        print_error "Please run this script from the ChatQnA/docker_compose/amd/gpu/rocm/ directory"
        exit 1
    fi
    
    # If no arguments provided, show menu
    if [[ $# -eq 0 ]]; then
        show_menu
        exit 0
    fi
    
    # Handle command line arguments
    case "$1" in
        "setup") setup_environment ;;
        "setup-light") setup_lightweight ;;
        "start") start_services ;;
        "stop") stop_services ;;
        "restart") restart_services ;;
        "monitor-start") start_monitoring ;;
        "monitor-stop") stop_monitoring ;;
        "quick-eval") run_quick_eval ;;
        "full-eval") run_full_eval ;;
        "logs") show_logs ;;
        "monitor-logs") show_monitoring_logs ;;
        "status") check_status ;;
        "cleanup") cleanup ;;
        "menu") show_menu ;;
        "help"|"-h"|"--help") show_help ;;
        *) 
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 