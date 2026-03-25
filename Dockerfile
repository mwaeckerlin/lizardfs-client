# lizardfs-client is not available in Ubuntu 22.04+, so ubuntu:20.04 is required
FROM ubuntu:20.04

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      rsync \
      lizardfs-client \
 && rm -rf /var/lib/apt/lists/*
