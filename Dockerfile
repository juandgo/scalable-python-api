# --- Stage 1: Base Setup (Alpine) ---
FROM python:3.13-alpine AS python_base

# Python optimizations
ENV PYTHONUNBUFFERED=1
ENV UV_COMPILE_BYTECODE=1

WORKDIR /app

# --- Stage 2: Builder ---
FROM python_base AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/

COPY pyproject.toml uv.lock ./

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

# --- Stage 3: Dev Enviroments ---
FROM python_base AS dev
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Add common debug tools for local troubleshooting
RUN apk add --no-cache \
    curl \
    git \
    vim \
    bind-tools \
    netcat-openbsd \
    procps

WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app/src"

COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project

# Ajustamos la ruta en el CMD para que apunte a la nueva ubicación
CMD ["fastapi", "dev", "src/blazing/main.py", "--host", "0.0.0.0", "--port", "8000"]

# --- Stage 4: Production (The tiny image) ---
FROM python_base AS prod

RUN addgroup -S appuser && adduser -S appuser -G appuser -h /app
USER appuser

COPY --from=builder /app/.venv /app/.venv
COPY src /src

ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app/src"

CMD ["uvicorn", "blazing.main:app", "--host", "0.0.0.0", "--port", "8000"]
