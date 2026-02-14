#!/usr/bin/env python3
"""
Python Client for Cloud Compute Worker

This client demonstrates how to offload compute tasks from your local
Python application to Cloudflare Workers edge network.

Usage:
    python python-client.py
"""

import requests
import time
from typing import Dict, Any, List, Optional

BASE_URL = 'https://my-first-worker.elliottsaxton.workers.dev'
API_KEY = 'SECRET_API_KEY_c7a3b8e2d1f0'


class CloudComputeClient:
    """Client for interacting with the Cloud Compute Worker API."""

    def __init__(self, base_url: str = BASE_URL, api_key: str = API_KEY):
        self.base_url = base_url
        self.api_key = api_key
        self.session = requests.Session()
        self.session.headers.update({
            'X-API-Key': api_key,
            'Content-Type': 'application/json'
        })

    def _request(self, endpoint: str, method: str = 'GET', data: Optional[Dict] = None) -> Dict:
        """Make a request to the API."""
        url = f"{self.base_url}{endpoint}"

        if method == 'GET':
            response = self.session.get(url)
        elif method == 'POST':
            response = self.session.post(url, json=data)
        else:
            raise ValueError(f"Unsupported method: {method}")

        response.raise_for_status()
        return response.json()

    # Immediate compute operations
    def hash(self, text: str) -> Dict:
        """Generate SHA-256 hash of text."""
        return self._request('/compute/hash', 'POST', {'text': text})

    def base64_encode(self, input_str: str) -> Dict:
        """Encode string to Base64."""
        return self._request('/compute/base64', 'POST', {
            'operation': 'encode',
            'input': input_str
        })

    def base64_decode(self, input_str: str) -> Dict:
        """Decode Base64 string."""
        return self._request('/compute/base64', 'POST', {
            'operation': 'decode',
            'input': input_str
        })

    def transform_json(self, data: Any, transform: str = 'flatten') -> Dict:
        """Transform JSON data."""
        return self._request('/compute/json-transform', 'POST', {
            'data': data,
            'transform': transform
        })

    # Async job operations
    def submit_job(self, job_type: str, payload: Dict) -> Dict:
        """Submit an async job."""
        return self._request('/jobs', 'POST', {
            'type': job_type,
            'payload': payload
        })

    def get_job(self, job_id: str) -> Dict:
        """Get job status and results."""
        return self._request(f'/jobs/{job_id}')

    def list_jobs(self) -> Dict:
        """List recent jobs."""
        return self._request('/jobs')

    def wait_for_job(self, job_id: str, poll_interval: float = 1.0, timeout: float = 30.0) -> Any:
        """Wait for a job to complete and return the result."""
        start_time = time.time()

        while time.time() - start_time < timeout:
            job = self.get_job(job_id)

            if job['status'] == 'completed':
                return job['result']
            elif job['status'] == 'failed':
                raise Exception(f"Job failed: {job.get('error', 'Unknown error')}")

            time.sleep(poll_interval)

        raise TimeoutError(f"Job {job_id} did not complete within {timeout} seconds")

    # High-level convenience methods
    def analyze_text(self, text: str) -> Dict:
        """Analyze text and return statistics."""
        result = self.submit_job('text-analysis', {'text': text})
        return self.wait_for_job(result['jobId'])

    def transform_data(self, data: List, operation: str) -> Any:
        """Transform array data."""
        result = self.submit_job('data-transform', {
            'data': data,
            'operation': operation
        })
        return self.wait_for_job(result['jobId'])

    def heavy_compute(self, iterations: int) -> Dict:
        """Perform heavy computation."""
        result = self.submit_job('heavy-compute', {'iterations': iterations})
        return self.wait_for_job(result['jobId'])


def main():
    """Example usage of the Cloud Compute Client."""
    client = CloudComputeClient()

    print('=== Cloud Compute Worker Examples ===\n')

    # Example 1: Hash generation
    print('1. Hash Generation:')
    hash_result = client.hash('Hello, World!')
    print(f'   Hash: {hash_result["hash"]}\n')

    # Example 2: Base64 encoding
    print('2. Base64 Encoding:')
    encoded = client.base64_encode('Cloud computing is awesome!')
    print(f'   Encoded: {encoded["result"]}\n')

    # Example 3: JSON transformation
    print('3. JSON Transformation:')
    flattened = client.transform_json({
        'user': {'name': 'John', 'address': {'city': 'NYC', 'zip': '10001'}}
    }, 'flatten')
    print(f'   Flattened: {flattened["result"]}\n')

    # Example 4: Text analysis (async job)
    print('4. Text Analysis (Async Job):')
    text_stats = client.analyze_text(
        'The quick brown fox jumps over the lazy dog. This is a test sentence.'
    )
    print(f'   Stats: {text_stats}\n')

    # Example 5: Data transformation (async job)
    print('5. Data Transformation (Async Job):')
    sorted_data = client.transform_data([5, 2, 8, 1, 9, 3], 'sort')
    print(f'   Sorted: {sorted_data}\n')

    # Example 6: Heavy compute
    print('6. Heavy Compute (100k iterations):')
    compute_start = time.time()
    heavy_result = client.heavy_compute(100000)
    compute_time = (time.time() - compute_start) * 1000
    print(f'   Result: {heavy_result["result"]}')
    print(f'   Time: {compute_time:.0f}ms\n')

    # Example 7: List recent jobs
    print('7. Recent Jobs:')
    jobs_data = client.list_jobs()
    print(f'   Total jobs: {jobs_data["count"]}')
    for job in jobs_data['jobs'][:3]:
        print(f'   - {job["id"]}: {job["type"]} ({job["status"]})')


if __name__ == '__main__':
    main()
