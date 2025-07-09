#!/usr/bin/env python3
"""
Simple ChatQnA Evaluation Script
This script evaluates a ChatQnA service by sending test queries and measuring response quality.
"""

import requests
import json
import time
import statistics
from typing import List, Dict, Any
import argparse
from datetime import datetime
import os

class ChatQnAEvaluator:
    def __init__(self, service_url: str = "http://localhost:8888"):
        self.service_url = service_url
        self.results = []
        
    def wait_for_service(self, max_wait_time: int = 300) -> bool:
        """Wait for the ChatQnA service to be ready"""
        print(f"Waiting for ChatQnA service to be ready (max {max_wait_time}s)...")
        
        start_time = time.time()
        while time.time() - start_time < max_wait_time:
            try:
                response = requests.post(
                    f"{self.service_url}/v1/chatqna",
                    headers={"Content-Type": "application/json"},
                    json={"messages": "test"},
                    timeout=10
                )
                
                if response.status_code == 200:
                    print("✅ ChatQnA service is ready!")
                    return True
                elif response.status_code == 500:
                    # Service is running but model is still warming up
                    print("⏳ Service is running, waiting for model to warm up...")
                    time.sleep(30)
                    continue
                else:
                    print(f"⚠️  Service returned status {response.status_code}")
                    time.sleep(10)
                    
            except requests.exceptions.RequestException as e:
                print(f"⏳ Service not ready yet: {e}")
                time.sleep(10)
                
        print("❌ Service did not become ready within the timeout period")
        return False
        
    def test_query(self, query: str) -> Dict[str, Any]:
        """Send a single query to the ChatQnA service"""
        try:
            start_time = time.time()
            
            payload = {
                "messages": query
            }
            
            response = requests.post(
                f"{self.service_url}/v1/chatqna",
                headers={"Content-Type": "application/json"},
                json=payload,
                timeout=120,
                stream=True  # Enable streaming for SSE
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
                                # Decode base64 if needed, otherwise use as-is
                                try:
                                    import base64
                                    decoded = base64.b64decode(data).decode('utf-8')
                                    full_response += decoded
                                except:
                                    # If not base64, use as plain text
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
    
    def evaluate_responses(self, results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Evaluate the quality of responses"""
        successful_results = [r for r in results if r["status"] == "success"]
        
        if not successful_results:
            return {"error": "No successful responses to evaluate"}
        
        # Calculate response time statistics
        response_times = [r["response_time"] for r in successful_results]
        
        # Basic response quality metrics
        avg_response_length = statistics.mean([len(r["response"]) for r in successful_results])
        
        # Calculate success rate
        success_rate = len(successful_results) / len(results) * 100
        
        return {
            "total_queries": len(results),
            "successful_queries": len(successful_results),
            "success_rate": success_rate,
            "response_time_stats": {
                "mean": statistics.mean(response_times),
                "median": statistics.median(response_times),
                "min": min(response_times),
                "max": max(response_times),
                "std": statistics.stdev(response_times) if len(response_times) > 1 else 0
            },
            "response_quality": {
                "avg_response_length": avg_response_length,
                "avg_response_length_chars": avg_response_length
            }
        }
    
    def run_evaluation(self, queries: List[str], output_file: str | None = None, wait_for_service: bool = True) -> Dict[str, Any]:
        """Run the complete evaluation"""
        print(f"Starting ChatQnA evaluation with {len(queries)} queries...")
        print(f"Service URL: {self.service_url}")
        
        # Wait for service to be ready if requested
        if wait_for_service:
            if not self.wait_for_service():
                print("❌ Cannot proceed with evaluation - service is not ready")
                return {"error": "Service not ready"}
        
        results = []
        
        for i, query in enumerate(queries, 1):
            print(f"Query {i}/{len(queries)}: {query[:50]}...")
            result = self.test_query(query)
            results.append(result)
            
            if result["status"] == "success":
                print(f"  ✓ Success ({result['response_time']:.2f}s)")
            else:
                print(f"  ✗ Failed: {result.get('error', 'Unknown error')}")
        
        # Evaluate results
        evaluation = self.evaluate_responses(results)
        
        # Prepare final report
        report = {
            "timestamp": datetime.now().isoformat(),
            "service_url": self.service_url,
            "evaluation_summary": evaluation,
            "detailed_results": results
        }
        
        # Save results
        if output_file:
            os.makedirs(os.path.dirname(output_file), exist_ok=True)
            with open(output_file, 'w') as f:
                json.dump(report, f, indent=2)
            print(f"\nResults saved to: {output_file}")
        
        # Print summary
        self.print_summary(evaluation)
        
        return report
    
    def print_summary(self, evaluation: Dict[str, Any]):
        """Print evaluation summary"""
        print("\n" + "="*50)
        print("EVALUATION SUMMARY")
        print("="*50)
        
        if "error" in evaluation:
            print(f"Error: {evaluation['error']}")
            return
        
        print(f"Total Queries: {evaluation['total_queries']}")
        print(f"Successful Queries: {evaluation['successful_queries']}")
        print(f"Success Rate: {evaluation['success_rate']:.1f}%")
        
        print("\nResponse Time Statistics:")
        rt_stats = evaluation['response_time_stats']
        print(f"  Mean: {rt_stats['mean']:.2f}s")
        print(f"  Median: {rt_stats['median']:.2f}s")
        print(f"  Min: {rt_stats['min']:.2f}s")
        print(f"  Max: {rt_stats['max']:.2f}s")
        print(f"  Std Dev: {rt_stats['std']:.2f}s")
        
        print("\nResponse Quality:")
        quality = evaluation['response_quality']
        print(f"  Average Response Length: {quality['avg_response_length']:.0f} characters")

def main():
    parser = argparse.ArgumentParser(description="Simple ChatQnA Evaluation")
    parser.add_argument("--service-url", default="http://localhost:8888", 
                       help="ChatQnA service URL (AMD/ROCm default)")
    parser.add_argument("--output", default="/home/yw/Desktop/OPEA/evaluation_results/chatqna_eval.json",
                       help="Output file for results")
    parser.add_argument("--queries", nargs="+", 
                       default=[
                           "What is artificial intelligence and how does it work?",
                           "Explain the concept of machine learning in simple terms.",
                           "What are the main applications of AI in healthcare?",
                           "How does natural language processing work?",
                           "What is the difference between supervised and unsupervised learning?",
                           "Explain the concept of neural networks.",
                           "What are the ethical considerations in AI development?",
                           "How does computer vision technology work?",
                           "What is deep learning and why is it important?",
                           "Explain the concept of reinforcement learning."
                       ],
                       help="List of queries to test")
    parser.add_argument("--no-wait", action="store_true",
                       help="Don't wait for service to be ready")
    
    args = parser.parse_args()
    
    # Create evaluator
    evaluator = ChatQnAEvaluator(args.service_url)
    
    # Run evaluation
    evaluator.run_evaluation(args.queries, args.output, not args.no_wait)

if __name__ == "__main__":
    main() 