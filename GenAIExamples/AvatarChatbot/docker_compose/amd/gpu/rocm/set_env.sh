#!/usr/bin/env bash

# Copyright (C) 2024 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Use container DNS names and internal ports for inter-container communication

export HF_TOKEN=${HF_TOKEN}
export OPENAI_API_KEY=${OPENAI_API_KEY}

# Determine your IP addresses automatically
export HOST_IP=$(hostname -I | awk '{print $1}')
export HOST_IP_EXTERNAL=$(hostname -I | awk '{print $1}')

# =============================================================================
# PORT CONFIGURATION (using high port numbers like ChatQnA)
# =============================================================================

export AVATAR_WHISPER_PORT=18106
export AVATAR_ASR_PORT=18101
export AVATAR_SPEECHT5_PORT=18105
export AVATAR_TTS_PORT=18102
export AVATAR_TGI_SERVICE_PORT=18103
export AVATAR_WAV2LIP_PORT=18107
export AVATAR_ANIMATION_PORT=18108
export AVATAR_BACKEND_SERVICE_PORT=18109
export AVATAR_UI_PORT=18110

# =============================================================================
# SERVICE ENDPOINTS (External Access)
# =============================================================================

export AVATAR_WHISPER_ENDPOINT="http://${HOST_IP_EXTERNAL}:${AVATAR_WHISPER_PORT}"
export AVATAR_ASR_ENDPOINT="http://${HOST_IP_EXTERNAL}:${AVATAR_ASR_PORT}"
export AVATAR_SPEECHT5_ENDPOINT="http://${HOST_IP_EXTERNAL}:${AVATAR_SPEECHT5_PORT}"
export AVATAR_TTS_ENDPOINT="http://${HOST_IP_EXTERNAL}:${AVATAR_TTS_PORT}"
export AVATAR_TGI_ENDPOINT="http://${HOST_IP_EXTERNAL}:${AVATAR_TGI_SERVICE_PORT}"
export AVATAR_WAV2LIP_ENDPOINT="http://${HOST_IP_EXTERNAL}:${AVATAR_WAV2LIP_PORT}"
export AVATAR_ANIMATION_ENDPOINT="http://${HOST_IP_EXTERNAL}:${AVATAR_ANIMATION_PORT}"
export AVATAR_BACKEND_ENDPOINT="http://${HOST_IP_EXTERNAL}:${AVATAR_BACKEND_SERVICE_PORT}/v1/avatarchatbot"
export AVATAR_UI_ENDPOINT="http://${HOST_IP_EXTERNAL}:${AVATAR_UI_PORT}"

# =============================================================================
# INTER-CONTAINER COMMUNICATION CONFIGURATION (Container names from compose)
# =============================================================================

# Text Generation Inference (LLM) service
export TGI_SERVICE_PORT=80
export TGI_LLM_ENDPOINT="http://tgi-service:${TGI_SERVICE_PORT}"
export LLM_MODEL_ID="Intel/neural-chat-7b-v3-3"

# Automatic Speech Recognition (ASR) service
export ASR_ENDPOINT="http://asr-service:9099"
export ASR_SERVICE_PORT=9099

# Text-to-Speech (TTS) service
export TTS_ENDPOINT="http://tts-service:9088"
export TTS_SERVICE_PORT=9088

# Wav2Lip service
export WAV2LIP_ENDPOINT="http://wav2lip-service:7860"
export WAV2LIP_PORT=7860

# Whisper speech recognition server
export WHISPER_SERVER_HOST_IP="whisper-service"
export WHISPER_SERVER_PORT=7066

# SpeechT5 service
export SPEECHT5_SERVER_HOST_IP="speecht5-service"
export SPEECHT5_SERVER_PORT=7055

# MEGA backend service
export MEGA_SERVICE_HOST_IP="avatarchatbot-backend-server"
export MEGA_SERVICE_PORT=8888

# Animation server
export ANIMATION_SERVICE_HOST_IP="animation-server"
export ANIMATION_SERVICE_PORT=9066

# LLM service host info (for legacy or internal use)
export LLM_SERVICE_HOST_IP="tgi-service"
export LLM_SERVICE_PORT=80

# Animation, ASR, TTS service host info (for legacy or internal use)
export ASR_SERVICE_HOST_IP="asr-service"
export TTS_SERVICE_HOST_IP="tts-service"
export ANIMATION_SERVICE_HOST_IP="animation-server"

# =============================================================================
# MODEL CONFIGURATION
# =============================================================================

export MODEL_CACHE=./data

# =============================================================================
# DOCKER REGISTRY CONFIGURATION
# =============================================================================

export REGISTRY=opea
export TAG=latest

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

export LOGFLAG=INFO

# =============================================================================
# DEVICE AND INFERENCE SETTINGS
# =============================================================================

export DEVICE="cpu"
export INFERENCE_MODE='wav2lip+gfpgan'
export CHECKPOINT_PATH='/usr/local/lib/python3.11/site-packages/Wav2Lip/checkpoints/wav2lip_gan.pth'

# Face and audio configuration
export FACE="/home/user/comps/animation/src/assets/img/avatar5.png"
export AUDIO='None'  # optional audio input, set path or None

export FACESIZE=96
export OUTFILE="./outputs/result.mp4"

export GFPGAN_MODEL_VERSION=1.4  # can roll back to v1.3 if needed
export UPSCALE_FACTOR=1
export FPS=5

# =============================================================================
# DISPLAY CONFIGURATION
# =============================================================================

echo "✅ AvatarChatBot environment configuration loaded"
echo "🌐 Host IP: ${HOST_IP}"
echo "🔗 Backend Endpoint: ${AVATAR_BACKEND_ENDPOINT}"
echo "🎨 UI Endpoint: ${AVATAR_UI_ENDPOINT}"
echo ""
echo "📋 Service Ports:"
echo "  Whisper: ${AVATAR_WHISPER_PORT}"
echo "  ASR: ${AVATAR_ASR_PORT}"
echo "  SpeechT5: ${AVATAR_SPEECHT5_PORT}"
echo "  TTS: ${AVATAR_TTS_PORT}"
echo "  TGI: ${AVATAR_TGI_SERVICE_PORT}"
echo "  Wav2Lip: ${AVATAR_WAV2LIP_PORT}"
echo "  Animation: ${AVATAR_ANIMATION_PORT}"
echo "  Backend: ${AVATAR_BACKEND_SERVICE_PORT}"
echo "  UI: ${AVATAR_UI_PORT}"

