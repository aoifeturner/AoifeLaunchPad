# ChatQnA vLLM Complete System Architecture

## System Overview

ChatQnA with vLLM is a comprehensive Retrieval-Augmented Generation (RAG) system that combines document retrieval with high-performance LLM inference. The system is built using a microservices architecture with Docker containers.

## Complete System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                               EXTERNAL ACCESS                                   │
│                                                                                 │
│   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────────┐ │
│   │   Web Browser   │    │   API Clients   │    │   Monitoring Tools          │ │
│   │                 │    │                 │    │   (Grafana, Prometheus)     │ │
│   └─────────────────┘    └─────────────────┘    └─────────────────────────────┘ │
│           │                       │                           │                 │
│           │                       │                           │                 │
│           ▼                       ▼                           ▼                 │
│   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────────┐ │
│   │   Nginx Proxy   │    │   Backend API   │    │   Redis Insight             │ │
│   │   (Port 8081)   │    │   (Port 8890)   │    │   (Port 8002)               │ │
│   └─────────────────┘    └─────────────────┘    └─────────────────────────────┘ │
│           │                       │                           │                 │
│           │                       │                           │                 │
│           ▼                       ▼                           ▼                 │
│   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────────┐ │
│   │   Frontend UI   │    │   Backend       │    │   Redis Vector Database     │ │
│   │   (Port 5174)   │    │   Server        │    │   (Port 6380)               │ │
│   │   (React App)   │    │   (FastAPI)     │    │   (Vector Storage)          │ │
│   └─────────────────┘    └─────────────────┘    └─────────────────────────────┘ │
│                                   │                           │                 │
│                                   │                           │                 │
│                                   ▼                           ▼                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐│
│  │                           RAG PIPELINE                                      ││
│  │                                                                             ││
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐  ││
│  │  │   Retriever     │    │   TEI Embedding │    │   TEI Reranking         │  ││
│  │  │   Service       │    │   Service       │    │   Service               │  ││
│  │  │   (Port 7001)   │    │   (Port 18091)  │    │   (Port 18809)          │  ││
│  │  │                 │    │                 │    │                         │  ││
│  │  │ • Vector Search │    │ • Text Embedding│    │ • Document Reranking    │  ││
│  │  │ • Similarity    │    │ • BGE Model     │    │ • Relevance Scoring     │  ││
│  │  │   Matching      │    │ • CPU Inference │    │ • CPU Inference         │  ││
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────────┘  ││
│  │           │                       │                       │                 ││
│  │           │                       │                       │                 ││
│  │           ▼                       ▼                       ▼                 ││
│  │  ┌─────────────────────────────────────────────────────────────────────────┐││
│  │  │                    vLLM Service                                         │││
│  │  │                    (Port 18009)                                         │││
│  │  │                                                                         │││
│  │  │  • High-Performance LLM Inference                                       │││
│  │  │  • AMD GPU Acceleration (ROCm)                                          │││
│  │  │  • Qwen2.5-7B-Instruct Model                                            │││
│  │  │  • Optimized for Throughput & Latency                                   │││
│  │  │  • Tensor Parallel Support                                              │││
│  │  └─────────────────────────────────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────────────────────────┘│
│                                   │                                             │
│                                   │                                             │
│                                   ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────┐│
│  │                           DATA PIPELINE                                     ││
│  │                                                                             ││
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐  ││
│  │  │   Dataprep      │    │   Model Cache   │    │   Document Storage      │  ││
│  │  │   Service       │    │   (./data)      │    │   (Redis Vector DB)     │  ││
│  │  │   (Port 18104)  │    │                 │    │                         │  ││
│  │  │                 │    │ • Downloaded    │    │ • Vector Embeddings     │  ││
│  │  │ • Document      │    │   Models        │    │ • Metadata Index        │  ││
│  │  │   Processing    │    │ • Model Weights │    │ • Full-Text Search      │  ││
│  │  │ • Text          │    │ • Cache Storage │    │ • Similarity Search     │  ││
│  │  │   Extraction    │    │ • Shared Volume │    │ • Redis Stack           │  ││
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────────┘  ││
│  └─────────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Service Details

