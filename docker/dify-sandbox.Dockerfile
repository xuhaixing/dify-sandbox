FROM golang:1.23-bookworm AS builder

ARG TARGETARCH

# using goproxy if you have network issues
ENV GOPROXY=https://goproxy.cn,direct

# copy project
COPY . /app
WORKDIR /app



# RUN chmod +x /app/install.sh && /app/install.sh
RUN apt update && apt-get install -y pkg-config gcc libseccomp-dev \
    && go mod tidy \
    && case "${TARGETARCH}" in \
       "amd64") bash ./build/build_amd64.sh ;; \
       "arm64") bash ./build/build_arm64.sh ;; \
       *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
       esac


FROM python:3.10-slim-bookworm

RUN rm -rf /etc/apt/sources.list.d/*
ADD ./docker/sources.list /etc/apt/

ARG TARGETARCH
# if you located in China, you can use aliyun mirror to speed up
ARG DEBIAN_MIRROR="http://mirrors.aliyun.com/debian testing main"
# ARG DEBIAN_MIRROR="http://deb.debian.org/debian testing main"

ARG NODEJS_VERSION=v20.11.1
ARG NODEJS_MIRROR="https://npmmirror.com/mirrors/node"

# Install system dependencies
RUN echo "deb ${DEBIAN_MIRROR}" > /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       pkg-config \
       libseccomp-dev \
       wget \
       curl \
       xz-utils \
       zlib1g \
       expat \
       perl \
       libsqlite3-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
# Copy source code
COPY . /app

# copy main binary to /main
# COPY main /main
# copy initial env
# COPY env /env


COPY --from=builder /app/internal/core/runner/python/python.so /app/internal/core/runner/python/python.so
COPY --from=builder /app/internal/core/runner/nodejs/nodejs.so /app/internal/core/runner/nodejs/nodejs.so

COPY --from=builder /app/main /app/env /
# copy config file
COPY conf/config.yaml /conf/config.yaml
# copy python dependencies
COPY dependencies/python-requirements.txt /dependencies/python-requirements.txt
# copy entrypoint
COPY docker/entrypoint.sh /entrypoint.sh

RUN pip3 install --no-cache-dir httpx==0.27.2 requests==2.32.3 jinja2==3.1.6 PySocks httpx[socks]  -i https://mirrors.aliyun.com/pypi/simple/

ARG NODEJS_ARCH
# Install Node.js based on architecture
RUN case "${TARGETARCH}" in \
    "amd64") \
        NODEJS_ARCH="linux-x64" ;; \
    "arm64") \
        NODEJS_ARCH="linux-arm64" ;; \
    *) \
        echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && wget -O /opt/node-${NODEJS_VERSION}-${NODEJS_ARCH}.tar.xz \
       ${NODEJS_MIRROR}/${NODEJS_VERSION}/node-${NODEJS_VERSION}-${NODEJS_ARCH}.tar.xz

RUN ls -al /env && ldd /env || true

RUN chmod +x /main /env /entrypoint.sh \
    && /env \
    && rm -f /env

ENV NODE_TAR_XZ=/opt/node-${NODEJS_VERSION}-linux-__ARCH__.tar.xz
ENV NODE_DIR=/opt/node-${NODEJS_VERSION}-linux-__ARCH__

ENTRYPOINT ["/entrypoint.sh"]
