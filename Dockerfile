FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/root \
    PATH="/opt/spacetools/:${PATH}"

COPY cleanup /usr/local/sbin/
COPY spacetools /opt/spacetools/

# Install required packages
RUN echo 'APT::Get::Assume-Yes "true";' >> /etc/apt/apt.conf \
    && apt-get update && apt-get install \
    bash \
    ca-certificates \
    curl \
    git \
    gnutls-bin \
    gnupg \
    gzip \
    hub \
    jq \
    make \
    openssl \
    rsync \
    tar \
    emacs \
    && cleanup

# Set correct permissions
RUN chmod 777 /opt/spacetools/spacedoc/sdnize \
    && chmod 775 /opt/spacetools/run

# Create .emacs.d directory
RUN mkdir -p "${HOME}/.emacs.d"

WORKDIR "${HOME}/.emacs.d"

ENTRYPOINT ["/opt/spacetools/run"]
CMD ["--help"]