### Frontend Layer
- **Nginx Proxy** (Port 8081): Reverse proxy for external access
- **Frontend UI** (Port 5174): React-based web interface
- **Backend API** (Port 8890): FastAPI server handling requests

### RAG Pipeline
- **Retriever Service** (Port 7001): Vector search and document retrieval
- **TEI Embedding Service** (Port 18091): Text embedding generation
- **TEI Reranking Service** (Port 18809): Document relevance scoring
- **vLLM Service** (Port 18009): High-performance LLM inference

### Data Layer
- **Redis Vector Database** (Port 6380): Vector storage and search
- **Dataprep Service** (Port 18104): Document processing and ingestion
- **Model Cache** (./data): Shared volume for model storage

### Monitoring
- **Redis Insight** (Port 8002): Database monitoring interface

## Data Flow

### 1. Document Ingestion Flow
```
User Upload → Dataprep Service → TEI Embedding → Redis Vector DB
```

### 2. Question Answering Flow
```
User Question → Backend API → TEI Embedding → Retriever Service → 
Redis Vector DB → TEI Reranking → vLLM Service → Response
```

### 3. Real-time Processing Flow
```
1. User submits question via Frontend
2. Backend API receives request
3. TEI Embedding Service converts question to vector
4. Retriever Service searches Redis Vector DB
5. TEI Reranking Service scores retrieved documents
6. vLLM Service generates answer using context
7. Response returned to user via Frontend
```

## Network Architecture

### Internal Communication
- All services communicate via Docker network `rocm_default`
- Internal ports used for inter-service communication
- External ports exposed for client access

### Port Configuration
| Service | Internal Port | External Port | Purpose |
|---------|---------------|---------------|---------|
| Frontend UI | 5173 | 5174 | Web interface |
| Backend API | 8888 | 8890 | API endpoints |
| vLLM Service | 8011 | 18009 | LLM inference |
| Retriever | 7000 | 7001 | Vector search |
| TEI Embedding | 80 | 18091 | Text embedding |
| TEI Reranking | 80 | 18809 | Document reranking |
| Redis Vector DB | 6379 | 6380 | Vector storage |
| Redis Insight | 8001 | 8002 | Database monitoring |
| Dataprep | 5000 | 18104 | Document processing |
| Nginx Proxy | 80 | 8081 | Reverse proxy |

## Resource Requirements

### GPU Resources
- **vLLM Service**: Primary GPU usage for LLM inference
- **AMD GPU**: ROCm support for acceleration
- **Memory**: 128GB shared memory allocation
- **Devices**: `/dev/kfd` and `/dev/dri` for GPU access

### CPU Resources
- **TEI Services**: CPU-based embedding and reranking
- **Backend**: FastAPI request handling
- **Retriever**: Vector search operations
- **Dataprep**: Document processing

### Memory Resources
- **Redis**: Vector database storage
- **Model Cache**: Shared volume for model weights
- **Container Memory**: Per-service memory allocation

## Security & Access Control

### Network Security
- Internal services communicate via Docker network
- External access through Nginx proxy
- Port-based access control

### GPU Security
- Device access through Docker device mapping
- Group permissions for video devices
- Security options for GPU access

### Data Security
- Environment variable configuration
- Token-based authentication for model access
- Container isolation

## Monitoring & Observability

### Service Health
- Health checks for critical services
- Docker container monitoring
- Service dependency management

### Performance Metrics
- GPU utilization monitoring
- Memory usage tracking
- Response time measurement
- Throughput analysis

### Logging
- Container-level logging
- Service-specific log aggregation
- Error tracking and debugging

## Scalability Considerations

### Horizontal Scaling
- Multiple vLLM instances for higher throughput
- Load balancing across services
- Redis clustering for vector storage

### Vertical Scaling
- GPU memory optimization
- Model parameter tuning
- Resource allocation adjustment

### Performance Optimization
- vLLM parameter tuning
- Batch processing optimization
- Caching strategies
- Network optimization

---

This architecture provides a complete, scalable, and high-performance RAG system optimized for AMD GPUs with ROCm support. 
