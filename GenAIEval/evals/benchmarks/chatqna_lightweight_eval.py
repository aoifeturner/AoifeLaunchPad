#!/usr/bin/env python3
"""
Lightweight ChatQnA Evaluation Script
This script evaluates a ChatQnA service with shorter timeouts and simpler queries for quick testing.
"""

import requests
import json
import time
import statistics
from typing import List, Dict, Any
import argparse
from datetime import datetime
import os

class LightweightChatQnAEvaluator:
    def __init__(self, service_url: str = "http://localhost:8888"):
        self.service_url = service_url
        self.results = []
        
    def wait_for_service(self, max_wait_time: int = 60) -> bool:
        """Wait for the ChatQnA service to be ready (shorter timeout)"""
        print(f"Waiting for ChatQnA service to be ready (max {max_wait_time}s)...")
        
        start_time = time.time()
        while time.time() - start_time < max_wait_time:
            try:
                response = requests.post(
                    f"{self.service_url}/v1/chatqna",
                    headers={"Content-Type": "application/json"},
                    json={"messages": "test"},
                    timeout=5  # Shorter timeout
                )
                
                if response.status_code == 200:
                    print("✅ ChatQnA service is ready!")
                    return True
                elif response.status_code == 500:
                    # Service is running but model is still warming up
                    print("⏳ Service is running, waiting for model to warm up...")
                    time.sleep(10)  # Shorter wait
                    continue
                else:
                    print(f"⚠️  Service returned status {response.status_code}")
                    time.sleep(5)
                    
            except requests.exceptions.RequestException as e:
                print(f"⏳ Service not ready yet: {e}")
                time.sleep(5)
                
        print("❌ Service did not become ready within the timeout period")
        return False
        
    def test_query(self, query: str) -> Dict[str, Any]:
        """Send a single query to the ChatQnA service with shorter timeout"""
        try:
            start_time = time.time()
            
            payload = {
                "messages": query
            }
            
            response = requests.post(
                f"{self.service_url}/v1/chatqna",
                headers={"Content-Type": "application/json"},
                json=payload,
                timeout=30,  # Shorter timeout for testing
                stream=True
            )
            
            end_time = time.time()
            response_time = end_time - start_time
            
            if response.status_code == 200:
                # Handle Server-Sent Events (SSE) response
                full_response = ""
                for line in response.iter_lines():
                    if line:
                        line_str = line.decode('utf-8')
                        if line_str.startswith('data: '):
                            data = line_str[6:]  # Remove 'data: ' prefix
                            if data == '[DONE]':
                                break
                            elif data and data != '':
                                try:
                                    import base64
                                    decoded = base64.b64decode(data).decode('utf-8')
                                    full_response += decoded
                                except:
                                    full_response += data
                
                return {
                    "query": query,
                    "response": full_response,
                    "response_time": response_time,
                    "status": "success",
                    "status_code": response.status_code
                }
            else:
                return {
                    "query": query,
                    "response": "",
                    "response_time": response_time,
                    "status": "error",
                    "status_code": response.status_code,
                    "error": response.text
                }
                
        except Exception as e:
            return {
                "query": query,
                "response": "",
                "response_time": 0,
                "status": "exception",
                "error": str(e)
            }
    
    def run_quick_test(self, output_file: str | None = None) -> Dict[str, Any]:
        """Run a quick test with simple queries"""
        print("🚀 Starting lightweight ChatQnA evaluation...")
        print(f"Service URL: {self.service_url}")
        
        # Simple test queries
        test_queries = [
            "Hello",
            "What is AI?",
            "How are you?",
            "Tell me a joke"
        ]
        
        # Wait for service to be ready
        if not self.wait_for_service():
            print("❌ Cannot proceed with evaluation - service is not ready")
            return {"error": "Service not ready"}
        
        results = []
        
        for i, query in enumerate(test_queries, 1):
            print(f"Query {i}/{len(test_queries)}: {query}")
            result = self.test_query(query)
            results.append(result)
            
            if result["status"] == "success":
                print(f"  ✓ Success ({result['response_time']:.2f}s)")
                print(f"  Response: {result['response'][:100]}...")
            else:
                print(f"  ✗ Failed: {result.get('error', 'Unknown error')}")
        
        # Calculate basic metrics
        successful_results = [r for r in results if r["status"] == "success"]
        success_rate = len(successful_results) / len(results) * 100 if results else 0
        
        if successful_results:
            response_times = [r["response_time"] for r in successful_results]
            avg_response_time = statistics.mean(response_times)
            avg_response_length = statistics.mean([len(r["response"]) for r in successful_results])
        else:
            avg_response_time = 0
            avg_response_length = 0
        
        # Prepare report
        report = {
            "timestamp": datetime.now().isoformat(),
            "service_url": self.service_url,
            "evaluation_summary": {
                "total_queries": len(results),
                "successful_queries": len(successful_results),
                "success_rate": success_rate,
                "avg_response_time": avg_response_time,
                "avg_response_length": avg_response_length
            },
            "detailed_results": results
        }
        
        # Save results
        if output_file:
            os.makedirs(os.path.dirname(output_file), exist_ok=True)
            with open(output_file, 'w') as f:
                json.dump(report, f, indent=2)
            print(f"\nResults saved to: {output_file}")
        
        # Print summary
        print(f"\n📊 Quick Test Results:")
        print(f"  Total Queries: {len(results)}")
        print(f"  Successful: {len(successful_results)}")
        print(f"  Success Rate: {success_rate:.1f}%")
        print(f"  Avg Response Time: {avg_response_time:.2f}s")
        print(f"  Avg Response Length: {avg_response_length:.0f} chars")
        
        return report

def main():
    parser = argparse.ArgumentParser(description="Lightweight ChatQnA Evaluation")
    parser.add_argument("--service-url", default="http://localhost:8888", 
                       help="ChatQnA service URL")
    parser.add_argument("--output", default="/home/yw/Desktop/OPEA/evaluation_results/chatqna_quick_test.json",
                       help="Output file path")
    
    args = parser.parse_args()
    
    evaluator = LightweightChatQnAEvaluator(args.service_url)
    evaluator.run_quick_test(args.output)

if __name__ == "__main__":
    main() 