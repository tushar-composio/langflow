# syntax=docker/dockerfile:1
# Keep this syntax directive! It's used to enable Docker BuildKit


################################
# BUILDER-BASE
# Used to build deps + create our virtual environment
################################

# 1. use python:3.12.3-slim as the base image until https://github.com/pydantic/pydantic-core/issues/1292 gets resolved
# 2. do not add --platform=$BUILDPLATFORM because the pydantic binaries must be resolved for the final architecture
# Use a Python image with uv pre-installed
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

# Install the project into `/app`
WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    # deps for building python deps
    build-essential \
    # npm
    npm \
    # gcc
    gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install the project's dependencies using the lockfile and settings
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=src/backend/base/uv.lock \
    --mount=type=bind,source=src/backend/base/README.md,target=src/backend/base/README.md \
    --mount=type=bind,source=src/backend/base/pyproject.toml,target=src/backend/base/pyproject.toml \
    uv sync --frozen --directory src/backend/base --no-install-project --no-dev --no-editable

ADD ./src /app/src

COPY src/frontend /tmp/src/frontend
WORKDIR /tmp/src/frontend
RUN npm install \
    && npm run build \
    && cp -r build /app/src/backend/base/langflow/frontend \
    && rm -rf /tmp/src/frontend

ADD ./uv.lock /app/src/backend/base/uv.lock
ADD ./src/backend/base/pyproject.toml /app/src/backend/base/pyproject.toml
ADD ./src/backend/base/README.md /app/src/backend/base/README.md

WORKDIR /app/src/backend/base
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

################################
# RUNTIME
# Setup user, utilities and copy the virtual environment only
################################
FROM python:3.12.3-slim AS runtime

RUN useradd user -u 1000 -g 0 --no-create-home --home-dir /app/data
COPY --from=builder --chown=1000 /app/src/backend/base/.venv /app/src/backend/base/.venv

# Place executables in the environment at the front of the path
ENV PATH="/app/src/backend/base/.venv/bin:$PATH"

LABEL org.opencontainers.image.title=langflow
LABEL org.opencontainers.image.authors=['Langflow']
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.url=https://github.com/langflow-ai/langflow
LABEL org.opencontainers.image.source=https://github.com/langflow-ai/langflow

USER user
WORKDIR /app

ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860

CMD ["langflow-base", "run"]
