#!/usr/bin/env bash

# Copyright (C) 2024 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Use container DNS names and internal ports for inter-container communication

export HF_TOKEN=${HF_TOKEN}
export OPENAI_API_KEY=${OPENAI_API_KEY}

# Host IP is optional here since containers communicate via service names
# export host_ip=$(hostname -I | awk '{print $1}')

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

# Device and inference settings
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
