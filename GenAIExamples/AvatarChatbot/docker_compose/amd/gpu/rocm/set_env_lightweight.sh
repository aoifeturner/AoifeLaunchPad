#!/bin/bash

# =============================================================================
# LIGHTWEIGHT CONFIGURATION FOR AVATARCHATBOT
# =============================================================================

# Determine your IP addresses automatically
export HOST_IP=$(hostname -I | awk '{print $1}')
export HOST_IP_EXTERNAL=$(hostname -I | awk '{print $1}')

# =============================================================================
# MODEL CONFIGURATION - Replace with actual AvatarChatBot models if known
# =============================================================================

export AVATAR_LLM_MODEL_ID="Intel/neural-chat-7b-v3-3"
export AVATAR_ASR_MODEL_ID="your-asr-model"        # Placeholder, update if known
export AVATAR_TTS_MODEL_ID="your-tts-model"        # Placeholder, update if known
export AVATAR_WHISPER_MODEL_ID="your-whisper-model" # Placeholder
export AVATAR_ANIMATION_MODEL_ID="your-animation-model" # Placeholder
export AVATAR_WAV2LIP_MODEL_ID="your-wav2lip-model"     # Placeholder

# =============================================================================
# PORT CONFIGURATION (match your docker-compose ports)
# =============================================================================

export AVATAR_WHISPER_PORT=7066
export AVATAR_ASR_PORT=9099        # Matches asr-service internal port in compose
export AVATAR_SPEECHT5_PORT=7055
export AVATAR_TTS_PORT=9088        # Matches tts-service internal port in compose
export AVATAR_TGI_PORT=80          # Internal port of tgi-service
export AVATAR_WAV2LIP_PORT=7860
export AVATAR_ANIMATION_PORT=9066
export AVATAR_BACKEND_PORT=8888    # Internal port for avatarchatbot-backend-server

# =============================================================================
# SERVICE ENDPOINTS (External Access)
# =============================================================================

export AVATAR_WHISPER_ENDPOINT="http://${HOST_IP_EXTERNAL}:${AVATAR_WHISPER_PORT}"
export AVATAR_ASR_ENDPOINT="http://${HOST_IP_EXTERNAL}:3001"       # external mapped port for ASR
export AVATAR_SPEECHT5_ENDPOINT="http://${HOST_IP_EXTERNAL}:${AVATAR_SPEECHT5_PORT}"
export AVATAR_TTS_ENDPOINT="http://${HOST_IP_EXTERNAL}:3002"       # external mapped port for TTS
export AVATAR_TGI_ENDPOINT="http://${HOST_IP_EXTERNAL}:3006"       # external mapped port for TGI
export AVATAR_WAV2LIP_ENDPOINT="http://${HOST_IP_EXTERNAL}:${AVATAR_WAV2LIP_PORT}"
export AVATAR_ANIMATION_ENDPOINT="http://${HOST_IP_EXTERNAL}:3008" # external mapped port for animation
export AVATAR_BACKEND_ENDPOINT="http://${HOST_IP_EXTERNAL}:3009/v1/avatarchatbot"

# =============================================================================
# INTER-CONTAINER COMMUNICATION CONFIGURATION (Container names from compose)
# =============================================================================

export WHISPER_SERVICE_HOST_IP=whisper-service
export WHISPER_SERVICE_PORT=7066

export ASR_SERVICE_HOST_IP=asr-service
export ASR_SERVICE_PORT=9099

export SPEECHT5_SERVICE_HOST_IP=speecht5-service
export SPEECHT5_SERVICE_PORT=7055

export TTS_SERVICE_HOST_IP=tts-service
export TTS_SERVICE_PORT=9088

export TGI_SERVICE_HOST_IP=tgi-service
export TGI_SERVICE_PORT=80

export WAV2LIP_SERVICE_HOST_IP=wav2lip-service
export WAV2LIP_SERVICE_PORT=7860

export ANIMATION_SERVICE_HOST_IP=animation-server
export ANIMATION_SERVICE_PORT=9066

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

echo "✅ AvatarChatBot lightweight environment configuration loaded"
echo "🌐 Host IP: ${HOST_IP}"
echo "🔗 Backend Endpoint: ${AVATAR_BACKEND_ENDPOINT}"
