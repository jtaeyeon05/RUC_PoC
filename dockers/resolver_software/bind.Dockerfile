FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV BIND_VERSION="9.20.16"

# install dependencies
RUN apt update && \
    apt install -y \
    liburcu-dev libnghttp2-dev build-essential libssl-dev libuv1-dev \
    libcap-dev libtool automake pkg-config python3-ply wget

# build from source code
RUN wget https://downloads.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.xz && \
    tar xvf bind-${BIND_VERSION}.tar.xz && \
    cd bind-${BIND_VERSION} && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    rndc-confgen -a

# dump configuration file
RUN mkdir -p /usr/share/dns && \
    mkdir -p /var/cache/bind && \
    wget -O /usr/share/dns/root.hints https://www.internic.net/domain/named.root
RUN echo 'include "/usr/local/etc/rndc.key";\n\noptions {\n    directory "/var/cache/bind";\n    allow-query { any; };\n    allow-recursion { any; };\n};\n\nzone "." {\n    type hint;\n    file "/usr/share/dns/root.hints";\n};' > /usr/local/etc/named.conf

# start resolver service
EXPOSE 53/tcp 53/udp
CMD ["/usr/local/sbin/named", "-u", "root", "-g"]