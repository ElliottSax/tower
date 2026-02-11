# Toonz Animation API - Production Docker Image

FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Rhubarb Lip Sync
RUN wget https://github.com/DanielSWolf/rhubarb-lip-sync/releases/download/v1.13.0/Rhubarb-Lip-Sync-1.13.0-Linux.tar.gz \
    && tar -xzf Rhubarb-Lip-Sync-1.13.0-Linux.tar.gz \
    && mv rhubarb /usr/local/bin/ \
    && rm Rhubarb-Lip-Sync-1.13.0-Linux.tar.gz

# Set working directory
WORKDIR /app

# Copy requirements
COPY requirements-api.txt .
COPY pipeline/requirements.txt ./pipeline-requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements-api.txt -r pipeline-requirements.txt

# Copy application code
COPY pipeline/ ./pipeline/

# Create output directory
RUN mkdir -p /app/outputs

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Run API server
CMD ["uvicorn", "pipeline.api:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
