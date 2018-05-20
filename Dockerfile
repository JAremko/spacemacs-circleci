FROM jare/spacedoc

MAINTAINER JAremko <w3techplaygound@gmail.com>

COPY cleanup /usr/local/sbin/

# basic stuff
RUN echo 'APT::Get::Assume-Yes "true";' >> /etc/apt/apt.conf \
    && apt-get update && apt-get install \
    bash \
    ca-certificates \
    curl \
    git \
    git \
    gzip \
    jq \
    make \
    openssl \
    tar \
    && cleanup
