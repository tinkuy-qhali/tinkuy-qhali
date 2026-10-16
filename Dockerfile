# syntax=docker/dockerfile:1.7
# tinkuy-qhali — single reproducible image: R (rocker) + Python (uv) + Julia (juliaup) + DVC + Quarto + Claude Code.
# Why one image: every pipeline stage runs as a separate process inside the same container and exchanges Parquet;
# three lockfiles (env/r/renv.lock, env/python/uv.lock, env/julia/Manifest.toml) are baked in and verified in CI.
# Decision record: docs/adr/0006-imagen-base.md

ARG R_VERSION=4.6.0
FROM rocker/r-ver:${R_VERSION} AS base

LABEL org.opencontainers.image.title="tinkuy-qhali" \
      org.opencontainers.image.source="https://github.com/tinkuy-qhali/tinkuy-qhali" \
      org.opencontainers.image.licenses="MIT"

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Lima \
    LANG=en_US.UTF-8 \
    TQ_IN_CONTAINER=1

# --- system libraries: geospatial (sf/terra), graphics (ragg/textshaping for Quarto), tooling ---------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget git git-lfs unzip zip zstd jq make pkg-config less nano \
      locales tzdata gnupg openssh-client util-linux \
      libgdal-dev libgeos-dev libproj-dev libudunits2-dev libsqlite3-dev \
      libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev \
      libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev \
      libpng-dev libtiff-dev libjpeg-dev libcairo2-dev libglpk-dev \
    && sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen \
    && rm -rf /var/lib/apt/lists/*

# --- Quarto (pinned; rocker official script) ------------------------------------------------------------------------
ARG QUARTO_VERSION=1.10.19
RUN if [ ! -f /rocker_scripts/install_quarto.sh ]; then mkdir -p /rocker_scripts       && curl -fsSL -o /rocker_scripts/install_quarto.sh https://raw.githubusercontent.com/rocker-org/rocker-versioned2/master/scripts/install_quarto.sh       && chmod +x /rocker_scripts/install_quarto.sh; fi     && QUARTO_VERSION=${QUARTO_VERSION} /rocker_scripts/install_quarto.sh     && quarto --version

# --- Python toolchain: uv (pinned binary), Python, DVC with S3 extra (for Cloudflare R2) -----------------------------
ARG UV_VERSION=0.13.1
ARG PYTHON_VERSION=3.13
ARG DVC_VERSION=3.67.1
COPY --from=ghcr.io/astral-sh/uv:0.13.1 /uv /uvx /usr/local/bin/
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python \
    UV_TOOL_DIR=/opt/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/opt/uv/venv
RUN uv python install ${PYTHON_VERSION} \
    && uv tool install --python ${PYTHON_VERSION} "dvc[s3]==${DVC_VERSION}" \
    && dvc --version
COPY env/python/ /opt/env/python/
RUN cd /opt/env/python \
    && if [ ! -f uv.lock ]; then uv lock; fi \
    && uv sync --frozen --no-dev \
    && cp uv.lock /opt/env/python/uv.lock.generated
ENV PATH=/opt/uv/venv/bin:${PATH}

# --- Julia via juliaup (pinned channel) + precompiled depot in its own cached layer ----------------------------------
# Julia is available from day one, but using it in a pipeline stage still requires a benchmark and an ADR (spec 0.6).
ARG WITH_JULIA=1
ARG JULIA_VERSION=1.13.2
ENV JULIAUP_DEPOT_PATH=/opt/juliaup \
    JULIA_DEPOT_PATH=/opt/julia-depot \
    JULIA_PROJECT=/opt/env/julia \
    JULIA_HOME=/opt/juliaup/bin \
    PATH=/opt/juliaup/bin:${PATH}
RUN if [ "${WITH_JULIA}" = "1" ]; then \
      curl -fsSL https://install.julialang.org | sh -s -- --yes --default-channel ${JULIA_VERSION} \
        --path /opt/juliaup --add-to-path no --background-selfupdate 0 --startup-selfupdate 0 \
      && julia --version ; \
    fi
COPY env/julia/ /opt/env/julia/
RUN if [ "${WITH_JULIA}" = "1" ]; then       julia /opt/env/julia/setup.jl       && chmod -R a+rX /opt/julia-depot /opt/juliaup ;     fi

# --- R packages: restore from env/r/renv.lock if present, else install the list from the pinned P3M snapshot --------
# rocker/r-ver already sets CRAN to a dated p3m.dev snapshot with Ubuntu binaries, so installs are fast and reproducible.
ENV RENV_PATHS_LIBRARY=/usr/local/lib/R/site-library \
    RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
    RENV_PATHS_CACHE=/opt/renv-cache
# System requirements of every curated R package for Ubuntu 24.04, as reported by Posit Package Manager's sysreqs API
# (union in env/r/sysreqs-ubuntu-24.04.txt, one row per package -> dependency -> apt package). P3M binaries link against
# these (fs -> libuv, V8 -> libnode), so they must exist even though no compilation happens. Separate layer keeps caches above.
RUN apt-get update && apt-get install -y --no-install-recommends \
      cmake gdal-bin libabsl-dev libglpk-dev libicu-dev libnode-dev libuv1-dev libx11-dev pandoc xz-utils zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
COPY env/r/ /opt/env/r/
RUN Rscript /opt/env/r/install_packages.R \
    && Rscript -e 'library(arrow); library(duckdb); library(sf); library(targets); cat("R stack ok\n")'

# --- Non-root user (rocker/r-ver removes noble default user: create uid/gid 1000 explicitly) + Claude Code ----------
ARG CLAUDE_CODE_VERSION=2.1.301
ENV HOME=/home/ubuntu
RUN (getent group 1000 >/dev/null || groupadd -g 1000 ubuntu) \
    && (id -u ubuntu >/dev/null 2>&1 || useradd -m -u 1000 -g 1000 -s /bin/bash ubuntu) \
    && mkdir -p /workspace /home/ubuntu/.claude /home/ubuntu/.julia /home/ubuntu/.cache \
    && chown -R ubuntu:ubuntu /workspace /home/ubuntu
USER ubuntu
RUN curl -fsSL https://claude.ai/install.sh | bash -s ${CLAUDE_CODE_VERSION} \
    && /home/ubuntu/.local/bin/claude --version
USER root
ENV PATH=/home/ubuntu/.local/bin:${PATH} \
    JULIA_DEPOT_PATH=/home/ubuntu/.julia:/opt/julia-depot

COPY docker/entrypoint.sh /usr/local/bin/tq-entrypoint
RUN chmod +x /usr/local/bin/tq-entrypoint
WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/tq-entrypoint"]
CMD ["bash"]
