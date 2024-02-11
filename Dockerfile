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
RUN apk add --no-cache curl unzip git jq

COPY .docker /build
WORKDIR /build

RUN chmod -R +x /build

# Install Terraform
RUN ./buildTerraform

# Clone the Mattermost Load Test NG repository
RUN git clone --depth=1 --no-tags https://github.com/mattermost/mattermost-load-test-ng.git /mmlt
RUN rm -rf /mmlt/.git
RUN rm -rf /mmlt/.github
RUN cp -r /mmlt/config/ /mmlt/config.default

# Final stage
FROM golang:alpine as final

LABEL MAINTAINER="maxwell.power@mattermost.com"
LABEL org.opencontainers.image.title="mm-loadtest-shell"
LABEL org.opencontainers.image.description="Mattermost Load Test Shell"
LABEL org.opencontainers.image.authors="Maxwell Power"
LABEL org.opencontainers.image.source="https://github.com/maxwellpower/mm-loadtest-shell"
LABEL org.opencontainers.image.licenses=MIT

# Install bash for the entrypoint
RUN apk add --no-cache zsh openssh \
&& ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

# Copy Terraform binary and cloned repository from the builder stage
COPY --from=builder /terraform/terraform /usr/local/bin/terraform
COPY --from=builder /mmlt /mmlt
COPY --from=builder /build/entrypoint /usr/local/bin/docker-entrypoint

# Set the working directory inside the container
WORKDIR /mmlt

RUN go run ./cmd/ltctl loadtest init

# Volume to store and persist data
VOLUME ["/mmlt/config"]

ENTRYPOINT ["docker-entrypoint"]
CMD ["/bin/zsh"]
