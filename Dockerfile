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

# Builder stage for Terraform and repository cloning
FROM alpine AS builder

# Install necessary packages and set up Terraform
RUN apk add --no-cache curl unzip git jq bash \
    && git clone --depth=1 --no-tags https://github.com/mattermost/mattermost-load-test-ng.git /mmlt \
    && cp -r /mmlt/config/ /mmlt/config.default \
    && rm -rf /mmlt/.git /mmlt/.github /mmlt/config/*.sample.* /var/cache/apk/*

COPY .docker /build
WORKDIR /build
RUN chmod -R +x /build && ./buildTerraform

# Final stage
FROM golang:alpine as final

LABEL MAINTAINER="maxwell.power@mattermost.com"
LABEL org.opencontainers.image.title="mm-loadtest-shell"
LABEL org.opencontainers.image.description="Mattermost Load Test Shell"
LABEL org.opencontainers.image.authors="Maxwell Power"
LABEL org.opencontainers.image.source="https://github.com/maxwellpower/mm-loadtest-shell"
LABEL org.opencontainers.image.licenses=MIT

# Install necessary packages and SSH setup
RUN apk add --no-cache openssh bash nano jq curl \
    && ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

# Copy necessary files from builder stage
COPY --from=builder /terraform/terraform /usr/local/bin/terraform
COPY --from=builder /mmlt /mmlt

# Set aliases and environment variables in .bashrc
RUN echo 'alias ltcreate="go run ./cmd/ltctl deployment create"' >> /root/.bashrc \
    && echo 'alias ltinfo="go run ./cmd/ltctl deployment info"' >> /root/.bashrc \
    && echo 'alias ltsync="go run ./cmd/ltctl deployment sync"' >> /root/.bashrc \
    && echo 'alias ltdestroy="go run ./cmd/ltctl deployment destroy"' >> /root/.bashrc \
    && echo 'alias ltstart="go run ./cmd/ltctl loadtest start"' >> /root/.bashrc \
    && echo 'alias ltstatus="go run ./cmd/ltctl loadtest status"' >> /root/.bashrc \
    && echo 'alias ltstop="go run ./cmd/ltctl loadtest stop"' >> /root/.bashrc \
    && echo 'alias ltssh="go run ./cmd/ltctl ssh"' >> /root/.bashrc \
    && echo 'alias ltreset="go run ./cmd/ltctl loadtest reset"' >> /root/.bashrc

# Set working directory
WORKDIR /mmlt

# Ensure Go modules are initialized and dependencies are pulled
RUN go mod tidy

# Run the initial Terraform setup command
RUN go run ./cmd/ltctl loadtest

# Ensure scripts are executable
COPY runLoadTest /usr/local/bin/runLoadTest
COPY configureLoadTest /usr/local/bin/configureLoadTest
COPY .docker/entrypoint /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/runLoadTest /usr/local/bin/configureLoadTest /usr/local/bin/docker-entrypoint

# Volume for configuration persistence
VOLUME ["/mmlt/config"]

ENTRYPOINT ["docker-entrypoint"]
CMD ["runLoadTest"]

HEALTHCHECK CMD [ -f /tmp/loadtest.lock ] || exit 1
