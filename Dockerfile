# Use Python 3.13 slim for smaller image size
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
    # Essential Playwright dependencies only (minimal approach)
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgdk-pixbuf-2.0-0 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxkbcommon0 \
    libxrandr2 \
    libxss1 \
    libxtst6 \
    libgbm1 \
    xdg-utils \
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

# Install Playwright browsers AFTER pip install (this is the key fix)
RUN python -m playwright install --with-deps chromium

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

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "7860", "--workers", "1"]
