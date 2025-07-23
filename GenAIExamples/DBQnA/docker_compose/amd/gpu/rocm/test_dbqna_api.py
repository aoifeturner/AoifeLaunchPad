#!/usr/bin/env python3
"""
DBQnA API Test Script
This script tests the DBQnA API endpoints and functionality
"""

import requests
import json
import time
import sys
import os
from typing import Dict, Any, Optional

class DBQnATester:
    def __init__(self, base_url: str = "http://localhost"):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        })
    
    def test_health_endpoints(self) -> bool:
        """Test health endpoints for all services"""
        print("🔍 Testing health endpoints...")
        
        health_endpoints = [
            f"{self.base_url}:8008/health",  # TGI Service
            f"{self.base_url}:9090/health",  # Text-to-SQL Service
            f"{self.base_url}:5174/health",  # UI Service
        ]
        
        all_healthy = True
        for endpoint in health_endpoints:
            try:
                response = self.session.get(endpoint, timeout=10)
                if response.status_code == 200:
                    print(f"✅ {endpoint} - Healthy")
                else:
                    print(f"❌ {endpoint} - Status: {response.status_code}")
                    all_healthy = False
            except requests.exceptions.RequestException as e:
                print(f"❌ {endpoint} - Error: {e}")
                all_healthy = False
        
        return all_healthy
    
    def test_text_to_sql_api(self, test_queries: list) -> bool:
        """Test the Text-to-SQL API with various queries"""
        print("\n🔍 Testing Text-to-SQL API...")
        
        endpoint = f"{self.base_url}:9090/v1/texttosql"
        
        # Database connection string
        conn_str = {
            "user": "postgres",
            "password": "testpwd",
            "host": self.base_url.replace("http://", ""),
            "port": "5442",
            "database": "chinook"
        }
        
        all_successful = True
        
        for i, query in enumerate(test_queries, 1):
            print(f"\n📝 Test Query {i}: {query}")
            
            payload = {
                "input_text": query,
                "conn_str": conn_str
            }
            
            try:
                response = self.session.post(endpoint, json=payload, timeout=30)
                
                if response.status_code == 200:
                    result = response.json()
                    print(f"✅ Query successful")
                    print(f"   SQL: {result.get('sql', 'N/A')}")
                    print(f"   Result: {result.get('result', 'N/A')}")
                else:
                    print(f"❌ Query failed - Status: {response.status_code}")
                    print(f"   Response: {response.text}")
                    all_successful = False
                    
            except requests.exceptions.RequestException as e:
                print(f"❌ Request failed - Error: {e}")
                all_successful = False
            except json.JSONDecodeError as e:
                print(f"❌ JSON decode error - Error: {e}")
                print(f"   Response: {response.text}")
                all_successful = False
        
        return all_successful
    
    def test_backend_api(self) -> bool:
        """Test the backend API if available"""
        print("\n🔍 Testing Backend API...")
        
        endpoint = f"{self.base_url}:8889/v1/dbqna"
        
        try:
            response = self.session.get(endpoint, timeout=10)
            if response.status_code == 200:
                print(f"✅ Backend API accessible")
                return True
            else:
                print(f"❌ Backend API - Status: {response.status_code}")
                return False
        except requests.exceptions.RequestException as e:
            print(f"❌ Backend API - Error: {e}")
            return False
    
    def test_ui_access(self) -> bool:
        """Test UI accessibility"""
        print("\n🔍 Testing UI access...")
        
        endpoint = f"{self.base_url}:5174"
        
        try:
            response = self.session.get(endpoint, timeout=10)
            if response.status_code == 200:
                print(f"✅ UI accessible at {endpoint}")
                return True
            else:
                print(f"❌ UI - Status: {response.status_code}")
                return False
        except requests.exceptions.RequestException as e:
            print(f"❌ UI - Error: {e}")
            return False
    
    def run_comprehensive_test(self) -> bool:
        """Run all tests"""
        print("🚀 Starting DBQnA Comprehensive API Test")
        print("=" * 50)
        
        # Test queries for the Chinook database
        test_queries = [
            "Find the total number of Albums.",
            "Show me all artists from the database.",
            "What is the average track length?",
            "List all customers from Germany.",
            "How many tracks are there in the Rock genre?"
        ]
        
        # Run all tests
        health_ok = self.test_health_endpoints()
        text2sql_ok = self.test_text_to_sql_api(test_queries)
        backend_ok = self.test_backend_api()
        ui_ok = self.test_ui_access()
        
        # Summary
        print("\n" + "=" * 50)
        print("📊 Test Summary:")
        print(f"   Health Endpoints: {'✅ PASS' if health_ok else '❌ FAIL'}")
        print(f"   Text-to-SQL API: {'✅ PASS' if text2sql_ok else '❌ FAIL'}")
        print(f"   Backend API: {'✅ PASS' if backend_ok else '❌ FAIL'}")
        print(f"   UI Access: {'✅ PASS' if ui_ok else '❌ FAIL'}")
        
        overall_success = health_ok and text2sql_ok and ui_ok
        print(f"\n🎯 Overall Result: {'✅ ALL TESTS PASSED' if overall_success else '❌ SOME TESTS FAILED'}")
        
        return overall_success

def main():
    """Main function"""
    # Get base URL from command line or use default
    base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost"
    
    print(f"🌐 Testing DBQnA at: {base_url}")
    
    # Create tester instance
    tester = DBQnATester(base_url)
    
    # Run comprehensive test
    success = tester.run_comprehensive_test()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main() 