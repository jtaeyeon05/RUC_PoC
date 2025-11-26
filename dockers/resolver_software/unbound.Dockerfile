FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive \
    UNBOUND_VERSION="1.24.2"

# install dependencies
RUN apt-get update && \
    apt-get install -y \
    build-essential libssl-dev libexpat1-dev libevent-dev wget

# build from source code
WORKDIR /tmp
RUN wget https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz && \
    tar -xzf unbound-${UNBOUND_VERSION}.tar.gz

WORKDIR /tmp/unbound-${UNBOUND_VERSION}
RUN ./configure && \
    make && \
    make install

# configure dnssec trust anchor
RUN mkdir -p /usr/local/etc/unbound && \
    mkdir -p /var/lib/unbound && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/unbound.conf && \
    ldconfig && \
    (unbound-anchor -a "/var/lib/unbound/root.key" || true) && \
    cp /var/lib/unbound/root.key /usr/local/etc/unbound/root.key

# configure unbound
RUN echo "\
server:\n\
    interface: 0.0.0.0\n\
    access-control: 0.0.0.0/0 allow\n\
    username: \"root\"\n\
    auto-trust-anchor-file: \"/usr/local/etc/unbound/root.key\"\n\
    module-config: \"validator iterator\"\n\
" > /usr/local/etc/unbound/unbound.conf

# start resolver service
RUN adduser --system --no-create-home --disabled-login unbound
RUN unbound-checkconf /usr/local/etc/unbound/unbound.conf
EXPOSE 53/tcp 53/udp
CMD ["/usr/local/sbin/unbound", "-d"]