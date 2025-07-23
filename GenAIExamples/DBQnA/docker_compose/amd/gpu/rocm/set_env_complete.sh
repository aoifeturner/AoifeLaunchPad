#!/bin/bash

# =============================================================================
# HOST IP CONFIGURATION
# =============================================================================

# Determine your IP addresses automatically
export HOST_IP=$(hostname -I | awk '{print $1}')
export HOST_IP_EXTERNAL=$(hostname -I | awk '{print $1}')

# Alternative: Set manually based on your needs
# For local development only:
# export HOST_IP=127.0.0.1
# export HOST_IP_EXTERNAL=127.0.0.1

# For local network access (recommended):
# export HOST_IP=192.168.1.131  # Your local IP
# export HOST_IP_EXTERNAL=192.168.1.131

# For internet access (requires port forwarding):
# export HOST_IP=192.168.1.131  # Your local IP
# export HOST_IP_EXTERNAL=99.151.13.97  # Your public IP

# =============================================================================
# MODEL CONFIGURATION
# =============================================================================

export DBQNA_LLM_MODEL_ID="mistralai/Mistral-7B-Instruct-v0.3"
export DBQNA_HUGGINGFACEHUB_API_TOKEN="" # or your actual HF token

# =============================================================================
# PORT CONFIGURATION
# =============================================================================

export DBQNA_BACKEND_SERVICE_PORT=8889
export DBQNA_FRONTEND_SERVICE_PORT=5174
export DBQNA_NGINX_PORT=8080
export DBQNA_TGI_SERVICE_PORT=8008
export DBQNA_TEXT_TO_SQL_PORT=9090
export DBQNA_POSTGRES_PORT=5442

# =============================================================================
# SERVICE ENDPOINTS (External Access)
# =============================================================================

export DBQNA_BACKEND_SERVICE_ENDPOINT="http://${HOST_IP_EXTERNAL}:${DBQNA_BACKEND_SERVICE_PORT}/v1/dbqna"
export DBQNA_BACKEND_SERVICE_IP=${HOST_IP}
export DBQNA_FRONTEND_SERVICE_IP=${HOST_IP}
export DBQNA_TGI_LLM_ENDPOINT="http://${HOST_IP_EXTERNAL}:${DBQNA_TGI_SERVICE_PORT}"
export DBQNA_TEXT_TO_SQL_ENDPOINT="http://${HOST_IP_EXTERNAL}:${DBQNA_TEXT_TO_SQL_PORT}/v1/texttosql"

# =============================================================================
# INTER-CONTAINER COMMUNICATION CONFIGURATION
# =============================================================================

# TGI (Text Generation Inference) Service Configuration
export LLM_SERVER_HOST_IP=dbqna-tgi-service
export LLM_SERVER_PORT=80  # Internal port (NOT 8008)

# Text-to-SQL Service Configuration
export TEXT2SQL_SERVICE_HOST_IP=text2sql
export TEXT2SQL_SERVICE_PORT=8080  # Internal port (NOT 9090)

# PostgreSQL Service Configuration
export POSTGRES_SERVICE_HOST_IP=postgres
export POSTGRES_SERVICE_PORT=5432  # Internal port (NOT 5442)

# LLM Model Configuration
export LLM_MODEL=${DBQNA_LLM_MODEL_ID}

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

export POSTGRES_USER="postgres"
export POSTGRES_PASSWORD="testpwd"
export POSTGRES_DB="chinook"

# =============================================================================
# LEGACY VARIABLES (for backward compatibility)
# =============================================================================

export DBQNA_LLM_SERVICE_HOST_IP=${LLM_SERVER_HOST_IP}
export DBQNA_MEGA_SERVICE_HOST_IP=${HOST_IP}
export DBQNA_BACKEND_SERVICE_NAME=dbqna

# =============================================================================
# PROXY CONFIGURATION (if needed)
# =============================================================================

# Uncomment and set if you're behind a proxy
# export http_proxy=http://your-proxy:port
# export https_proxy=http://your-proxy:port
# export no_proxy=localhost,127.0.0.1,${HOST_IP}

# =============================================================================
# DOCKER REGISTRY CONFIGURATION
# =============================================================================

export REGISTRY=opea
export TAG=latest
export MODEL_CACHE=./data

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

export LOGFLAG=INFO

# =============================================================================
# FIREWALL PORTS (for DigitalOcean droplet)
# =============================================================================

# These are the ports that need to be opened in UFW
export FIREWALL_PORTS=(
    "22"      # SSH
    "80"      # HTTP
    "443"     # HTTPS
    "8889"    # DBQnA Backend
    "5174"    # DBQnA Frontend
    "8008"    # TGI Service
    "9090"    # Text-to-SQL Service
    "5442"    # PostgreSQL
    "8080"    # Nginx (optional)
)

echo "DBQnA Environment Configuration Complete!"
echo "Host IP: ${HOST_IP}"
echo "External IP: ${HOST_IP_EXTERNAL}"
echo "Backend Service: ${DBQNA_BACKEND_SERVICE_ENDPOINT}"
echo "Frontend Service: http://${HOST_IP_EXTERNAL}:${DBQNA_FRONTEND_SERVICE_PORT}"
echo "TGI Service: ${DBQNA_TGI_LLM_ENDPOINT}"
echo "Text-to-SQL Service: ${DBQNA_TEXT_TO_SQL_ENDPOINT}" 