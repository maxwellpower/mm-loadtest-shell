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

# Builder stage for Terraform and repository cloning
FROM alpine AS builder

# Install necessary packages
ENV TERRAFORM_VERSION=1.7.3

RUN apk add --no-cache curl unzip git \
    # Download and unzip Terraform
    && curl -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /terraform \
    # Clone the Mattermost Load Test NG repository
    && git clone --depth=1 --no-tags https://github.com/mattermost/mattermost-load-test-ng.git /mmlt

# Final stage
FROM golang:alpine

# Install bash for the entrypoint
RUN apk add --no-cache bash

# Copy Terraform binary and cloned repository from the builder stage
COPY --from=builder /terraform/terraform /usr/local/bin/terraform
COPY --from=builder /mmlt /mmlt

# Set the working directory inside the container
WORKDIR /mmlt

RUN go run ./cmd/ltctl loadtest

# Volume to store and persist data
VOLUME ["/mmlt/config"]

ENTRYPOINT ["/bin/bash"]

