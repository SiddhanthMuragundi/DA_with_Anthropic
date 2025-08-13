# Use Python 3.11 slim for better compatibility
FROM python:3.13-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV DUCKDB_EXTENSION_DIRECTORY=/tmp/.duckdb
ENV PATH="/root/.local/bin:$PATH"
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
ENV PORT=7860

# Set the working directory
WORKDIR /app

# Install system dependencies including PostgreSQL and MySQL client libraries
RUN apt-get update && apt-get install -y \
    wget \
    gnupg2 \
    curl \
    unzip \
    build-essential \
    pkg-config \
    default-libmysqlclient-dev \
    libpq-dev \
    postgresql-client \
    libssl-dev \
    libffi-dev \
    python3-dev \
    tesseract-ocr \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libdrm2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    libgbm1 \
    libxss1 \
    libgconf-2-4 \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories with proper permissions
RUN mkdir -p /tmp/.duckdb /app/prompts /app/logs /app/uploads /ms-playwright && \
    chmod -R 755 /app && \
    chmod -R 777 /tmp && \
    chmod -R 777 /ms-playwright

# Copy requirements first for better Docker layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Install Playwright and browsers (fixed version)
RUN pip install playwright && \
    playwright install chromium && \
    playwright install-deps

# Copy application source code
COPY . .

# Create default prompt files if they don't exist
RUN touch /app/prompts/task_breaker.txt && \
    echo "Default task breaker instructions" > /app/prompts/task_breaker.txt

# Create a non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app /tmp/.duckdb /ms-playwright

# Switch to non-root user
USER appuser

# Expose the port
EXPOSE 7860

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:7860/health || exit 1

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "7860", "--workers", "1"]
