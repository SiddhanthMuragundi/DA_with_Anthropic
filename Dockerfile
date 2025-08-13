# Use stable Python 3.11 slim for compatibility
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

# Install system dependencies needed by Playwright and your app
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
    && rm -rf /var/lib/apt/lists/*

# Prepare directories with proper permissions
RUN mkdir -p /tmp/.duckdb /ms-playwright /app/prompts /app/logs /app/uploads && \
    chmod 777 /tmp /ms-playwright && \
    chmod -R 755 /app

# Copy requirements for Docker cache optimization
COPY requirements.txt .

# Upgrade pip tools and install dependencies
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# Install Playwright and its browsers and dependencies in one step
RUN pip install --no-cache-dir playwright && \
    python -m playwright install --with-deps chromium

# Copy all application source code
COPY . .

# Create default prompt file if not present
RUN mkdir -p /app/prompts && \
    touch /app/prompts/task_breaker.txt && \
    echo "Default task breaker instructions" > /app/prompts/task_breaker.txt

# Add a non-root user and set permissions
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app /tmp/.duckdb /ms-playwright

# Switch to non-root user for runtime security
USER appuser

# Expose port (Railway uses PORT environment variable)
EXPOSE 7860

# Healthcheck to verify the app is running
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:7860/health || exit 1

# Command to run your app
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "7860", "--workers", "1"]
