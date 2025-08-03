# Base image
FROM python:3.10-slim
# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    python3-dev \
    g++ \
    pkg-config \
    poppler-utils \
    libpoppler-cpp-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY doc_processing_service/requirements.txt /app/requirements.txt

# Install Python dependencies
RUN pip install --upgrade pip setuptools
RUN pip install uvicorn uvicorn-worker gunicorn
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install gunicorn newrelic

# Copy app files
COPY . /src
RUN useradd -m -d /src -s /bin/bash app \
    && chown -R app:app /src/* && chmod +x /src/*
# Set PYTHONPATH to /app
ENV PYTHONPATH=/src
WORKDIR /src/doc_processing_service

# Run migrations and start the server
CMD ["../init_script.sh"]

