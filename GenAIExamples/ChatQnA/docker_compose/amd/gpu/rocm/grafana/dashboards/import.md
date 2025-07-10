# Grafana Dashboard Import Commands

This file contains all the commands needed to import dashboards and data sources into Grafana for the ChatQnA monitoring system.

## Prerequisites

1. Grafana is running and accessible at `http://localhost:3000`
2. Admin credentials are set (default: admin/admin)
3. Prometheus data source is configured

## Data Source Import

### Prometheus Data Source
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YWRtaW46YWRtaW4=" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://prometheus:9090",
    "access": "proxy",
    "isDefault": true
  }' \
  http://localhost:3000/api/datasources
```

## Dashboard Imports

### 1. Comprehensive Dashboard (TGI + vLLM) - Fixed
**Use this for remote nodes with both TGI and vLLM services**

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YWRtaW46YWRtaW4=" \
  -d @dashboards/chatqna_comprehensive_dashboard_vllm_fixed_import.json \
  http://localhost:3000/api/dashboards/import
```

### 2. TGI-Only Dashboard (Local Development)
**Use this for local development where vLLM is not available**

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YWRtaW46YWRtaW4=" \
  -d @dashboards/chatqna_tgi_only_dashboard_import.json \
  http://localhost:3000/api/dashboards/import
```

## Command Breakdown

### Authentication
- `Authorization: Basic YWRtaW46YWRtaW4=` - Base64 encoded "admin:admin"
- For custom credentials, encode as: `echo -n "username:password" | base64`

### Import Structure
The JSON files contain:
- `dashboard`: The actual dashboard configuration
- `folderId`: 0 (root folder)
- `overwrite`: true (replace existing dashboards with same name)

### Expected Responses

**Success (200 OK):**
```json
{
  "id": 1,
  "slug": "chatqna-comprehensive-dashboard",
  "status": "success",
  "uid": "abc123",
  "url": "/d/abc123/chatqna-comprehensive-dashboard",
  "version": 1
}
```

**Authentication Error (401):**
```json
{
  "message": "Invalid username or password"
}
```

**Bad Request (400):**
```json
{
  "message": "bad request data"
}
```

## Troubleshooting

### 1. Authentication Issues
```bash
# Test Grafana health
curl -u admin:admin http://localhost:3000/api/health

# Reset admin password if needed
docker exec -it chatqna-grafana-1 grafana-cli admin reset-admin-password newpassword
```

### 2. Data Source Issues
```bash
# Test Prometheus connectivity
curl http://localhost:9090/api/v1/status/targets

# Check if Prometheus is scraping targets
curl http://localhost:9090/api/v1/targets
```

### 3. Dashboard Import Issues
```bash
# Validate JSON syntax
jq . dashboards/chatqna_comprehensive_dashboard_vllm_fixed_import.json

# Check file size (should be > 1KB)
ls -la dashboards/*.json
```

### 4. No Data in Panels
```bash
# Check if metrics are being exposed
curl -s http://localhost:18009/metrics | grep -E "^(vllm|http_requests_total)" | head -10
curl -s http://localhost:18010/metrics | grep -E "^(tgi|http_request)" | head -10

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health, lastError: .lastError}'
```

## Usage Instructions

### For Remote Nodes (GPU-enabled)
1. Import the comprehensive dashboard: `chatqna_comprehensive_dashboard_vllm_fixed_import.json`
2. This includes both TGI and vLLM metrics with correct metric names
3. All panels should show data if services are running

### For Local Development
1. Import the TGI-only dashboard: `chatqna_tgi_only_dashboard_import.json`
2. This focuses on TGI metrics and system resources
3. vLLM panels will show "No data" (expected)

### Dashboard Features

**Comprehensive Dashboard:**
- System overview with service health
- TGI metrics (request rate, success rate, response times)
- vLLM metrics (request rate, token generation, latency)
- TEI embedding metrics
- Resource utilization (CPU, memory, GPU)
- GPU monitoring (utilization, memory, temperature)

**TGI-Only Dashboard:**
- Focused on TGI and TEI services
- System resource monitoring
- GPU metrics (if available)
- Simplified for local development

## Security Considerations

### Production Use
- Change default admin password
- Use environment variables for credentials
- Enable authentication and authorization
- Use HTTPS in production
- Consider using API keys instead of basic auth

### Credential Management
```bash
# Set custom admin password
export GRAFANA_ADMIN_PASSWORD="your_secure_password"
docker exec -it chatqna-grafana-1 grafana-cli admin reset-admin-password $GRAFANA_ADMIN_PASSWORD

# Update import commands with new credentials
echo -n "admin:your_secure_password" | base64
```

## Alternative Import Methods

### 1. Grafana UI Import
1. Open Grafana at `http://localhost:3000`
2. Go to Dashboards → Import
3. Upload the JSON file
4. Configure data source mapping
5. Import

### 2. Provisioning (Recommended for Production)
Create `grafana/provisioning/dashboards/` directory and place JSON files there for automatic import.

### 3. Grafana CLI
```bash
# Install Grafana CLI
wget https://github.com/grafana/grafana/releases/latest/download/grafana-cli-linux-amd64.tar.gz

# Import dashboard
grafana-cli --config /etc/grafana/grafana.ini dashboard import dashboard.json
```

## Monitoring Checklist

After importing dashboards, verify:

- [ ] All services show as "UP" in Container Health panel
- [ ] Request rates show activity when making API calls
- [ ] Response times are reasonable (< 5 seconds)
- [ ] CPU and memory usage are within expected ranges
- [ ] GPU metrics show data (if GPU is available)
- [ ] No error panels show red indicators
- [ ] Time range shows recent data (last 1 hour)

## Metric Naming Reference

### vLLM Metrics (Actual)
- `http_requests_total` - Total HTTP requests
- `vllm:iteration_tokens_total_sum` - Total tokens generated
- `vllm:e2e_request_latency_seconds` - End-to-end request latency
- `vllm:request_queue_time_seconds` - Request queue time

### TGI Metrics (Expected)
- `tgi_request_count` - Total TGI requests
- `tgi_request_success` - Successful TGI requests
- `http_request_duration_seconds` - TGI response time

### TEI Metrics (Expected)
- `te_request_count` - TEI request count
- `te_embed_success` - TEI embedding success
- `te_embed_duration_bucket` - TEI embedding duration 