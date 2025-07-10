# Grafana Dashboard Import Commands

## Import Dashboards

### 1. ChatQnA Comprehensive Dashboard (TGI + vLLM)
```bash
curl -X POST -H "Content-Type: application/json" -u admin:admin -d @chatqna_comprehensive_dashboard_vllm_import.json http://localhost:3000/api/dashboards/db
```

### 2. ChatQnA AI/LLM Metrics Dashboard (TGI + vLLM)
```bash
curl -X POST -H "Content-Type: application/json" -u admin:admin -d @chatqna_ai_metrics_dashboard_vllm_import.json http://localhost:3000/api/dashboards/db
```

### 3. ChatQnA Comprehensive Dashboard (TGI Only - for local development)
```bash
curl -X POST -H "Content-Type: application/json" -u admin:admin -d @chatqna_comprehensive_dashboard_import.json http://localhost:3000/api/dashboards/db
```

### 4. ChatQnA AI/LLM Metrics Dashboard (TGI Only - for local development)
```bash
curl -X POST -H "Content-Type: application/json" -u admin:admin -d @chatqna_ai_metrics_dashboard_import.json http://localhost:3000/api/dashboards/db
```

## Import Data Sources

### 1. Prometheus Data Source
```bash
curl -X POST -H "Content-Type: application/json" -u admin:admin -d @prometheus_datasource.json http://localhost:3000/api/datasources
```

## Dashboard Selection Guide

### For Remote Node (GPU-enabled, supports vLLM):
- Use **Comprehensive Dashboard (TGI + vLLM)** - Full monitoring for both TGI and vLLM services
- Use **AI/LLM Metrics Dashboard (TGI + vLLM)** - Specialized AI metrics for both LLM engines

### For Local Development (CPU-only, TGI only):
- Use **Comprehensive Dashboard (TGI Only)** - Basic monitoring for TGI services
- Use **AI/LLM Metrics Dashboard (TGI Only)** - Basic AI metrics for TGI only

## Command Explanation

### Dashboard Import Format
The JSON files must be wrapped in the following structure:
```json
{
  "dashboard": { /* actual dashboard JSON */ },
  "folderId": 0,
  "overwrite": true
}
```

### Expected Responses
- **Success**: `{"id": X, "slug": "...", "status": "success", "uid": "...", "url": "..."}`
- **Error**: `{"message": "error description", "traceID": "..."}`

### Troubleshooting
1. **401 Unauthorized**: Reset Grafana admin password
2. **Bad request data**: Ensure JSON is properly wrapped
3. **No data in panels**: Add Prometheus data source first
4. **vLLM panels show no data**: Ensure vLLM service is running and properly configured

### File Structure Requirements
- All JSON files must be in the same directory as the curl command
- Use `@filename.json` syntax to reference files
- Ensure proper JSON formatting (no syntax errors)

### Usage Instructions
1. Copy all JSON files to the remote node
2. Run the Prometheus data source import first
3. Choose appropriate dashboard based on your setup:
   - **Remote node with GPU**: Use vLLM-enabled dashboards
   - **Local development**: Use TGI-only dashboards
4. Access dashboards at: `http://localhost:3000/d/{uid}/{slug}`

### Dashboard Features

#### Comprehensive Dashboard (TGI + vLLM):
- **System Overview**: Container health, response times
- **TGI Metrics**: Request rates, success rates, operations
- **vLLM Metrics**: Request rates, token generation, queue size
- **TEI Metrics**: Embedding and reranking performance
- **Resource Utilization**: CPU, memory for all services
- **GPU Metrics**: Utilization, memory, temperature
- **System Metrics**: System-level monitoring
- **Network Metrics**: Traffic and error monitoring

#### AI/LLM Metrics Dashboard (TGI + vLLM):
- **TGI Performance**: Detailed TGI metrics and operations
- **vLLM Performance**: Detailed vLLM metrics and token generation
- **TEI Performance**: Embedding and reranking metrics
- **Resource Monitoring**: CPU and memory for AI services
- **GPU Monitoring**: GPU utilization and memory
- **Service Health**: Status monitoring for all AI services
- **Success Rates**: Performance metrics for all services

### Alternative Import Methods
- **Grafana UI**: Import via web interface (if available)
- **Provisioning**: Use Grafana provisioning for automated setup
- **Docker volumes**: Mount dashboard files directly

### Security Considerations
- Change default admin password in production
- Use environment variables for credentials
- Consider using API tokens instead of admin credentials
- Restrict network access to Grafana API endpoints
