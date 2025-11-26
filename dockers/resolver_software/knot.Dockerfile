FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV KNOT_VERSION="5.7.6"

# install dependencies
RUN apt-get update && \
    apt-get install -y \
        build-essential pkg-config meson ninja-build \
        libknot-dev libuv1-dev libluajit-5.1-dev libssl-dev \
        libcmocka-dev liblmdb-dev luajit luajit-5.1-dev \
        wget ca-certificates dnsutils

# build from source code
RUN wget https://knot-resolver.nic.cz/release/knot-resolver-${KNOT_VERSION}.tar.xz -O /tmp/knot-resolver.tar.xz && \
    tar xvf /tmp/knot-resolver.tar.xz -C /tmp/ && \
    cd /tmp/knot-resolver-*/ && \
    meson setup --prefix=/usr --buildtype=release --sysconfdir=/etc build && \
    cd build && ninja && ninja install

# configure knot resolver
RUN mkdir -p /etc/knot-resolver && \
    touch /etc/knot-resolver/kresd.conf

RUN echo "\
-- SPDX-License-Identifier: CC0-1.0\n\
-- vim:syntax=lua:set ts=4 sw=4:\n\
-- Refer to manual: https://knot-resolver.readthedocs.org/en/stable/\n\
\n\
-- Network interface configuration\n\
net.listen('0.0.0.0', 53, { kind = 'dns' })\n\
net.listen('0.0.0.0', 853, { kind = 'tls' })\n\
--net.listen('127.0.0.1', 443, { kind = 'doh2' })\n\
net.listen('::', 53, { kind = 'dns', freebind = true })\n\
net.listen('::', 853, { kind = 'tls', freebind = true })\n\
--net.listen('::1', 443, { kind = 'doh2' })\n\
\n\
-- Load useful modules\n\
modules = {\n\
        'hints > iterate',  -- Allow loading /etc/hosts or custom root hints\n\
        'stats',            -- Track internal statistics\n\
        'predict',          -- Prefetch expiring/frequent records\n\
}\n\
\n\
-- Cache size\n\
cache.size = 100 * MB\n\
" > /etc/knot-resolver/kresd.conf

# start resolver service
EXPOSE 53/tcp 53/udp
CMD ["/usr/sbin/kresd", "-c", "/etc/knot-resolver/kresd.conf", "-v", "-n"]
