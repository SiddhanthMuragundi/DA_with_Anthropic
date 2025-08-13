# Use Python 3.13 slim for smaller image size
FROM python:3.13-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV DUCKDB_EXTENSION_DIRECTORY=/tmp/.duckdb
ENV PATH="/root/.local/bin:$PATH"

# Set the working directory
WORKDIR /app

# Install system dependencies including PostgreSQL and MySQL client libraries
RUN apt-get update && apt-get install -y \
    wget \
    gnupg2 \
    curl \
    unzip \
    libnss3 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libxkbcommon0 \
    libgtk-3-0 \
    libgbm1 \
    libasound2 \
    build-essential \
    pkg-config \
    default-libmysqlclient-dev \
    libpq-dev \
    postgresql-client \
    libssl-dev \
    libffi-dev \
    python3-dev \
    tesseract-ocr \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories with proper permissions
RUN mkdir -p /tmp/.duckdb /app/prompts /app/logs /app/uploads && \
    chmod -R 755 /app && \
    chmod -R 777 /tmp

# Copy requirements first for better Docker layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Install Playwright and browsers
RUN playwright install-deps && \
    playwright install chromium

# Copy application source code
COPY . .

# Create default prompt files if they don't exist
RUN touch /app/prompts/task_breaker.txt && \
    echo "Default task breaker instructions" > /app/prompts/task_breaker.txt

# Create a non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app /tmp/.duckdb

# Switch to non-root user
USER appuser

# Expose the port
EXPOSE 7860

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "7860", "--workers", "1"]
