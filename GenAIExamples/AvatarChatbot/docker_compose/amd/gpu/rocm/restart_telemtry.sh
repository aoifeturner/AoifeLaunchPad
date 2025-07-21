#!/bin/bash

echo "Restarting Prometheus and telemetry stack..."
docker compose -f compose.telemetry.yaml restart prometheus
echo "Prometheus restarted!"

# Optionally, restart all telemetry services:
# docker compose -f compose.telemetry.yaml restart