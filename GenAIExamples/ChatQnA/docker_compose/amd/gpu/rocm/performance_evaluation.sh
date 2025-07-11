#!/bin/bash

# ChatQnA vLLM Performance Evaluation Script
# This script provides comprehensive performance testing and analysis

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_section() {
    echo -e "${PURPLE}--- $1 ---${NC}"
}

# Configuration
BACKEND_URL="http://localhost:8890/v1/chatqna"
DATAPREP_URL="http://localhost:18104/v1/dataprep/ingest"
RESULTS_DIR="./performance_results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create results directory
mkdir -p "$RESULTS_DIR"

# Function to check if services are running
check_services() {
    print_header "Checking Service Status"
    
    if ! docker ps --format "{{.Names}}" | grep -q "chatqna-vllm-service"; then
        print_error "vLLM services are not running. Please start them first:"
        print_status "./run_chatqna.sh start-vllm"
        exit 1
    fi
    
    print_status "vLLM services are running"
}

# Function to test basic connectivity
test_connectivity() {
    print_section "Testing Basic Connectivity"
    
    # Test backend API
    print_status "Testing backend API..."
    if curl -s "$BACKEND_URL" \
        -H "Content-Type: application/json" \
        -d '{"messages": "Hello"}' > /dev/null 2>&1; then
        print_status "✓ Backend API is responding"
    else
        print_error "✗ Backend API is not responding"
        return 1
    fi
    
    # Test dataprep service
    print_status "Testing dataprep service..."
    if curl -s -X POST "$DATAPREP_URL" \
        -H "Content-Type: application/json" \
        -d '{"file_name": "test.txt", "content": "Test document."}' > /dev/null 2>&1; then
        print_status "✓ Dataprep service is responding"
    else
        print_warning "⚠ Dataprep service may not be ready"
    fi
}

