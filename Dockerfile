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

ARG GO_VERSION=1.23
ARG ALPINE_VERSION=3.20

FROM alpine AS terraform

RUN apk add --no-cache curl unzip jq bash

COPY /tools /build
WORKDIR /build
RUN chmod -R +x /build && ./buildTerraform

# Builder stage for Terraform and repository cloning
FROM alpine AS mmlt

# Install necessary packages
RUN apk add --no-cache curl git jq bash

RUN git clone --depth=1 --no-tags https://github.com/mattermost/mattermost-load-test-ng.git /mmlt \
    && cp -r /mmlt/config/ /mmlt/config.default \
    && rm -rf /mmlt/.git /mmlt/.github /mmlt/config/*.sample.*

# Final stage
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS final

ENV MMLT_BUILD_VERSION=1.0.0
ENV AWS_SHARED_CREDENTIALS_FILE=/mmlt/config/credentials
ENV AWS_PROFILE=mm-loadtest

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

# Install necessary packages and SSH setup
RUN apk add --no-cache openssh bash nano jq curl aws-cli \
    && chmod -R +x /usr/local/bin \
    && ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

# Set working directory
WORKDIR /mmlt

# Run ltctl and install dependencies
RUN go run ./cmd/ltctl help

# Volume for configuration persistence
VOLUME ["/mmlt/config"]

ENTRYPOINT ["mmltSetup"]
CMD ["mmltShell"]

HEALTHCHECK CMD [ -f /tmp/loadtest.lock ] || exit 1
