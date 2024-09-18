# Mattermost Load Test Shell

# Copyright (c) 2024 Maxwell Power
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom
# the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
# AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# File: Dockerfile

ARG MMLT_SHELL_VERSION=1.0.2

# Pin Dependencies
ARG MMLT_VERSION=master
ARG GO_VERSION=1.23
ARG DEBIAN_VERSION=bookworm
ARG TERRAFORM_VERSION=1.6.6

# STAGE 1: Build Terraform
FROM debian:${DEBIAN_VERSION} AS terraform

ARG TERRAFORM_VERSION
ENV TERRAFORM_VERSION=$TERRAFORM_VERSION

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    bash \
    jq \
    curl \
    unzip && \
    rm -rf /var/lib/apt/lists/*

COPY /scripts /build
RUN chmod -R +x /build

WORKDIR /build
RUN ./install_terraform

# STAGE 2: Build Load Test Binaries
FROM golang:${GO_VERSION} AS mmlt

ARG MMLT_VERSION
ENV MMLT_VERSION=${MMLT_VERSION}

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    jq \
    curl \
    tar \
    git && \
    rm -rf /var/lib/apt/lists/*

ADD https://api.github.com/repos/mattermost/mattermost-load-test-ng/git/refs/heads/${MMLT_VERSION} version.json
RUN git clone --depth=1 --branch ${MMLT_VERSION} --no-tags https://github.com/mattermost/mattermost-load-test-ng.git /mmlt \
    && cp -r /mmlt/config/ /mmlt/config.default

WORKDIR /mmlt

# Build binaries
RUN go build -o /mmlt/bin/ltctl ./cmd/ltctl \
    && go build -o /mmlt/bin/ltagent ./cmd/ltagent \
    && go build -o /mmlt/bin/ltapi ./cmd/ltapi \
    && go build -o /mmlt/bin/ltassist ./cmd/ltassist \
    && go build -o /mmlt/bin/ltcoordinator ./cmd/ltcoordinator \
    && go build -o /mmlt/bin/metricswatcher ./cmd/metricswatcher \
    && go build -o /mmlt/bin/ltkeycloak ./cmd/ltkeycloak \
    && chmod -R +x /mmlt/bin

# Prepare for packaging
RUN mkdir -p /mmlt/dist/build/mattermost-load-test-ng-linux-amd64/bin && mkdir -p /mmlt/dist/build/mattermost-load-test-ng-linux-amd64/config \
    && cp /mmlt/bin/ltagent /mmlt/bin/ltapi /mmlt/dist/build/mattermost-load-test-ng-linux-amd64/bin \
    && cp /mmlt/config/config.sample.json /mmlt/config/coordinator.sample.json /mmlt/config/simplecontroller.sample.json /mmlt/config/simulcontroller.sample.json /mmlt/dist/build/mattermost-load-test-ng-linux-amd64/config \
    && tar -C /mmlt/dist/build/ -czf /mmlt/dist/mattermost-load-test-ng-linux-amd64.tar.gz mattermost-load-test-ng-linux-amd64 \
    && rm -rf /mmlt/dist/build/ \
    && rm -rf /mmlt/.git /mmlt/.github /mmlt/config/*.sample.* \
    && rm -rf .editorconfig .gitignore .gitignore .gitignore Dockerfile Makefile api/ cmd/ comparison/ coordinator/ defaults/ examples/ go.mod go.sum loadtest/ logger/ performance/

# STAGE 3: Final stage
FROM debian:${DEBIAN_VERSION} AS final

ARG MMLT_SHELL_VERSION
ARG TERRAFORM_VERSION
ARG MMLT_VERSION

ENV MMLT_SHELL_VERSION=${MMLT_SHELL_VERSION}
ENV TERRAFORM_VERSION=${TERRAFORM_VERSION}
ENV MMLT_VERSION=${MMLT_VERSION}

LABEL MAINTAINER="maxwell.power@mattermost.com"
LABEL org.opencontainers.image.title="mm-loadtest-shell"
LABEL org.opencontainers.image.description="Mattermost Load Test Shell"
LABEL org.opencontainers.image.authors="Maxwell Power"
LABEL org.opencontainers.image.source="https://github.com/maxwellpower/mm-loadtest-shell"
LABEL org.opencontainers.image.licenses=MIT

# Copy necessary files from builder stages
COPY --from=terraform /terraform/terraform /usr/local/bin/terraform
COPY --from=mmlt /mmlt /mmlt
COPY bin/ /usr/local/bin/

# Install necessary runtime packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates bash iputils-ping net-tools dnsutils traceroute \
    openssh-client \
    nano \
    jq \
    vim \
    traceroute \
    postgresql-client \
    curl \
    watch \
    awscli less groff && \
    rm -rf /var/lib/apt/lists/* && \
    ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

# Set working directory
WORKDIR /mmlt

# Volume for configuration persistence
VOLUME ["/mmlt/config"]
VOLUME ["/var/lib/mattermost-load-test-ng"]

# Entry point and healthcheck
ENTRYPOINT ["docker-entrypoint"]
CMD ["mmlt"]
HEALTHCHECK CMD [ -f /tmp/loadtest.lock ] || exit 1
