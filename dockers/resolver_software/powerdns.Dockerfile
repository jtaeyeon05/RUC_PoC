FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive \
    POWERDNS_VERSION="5.3.1"

# install dependencies
RUN apt-get update && \
    apt-get install -y \
        g++ make pkg-config libboost-all-dev libtool autoconf automake \
        libssl-dev libsqlite3-dev libpq-dev libmysqlclient-dev lua5.3 liblua5.3-dev \
        curl wget ca-certificates dnsutils

# build from source code
RUN wget https://downloads.powerdns.com/releases/pdns-recursor-${POWERDNS_VERSION}.tar.xz && \
    tar xjf pdns-recursor-${POWERDNS_VERSION}.tar.xz && \
    cd pdns-recursor-${POWERDNS_VERSION} && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . $HOME/.cargo/env && \
    ./configure && \
    make -j$(nproc) && \
    make install

# start resolver service
RUN mkdir -p /var/run/pdns-recursor && \
    touch /var/log/powerdns.log && \
    chmod 644 /var/log/powerdns.log

# configure powerdns
RUN mkdir -p /usr/share/dns /usr/local/etc /etc/powerdns/recursor.d

RUN curl -o /usr/share/dns/root.hints https://www.internic.net/domain/named.root
RUN echo ". IN DNSKEY 257 3 8 AwEAAaz/tAm8yTn4Mfeh5eyI96WSVexTBAvkMgJzkKTOiW1vkIbzxeF3+/4RgWOq7HrxRixHlFlExOLAJr5emLvN7SWXgnLh4+B5xQlNVz8Og8kvArMtNROxVQuCaSnIDdD5LKyWbRd2n9WGe2R8PzgCmr3EgVLrjyBxWezF0jLHwVN8efS3rCj/EWgvIWgb9tarpVUDK/b58Da+sqqls3eNbuv7pr+eoZG+SrDK6nWeL3c6H5Apxz7LjVc1uTIdsIXxuOLYA4/ilBmSVIzuDWfdRUfhHdY6+cn8HFRm+2hM8AnXGXws9555KrUB5qihylGa8subX2Nn6UwNR1AkUTV74bU= ; keytag 20326\n\
. IN DNSKEY 257 3 8 AwEAAa96jeuknZlaeSrvyAJj6ZHv28hhOKkx3rLGXVaC6rXTsDc449/cidltpkyGwCJNnOAlFNKF2jBosZBU5eeHspaQWOmOElZsjICMQMC3aeHbGiShvZsx4wMYSjH8e7Vrhbu6irwCzVBApESjbUdpWWmEnhathWu1jo+siFUiRAAxm9qyJNg/wOZqqzL/dL/q8PkcRU5oUKEpUge71M3ej2/7CPqpdVwuMoTvoB+ZOT4YeGyxMvHmbrxlFzGOHOijtzN+u1TQNatX2XBuzZNQ1K+s2CXkPIZo7s6JgZyvaBevYtxPvYLw4z9mR7K2vaF18UYH9Z9GNUUeayffKC73PYc= ; keytag 38696" > /usr/share/dns/root.key

RUN echo "dnssec:\n\
  trustanchorfile: /usr/share/dns/root.key\n\
\n\
recursor:\n\
  hint_file: /usr/share/dns/root.hints\n\
  include_dir: /etc/powerdns/recursor.d\n\
\n\
incoming:\n\
  allow_from:\n\
    - 0.0.0.0/0\n\
  listen:\n\
    - 0.0.0.0\n\
\n\
outgoing:\n\
  dont_query:\n\
    - 127.0.0.0/8" > /usr/local/etc/recursor.conf

EXPOSE 53/tcp 53/udp
CMD ["/usr/local/sbin/pdns_recursor", "--config-dir=/usr/local/etc"]
