#!/bin/bash
#
# Cloud Compute CLI Tool
#
# A simple bash script to interact with the Cloud Compute Worker
# from the command line.
#
# Usage:
#   ./cli-tool.sh hash "text to hash"
#   ./cli-tool.sh analyze "long text to analyze"
#   ./cli-tool.sh compute 50000
#   ./cli-tool.sh jobs
#

set -e

BASE_URL="https://my-first-worker.elliottsaxton.workers.dev"
API_KEY="SECRET_API_KEY_c7a3b8e2d1f0"

# Helper function to make API requests
api_request() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" "${BASE_URL}${endpoint}" \
            -H "X-API-Key: ${API_KEY}" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "${BASE_URL}${endpoint}" \
            -H "X-API-Key: ${API_KEY}"
    fi
}

# Command handlers
cmd_hash() {
    local text="$1"
    echo "Computing hash for: $text"
    result=$(api_request "/compute/hash" "POST" "{\"text\": \"$text\"}")
    echo "$result" | jq -r '.hash'
}

cmd_encode() {
    local text="$1"
    echo "Encoding to Base64: $text"
    result=$(api_request "/compute/base64" "POST" "{\"operation\": \"encode\", \"input\": \"$text\"}")
    echo "$result" | jq -r '.result'
}

cmd_decode() {
    local encoded="$1"
    echo "Decoding from Base64: $encoded"
    result=$(api_request "/compute/base64" "POST" "{\"operation\": \"decode\", \"input\": \"$encoded\"}")
    echo "$result" | jq -r '.result'
}

cmd_analyze() {
    local text="$1"
    echo "Submitting text analysis job..."

    # Submit job
    job_response=$(api_request "/jobs" "POST" "{\"type\": \"text-analysis\", \"payload\": {\"text\": \"$text\"}}")
    job_id=$(echo "$job_response" | jq -r '.jobId')
    echo "Job ID: $job_id"

    # Poll for completion
    echo "Waiting for results..."
    for i in {1..30}; do
        sleep 1
        job_status=$(api_request "/jobs/$job_id")
        status=$(echo "$job_status" | jq -r '.status')

        if [ "$status" = "completed" ]; then
            echo ""
            echo "Results:"
            echo "$job_status" | jq '.result'
            return 0
        elif [ "$status" = "failed" ]; then
            echo "Job failed: $(echo "$job_status" | jq -r '.error')"
            return 1
        fi

        echo -n "."
    done

    echo ""
    echo "Job timed out"
    return 1
}

cmd_compute() {
    local iterations="$1"
    echo "Submitting heavy compute job ($iterations iterations)..."

    # Submit job
    job_response=$(api_request "/jobs" "POST" "{\"type\": \"heavy-compute\", \"payload\": {\"iterations\": $iterations}}")
    job_id=$(echo "$job_response" | jq -r '.jobId')
    echo "Job ID: $job_id"

    # Poll for completion
    echo "Computing..."
    for i in {1..60}; do
        sleep 1
        job_status=$(api_request "/jobs/$job_id")
        status=$(echo "$job_status" | jq -r '.status')

        if [ "$status" = "completed" ]; then
            echo ""
            echo "Results:"
            echo "$job_status" | jq '.result'
            return 0
        elif [ "$status" = "failed" ]; then
            echo "Job failed: $(echo "$job_status" | jq -r '.error')"
            return 1
        fi

        echo -n "."
    done

    echo ""
    echo "Job timed out"
    return 1
}

cmd_jobs() {
    echo "Recent jobs:"
    result=$(api_request "/jobs")
    echo "$result" | jq '.jobs[] | "\(.id | .[0:8])... [\(.type)] \(.status)"' -r
}

cmd_health() {
    echo "Checking worker health..."
    result=$(api_request "/health")
    echo "$result" | jq '.'
}

# Main command dispatcher
case "${1:-help}" in
    hash)
        cmd_hash "$2"
        ;;
    encode)
        cmd_encode "$2"
        ;;
    decode)
        cmd_decode "$2"
        ;;
    analyze)
        cmd_analyze "$2"
        ;;
    compute)
        cmd_compute "${2:-100000}"
        ;;
    jobs)
        cmd_jobs
        ;;
    health)
        cmd_health
        ;;
    help|*)
        echo "Cloud Compute CLI Tool"
        echo ""
        echo "Usage:"
        echo "  $0 hash <text>         - Generate SHA-256 hash"
        echo "  $0 encode <text>       - Encode to Base64"
        echo "  $0 decode <encoded>    - Decode from Base64"
        echo "  $0 analyze <text>      - Analyze text (async)"
        echo "  $0 compute [iterations] - Heavy compute (async)"
        echo "  $0 jobs                - List recent jobs"
        echo "  $0 health              - Check worker health"
        echo ""
        echo "Examples:"
        echo "  $0 hash \"Hello World\""
        echo "  $0 analyze \"The quick brown fox jumps over the lazy dog\""
        echo "  $0 compute 50000"
        ;;
esac
