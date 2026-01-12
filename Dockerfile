# syntax=docker/dockerfile:1

FROM haskell:9.6 AS builder

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    libicu-dev \
    libtinfo6 \
    libgmp-dev \
    zlib1g-dev \
    pkg-config \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src

COPY stack.yaml stack.yaml.lock ./
COPY pandoc.cabal .
COPY pandoc-cli/pandoc-cli.cabal pandoc-cli/
COPY pandoc-server/pandoc-server.cabal pandoc-server/
COPY pandoc-lua-engine/pandoc-lua-engine.cabal pandoc-lua-engine/

ENV STACK_ROOT=/opt/stack \
    PATH=/root/.local/bin:${PATH}

RUN stack setup --system-ghc
RUN stack build --system-ghc --only-dependencies

COPY . .

RUN stack build --system-ghc --copy-bins --local-bin-path /opt/pandoc/bin
RUN mkdir -p /opt/pandoc/share && cp -a data/. /opt/pandoc/share/

FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    libicu72 \
    libtinfo6 \
    libgmp10 \
    libffi8 \
    zlib1g \
  && rm -rf /var/lib/apt/lists/*

ENV PANDOC_DATA_DIR=/usr/share/pandoc

COPY --from=builder /opt/pandoc/bin/pandoc /usr/local/bin/pandoc
COPY --from=builder /opt/pandoc/share /usr/share/pandoc
COPY docker/entrypoint/pandoc-run.sh /usr/local/bin/pandoc-run
RUN chmod +x /usr/local/bin/pandoc-run

ENTRYPOINT ["/usr/local/bin/pandoc-run"]
CMD ["--help"]
