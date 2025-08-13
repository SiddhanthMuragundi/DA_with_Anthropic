# Use a stable Python version for better compatibility
FROM python:3.11-slim

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DUCKDB_EXTENSION_DIRECTORY=/tmp/.duckdb \
    PATH="/root/.local/bin:$PATH" \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    PORT=7860

# Set working directory
WORKDIR /app

# Install system dependencies
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
    # Note: libgconf-2-4 removed in new Debian; can be omitted if not needed
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories with proper permissions
RUN mkdir -p /tmp/.duckdb /app/prompts /app/logs /app/uploads /ms-playwright && \
    chmod -R 755 /app && \
    chmod -R 777 /tmp && \
    chmod -R 777 /ms-playwright

# Copy requirements first for caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Install Playwright and Chromium
RUN pip install playwright && \
    playwright install chromium && \
    playwright install-deps

# Copy the full application
COPY . .

# Create default prompt files if missing
RUN touch /app/prompts/task_breaker.txt && \
    echo "Default task breaker instructions" > /app/prompts/task_breaker.txt

# Create a non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app /tmp/.duckdb /ms-playwright

# Switch to non-root
USER appuser

# Expose application port
EXPOSE 7860

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:7860/health || exit 1

# Start the app
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "7860", "--workers", "1"]
