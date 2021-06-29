### Dockerfile --- Dockerfile for Spacemacs' CircleCI jobs
##
## Copyright (c) 2012-2021 Sylvain Benner & Contributors
##
## Author: Eugene "JAremko" Yaremenko <w3techplayground@gmail.com>
##
##
## This file is not part of GNU Emacs.
##
### License: GPLv3

FROM jare/spacetools:noemacs

ENV DEBIAN_FRONTEND=noninteractive

COPY cleanup /usr/local/sbin/

# basic stuff
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
    && cleanup

RUN apt-get update && apt-get install emacs-nox \
    && cleanup