# Function to measure latency
measure_latency() {
    print_section "Latency Measurement"
    
    local num_requests=${1:-10}
    local results_file="$RESULTS_DIR/latency_${TIMESTAMP}.txt"
    
    print_status "Measuring latency for $num_requests requests..."
    
    # Test questions for latency measurement
    questions=(
        "What is machine learning?"
        "Explain artificial intelligence"
        "How does deep learning work?"
        "What are neural networks?"
        "Explain natural language processing"
    )
    
    echo "Latency Test Results - $(date)" > "$results_file"
    echo "=================================" >> "$results_file"
    
    total_time=0
    times=()
    
    for i in $(seq 1 $num_requests); do
        # Select a random question
        question="${questions[$((RANDOM % ${#questions[@]}))]}"
        
        start_time=$(date +%s.%N)
        response=$(curl -s "$BACKEND_URL" \
            -H "Content-Type: application/json" \
            -d "{\"messages\": \"$question\"}" \
            -w "%{http_code}")
        end_time=$(date +%s.%N)
        
        latency=$(echo "$end_time - $start_time" | bc -l)
        times+=($latency)
        total_time=$(echo "$total_time + $latency" | bc -l)
        
        echo "Request $i: ${latency}s (HTTP: ${response: -3})" | tee -a "$results_file"
    done
    
    # Calculate statistics
    avg_time=$(echo "scale=3; $total_time / $num_requests" | bc -l)
    
    # Sort times for median calculation
    IFS=$'\n' sorted_times=($(sort -n <<<"${times[*]}"))
    unset IFS
    
    if [ $((${#times[@]} % 2)) -eq 0 ]; then
        # Even number of elements
        mid1=$(((${#times[@]} / 2) - 1))
        mid2=$((${#times[@]} / 2))
        median=$(echo "scale=3; (${sorted_times[$mid1]} + ${sorted_times[$mid2]}) / 2" | bc -l)
    else
        # Odd number of elements
        mid=$(((${#times[@]} - 1) / 2))
        median=${sorted_times[$mid]}
    fi
    
    # Find min and max
    min_time=${sorted_times[0]}
    max_time=${sorted_times[-1]}
    
    echo "" | tee -a "$results_file"
    echo "Latency Statistics:" | tee -a "$results_file"
    echo "  Average: ${avg_time}s" | tee -a "$results_file"
    echo "  Median:  ${median}s" | tee -a "$results_file"
    echo "  Min:     ${min_time}s" | tee -a "$results_file"
    echo "  Max:     ${max_time}s" | tee -a "$results_file"
    
    print_status "Latency measurement completed. Results saved to $results_file"
}

# Function to measure throughput
measure_throughput() {
    print_section "Throughput Measurement"
    
    local duration=${1:-60}  # Duration in seconds
    local concurrency=${2:-5}  # Number of concurrent requests
    local results_file="$RESULTS_DIR/throughput_${TIMESTAMP}.txt"
    
    print_status "Measuring throughput for ${duration}s with ${concurrency} concurrent requests..."
    
    # Test questions for throughput measurement
    questions=(
        "What is AI?"
        "Explain ML"
        "What is NLP?"
        "How does DL work?"
        "What are neural networks?"
    )
    
    echo "Throughput Test Results - $(date)" > "$results_file"
    echo "===================================" >> "$results_file"
    echo "Duration: ${duration}s" >> "$results_file"
    echo "Concurrency: ${concurrency}" >> "$results_file"
    echo "" >> "$results_file"
    
    # Start time
    start_time=$(date +%s)
    end_time=$((start_time + duration))
    
    # Counter for successful requests
    successful_requests=0
    failed_requests=0
    
    # Run concurrent requests
    while [ $(date +%s) -lt $end_time ]; do
        # Start concurrent requests
        for i in $(seq 1 $concurrency); do
            question="${questions[$((RANDOM % ${#questions[@]}))]}"
            
            # Make request in background
            (
                if curl -s "$BACKEND_URL" \
                    -H "Content-Type: application/json" \
                    -d "{\"messages\": \"$question\"}" > /dev/null 2>&1; then
                    echo "success" >> /tmp/throughput_success_$$.tmp
                else
                    echo "failed" >> /tmp/throughput_failed_$$.tmp
                fi
            ) &
        done
        
        # Wait for all background processes
        wait
        
        # Count results
        if [ -f /tmp/throughput_success_$$.tmp ]; then
            successful_requests=$((successful_requests + $(wc -l < /tmp/throughput_success_$$.tmp)))
            rm /tmp/throughput_success_$$.tmp
        fi
        
        if [ -f /tmp/throughput_failed_$$.tmp ]; then
            failed_requests=$((failed_requests + $(wc -l < /tmp/throughput_failed_$$.tmp)))
            rm /tmp/throughput_failed_$$.tmp
        fi
        
        # Small delay to prevent overwhelming
        sleep 0.1
    done
    
    # Calculate throughput
    actual_duration=$((end_time - start_time))
    requests_per_second=$(echo "scale=2; $successful_requests / $actual_duration" | bc -l)
    
    echo "Test Results:" | tee -a "$results_file"
    echo "  Duration: ${actual_duration}s" | tee -a "$results_file"
    echo "  Successful Requests: $successful_requests" | tee -a "$results_file"
    echo "  Failed Requests: $failed_requests" | tee -a "$results_file"
    echo "  Throughput: ${requests_per_second} requests/second" | tee -a "$results_file"
    echo "  Success Rate: $(echo "scale=2; $successful_requests * 100 / ($successful_requests + $failed_requests)" | bc -l)%" | tee -a "$results_file"
    
    print_status "Throughput measurement completed. Results saved to $results_file"
}

# Function to monitor system resources
monitor_resources() {
    print_section "System Resource Monitoring"
    
    local duration=${1:-30}  # Duration in seconds
    local interval=${2:-2}   # Monitoring interval in seconds
    local results_file="$RESULTS_DIR/resources_${TIMESTAMP}.txt"
    
    print_status "Monitoring system resources for ${duration}s (every ${interval}s)..."
    
    echo "System Resource Monitoring - $(date)" > "$results_file"
    echo "=====================================" >> "$results_file"
    echo "Duration: ${duration}s" >> "$results_file"
    echo "Interval: ${interval}s" >> "$results_file"
    echo "" >> "$results_file"
    
    start_time=$(date +%s)
    end_time=$((start_time + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "=== $timestamp ===" >> "$results_file"
        
        # CPU and Memory usage
        echo "System Resources:" >> "$results_file"
        top -bn1 | grep "Cpu(s)\|Mem\|Swap" >> "$results_file"
        
        # Docker container stats
        echo "Docker Container Stats:" >> "$results_file"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | grep chatqna >> "$results_file"
        
        # GPU usage (if available)
        if command -v rocm-smi &> /dev/null; then
            echo "GPU Usage:" >> "$results_file"
            rocm-smi --showproductname --showmeminfo --showuse | grep -E "(GPU|Memory|GPU.*Use)" >> "$results_file"
        fi
        
        echo "" >> "$results_file"
        
        sleep $interval
    done
    
    print_status "Resource monitoring completed. Results saved to $results_file"
}

# Function to run comprehensive evaluation
run_comprehensive_eval() {
    print_header "Comprehensive Performance Evaluation"
    
    # Check services
    check_services
    
    # Test connectivity
    test_connectivity
    
    # Run different types of tests
    print_status "Starting comprehensive evaluation..."
    
    # 1. Latency test
    measure_latency 20
    
    # 2. Throughput test
    measure_throughput 60 3
    
    # 3. Resource monitoring during load
    monitor_resources 60 5
    
    print_status "Comprehensive evaluation completed!"
    print_status "Results saved in: $RESULTS_DIR"
}

# Function to generate summary report
generate_summary() {
    print_section "Generating Summary Report"
    
    local summary_file="$RESULTS_DIR/summary_${TIMESTAMP}.md"
    
    echo "# ChatQnA vLLM Performance Evaluation Summary" > "$summary_file"
    echo "" >> "$summary_file"
    echo "**Date:** $(date)" >> "$summary_file"
    echo "**Backend URL:** $BACKEND_URL" >> "$summary_file"
    echo "" >> "$summary_file"
    
    # Find latest results
    latest_latency=$(ls -t "$RESULTS_DIR"/latency_*.txt 2>/dev/null | head -1)
    latest_throughput=$(ls -t "$RESULTS_DIR"/throughput_*.txt 2>/dev/null | head -1)
    latest_resources=$(ls -t "$RESULTS_DIR"/resources_*.txt 2>/dev/null | head -1)
    
    if [ -n "$latest_latency" ]; then
        echo "## Latency Results" >> "$summary_file"
        echo '```' >> "$summary_file"
        cat "$latest_latency" >> "$summary_file"
        echo '```' >> "$summary_file"
        echo "" >> "$summary_file"
    fi
    
    if [ -n "$latest_throughput" ]; then
        echo "## Throughput Results" >> "$summary_file"
        echo '```' >> "$summary_file"
        cat "$latest_throughput" >> "$summary_file"
        echo '```' >> "$summary_file"
        echo "" >> "$summary_file"
    fi
    
    if [ -n "$latest_resources" ]; then
        echo "## Resource Usage" >> "$summary_file"
        echo "Resource monitoring data available in: $latest_resources" >> "$summary_file"
        echo "" >> "$summary_file"
    fi
    
    echo "## System Information" >> "$summary_file"
    echo "- **Docker Version:** $(docker --version)" >> "$summary_file"
    echo "- **OS:** $(uname -a)" >> "$summary_file"
    if command -v rocm-smi &> /dev/null; then
        echo "- **ROCm Version:** Available" >> "$summary_file"
    fi
    echo "" >> "$summary_file"
    
    echo "## Recommendations" >> "$summary_file"
    echo "1. Review latency results for optimization opportunities" >> "$summary_file"
    echo "2. Monitor resource usage during peak loads" >> "$summary_file"
    echo "3. Consider scaling if throughput is insufficient" >> "$summary_file"
    echo "4. Optimize vLLM parameters based on your use case" >> "$summary_file"
    
    print_status "Summary report generated: $summary_file"
}

# Function to show help
show_help() {
    echo "ChatQnA vLLM Performance Evaluation Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  comprehensive    Run complete evaluation (default)"
    echo "  latency         Measure response latency"
    echo "  throughput      Measure throughput"
    echo "  resources       Monitor system resources"
    echo "  summary         Generate summary report"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run comprehensive evaluation"
    echo "  $0 latency           # Measure latency only"
    echo "  $0 throughput        # Measure throughput only"
    echo "  $0 resources         # Monitor resources only"
    echo "  $0 summary           # Generate summary report"
}

# Main script logic
main() {
    case "${1:-comprehensive}" in
        "comprehensive")
            run_comprehensive_eval
            generate_summary
            ;;
        "latency")
            check_services
            test_connectivity
            measure_latency
            ;;
        "throughput")
            check_services
            test_connectivity
            measure_throughput
            ;;
        "resources")
            check_services
            monitor_resources
            ;;
        "summary")
            generate_summary
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 