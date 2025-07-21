#!/bin/bash

# AvatarChatbot TGI Performance Evaluation Script
# Provides comprehensive performance testing and analysis

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${BLUE}================================${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}================================${NC}"; }
print_section() { echo -e "${PURPLE}--- $1 ---${NC}"; }

BACKEND_URL="http://localhost:8888/v1/avatarchatbot"
RESULTS_DIR="./performance_results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$RESULTS_DIR"

check_services() {
    print_header "Checking Service Status"
    if ! docker ps --format "{{.Names}}" | grep -q "avatarchatbot-backend-server"; then
        print_error "AvatarChatbot backend service is not running. Please start it first."; exit 1;
    fi
    print_status "AvatarChatbot backend service is running"
}

test_connectivity() {
    print_section "Testing Basic Connectivity"
    print_status "Testing backend API..."
    if curl -s "$BACKEND_URL" -H "Content-Type: application/json" -d '{"messages": "Hello"}' > /dev/null 2>&1; then
        print_status "\u2713 Backend API is responding"
    else
        print_error "\u2717 Backend API is not responding"; return 1;
    fi
}

measure_latency() {
    print_section "Latency Measurement"
    local num_requests=${1:-10}
    local results_file="$RESULTS_DIR/latency_${TIMESTAMP}.txt"
    print_status "Measuring latency for $num_requests requests..."
    questions=("What is AvatarChatbot?" "How does TGI work?" "What is AI?" "Tell me a joke." "What is deep learning?")
    echo "Latency Test Results - $(date)" > "$results_file"
    echo "=================================" >> "$results_file"
    total_time=0
    times=()
    for i in $(seq 1 $num_requests); do
        question="${questions[$((RANDOM % ${#questions[@]}))]}"
        start_time=$(date +%s.%N)
        response=$(curl -s "$BACKEND_URL" -H "Content-Type: application/json" -d "{\"messages\": \"$question\"}" -w "%{http_code}")
        end_time=$(date +%s.%N)
        latency=$(echo "$end_time - $start_time" | bc -l)
        times+=($latency)
        total_time=$(echo "$total_time + $latency" | bc -l)
        echo "Request $i: ${latency}s (HTTP: ${response: -3})" | tee -a "$results_file"
    done
    avg_time=$(echo "scale=3; $total_time / $num_requests" | bc -l)
    IFS=$'\n' sorted_times=($(sort -n <<<"${times[*]}")); unset IFS
    if [ $((${#times[@]} % 2)) -eq 0 ]; then mid1=$(((${#times[@]} / 2) - 1)); mid2=$((${#times[@]} / 2)); median=$(echo "scale=3; (${sorted_times[$mid1]} + ${sorted_times[$mid2]}) / 2" | bc -l); else mid=$(((${#times[@]} - 1) / 2)); median=${sorted_times[$mid]}; fi
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

measure_throughput() {
    print_section "Throughput Measurement"
    local duration=${1:-60}
    local concurrency=${2:-5}
    local results_file="$RESULTS_DIR/throughput_${TIMESTAMP}.txt"
    print_status "Measuring throughput for ${duration}s with ${concurrency} concurrent requests..."
    questions=("What is AI?" "How does AvatarChatbot work?" "What is TGI?" "Tell me a fun fact." "What is NLP?")
    echo "Throughput Test Results - $(date)" > "$results_file"
    echo "===================================" >> "$results_file"
    echo "Duration: ${duration}s" >> "$results_file"
    echo "Concurrency: ${concurrency}" >> "$results_file"
    echo "" >> "$results_file"
    start_time=$(date +%s)
    end_time=$((start_time + duration))
    successful_requests=0
    failed_requests=0
    while [ $(date +%s) -lt $end_time ]; do
        for i in $(seq 1 $concurrency); do
            question="${questions[$((RANDOM % ${#questions[@]}))]}"
            (
                if curl -s "$BACKEND_URL" -H "Content-Type: application/json" -d "{\"messages\": \"$question\"}" > /dev/null 2>&1; then
                    echo "success" >> /tmp/throughput_success_$$.tmp
                else
                    echo "failed" >> /tmp/throughput_failed_$$.tmp
                fi
            ) &
        done
        wait
        if [ -f /tmp/throughput_success_$$.tmp ]; then
            successful_requests=$((successful_requests + $(wc -l < /tmp/throughput_success_$$.tmp)))
            rm /tmp/throughput_success_$$.tmp
        fi
        if [ -f /tmp/throughput_failed_$$.tmp ]; then
            failed_requests=$((failed_requests + $(wc -l < /tmp/throughput_failed_$$.tmp)))
            rm /tmp/throughput_failed_$$.tmp
        fi
        sleep 0.1
    done
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

monitor_resources() {
    print_section "System Resource Monitoring"
    local duration=${1:-30}
    local interval=${2:-2}
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
        echo "System Resources:" >> "$results_file"
        top -bn1 | grep "Cpu(s)\|Mem\|Swap" >> "$results_file"
        echo "Docker Container Stats:" >> "$results_file"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | grep avatarchatbot >> "$results_file"
        echo "" >> "$results_file"
        sleep $interval
    done
    print_status "Resource monitoring completed. Results saved to $results_file"
}

run_comprehensive_eval() {
    print_header "Comprehensive Performance Evaluation"
    check_services
    test_connectivity
    print_status "Starting comprehensive evaluation..."
    measure_latency 20
    measure_throughput 60 3
    monitor_resources 60 5
    print_status "Comprehensive evaluation completed!"
    print_status "Results saved in: $RESULTS_DIR"
}

generate_summary() {
    print_section "Generating Summary Report"
    local summary_file="$RESULTS_DIR/summary_${TIMESTAMP}.md"
    echo "# AvatarChatbot TGI Performance Evaluation Summary" > "$summary_file"
    echo "" >> "$summary_file"
    echo "**Date:** $(date)" >> "$summary_file"
    echo "**Backend URL:** $BACKEND_URL" >> "$summary_file"
    echo "" >> "$summary_file"
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
    echo "" >> "$summary_file"
    echo "## Recommendations" >> "$summary_file"
    echo "1. Review latency results for optimization opportunities" >> "$summary_file"
    echo "2. Monitor resource usage during peak loads" >> "$summary_file"
    echo "3. Consider scaling if throughput is insufficient" >> "$summary_file"
    echo "4. Optimize TGI parameters based on your use case" >> "$summary_file"
    print_status "Summary report generated: $summary_file"
}

show_help() {
    echo "AvatarChatbot TGI Performance Evaluation Script"
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

main "$@" 