#!/bin/bash

# =============================================================================
# LIGHTWEIGHT CONFIGURATION FOR QUICK TESTING
# =============================================================================

# Determine your IP addresses automatically
export HOST_IP=$(hostname -I | awk '{print $1}')
export HOST_IP_EXTERNAL=$(hostname -I | awk '{print $1}')

# =============================================================================
# MODEL CONFIGURATION - LIGHTWEIGHT MODELS
# =============================================================================

export CHATQNA_EMBEDDING_MODEL_ID="BAAI/bge-base-en-v1.5"
export CHATQNA_HUGGINGFACEHUB_API_TOKEN=""
# Using a reliable lightweight model for faster testing
export CHATQNA_LLM_MODEL_ID="google/gemma-2b-it"  # More compatible than small
export CHATQNA_RERANK_MODEL_ID="BAAI/bge-reranker-base"

# =============================================================================
# PORT CONFIGURATION
# =============================================================================

export CHATQNA_BACKEND_SERVICE_PORT=8889
export CHATQNA_FRONTEND_SERVICE_PORT=5173
export CHATQNA_NGINX_PORT=8080
export CHATQNA_REDIS_DATAPREP_PORT=18103
export CHATQNA_REDIS_RETRIEVER_PORT=7000
export CHATQNA_REDIS_VECTOR_INSIGHT_PORT=8001
export CHATQNA_REDIS_VECTOR_PORT=6379
export CHATQNA_TEI_EMBEDDING_PORT=18090
export CHATQNA_TEI_RERANKING_PORT=18808
export CHATQNA_TGI_SERVICE_PORT=18008

# =============================================================================
# SERVICE ENDPOINTS (External Access)
# =============================================================================

export CHATQNA_BACKEND_SERVICE_ENDPOINT="http://${HOST_IP_EXTERNAL}:${CHATQNA_BACKEND_SERVICE_PORT}/v1/chatqna"
export CHATQNA_BACKEND_SERVICE_IP=${HOST_IP}
export CHATQNA_DATAPREP_DELETE_FILE_ENDPOINT="http://${HOST_IP_EXTERNAL}:${CHATQNA_REDIS_DATAPREP_PORT}/v1/dataprep/delete"
export CHATQNA_DATAPREP_GET_FILE_ENDPOINT="http://${HOST_IP_EXTERNAL}:${CHATQNA_REDIS_DATAPREP_PORT}/v1/dataprep/get"
export CHATQNA_DATAPREP_SERVICE_ENDPOINT="http://${HOST_IP_EXTERNAL}:${CHATQNA_REDIS_DATAPREP_PORT}/v1/dataprep/ingest"
export CHATQNA_FRONTEND_SERVICE_IP=${HOST_IP}

# =============================================================================
# INTER-CONTAINER COMMUNICATION CONFIGURATION
# =============================================================================

export RETRIEVER_SERVICE_HOST_IP=chatqna-retriever
export RETRIEVER_SERVICE_PORT=7000
export LLM_SERVER_HOST_IP=chatqna-tgi-service
export LLM_SERVER_PORT=80
export EMBEDDING_SERVER_HOST_IP=chatqna-tei-embedding-service
export EMBEDDING_SERVER_PORT=80
export RERANK_SERVER_HOST_IP=chatqna-tei-reranking-service
export RERANK_SERVER_PORT=80
export LLM_MODEL=${CHATQNA_LLM_MODEL_ID}

# =============================================================================
# RETRIEVER-SPECIFIC ENVIRONMENT VARIABLES
# =============================================================================

export TEI_EMBEDDING_ENDPOINT=http://chatqna-tei-embedding-service:80
export HF_TOKEN=${CHATQNA_HUGGINGFACEHUB_API_TOKEN}
export REDIS_URL=redis://chatqna-redis-vector-db:6379

# =============================================================================
# LEGACY VARIABLES (for backward compatibility)
# =============================================================================

export CHATQNA_EMBEDDING_SERVICE_HOST_IP=${EMBEDDING_SERVER_HOST_IP}
export CHATQNA_LLM_SERVICE_HOST_IP=${LLM_SERVER_HOST_IP}
export CHATQNA_MEGA_SERVICE_HOST_IP=${HOST_IP}
export CHATQNA_REDIS_URL=${REDIS_URL}
export CHATQNA_RERANK_SERVICE_HOST_IP=${RERANK_SERVER_HOST_IP}
export CHATQNA_RETRIEVER_SERVICE_HOST_IP=${RETRIEVER_SERVICE_HOST_IP}
export CHATQNA_TEI_EMBEDDING_ENDPOINT=${TEI_EMBEDDING_ENDPOINT}

export CHATQNA_BACKEND_SERVICE_NAME=chatqna
export CHATQNA_INDEX_NAME="rag-redis"

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

echo "✅ Lightweight environment configuration loaded"
echo "📝 Using model: ${CHATQNA_LLM_MODEL_ID}"
echo "🌐 Host IP: ${HOST_IP}" 
