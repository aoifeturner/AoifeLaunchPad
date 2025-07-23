#!/bin/bash

# Start AvatarChatBot Monitoring Stack
# This script starts Prometheus and Grafana for monitoring AvatarChatBot performance

set -e

echo "🚀 Starting AvatarChatBot Monitoring Stack"
echo "=========================================="

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

# Check if AvatarChatBot services are running
check_avatarchatbot() {
    print_status "Checking if AvatarChatBot backend service is running..."
    
    if docker ps --format "{{.Names}}" | grep -q "avatarchatbot-backend-server"; then
        print_success "AvatarChatBot backend service is running"
        return 0
    else
        print_error "AvatarChatBot backend service is not running. Please start it first:"
        print_status "docker compose up -d avatarchatbot-backend-server"
        exit 1
    fi
}

# Start monitoring services
start_monitoring() {
    print_status "Starting monitoring services (Prometheus + Grafana)..."
    
    # Start telemetry services
    docker compose -f compose.telemetry.yaml up -d
    
    # Wait for services to be ready
    print_status "Waiting for monitoring services to be ready..."
    sleep 10
    
    # Check if services are running
    if docker ps --format "{{.Names}}" | grep -q "avatarchatbot-prometheus"; then
        print_success "Prometheus started successfully"
    else
        print_error "Failed to start Prometheus"
        exit 1
    fi
    
    if docker ps --format "{{.Names}}" | grep -q "avatarchatbot-grafana"; then
        print_success "Grafana started successfully"
    else
        print_error "Failed to start Grafana"
        exit 1
    fi
}

# Show access information
show_access_info() {
    echo ""
    echo "🎉 AvatarChatBot Monitoring Stack Started Successfully!"
    echo "========================================================"
    echo ""
    echo "📊 Access URLs:"
    echo "  Grafana Dashboard: http://localhost:3000"
    echo "    Username: admin"
    echo "    Password: admin"
    echo ""
    echo "  Prometheus UI: http://localhost:9090"
    echo "    (For advanced users - raw metrics)"
    echo ""
    echo "📈 Available Dashboards:"
    echo "  - AvatarChatBot MegaService Dashboard"
    echo "  - TGI (LLM) Performance Dashboard"
    echo "  - System CPU & Memory Dashboard"
    echo "  - Node Metrics Dashboard"
    echo ""
    echo "🔧 Next Steps:"
    echo "  1. Open Grafana: http://localhost:3000"
    echo "  2. Login with admin/admin"
    echo "  3. Navigate to Dashboards"
    echo "  4. Run your AvatarChatBot benchmarks while monitoring"
    echo ""
    echo "🛑 To stop monitoring:"
    echo "  docker compose -f compose.telemetry.yaml down"
}

# Main execution
main() {
    check_avatarchatbot
    start_monitoring
    show_access_info
}

# Handle command line arguments
case "${1:-}" in
    "stop")
        print_status "Stopping monitoring services..."
        docker compose -f compose.telemetry.yaml down
        print_success "Monitoring services stopped"
        ;;
    "restart")
        print_status "Restarting monitoring services..."
        docker compose -f compose.telemetry.yaml down
        docker compose -f compose.telemetry.yaml up -d
        print_success "Monitoring services restarted"
        ;;
    "status")
        print_status "Monitoring services status:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(prometheus|grafana|node-exporter|avatarchatbot)"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (no args)    Start monitoring stack"
        echo "  stop         Stop monitoring services"
        echo "  restart      Restart monitoring services"
        echo "  status       Show monitoring services status"
        echo "  help         Show this help message"
        ;;
    *)
        main
        ;;
esac
