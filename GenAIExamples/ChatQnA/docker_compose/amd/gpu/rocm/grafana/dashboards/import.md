# Grafana Dashboard Import Commands

## Import Dashboards

### 1. ChatQnA Comprehensive Dashboard
```bash
curl -X POST -H "Content-Type: application/json" -u admin:admin -d @chatqna_comprehensive_dashboard_import.json http://localhost:3000/api/dashboards/db
```

### 2. ChatQnA AI/LLM Metrics Dashboard
```bash
curl -X POST -H "Content-Type: application/json" -u admin:admin -d @chatqna_ai_metrics_dashboard_import.json http://localhost:3000/api/dashboards/db
```

## Import Data Sources

### 1. Prometheus Data Source
```bash
curl -X POST -H "Content-Type: application/json" -u admin:admin -d @prometheus_datasource.json http://localhost:3000/api/datasources
```

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

### File Structure Requirements
- All JSON files must be in the same directory as the curl command
- Use `@filename.json` syntax to reference files
- Ensure proper JSON formatting (no syntax errors)

### Usage Instructions
1. Copy all JSON files to the remote node
2. Run the Prometheus data source import first
3. Then import the dashboards
4. Access dashboards at: `http://localhost:3000/d/{uid}/{slug}`

### Alternative Import Methods
- **Grafana UI**: Import via web interface (if available)
- **Provisioning**: Use Grafana provisioning for automated setup
- **Docker volumes**: Mount dashboard files directly

### Security Considerations
- Change default admin password in production
- Use environment variables for credentials
- Consider using API tokens instead of admin credentials
- Restrict network access to Grafana API endpoints
