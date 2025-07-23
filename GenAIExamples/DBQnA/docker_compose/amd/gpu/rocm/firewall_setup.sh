#!/bin/bash

# DBQnA Firewall Setup Script for DigitalOcean Droplet
# This script configures UFW to allow access to DBQnA services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_header "DBQnA Firewall Setup for DigitalOcean Droplet"

# Check if UFW is installed
if ! command -v ufw &> /dev/null; then
    print_error "UFW is not installed. Please install it first:"
    echo "sudo apt update && sudo apt install ufw"
    exit 1
fi

# Check current UFW status
print_status "Checking current UFW status..."
ufw status

# Define ports to open
PORTS=(
    "22"      # SSH (already open)
    "80"      # HTTP (already open)
    "443"     # HTTPS (already open)
    "8889"    # DBQnA Backend
    "5174"    # DBQnA Frontend
    "8008"    # TGI Service
    "9090"    # Text-to-SQL Service
    "5442"    # PostgreSQL
    "8080"    # Nginx (optional)
)

print_status "Opening ports for DBQnA services..."

# Open each port
for port in "${PORTS[@]}"; do
    if ufw status | grep -q "$port"; then
        print_status "Port $port is already open"
    else
        print_status "Opening port $port..."
        ufw allow $port
    fi
done

# Enable UFW if not already enabled
if ! ufw status | grep -q "Status: active"; then
    print_warning "UFW is not active. Enabling UFW..."
    ufw --force enable
fi

print_status "Reloading UFW rules..."
ufw reload

print_status "Final UFW status:"
ufw status

print_header "Firewall Setup Complete!"

echo "The following ports are now open:"
echo "  - 22 (SSH)"
echo "  - 80 (HTTP)"
echo "  - 443 (HTTPS)"
echo "  - 8889 (DBQnA Backend)"
echo "  - 5174 (DBQnA Frontend)"
echo "  - 8008 (TGI Service)"
echo "  - 9090 (Text-to-SQL Service)"
echo "  - 5442 (PostgreSQL)"
echo "  - 8080 (Nginx - optional)"

print_status "You can now access DBQnA services from external networks!" 